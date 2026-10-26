// The OpenGL 3.3 core functions the examples call, declared for HolyC.
// GLenum/GLuint/GLbitfield -> U32, GLint/GLsizei -> I32, GLfloat -> F32,
// GLsizeiptr/GLintptr -> I64.
//
// libGL on Linux and OpenGL.framework on macOS export these symbols
// directly, so no loader (GLAD, GLEW) is needed. On macOS link with
// `hcc ... -clibs "-framework OpenGL"`.

#ifdef IS_LINUX
#link <GL>
#endif

#define GL_COLOR_BUFFER_BIT  0x00004000
#define GL_DEPTH_BUFFER_BIT  0x00000100
#define GL_DEPTH_TEST        0x0B71
#define GL_TRIANGLES         0x0004
#define GL_TRIANGLE_STRIP    0x0005
#define GL_UNSIGNED_BYTE     0x1401
#define GL_FLOAT             0x1406
#define GL_UNSIGNED_INT      0x1405
#define GL_FALSE             0
#define GL_ARRAY_BUFFER      0x8892
#define GL_ELEMENT_ARRAY_BUFFER 0x8893
#define GL_STATIC_DRAW       0x88E4
#define GL_FRAGMENT_SHADER   0x8B30
#define GL_VERTEX_SHADER     0x8B31
#define GL_COMPILE_STATUS    0x8B81
#define GL_LINK_STATUS       0x8B82
#define GL_VERSION           0x1F02
#define GL_RENDERER          0x1F01
#define GL_TEXTURE_2D        0x0DE1
#define GL_TEXTURE_MAG_FILTER 0x2800
#define GL_TEXTURE_MIN_FILTER 0x2801
#define GL_TEXTURE_WRAP_S    0x2802
#define GL_TEXTURE_WRAP_T    0x2803
#define GL_NEAREST           0x2600
#define GL_CLAMP_TO_EDGE     0x812F
#define GL_RGBA8             0x8058
#define GL_BGRA              0x80E1

extern "c" U8 *glGetString(U32 name);
extern "c" U0 glViewport(I32 x, I32 y, I32 w, I32 h);
extern "c" U0 glClearColor(F32 r, F32 g, F32 b, F32 a);
extern "c" U0 glClear(U32 mask);
extern "c" U0 glEnable(U32 cap);

extern "c" U0 glGenVertexArrays(I32 n, U32 *arrays);
extern "c" U0 glBindVertexArray(U32 array);
extern "c" U0 glDeleteVertexArrays(I32 n, U32 *arrays);
extern "c" U0 glGenBuffers(I32 n, U32 *buffers);
extern "c" U0 glBindBuffer(U32 target, U32 buffer);
extern "c" U0 glBufferData(U32 target, I64 size, U0 *data, U32 usage);
extern "c" U0 glDeleteBuffers(I32 n, U32 *buffers);
extern "c" U0 glEnableVertexAttribArray(U32 index);
// The last argument is a byte offset into the bound buffer, passed as a pointer.
extern "c" U0 glVertexAttribPointer(U32 index, I32 size, U32 type, U8 normalized,
                                    I32 stride, I64 offset);
extern "c" U0 glDrawElements(U32 mode, I32 count, U32 type, I64 offset);
extern "c" U0 glDrawArrays(U32 mode, I32 first, I32 count);

extern "c" U0 glGenTextures(I32 n, U32 *textures);
extern "c" U0 glBindTexture(U32 target, U32 texture);
extern "c" U0 glDeleteTextures(I32 n, U32 *textures);
extern "c" U0 glTexParameteri(U32 target, U32 pname, I32 param);
extern "c" U0 glTexImage2D(U32 target, I32 level, I32 internal_format, I32 w, I32 h,
                           I32 border, U32 format, U32 type, U0 *pixels);
extern "c" U0 glTexSubImage2D(U32 target, I32 level, I32 x, I32 y, I32 w, I32 h,
                              U32 format, U32 type, U0 *pixels);

extern "c" U32 glCreateShader(U32 type);
extern "c" U0 glShaderSource(U32 shader, I32 count, U8 **strings, I32 *lengths);
extern "c" U0 glCompileShader(U32 shader);
extern "c" U0 glGetShaderiv(U32 shader, U32 pname, I32 *out);
extern "c" U0 glGetShaderInfoLog(U32 shader, I32 max, I32 *len, U8 *log);
extern "c" U0 glDeleteShader(U32 shader);
extern "c" U32 glCreateProgram();
extern "c" U0 glAttachShader(U32 program, U32 shader);
extern "c" U0 glLinkProgram(U32 program);
extern "c" U0 glGetProgramiv(U32 program, U32 pname, I32 *out);
extern "c" U0 glGetProgramInfoLog(U32 program, I32 max, I32 *len, U8 *log);
extern "c" U0 glUseProgram(U32 program);
extern "c" U0 glDeleteProgram(U32 program);
extern "c" I32 glGetUniformLocation(U32 program, U8 *name);
extern "c" U0 glUniform1f(I32 location, F32 value);
extern "c" U0 glUniformMatrix4fv(I32 location, I32 count, U8 transpose, F32 *value);
