public class Ch3.Model : Object {
    public HashTable<string, Mesh> meshes { get; default = new HashTable<string, Mesh> (str_hash, str_equal); }
    public HashTable<string, Material> materials { get; default = new HashTable<string, Material> (str_hash, str_equal); }

    public Vec3 position { get; set; }
    public Vec3 rotation { get; set; }
    public Vec3 scale { get; set; default = Vec3 (1.0f, 1.0f, 1.0f); }

    public GenericSet<Model> children { get; default = new GenericSet<Model> (null, null); }

    /**
     * Construct a model from a Wavefront object.
     *
     * @param path      GResource path
     */
    public Model (string path, GL.Program program) throws Error {
        var data = new Utf8InputStream (resources_open_stream (path, ResourceLookupFlags.NONE));
        Vec3[] vertices = {};           // all the vertices in the .obj
        Vec2[] uvs = {};                // all the UVs in the .obj
        Vec3[] normals = {};            // all the normals in the .obj
        Mesh.Face[] faces = {};         // only the faces of the current mesh
        string? mesh_id = null;
        Material? material = null;      // the current material

        debug ("loading %s ...", path);
        while (data.next_line ()) {
            if (data.skip_char ('#')) {                 // comments
                continue;
            } else if (data.skip_symbol ("mtllib")) {
                string mtllib = data.read_string ();
                foreach (var mat in Material.load_library (@"/com/github/prince781/Ch3/materials/$mtllib")) {
                    materials[mat.id] = mat;
                }
            } else if (data.skip_symbol ("usemtl")) {
                string mat_id = data.read_string ();
                if (!materials.contains (mat_id))
                    throw new IOError.INVALID_DATA ("%s:line %u:%s is not a valid material ID", path, data.lineno, mat_id);
                // save a new mesh with the previous material first
                if (faces.length > 0) {
                    var mesh = new Mesh (mesh_id ?? @"Mesh#$(meshes.length)", faces, program, material);
                    meshes[mesh.id] = mesh;
                    // reset faces
                    faces = {};
                    material = null;
                    mesh_id = null;
                }
                material = materials[mat_id];
            } else if (data.skip_symbol ("o")) {
                if (faces.length > 0) {
                    var mesh = new Mesh (mesh_id ?? @"Mesh#$(meshes.length)", faces, program, material);
                    meshes[mesh.id] = mesh;
                    // reset faces
                    faces = {};
                    material = null;
                    mesh_id = null;
                }
                mesh_id = data.read_string ();
                if (mesh_id.length == 0)        // object name is optional
                    mesh_id = null;
            } else if (data.skip_symbol ("v")) {
                float x = data.parse_float ();
                float y = data.parse_float ();
                float z = data.parse_float ();
                try {
                    float w = data.parse_float (); // w
                    x /= w;
                    y /= w;
                    z /= w;
                } catch (Error e) { /* ignore */ }
                vertices += Vec3 (x, y, z);
            } else if (data.skip_symbol ("vt")) {       // texture coordinates
                float u = data.parse_float ();
                float v = data.parse_float ();
                try {
                    data.parse_float (); // w
                } catch (Error e) { /* ignore */ }
                uvs += Vec2 (u, v);
            } else if (data.skip_symbol ("vn")) {       // normals
                float x = data.parse_float ();
                float y = data.parse_float ();
                float z = data.parse_float ();
                normals += Vec3 (x, y, z).normalized ();
            } else if (data.skip_symbol ("f")) {        // face
                Mesh.Point points[3];
                int npoints = 0;

                while (!data.at_end_of_line) {
                    int vi = -1, vt = -1, vn = -1;

                    vi = data.parse_int ();
                    if (data.skip_char ('/')) {
                        if (data.peek_char () != '/')
                            vt = data.parse_int ();
                    }
                    if (data.skip_char ('/'))
                        vn = data.parse_int ();

                    if (vi - 1 < 0 || vi - 1 >= vertices.length)
                        throw new IOError.INVALID_DATA ("%s:line %u: invalid vertex ID %d", path, data.lineno, vi - 1);
                    points[npoints % 3].v = vertices[vi - 1];
                    if (vt != -1) {
                        if (vt - 1 < 0 || vt - 1 >= uvs.length)
                            throw new IOError.INVALID_DATA ("%s:line %u: invalid texture ID %d", path, data.lineno, vt - 1);
                        points[npoints % 3].uv = uvs[vt - 1];
                    }
                    if (vn != -1) {
                        if (vn - 1 < 0 || vn - 1 >= normals.length)
                            throw new IOError.INVALID_DATA ("%s:line %u: invalid normal ID %d", path, data.lineno, vn - 1);
                        points[npoints % 3].n = normals[vn - 1];
                    }

                    npoints++;
                    if (npoints >= 3) {
                        faces += Mesh.Face () { p = points };
                        points[1] = points[2];
                        npoints += 2;
                    }
                }
            }
        }

        if (faces.length > 0) {
            var mesh = new Mesh (mesh_id ?? @"Mesh#$(meshes.length)", faces, program, material);
            meshes[mesh.id] = mesh;
            faces = {};
            material = null;
            mesh_id = null;
        }
    }
}
