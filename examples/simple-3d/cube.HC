// A software 3D renderer in about 200 lines: rotation, perspective
// projection, backface culling, flat shading and painter's-algorithm
// sorting. Everything runs on the CPU and draws into a Canvas.
//
// This is a concept demo for learning the pipeline. For a real 3D game,
// do the same maths in HolyC but hand the triangles to OpenGL
// (see ../opengl-demo).
//
//   ./cube              open a window; Space toggles wireframe, Esc quits
//   ./cube --ppm a.ppm  render one frame to a file, no window

#include "../common/canvas.HC"
#include "../common/sdl2.HC"
#include "../common/screen.HC"

#define WIDTH     320
#define HEIGHT    200
#define SCALE     3
#define FOCAL     220.0
#define NEAR_Z    0.1
#define MAX_FACES 64

class Vec3
{
  F64 x, y, z;
};

class Mesh
{
  I64 vertex_count;
  F64 *vertices;
  I64 tri_count;
  I64 *tris;
  U32 *colors;
};

class Face
{
  I64 x0, y0, x1, y1, x2, y2;
  F64 depth;
  U32 color;
};

F64 g_cube_vertices[8 * 3] = {
  -1.0, -1.0, -1.0,   1.0, -1.0, -1.0,   1.0, 1.0, -1.0,   -1.0, 1.0, -1.0,
  -1.0, -1.0,  1.0,   1.0, -1.0,  1.0,   1.0, 1.0,  1.0,   -1.0, 1.0,  1.0,
};

// Counter-clockwise when seen from outside the cube.
I64 g_cube_tris[12 * 3] = {
  0, 2, 1,  0, 3, 2,
  4, 5, 6,  4, 6, 7,
  0, 1, 5,  0, 5, 4,
  3, 6, 2,  3, 7, 6,
  0, 4, 7,  0, 7, 3,
  1, 2, 6,  1, 6, 5,
};

U32 g_cube_colors[12] = {
  0xFFE05A47, 0xFFE05A47, 0xFF4FA3E0, 0xFF4FA3E0,
  0xFFF2C14E, 0xFFF2C14E, 0xFF5FCB7A, 0xFF5FCB7A,
  0xFFB57BE0, 0xFFB57BE0, 0xFFE0E0E0, 0xFFE0E0E0,
};

F64 g_pyramid_vertices[5 * 3] = {
  -1.0, -1.0, -1.0,   1.0, -1.0, -1.0,   1.0, -1.0, 1.0,   -1.0, -1.0, 1.0,
   0.0,  1.2,  0.0,
};

I64 g_pyramid_tris[6 * 3] = {
  0, 1, 2,  0, 2, 3,
  0, 4, 1,  1, 4, 2,  2, 4, 3,  3, 4, 0,
};

U32 g_pyramid_colors[6] = {
  0xFF8A6A50, 0xFF8A6A50, 0xFFE8A33D, 0xFFD48A2C, 0xFFE8A33D, 0xFFD48A2C,
};

Mesh g_cube;
Mesh g_pyramid;
Face g_faces[MAX_FACES];
I64 g_order[MAX_FACES];
I64 g_face_count;

U0 V3Sub(Vec3 *out, Vec3 *a, Vec3 *b)
{
  out->x = a->x - b->x;
  out->y = a->y - b->y;
  out->z = a->z - b->z;
}

F64 V3Dot(Vec3 *a, Vec3 *b)
{
  return a->x * b->x + a->y * b->y + a->z * b->z;
}

U0 V3Cross(Vec3 *out, Vec3 *a, Vec3 *b)
{
  F64 x = a->y * b->z - a->z * b->y;
  F64 y = a->z * b->x - a->x * b->z;
  F64 z = a->x * b->y - a->y * b->x;
  out->x = x;
  out->y = y;
  out->z = z;
}

