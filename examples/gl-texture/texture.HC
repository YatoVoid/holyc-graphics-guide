// A software canvas shown through OpenGL. Each frame is drawn on the CPU
// with canvas.HC and font.HC, copied into a GL texture, and drawn on a
// quad that turns slowly in 3D.
//
// Linux:  hcc texture.HC -o texture
// macOS:  hcc texture.HC -o texture -clibs "-framework OpenGL"

#include "../common/canvas.HC"
#include "../common/font.HC"
#include "../common/sdl2.HC"
#include "../common/gl.HC"

#define WIDTH  800
#define HEIGHT 600

#define CANVAS_W 160
#define CANVAS_H 120

// The quad turns around the y axis, is pushed 3 units away from the
// camera, and is projected with a focal length of 2. One quad needs no
// matrices, so the shader does it directly.
U8 *g_vertex_src =
  "#version 330 core\n"
  "layout(location = 0) in vec2 a_pos;\n"
  "layout(location = 1) in vec2 a_uv;\n"
  "uniform float u_angle;\n"
  "uniform float u_aspect;\n"
  "out vec2 v_uv;\n"
  "void main() {\n"
  "  float c = cos(u_angle);\n"
  "  float s = sin(u_angle);\n"
  "  vec3 p = vec3(a_pos.x * c, a_pos.y, a_pos.x * s - 3.0);\n"
  "  gl_Position = vec4(p.x * 2.0 / u_aspect, p.y * 2.0, 0.0, -p.z);\n"
  "  v_uv = a_uv;\n"
  "}\n";

U8 *g_fragment_src =
  "#version 330 core\n"
  "uniform sampler2D u_canvas;\n"
  "in vec2 v_uv;\n"
  "out vec4 frag;\n"
  "void main() {\n"
  "  frag = texture(u_canvas, v_uv);\n"
  "}\n";

// x, y, u, v for a triangle strip. The canvas's first row is its top, and
// it's also the first row of the texture (v = 0), so the top corners of
// the quad get v = 0.
F32 g_quad[4 * 4] = {
  -1.333, -1.0,  0.0, 1.0,
   1.333, -1.0,  1.0, 1.0,
  -1.333,  1.0,  0.0, 0.0,
   1.333,  1.0,  1.0, 0.0,
};

U32 CompileShader(U32 type, U8 *src)
{
  U32 shader = glCreateShader(type);
  glShaderSource(shader, 1, &src, NULL);
  glCompileShader(shader);

  I32 ok;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
  if (!ok) {
    U8 log[1024];
    glGetShaderInfoLog(shader, 1024, NULL, log);
    "shader compile failed:\n%s\n", log;
    glDeleteShader(shader);
    return 0;
  }
  return shader;
}

U32 LinkProgram(U8 *vertex_src, U8 *fragment_src)
{
  U32 vs = CompileShader(GL_VERTEX_SHADER, vertex_src);
  U32 fs = CompileShader(GL_FRAGMENT_SHADER, fragment_src);
  if (!vs || !fs)
    return 0;

  U32 program = glCreateProgram();
  glAttachShader(program, vs);
  glAttachShader(program, fs);
  glLinkProgram(program);
  glDeleteShader(vs);
  glDeleteShader(fs);

  I32 ok;
  glGetProgramiv(program, GL_LINK_STATUS, &ok);
  if (!ok) {
    U8 log[1024];
    glGetProgramInfoLog(program, 1024, NULL, log);
    "program link failed:\n%s\n", log;
    glDeleteProgram(program);
    return 0;
  }
  return program;
}

// Allocates GPU storage for a texture the size of the canvas. Nearest
// filtering keeps the pixels sharp when the quad is scaled up.
U32 CreateCanvasTexture(Canvas *c)
{
  U32 texture;
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, c->width, c->height, 0,
               GL_BGRA, GL_UNSIGNED_BYTE, NULL);
  return texture;
}

// A canvas pixel is the U32 0xAARRGGBB. Stored little-endian, its bytes
// are B, G, R, A, which is exactly GL_BGRA with GL_UNSIGNED_BYTE, so the
// pixels go to the GPU as they are.
U0 UploadCanvas(U32 texture, Canvas *c)
{
  glBindTexture(GL_TEXTURE_2D, texture);
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, c->width, c->height,
                  GL_BGRA, GL_UNSIGNED_BYTE, c->pixels);
}

