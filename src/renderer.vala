/**
 * The renderer for a scene. Requires a {@link Gtk.GLArea}
 */
public class Ch3.Renderer : Object {
    public GL.Program render_program { get; private set; }
    public GL.Program picker_program { get; private set; }
    public GenericSet<Model> scene { get; default = new GenericSet<Model> (null, null); }

    public Vec3 ambient_light { get; default = Vec3 (0.6f, 0.6f, 0.6f); }
    public Vec3 light_position { get; default = Vec3 (0.0f, 1.0f, 0.0f); }
    public Model? selected_model { get; set; }
    public Camera main_camera { get; set; default = new Camera (Vec3 (0, 0, 1)); }

    /**
     * A framebuffer to store debug info about objects, such as their IDs. Used for picking.
     *
     * @see handle_click
     */
    GL.Framebuffer picker_framebuf;
    GL.Renderbuffer picker_renderbuf;
    GL.Renderbuffer picker_depthbuf;

    int viewport_width;
    int viewport_height;

    // --- SCENE SETUP
    public void setup (Gtk.Widget widget) {
        var area = (Gtk.GLArea) widget;
        area.make_current ();
        if (area.get_error () != null)
            return;

        print ("OpenGL version is %s\n", GL.get_string (GL.VERSION));
        print ("GLSL version is %s\n", GL.get_string (GL.SHADING_LANGUAGE_VERSION));
        print ("OpenGL renderer is %s\n", GL.get_string (GL.RENDERER));

        render_program = GL.Program ();
        picker_program = GL.Program ();

        // create a shader program
        // load the shaders for the program, compile and link them
        var vshader = GL.Shader (GL.VERTEX_SHADER);
        try {
            vshader.load ("/com/github/prince781/Ch3/shaders/shader.vert");
            vshader.compile ();

            var render_fshader = GL.Shader (GL.FRAGMENT_SHADER);
            render_fshader.load ("/com/github/prince781/Ch3/shaders/shader.frag");
            render_fshader.compile ();

            render_program.attach_shader (vshader);
            render_program.attach_shader (render_fshader);

            // render_program.bind_frag_data_location (0, "outColor");
            render_program.link ();
        } catch (Error e) {
            printerr ("ERROR: %s\n", e.message);
            Application.get_default ().quit ();
            return;
        }
        debug ("compiled and linked shaders");

        // we have to activate the shader first before setting uniforms
        GL.use_program (render_program);

        // now set uniforms
        render_program.set_int ("AmbientTex", 0);
        render_program.set_int ("DiffuseTex", 1);
        render_program.set_int ("SpecularTex", 2);

        // now load the models
        try {
            const string model_dir = "/com/github/prince781/Ch3/models";

            var chess_board = new Model ("Chess Board", @"$model_dir/ChessBoard.obj", render_program) {
                position = Vec3 (0, 0, -1),
                scale = Vec3 (4, 4, 4)
            };
            scene.add (chess_board);

            // add black pawn
            chess_board.children.add (new Model ("Black Pawn", @"$model_dir/ChessPiecePawnBlack.obj", render_program) {
                scale = Vec3 (2, 2, 2),
                position = Vec3 (0, 0.01f, 0)
            });

            // add white pawn
            chess_board.children.add (new Model ("White Pawn", @"$model_dir/ChessPiecePawnWhite.obj", render_program) {
                scale = Vec3 (2, 2, 2),
                position = Vec3 (0, 0.01f, 0)
            });

            // create animations moving the chess board into view:
            // - add an animation (move z from -1 -> -3 over 1.6s)
            chess_board.position_z_anim = new Animation (-1, -3, 1.6f);
            // - add animation (rotate 45 deg along x axis)
            chess_board.rotation_x_anim = new Animation (0, 45f, 1.6f);
        } catch (Error e) {
            printerr ("ERROR: %s\n", e.message);
            Application.get_default ().quit ();
            return;
        }
        debug ("loaded models");

        // establish a tick callback for queueing rendering
        area.add_tick_callback ((widget, frame_clock) => {
            // queue redraw
            widget.queue_draw ();
            return Source.CONTINUE;
        });

        // update the animations precisely on each frame
        var frame_clock = (!)area.get_frame_clock ();       // widget is realized
        frame_clock.update.connect (frame_clock => {
            int64 frame_time = frame_clock.get_frame_time ();
            scene.foreach (model => {
                // animate position
                var anim_position = model.position;
                if (model.position_x_anim != null) {
                    model.position_x_anim.update (frame_time);
                    anim_position.x = model.position_x_anim.current_val;
                    if (model.position_x_anim.finished)
                        model.position_x_anim = null;
                }
                if (model.position_y_anim != null) {
                    model.position_y_anim.update (frame_time);
                    anim_position.y = model.position_y_anim.current_val;
                    if (model.position_y_anim.finished)
                        model.position_y_anim = null;
                }
                if (model.position_z_anim != null) {
                    model.position_z_anim.update (frame_time);
                    anim_position.z = model.position_z_anim.current_val;
                    if (model.position_z_anim.finished)
                        model.position_z_anim = null;
                }

                // animate rotation
                var anim_rotation = model.rotation;
                if (model.rotation_x_anim != null) {
                    model.rotation_x_anim.update (frame_time);
                    anim_rotation.x = model.rotation_x_anim.current_val;
                    if (model.rotation_x_anim.finished)
                        model.rotation_x_anim = null;
                }
                if (model.rotation_y_anim != null) {
                    model.rotation_y_anim.update (frame_time);
                    anim_rotation.y = model.rotation_y_anim.current_val;
                    if (model.rotation_y_anim.finished)
                        model.rotation_y_anim = null;
                }
                if (model.rotation_z_anim != null) {
                    model.rotation_z_anim.update (frame_time);
                    anim_rotation.z = model.rotation_z_anim.current_val;
                    if (model.rotation_z_anim.finished)
                        model.rotation_z_anim = null;
                }

                model.position = anim_position;
                model.rotation = anim_rotation;
            });
        });

        // separately, setup picker program
        try {
            // load the picker fragment shader
            var picker_fshader = GL.Shader (GL.FRAGMENT_SHADER);
            picker_fshader.load ("/com/github/prince781/Ch3/shaders/picker.frag");
            picker_fshader.compile ();

            // attach the same vertex shader and the new picker shader
            picker_program.attach_shader (vshader);
            picker_program.attach_shader (picker_fshader);

            picker_program.link ();
        } catch (Error e) {
            printerr ("ERROR: %s\n", e.message);
            Application.get_default ().quit ();
            return;
        }

        // we don't have to set any uniforms for the picker shader

        // setup debug framebuffer
        picker_framebuf = GL.Framebuffer ();
        picker_framebuf.bind ();

        // create the render buffer - this will render a unique color for each object
        picker_renderbuf = GL.Renderbuffer ();
        picker_renderbuf.bind ();
        picker_renderbuf.storage (GL.R32UI, area.get_width (), area.get_height ());
        picker_renderbuf.attach_to_current_framebuffer (GL.COLOR_ATTACHMENT0);

        // create the depth buffer - needed to enforce hierarchy of visible objects
        picker_depthbuf = GL.Renderbuffer ();
        picker_depthbuf.bind ();
        picker_depthbuf.storage (GL.DEPTH_COMPONENT24, area.get_width (), area.get_height ());
        picker_depthbuf.attach_to_current_framebuffer (GL.DEPTH_ATTACHMENT);

        // NOTE: we don't need to rebind the default framebuffer - GTK does this automatically
        // after this function.
    }