// Rotate around Y (yaw) then X (pitch), scale, then move into place.
U0 TransformPoint(Vec3 *out, F64 *v, F64 yaw, F64 pitch, F64 size, Vec3 *pos)
{
  F64 cy = cos(yaw), sy = sin(yaw);
  F64 cp = cos(pitch), sp = sin(pitch);
  F64 x = v[0] * cy + v[2] * sy;
  // Written this way round on purpose: hcc 0.0.15 parses `-v[0] * sy + ...`
  // as `-(v[0] * sy + ...)` when the negated operand is indexed.
  F64 z = v[2] * cy - v[0] * sy;
  F64 y = v[1] * cp - z * sp;
  z = v[1] * sp + z * cp;
  out->x = x * size + pos->x;
  out->y = y * size + pos->y;
  out->z = z * size + pos->z;
}

U32 Shade(U32 color, F64 light)
{
  I64 r = (color >> 16) & 0xFF, g = (color >> 8) & 0xFF, b = color & 0xFF;
  F64 fr = r * light, fg = g * light, fb = b * light;
  I64 ir = fr, ig = fg, ib = fb;
  return Rgb(ir, ig, ib);
}

U0 ProjectPoint(Vec3 *p, I64 *sx, I64 *sy)
{
  F64 x = WIDTH / 2 + p->x * FOCAL / p->z;
  F64 y = HEIGHT / 2 - p->y * FOCAL / p->z;
  *sx = x;
  *sy = y;
}

// Transforms one object and queues its visible triangles.
U0 QueueMesh(Mesh *m, Vec3 *pos, F64 yaw, F64 pitch, F64 size)
{
  Vec3 world[8];
  for (I64 i = 0; i < m->vertex_count; i++)
    TransformPoint(&world[i], &m->vertices[i * 3], yaw, pitch, size, pos);

  Vec3 light;
  light.x = -0.4; light.y = 0.7; light.z = -0.6;
  F64 light_len = sqrt(V3Dot(&light, &light));

  for (I64 t = 0; t < m->tri_count; t++) {
    Vec3 *a = &world[m->tris[t * 3]];
    Vec3 *b = &world[m->tris[t * 3 + 1]];
    Vec3 *c = &world[m->tris[t * 3 + 2]];
    if (a->z < NEAR_Z || b->z < NEAR_Z || c->z < NEAR_Z)
      continue;

    Vec3 ab, ac, normal;
    V3Sub(&ab, b, a);
    V3Sub(&ac, c, a);
    V3Cross(&normal, &ab, &ac);

    // The camera sits at the origin, so `a` is also the view direction.
    // A face pointing away from the camera can't be seen.
    if (V3Dot(&normal, a) > 0.0)
      continue;
    if (g_face_count >= MAX_FACES)
      return;

    F64 brightness = V3Dot(&normal, &light) / (sqrt(V3Dot(&normal, &normal)) * light_len);
    if (brightness < 0.0)
      brightness = 0.0;
    brightness = 0.25 + brightness * 0.75;

    Face *f = &g_faces[g_face_count];
    ProjectPoint(a, &f->x0, &f->y0);
    ProjectPoint(b, &f->x1, &f->y1);
    ProjectPoint(c, &f->x2, &f->y2);
    f->depth = a->z + b->z + c->z;
    f->color = Shade(m->colors[t], brightness);
    g_order[g_face_count] = g_face_count;
    g_face_count++;
  }
}

// Painter's algorithm: draw far faces first so near ones cover them.
U0 SortFacesFarToNear()
{
  for (I64 i = 1; i < g_face_count; i++) {
    I64 key = g_order[i];
    I64 j = i - 1;
    while (j >= 0) {
      if (g_faces[g_order[j]].depth > g_faces[key].depth)
        break;
      g_order[j + 1] = g_order[j];
      j--;
    }
    g_order[j + 1] = key;
  }
}