U0 DrawScene(Canvas *c, I64 ms)
{
  CanvasClear(c, Rgb(24, 22, 34));
  for (I64 y = 0; y < c->height; y += 8)
    for (I64 x = (y / 8 % 2) * 8; x < c->width; x += 16)
      CanvasFillRect(c, x, y, 8, 8, Rgb(30, 28, 42));
  CanvasRect(c, 0, 0, c->width, c->height, Rgb(120, 60, 150));

  // Back and forth across the canvas, one pixel every 8 ms.
  I64 range = c->width - 24;
  I64 t = (ms / 8) % (range * 2);
  if (t > range)
    t = range * 2 - t;
  CanvasFillCircle(c, 12 + t, 70, 8, Rgb(240, 200, 90));

  FontDrawText(c, 8, 8, "Canvas", Rgb(240, 240, 250), 2);
  FontDrawText(c, 8, 28, "on a GL texture", Rgb(60, 220, 200));
  U8 clock[32];
  StrPrint(clock, "%d ms", ms);
  FontDrawText(c, 8, c->height - 14, clock, Rgb(200, 200, 220));
}

I32 Main()
{
  if (SDL_Init(SDL_INIT_VIDEO) != 0) {
    "SDL_Init failed: %s\n", SDL_GetError();
    return 1;
  }

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

  U0 *window = SDL_CreateWindow("HolyC canvas on OpenGL", SDL_WINDOWPOS_CENTERED,
                                SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT,
                                SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
  if (!window) {
    "SDL_CreateWindow failed: %s\n", SDL_GetError();
    SDL_Quit();
    return 1;
  }
  U0 *context = SDL_GL_CreateContext(window);
  if (!context) {
    "SDL_GL_CreateContext failed: %s\n", SDL_GetError();
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 1;
  }
  SDL_GL_SetSwapInterval(1);
  "OpenGL %s on %s\n", glGetString(GL_VERSION), glGetString(GL_RENDERER);

  U32 program = LinkProgram(g_vertex_src, g_fragment_src);
  Canvas canvas;
  if (!program || !CanvasInit(&canvas, CANVAS_W, CANVAS_H)) {
    SDL_GL_DeleteContext(context);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 1;
  }
  I32 u_angle = glGetUniformLocation(program, "u_angle");
  I32 u_aspect = glGetUniformLocation(program, "u_aspect");
  U32 texture = CreateCanvasTexture(&canvas);

  U32 vao, vbo;
  glGenVertexArrays(1, &vao);
  glBindVertexArray(vao);
  glGenBuffers(1, &vbo);
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  glBufferData(GL_ARRAY_BUFFER, sizeof(g_quad), g_quad, GL_STATIC_DRAW);
  I32 stride = 4 * sizeof(F32);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, stride, 0);
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, stride, 2 * sizeof(F32));

  while (SdlPumpEvents() && !SdlKeyDown(SC_ESCAPE)) {
    I32 fb_w, fb_h;
    SDL_GL_GetDrawableSize(window, &fb_w, &fb_h);
    glViewport(0, 0, fb_w, fb_h);

    I64 ms = SDL_GetTicks();
    DrawScene(&canvas, ms);
    UploadCanvas(texture, &canvas);

    F64 t = ms;
    F64 aspect = fb_w;
    aspect /= fb_h;
    // Swing up to about 35 degrees each way, so the back never shows.
    F32 angle = sin(t / 1600.0) * 0.6;
    F32 aspect32 = aspect;

    glClearColor(0.08, 0.09, 0.12, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(program);
    glUniform1f(u_angle, angle);
    glUniform1f(u_aspect, aspect32);
    glBindVertexArray(vao);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    SDL_GL_SwapWindow(window);
  }

  glDeleteTextures(1, &texture);
  glDeleteBuffers(1, &vbo);
  glDeleteVertexArrays(1, &vao);
  glDeleteProgram(program);
  CanvasFree(&canvas);
  SDL_GL_DeleteContext(context);
  SDL_DestroyWindow(window);
  SDL_Quit();
  return 0;
}
