public class Ch3.Material : Object {
    public string id { get; construct; }

    public Vec3 ambient_color { get; set; }
    public Vec3 diffuse_color { get; set; }
    public Vec3 specular_color { get; set; }
    public float specular_exponent { get; set; }

    public Texture2d? ambient_texture { get; set; }
    public Texture2d? diffuse_texture { get; set; }
    public Texture2d? specular_texture { get; set; }

    public Material (string id) {
        Object (id: id);
    }

    /**
     * Parse a .mtl file and return all the materials found.
     */
    public static Material[] load_library (string path) throws Error {
        Material[] mats = {};
        var data = new Utf8InputStream (resources_open_stream (path, ResourceLookupFlags.NONE));

        debug ("loading %s ...", path);
        while (data.next_line ()) {
            if (data.at_end_of_line || data.skip_char ('#')) {  // empty line or comment
                continue;
            } else if (data.skip_symbol ("newmtl")) {
                string mtlname = data.read_string ();
                mats += new Material (mtlname);
            } else {
                if (mats.length == 0)
                    throw new IOError.INVALID_DATA ("line %u: material undefined here", data.lineno);

                if (data.skip_symbol ("Ka")) {
                    float x = data.parse_float ();
                    float y = data.parse_float ();
                    float z = data.parse_float ();
                    mats[mats.length-1].ambient_color = Vec3 (x, y, z);
                } else if (data.skip_symbol ("Kd")) {
                    float x = data.parse_float ();
                    float y = data.parse_float ();
                    float z = data.parse_float ();
                    mats[mats.length-1].diffuse_color = Vec3 (x, y, z);
                } else if (data.skip_symbol ("Ks")) {
                    float x = data.parse_float ();
                    float y = data.parse_float ();
                    float z = data.parse_float ();
                    mats[mats.length-1].specular_color = Vec3 (x, y, z);
                } else if (data.skip_symbol ("Ns")) {
                    mats[mats.length-1].specular_exponent = data.parse_float ();
                } else if (data.skip_symbol ("map_Ka")) {
                    string filename = Path.get_basename (data.read_string ());
                    mats[mats.length-1].ambient_texture = new Texture2d (filename);
                } else if (data.skip_symbol ("map_Kd")) {
                    string filename = Path.get_basename (data.read_string ());
                    mats[mats.length-1].diffuse_texture = new Texture2d (filename);
                } else if (data.skip_symbol ("map_Ks")) {
                    string filename = Path.get_basename (data.read_string ());
                    mats[mats.length-1].specular_texture = new Texture2d (filename);
                }
            }
        }

        return mats;
    }

    public string to_string () {
        var sb = new StringBuilder ();
        sb.append ("Material ");
        sb.append (id);
        sb.append (" { ambient: ");
        if (ambient_texture != null) {
            sb.append ("( ");
            sb.append (ambient_color.to_string ());
            sb.append (", ");
            sb.append (ambient_texture.path);
            sb.append_c (')');
        } else {
            sb.append (ambient_color.to_string ());
        }
        sb.append (", diffuse: ");
        if (diffuse_texture != null) {
            sb.append ("( ");
            sb.append (diffuse_color.to_string ());
            sb.append (", ");
            sb.append (diffuse_texture.path);
            sb.append_c (')');
        } else {
            sb.append (diffuse_color.to_string ());
        }
        sb.append (", specular: ");
        if (specular_texture != null) {
            sb.append ("( ");
            sb.append (specular_color.to_string ());
            sb.append (", ");
            sb.append (specular_texture.path);
            sb.append_c (')');
        } else {
            sb.append (specular_color.to_string ());
        }
        sb.append (" }");
        return sb.str;
    }
}