U0 DrawFloor(Canvas *c)
{
  CanvasFillRect(c, 0, 0, WIDTH, HEIGHT / 2, Rgb(18, 20, 34));
  CanvasFillRect(c, 0, HEIGHT / 2, WIDTH, HEIGHT / 2, Rgb(28, 26, 30));
  for (I64 i = 0; i < 9; i++) {
    Vec3 near, far;
    near.x = -8.0 + i * 2.0; near.y = -1.6; near.z = 2.0;
    far.x = near.x; far.y = -1.6; far.z = 30.0;
    I64 x0, y0, x1, y1;
    ProjectPoint(&near, &x0, &y0);
    ProjectPoint(&far, &x1, &y1);
    CanvasLine(c, x0, y0, x1, y1, Rgb(55, 50, 60));
  }
}

U0 RenderFrame(Canvas *c, F64 t, Bool wireframe)
{
  DrawFloor(c);
  g_face_count = 0;

  Vec3 cube_pos, pyramid_pos;
  cube_pos.x = -1.4; cube_pos.y = 0.0; cube_pos.z = 6.0;
  pyramid_pos.x = 1.8 + sin(t) * 0.4; pyramid_pos.y = -0.2; pyramid_pos.z = 6.5 + cos(t) * 1.5;

  QueueMesh(&g_cube, &cube_pos, t * 0.9, sin(t * 0.7) * 0.3 - 0.45, 0.9);
  QueueMesh(&g_pyramid, &pyramid_pos, -t * 1.3, 0.25, 0.8);
  SortFacesFarToNear();

  for (I64 i = 0; i < g_face_count; i++) {
    Face *f = &g_faces[g_order[i]];
    if (wireframe) {
      U32 line = Rgb(220, 220, 230);
      CanvasLine(c, f->x0, f->y0, f->x1, f->y1, line);
      CanvasLine(c, f->x1, f->y1, f->x2, f->y2, line);
      CanvasLine(c, f->x2, f->y2, f->x0, f->y0, line);
    } else {
      CanvasFillTriangle(c, f->x0, f->y0, f->x1, f->y1, f->x2, f->y2, f->color);
    }
  }
}

U0 SetupMeshes()
{
  g_cube.vertex_count = 8;
  g_cube.vertices = g_cube_vertices;
  g_cube.tri_count = 12;
  g_cube.tris = g_cube_tris;
  g_cube.colors = g_cube_colors;

  g_pyramid.vertex_count = 5;
  g_pyramid.vertices = g_pyramid_vertices;
  g_pyramid.tri_count = 6;
  g_pyramid.tris = g_pyramid_tris;
  g_pyramid.colors = g_pyramid_colors;
}

I32 RenderToFile(U8 *path)
{
  Canvas c;
  if (!CanvasInit(&c, WIDTH, HEIGHT))
    return 1;
  RenderFrame(&c, 0.7, FALSE);
  Bool ok = CanvasSavePpm(&c, path);
  CanvasFree(&c);
  if (!ok) {
    "could not write %s\n", path;
    return 1;
  }
  "wrote %s\n", path;
  return 0;
}

I32 Main(I32 argc, U8 **argv)
{
  SetupMeshes();
  if (argc > 2 && !StrCmp(argv[1], "--ppm"))
    return RenderToFile(argv[2]);

  Screen screen;
  if (!ScreenOpen(&screen, "HolyC software 3D", WIDTH, HEIGHT, SCALE))
    return 1;

  Bool wireframe = FALSE;
  Bool space_was_down = FALSE;
  while (SdlPumpEvents() && !SdlKeyDown(SC_ESCAPE)) {
    Bool space = SdlKeyDown(SC_SPACE);
    if (space && !space_was_down)
      wireframe = !wireframe;
    space_was_down = space;

    I64 ms = SDL_GetTicks();
    F64 t = ms;
    RenderFrame(&screen.canvas, t / 1000.0, wireframe);
    ScreenPresent(&screen);
  }

  ScreenClose(&screen);
  return 0;
}
