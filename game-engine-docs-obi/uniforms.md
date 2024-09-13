the uniforms type is a very thin wrapper on the openGL uniform, it only has 2 thing the name of the uniform and the location of it. (i will be changing this to have a type field in the future for more type safety). this uniform type has 100% coverage of all types that can be sent to an opengl program.

for an example of this see [[uniform_type]] for how its implemented within the larger scope.

uniform type are accpected within the [[program]] when linking.

```ts
pub const Uniform = struct {

    const Self = @This();

    name: []const u8,

    location: gl.GLint,

  

    pub inline fn init(name: []const u8) Self {

        return Self{

            .name = name,

            .location = undefined,

        };

    }
}
```
## fields
`name` : `[]const u8` is the name of the uniform within the shader
`location` : the opengl id of the uniform within the program