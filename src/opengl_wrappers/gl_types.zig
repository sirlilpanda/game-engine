const gl = @import("gl");

pub const GlType = enum(c_uint) {
    byte = gl.BYTE,
    unsigned_byte = gl.UNSIGNED_BYTE,
    short = gl.SHORT,
    unsigned_short = gl.UNSIGNED_SHORT,
    int = gl.INT,
    unsigned_int = gl.UNSIGNED_INT,
    fixed = gl.FIXED,
    float = gl.FLOAT,
    double = gl.DOUBLE,
};

pub const DrawType = enum(c_uint) {
    dynamic = gl.DYNAMIC_DRAW,
    static = gl.STATIC_DRAW,
    stream = gl.STREAM_DRAW,
};

pub fn sizeofGLType(t: GlType) usize {
    return switch (t) {
        .byte => @sizeOf(gl.GLbyte),
        .unsigned_byte => @sizeOf(gl.GLubyte),
        .short => @sizeOf(gl.GLshort),
        .unsigned_short => @sizeOf(gl.GLushort),
        .int => @sizeOf(gl.GLint),
        .unsigned_int => @sizeOf(gl.GLuint),
        .fixed => @sizeOf(gl.GLfixed),
        .float => @sizeOf(gl.GLfloat),
        .double => @sizeOf(gl.GLdouble),
    };
}

pub fn asGLType(t: GlType) type {
    return switch (t) {
        .byte => gl.GLbyte,
        .unsigned_byte => gl.GLubyte,
        .short => gl.GLshort,
        .unsigned_short => gl.GLushort,
        .int => gl.GLint,
        .unsigned_int => gl.GLuint,
        .fixed => gl.GLfixed,
        .float => gl.GLfloat,
        .double => gl.GLdouble,
    };
}
