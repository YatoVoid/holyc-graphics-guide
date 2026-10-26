// A spinning, vertex-coloured cube on OpenGL 3.3 core.
//
// HolyC owns everything the CPU does: the window, the vertex data, the
// matrices and the frame loop. The two small GLSL shaders below are the
// only non-HolyC code, and they run on the GPU.
//
// Linux:  hcc opengl_example.HC -o opengl_example
// macOS:  hcc opengl_example.HC -o opengl_example -clibs "-framework OpenGL"

#include "../common/sdl2.HC"
#include "../common/gl.HC"

#define WIDTH  800
#define HEIGHT 600

U8 *g_vertex_src =
  "#version 330 core\n"
  "layout(location = 0) in vec3 a_pos;\n"
  "layout(location = 1) in vec3 a_color;\n"
  "uniform mat4 u_mvp;\n"
  "out vec3 v_color;\n"
  "void main() {\n"
  "  v_color = a_color;\n"
  "  gl_Position = u_mvp * vec4(a_pos, 1.0);\n"
  "}\n";

U8 *g_fragment_src =
  "#version 330 core\n"
  "in vec3 v_color;\n"
  "out vec4 frag;\n"
  "void main() {\n"
  "  frag = vec4(v_color, 1.0);\n"
  "}\n";

// x, y, z, r, g, b per corner.
F32 g_vertices[8 * 6] = {
  -1.0, -1.0, -1.0,  0.9, 0.3, 0.2,
   1.0, -1.0, -1.0,  0.9, 0.8, 0.2,
   1.0,  1.0, -1.0,  0.3, 0.9, 0.4,
  -1.0,  1.0, -1.0,  0.2, 0.6, 0.9,
  -1.0, -1.0,  1.0,  0.7, 0.3, 0.9,
   1.0, -1.0,  1.0,  0.9, 0.9, 0.9,
   1.0,  1.0,  1.0,  0.2, 0.9, 0.8,
  -1.0,  1.0,  1.0,  0.9, 0.5, 0.6,
};

U32 g_indices[36] = {
  0, 2, 1,  0, 3, 2,
  4, 5, 6,  4, 6, 7,
  0, 1, 5,  0, 5, 4,
  3, 6, 2,  3, 7, 6,
  0, 4, 7,  0, 7, 3,
  1, 2, 6,  1, 6, 5,
};

// Matrices are 16 floats in column-major order, which is what GLSL expects.

U0 Mat4Identity(F64 *m)
{
  MemSet(m, 0, 16 * sizeof(F64));
  m[0] = 1.0;
  m[5] = 1.0;
  m[10] = 1.0;
  m[15] = 1.0;
}

U0 Mat4Mul(F64 *out, F64 *a, F64 *b)
{
  F64 tmp[16];
  for (I64 col = 0; col < 4; col++) {
    for (I64 row = 0; row < 4; row++) {
      F64 sum = 0.0;
      for (I64 k = 0; k < 4; k++)
        sum += a[k * 4 + row] * b[col * 4 + k];
      tmp[col * 4 + row] = sum;
    }
  }
  MemCpy(out, tmp, 16 * sizeof(F64));
}

U0 Mat4Perspective(F64 *m, F64 fov_y, F64 aspect, F64 near, F64 far)
{
  F64 f = 1.0 / tan(fov_y / 2.0);
  MemSet(m, 0, 16 * sizeof(F64));
  m[0] = f / aspect;
  m[5] = f;
  m[10] = (far + near) / (near - far);
  m[11] = -1.0;
  m[14] = 2.0 * far * near / (near - far);
}

U0 Mat4RotateY(F64 *m, F64 angle)
{
  F64 c = cos(angle), s = sin(angle);
  Mat4Identity(m);
  m[0] = c;
  m[2] = -s;
  m[8] = s;
  m[10] = c;
}

U0 Mat4RotateX(F64 *m, F64 angle)
{
  F64 c = cos(angle), s = sin(angle);
  Mat4Identity(m);
  m[5] = c;
  m[6] = s;
  m[9] = -s;
  m[10] = c;
}

U0 Mat4Translate(F64 *m, F64 x, F64 y, F64 z)
{
  Mat4Identity(m);
  m[12] = x;
  m[13] = y;
  m[14] = z;
}

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

I32 Main()
{
  if (SDL_Init(SDL_INIT_VIDEO) != 0) {
    "SDL_Init failed: %s\n", SDL_GetError();
    return 1;
  }

  // Ask for 3.3 core before the window exists. macOS only hands out a
  // modern context when it's core and forward-compatible.
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

  U0 *window = SDL_CreateWindow("HolyC + OpenGL", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                WIDTH, HEIGHT, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
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
  if (!program) {
    SDL_GL_DeleteContext(context);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 1;
  }
  I32 u_mvp = glGetUniformLocation(program, "u_mvp");

  U32 vao, vbo, ebo;
  glGenVertexArrays(1, &vao);
  glBindVertexArray(vao);
  glGenBuffers(1, &vbo);
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertices), g_vertices, GL_STATIC_DRAW);
  glGenBuffers(1, &ebo);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(g_indices), g_indices, GL_STATIC_DRAW);

  I32 stride = 6 * sizeof(F32);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, stride, 0);
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, stride, 3 * sizeof(F32));

  glEnable(GL_DEPTH_TEST);

  F64 proj[16], rot_x[16], rot_y[16], move[16], model[16], mvp[16];
  F32 mvp32[16];

  while (SdlPumpEvents() && !SdlKeyDown(SC_ESCAPE)) {
    I32 fb_w, fb_h;
    SDL_GL_GetDrawableSize(window, &fb_w, &fb_h);
    glViewport(0, 0, fb_w, fb_h);

    I64 ms = SDL_GetTicks();
    F64 t = ms;
    t /= 1000.0;
    F64 aspect = fb_w;
    aspect /= fb_h;

    Mat4Perspective(proj, 1.0, aspect, 0.1, 100.0);
    Mat4RotateY(rot_y, t * 0.8);
    Mat4RotateX(rot_x, t * 0.5);
    Mat4Translate(move, 0.0, 0.0, -5.0);
    Mat4Mul(model, rot_y, rot_x);
    Mat4Mul(model, move, model);
    Mat4Mul(mvp, proj, model);
    for (I64 i = 0; i < 16; i++)
      mvp32[i] = mvp[i];

    glClearColor(0.08, 0.09, 0.12, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(program);
    glUniformMatrix4fv(u_mvp, 1, GL_FALSE, mvp32);
    glBindVertexArray(vao);
    glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, 0);

    SDL_GL_SwapWindow(window);
  }

  glDeleteBuffers(1, &ebo);
  glDeleteBuffers(1, &vbo);
  glDeleteVertexArrays(1, &vao);
  glDeleteProgram(program);
  SDL_GL_DeleteContext(context);
  SDL_DestroyWindow(window);
  SDL_Quit();
  return 0;
}
