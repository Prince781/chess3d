public class Ch3.Texture2d : Object {
    public string path { get; construct; }
    public GL.uint id { get; private set; }

    /**
     * Loads a 2D texture from a resource and sets up a GL texture buffer.
     *
     * @param filename  basename
     */
    public Texture2d (string filename) throws Error {
        Object (path: @"/com/github/prince781/Ch3/textures/$filename");
        var pixbuf = new Gdk.Pixbuf.from_resource (this.path);
        debug ("loading %s ...", this.path);
        id = GL.gen_texture ();
        GL.bind_texture (GL.TEXTURE_2D, id);
        GL.tex_image_2D (GL.TEXTURE_2D, 0, GL.RGB, pixbuf.width, pixbuf.height, 0, GL.RGB, GL.UNSIGNED_BYTE, pixbuf.get_pixels ());
        GL.generate_mipmap (GL.TEXTURE_2D);
        GL.bind_texture (GL.TEXTURE_2D, 0);     // unbind
    }
}
