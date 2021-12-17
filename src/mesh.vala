public class Ch3.Mesh : Object {
    public struct Point {
        public Vec3 v;
        public Vec2 uv;
        public Vec3 n;

        public Point (Vec3 v = Vec3(), Vec2 uv = Vec2(), Vec3 n = Vec3()) {
            this.v = v;
            this.uv = uv;
            this.n = n;
        }
    }

    public struct Face {
        public Point p[3];

        public string to_string () {
            return @"($(p[0].v)/$(p[0].uv)/$(p[0].n), $(p[1].v)/$(p[1].uv)/$(p[1].n), $(p[2].v)/$(p[2].uv)/$(p[2].n))";
        }
    }

    public string id { get; construct; }
    public GL.uint vao { get; construct; }
    public GL.uint vbo { get; construct; }

    /**
     * Number of vertices in this mesh. Pass this value to {@link GL.draw_arrays}
     */
    public int size { get; construct; }

    public Material? material { get; set; }

    /**
     * Construct GL buffers for all vertices, UVs, and normals.
     *
     * @param id        a unique identifier for the mesh
     * @param program   the current GL program, used to recover attribute locations
     * @param material  the material for this mesh, or null
     */
    public Mesh (string id, Face[] tris, GL.Program program, Material? material) {
        Object (id: id,
                vao: GL.gen_vertex_array (),
                vbo: GL.gen_buffer (),
                size: tris.length * 3);
        this.material = material;

        // debug (@"mesh $id has $(tris.length) triangle(s):");
        // for (var i = 0; i < tris.length; i++)
        //     debug (@" [$i] = $(tris[i])");
        // create one contiguous view of the mesh data
        unowned float[] data = (float[]) tris;

        GL.bind_vertex_array (vao);

        // upload the data
        GL.bind_buffer (GL.ARRAY_BUFFER, vbo);
        GL.buffer_floats (GL.ARRAY_BUFFER, data, GL.STATIC_DRAW);

        // set up the vertex attribute locations for this data
        GL.VertexAttribute position_attr = program.get_attrib_location ("position");
        GL.VertexAttribute texcoord_attr = program.get_attrib_location ("texcoord");
        GL.VertexAttribute normal_attr = program.get_attrib_location ("normal");

        debug (@"shader attributes: (position: $position_attr, texcoord: $texcoord_attr, normal: $normal_attr)");
        if (position_attr != GL.NULL_ATTRIBUTE) {
            position_attr.pointer (3, GL.FLOAT, GL.FALSE, (GL.sizei) ((3 + 2 + 3) * sizeof(float)));
            position_attr.enable_array ();
        }

        if (texcoord_attr != GL.NULL_ATTRIBUTE) {
            texcoord_attr.pointer (2, GL.FLOAT, GL.FALSE, (GL.sizei) ((3 + 2 + 3) * sizeof(float)), 3 * sizeof(float));
            texcoord_attr.enable_array ();
        }

        if (normal_attr != GL.NULL_ATTRIBUTE) {
            normal_attr.pointer (3, GL.FLOAT, GL.FALSE, (GL.sizei) ((3 + 2 + 3) * sizeof(float)), (3 + 2) * sizeof(float));
            normal_attr.enable_array ();
        }

        GL.bind_vertex_array (0);       // unbind VAO
    }

    ~Mesh () {
        // TODO: GL.delete_vertex_array (vao);
        // TODO: delete other buffers
    }

    public string to_string () {
        return @"$id (vbo: $vbo)";
    }
}
