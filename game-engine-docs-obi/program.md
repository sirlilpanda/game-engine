
this program struct is a wrapper on an openGL program. The program accepts 2 compile time arguments, the [[uniform_type]] and the `amount_of_object`. the amount of objects is the amount of objects that the program has to render, ( i will probably change this to an arraylist in the end). the idea behind the [[uniform_type]] is uniforms should be compile time known. This also allows as the uniform type to work as a compile time hashmap type thing, so there is no extra over head when sending data to uniforms.
## example usage below:
```ts
// creates the new program type
pub const BasicProgram = Program(BasicUniforms, 32);

var prog = BasicProgram.init();

// loads the shaders
const vert = try shader.Shader.init(allocator, "shaders/crab.vert", .vertex);
const frag = try shader.Shader.init(allocator, "shaders/crab.frag", .frag);

// links the shaders
prog.load_shader(vert);
prog.load_shader(frag);

// links the program to the uniforms
prog.link();

// uses the program
prog.use();
```

## fields:

`program_id` : `gl.GLuint` = the opengl program id
`shaders` : \[AMOUNT_OF_SHADERS]?[[Shader]] = an array of shader the program has access too
`shader_index` : `u8` = index of the last shader, please dont touch this
`uniforms`: [[uniform_type]] = the type of the uniforms struct that is needed to run this program
`camera`: \*[[Camera]] = pointer to the camera object
`objects` : \[amount_of_object]?[[Object]] = a list of optional objects