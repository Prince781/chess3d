public class Ch3.MainWindow : Gtk.ApplicationWindow {
    public Renderer renderer { get; construct; }

    public MainWindow (Gtk.Application app) {
        Object (application: app,
                default_width: 800, default_height: 640,
                title: "Chess 3D",
                renderer: new Renderer ());

        var header = new Gtk.HeaderBar ();
        this.set_titlebar (header);

        var area = new Gtk.GLArea () {
            hexpand = true,
            vexpand = true,
            use_es = true,
            has_depth_buffer = true,
            // has_stencil_buffer = true
            width_request = 640,
            height_request = 640
        };

        // set up renderer
        area.realize.connect (renderer.setup);
        area.render.connect (renderer.render);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.append (area);

        this.child = box;

        // create debug panel for objects in the scene
        var panel_viewport = new Gtk.Viewport (null, null);
        box.append (panel_viewport);

        var panel = new Gtk.Box (Gtk.Orientation.VERTICAL, 10) {
            width_request = 256
        };
        panel_viewport.child = panel;
    }
}