    // --- RENDERING
    public bool render (Gtk.GLArea area, Gdk.GLContext context) {
        Error? area_err;
        if ((area_err = area.get_error ()) != null) {
            printerr ("GL ERROR: %s\nGL Area Error: %s\n",
                      GL.get_error ().to_string (),
                      area_err.message);
            Application.get_default ().quit ();
            return Source.REMOVE;
        }

        // update transformation
        float aspect_ratio = area.get_width () / (float) area.get_height ();
        var projection_matrix = Mat4x4.perspective ((float)Math.PI_4, aspect_ratio, 0.1f, 1000f);

        // construct view matrix from camera
        var view_matrix = Mat4x4.look_at (main_camera.position, main_camera.position.add (main_camera.direction), Vec3 (0, 1, 0));

        area.make_current ();
        GL.use_program (render_program);

        // get view from camera position and rotation
        render_program.set_mat4x4 ("view", ref view_matrix);
        render_program.set_mat4x4 ("proj", ref projection_matrix);

        // ambient color and light position can vary throughout the scene
        render_program.set_vec3 ("AmbientLight", ambient_light);
        render_program.set_vec3 ("LightPosition", light_position);
        render_program.set_vec3 ("CameraPosition", main_camera.position);

        // debug (@"view matrix:\n$view_matrix");
        // debug (@"projection matrix:\n$projection_matrix");

        // BEGIN rendering ---
        // note: default framebuffer should already be bound here

        // set the background color
        GL.clear_color (0.2f, 0.2f, 0.2f, 1f);
        GL.clear (GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

        // iterate over all objects in scene
        scene.foreach (model => render_model (model, Mat4x4.identity (), render_program));

        // clear the viewport
        GL.flush ();

        // ensure the frame buffer contents are completely updated in this
        GL.finish ();

        // BEGIN debug rendering ---
        picker_framebuf.bind ();
        GL.use_program (picker_program);

        // get view from camera position and rotation
        picker_program.set_mat4x4 ("view", ref view_matrix);
        picker_program.set_mat4x4 ("proj", ref projection_matrix);

        // clear object ID
        GL.Framebuffer.clear_buffer_uiv (GL.COLOR, 0, {0, 0, 0, 0});
        GL.clear (GL.DEPTH_BUFFER_BIT);

        scene.foreach (model => render_model (model, Mat4x4.identity (), picker_program));

        return Source.CONTINUE;
    }

    /**
     * This is a recursive procedure because we want to render each child in a
     * model hierarchy with a model transform that is relative to the parent
     * model.
     */
    void render_model (Model model, Mat4x4 parent_model_matrix, GL.Program program) {
        // construct a model matrix from the up-to-date transform
        // attributes of the object
        var model_matrix = Mat4x4.identity ()
            .scale (model.scale.x, model.scale.y, model.scale.z)
            .rotateX (model.rotation.x/180 * (float)Math.PI)
            .rotateY (model.rotation.y/180 * (float)Math.PI)
            .rotateZ (model.rotation.z/180 * (float)Math.PI)
            .translate (model.position.x, model.position.y, model.position.z);
        model_matrix = parent_model_matrix.multiply (model_matrix);
        program.set_mat4x4 ("model", ref model_matrix);

        if (program == picker_program) {
            // render just the object ID as a color
            program.set_uint ("inObjectId", model.id);

            // render every mesh of the object
            model.meshes.foreach ((_, mesh) => {
                // render the mesh vertices
                GL.bind_vertex_array (mesh.vao);
                // GL.bind_buffer (GL.ARRAY_BUFFER, mesh.vbo);
                GL.draw_arrays (GL.TRIANGLES, 0, mesh.size);
            });
        } else {
            // render every mesh of the object
            model.meshes.foreach ((_, mesh) => {
                // update the material
                if (mesh.material != null) {
                    // debug (@"mesh has $(mesh.material)");
                    program.set_vec3 ("AmbientColor", mesh.material.ambient_color);
                    if (mesh.material.ambient_texture != null) {
                        program.set_boolean ("HaveAmbientTex", GL.TRUE);
                        GL.active_texture (GL.TEXTURE0);
                        GL.bind_texture (GL.TEXTURE_2D, mesh.material.ambient_texture.id);
                    } else {
                        program.set_boolean ("HaveAmbientTex", GL.FALSE);
                    }
                    program.set_vec3 ("DiffuseColor", mesh.material.diffuse_color);
                    if (mesh.material.diffuse_texture != null) {
                        render_program.set_boolean ("HaveDiffuseTex", GL.TRUE);
                        GL.active_texture (GL.TEXTURE1);
                        GL.bind_texture (GL.TEXTURE_2D, mesh.material.diffuse_texture.id);
                    } else {
                        program.set_boolean ("HaveDiffuseTex", GL.FALSE);
                    }
                    program.set_vec3 ("SpecularColor", mesh.material.specular_color);
                    program.set_float ("SpecularCoeff", mesh.material.specular_exponent);
                    if (mesh.material.specular_texture != null) {
                        program.set_boolean ("HaveSpecularTex", GL.TRUE);
                        GL.active_texture (GL.TEXTURE2);
                        GL.bind_texture (GL.TEXTURE_2D, mesh.material.specular_texture.id);
                    } else {
                        program.set_boolean ("HaveSpecularTex", GL.FALSE);
                    }
                } else {
                    // reset the shader material
                    // GL.active_texture (GL.TEXTURE0);
                    // GL.bind_texture (GL.TEXTURE_2D, 0);
                    // GL.active_texture (GL.TEXTURE1);
                    // GL.bind_texture (GL.TEXTURE_2D, 0);
                    // GL.active_texture (GL.TEXTURE2);
                    // GL.bind_texture (GL.TEXTURE_2D, 0);
                    program.set_vec3 ("AmbientColor", Vec3 ());
                    program.set_vec3 ("DiffuseColor", Vec3 ());
                    program.set_vec3 ("SpecularColor", Vec3 ());
                    program.set_float ("SpecularCoeff", 0f);
                    program.set_boolean ("HaveAmbientTex", GL.FALSE);
                    program.set_boolean ("HaveDiffuseTex", GL.FALSE);
                    program.set_boolean ("HaveSpecularTex", GL.FALSE);
                }

                program.set_boolean ("Selected", model == selected_model ? GL.TRUE : GL.FALSE);

                // render the mesh vertices
                GL.bind_vertex_array (mesh.vao);
                // GL.bind_buffer (GL.ARRAY_BUFFER, mesh.vbo);
                GL.draw_arrays (GL.TRIANGLES, 0, mesh.size);
            });
        }

        // now render all children
        model.children.foreach (child => render_model (child, model_matrix, program));
    }

    public void fill_scene_objects (ListStore list, Model? parent = null) {
        if (parent == null) {
            scene.foreach (model => {
                list.append (model);
                fill_scene_objects (list, model);
            });
        } else {
            parent.children.foreach (child => {
                list.append (child);
                fill_scene_objects (list, child);
            });
        }
    }

    public delegate bool ModelMatchFunc<T> (Model model, T property);

    public Model? find<T> (T value, ModelMatchFunc<T> match, Model? parent = null) {
        Model? found = null;

        if (parent == null) {
            scene.foreach (model => {
                if (match (model, value))
                    found = model;
                if (found == null)
                    found = find (value, match, model);
            });
        } else {
            parent.children.foreach (child => {
                if (match (child, value))
                    found = child;
                if (found == null)
                    found = find (value, match, child);
            });
        }

        return found;
    }

    /**
     * Resize the render buffers.
     */
    public void resize (Gtk.Widget widget, int width, int height) {
        picker_framebuf.bind ();
        picker_renderbuf.bind ();
        picker_renderbuf.storage (GL.R32UI, width, height);
        picker_depthbuf.bind ();
        picker_depthbuf.storage (GL.DEPTH_COMPONENT24, width, height);

        viewport_width = width;
        viewport_height = height;
    }

    // --- EVENT HANDLING

    // note: x, y are in GTK's device coords
    public void handle_click (Gtk.GestureClick click, int n_press, double x, double y) {
        var area = (Gtk.GLArea)click.widget;
        area.make_current ();
        picker_framebuf.bind  ();

        // read object ID from second framebuffer
        debug ("received %d click(s) in GTK device coords: (x=%lf, y=%lf)", n_press, x, y);

        // convert to viewport coords
        x *= viewport_width / (double) area.get_width ();
        y = viewport_height - y * viewport_height / (double) area.get_height ();
        
        var pixels = GL.read_pixels_uint ((int)x, (int)y, 1, 1, GL.PixelFormat.RGBA_INTEGER, GL.PixelType.UNSIGNED_INT);
        var id = pixels[0];
        var model = find<uint> (id, (model, id) => model.id == id);
        if (model != null) {
            debug ("clicked on %s", model.name);
        } else {
            debug ("got bad ID: %u", id);
        }
    }
}
