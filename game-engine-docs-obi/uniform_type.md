
the uniform type is the struct passed to the [[program]] that allows for the extra computations to be done to the this type requires you to implement the declarations as seen in `program_uniform.zig`. the uniform type normal consists of [[uniforms]] types which will get auto added in to the [[program]] during its linking stage.

an example of how to use this can be seen below:
```ts

pub const BasicUniformsText = struct {

    const Self = @This();

    hasDiffuseLighting: uni.Uniform = uni.Uniform.init("hasDiffuseLighting"),

    ambient_colour: uni.Uniform = uni.Uniform.init("ambient_colour"),

    norMatrixUniform: uni.Uniform = uni.Uniform.init("norMatrix"),

    mvpMatrixUniform: uni.Uniform = uni.Uniform.init("mvpMatrix"),

    mvMatrixUniform: uni.Uniform = uni.Uniform.init("mvMatrix"),

    textureUniform: uni.Uniform = uni.Uniform.init("tSampler"),

    mMatrixUniform: uni.Uniform = uni.Uniform.init("mMatrix"),

    obj_colour: uni.Uniform = uni.Uniform.init("obj_colour"),

    lgtUniform: uni.Uniform = uni.Uniform.init("lightPos"),
	// this runs everytime the program renders the object
    pub fn draw(self: Self, camera: *cam.Camera, object: obj.Object) void {


        if (object.texture) |tex| tex.useTexture();

  

        var model = mat.Mat4x4.idenity();

  

        model = model.mul(mat.Mat4x4.translate(object.pos))

            .mul(mat.Mat4x4.rotate(object.roation.vec[0], vec.init3(1, 0, 0)))

            .mul(mat.Mat4x4.rotate(object.roation.vec[1], vec.init3(0, 1, 0)))

            .mul(mat.Mat4x4.rotate(object.roation.vec[2], vec.init3(0, 0, 1)))

            .mul(mat.Mat4x4.scale(object.scale));

        self.mMatrixUniform.sendMatrix4(false, model);

  

        const mvMatrix = camera.view_matrix.mul(model);

        const mvpMatrix = camera.projection_matrix.mul(mvMatrix);

        const invMatrix = mvMatrix.inverseTranspose();


        self.mvMatrixUniform.sendMatrix4(false, mvMatrix);

        self.mvpMatrixUniform.sendMatrix4(false, mvpMatrix);

        self.norMatrixUniform.sendMatrix4(true, invMatrix);
        // call this at the end to render the object
        object.draw();

    }

  
	// this gets called when the program is reloaded
    pub fn reload(self: Self) void {

        self.hasDiffuseLighting.send1Uint(0);

        self.ambient_colour.sendVec4(vec.init4(0.2, 0.2, 0.2, 1));

        self.obj_colour.sendVec4(vec.init4(1, 1, 1, 1));

        const light: vec.Vec4 = vec.init4(5, 10, 7, 1);

        self.lgtUniform.sendVec4(light);

    }

};

```

this type requires to implement 2 functions, draw which is called on every object getting rendered and reload which is called when ever shaders are reloaded and new info needs to be sent to them.
