public class Ch3.MainWindow : Gtk.ApplicationWindow {
    public Renderer renderer { get; construct; }
    public Gtk.ListBox object_selector { get; private set; }
    public Gtk.Label panel_object_title { get; private set; }
    public Gtk.Box panel { get; private set; }
    public Vec3Field position_debug { get; private set; }
    public Vec3Field rotation_debug { get; private set; }
    Binding[] bindings = {};

    public ListStore scene_objects { get; private set; }

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

        panel = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 256,
            margin_start = 15,
            margin_end = 15,
            margin_top = 15,
            margin_bottom = 15
        };
        panel_viewport.child = panel;

        panel.append (new Gtk.Label ("Scene") {
            xalign = 0,
            margin_bottom = 15,
            css_classes = {"title-3"}
        });
        object_selector = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.SINGLE,
            show_separators = true,
            css_classes = {"rich-list"}
        };
        panel.append (new Gtk.Frame (null) {
            child = object_selector,
            margin_bottom = 15
        });

        panel_object_title = new Gtk.Label ("(No Object Selected)") {
            xalign = 0,
            margin_bottom = 15,
            css_classes = {"title-4"}
        };
        panel.append (panel_object_title);

        position_debug = new Vec3Field ("Position");
        rotation_debug = new Vec3Field ("Rotation");
        panel.append (position_debug.widget);
        panel.append (rotation_debug.widget);

        area.realize.connect (_ => {
            // create a list model from the scene objects
            scene_objects = new ListStore (typeof (Model));
            renderer.fill_scene_objects (scene_objects);

            // bind it to the object selector
            object_selector.bind_model (scene_objects, obj => {
                var model = (Model)obj;
                return new Gtk.Label (model.name) {
                    halign = Gtk.Align.START,
                    valign = Gtk.Align.CENTER
                };
            });

            object_selector.row_selected.connect (row => {
                if (row == null)
                    renderer.selected_model = null;
                else {
                    Model? found = renderer.find_by_name (((Gtk.Label)row.child).label);
                    renderer.selected_model = found;
                    if (found != null)
                        debug_object (found);
                }
            });
        });

        renderer.bind_property ("selected-model", panel_object_title, "label", BindingFlags.SYNC_CREATE,
        (binding, srcval, ref targetval) => {
            Model? model = (Model?) srcval;
            if (model == null)
                targetval = "(Nothing Selected)";
            else
                targetval = model.name;
            return true;
        });
    }

    void debug_object (Model model) {
        // unbind
        foreach (var binding in bindings)
            binding.unbind ();
        bindings = {};

        // --- bind position
        bindings += model.bind_property ("position", position_debug.x_spinbutton, "value",
                                         BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            transform_vector_to_x_component,
            transform_double_to_x_component);
        bindings += model.bind_property ("position", position_debug.y_spinbutton, "value",
                                         BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            transform_vector_to_y_component,
            transform_double_to_y_component);
        bindings += model.bind_property ("position", position_debug.z_spinbutton, "value",
                                         BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            transform_vector_to_z_component,
            transform_double_to_z_component);

        // --- bind rotation
        bindings += model.bind_property ("rotation", rotation_debug.x_spinbutton, "value",
                                         BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            transform_vector_to_x_component,
            transform_double_to_x_component);
        bindings += model.bind_property ("rotation", rotation_debug.y_spinbutton, "value",
                                         BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            transform_vector_to_y_component,
            transform_double_to_y_component);
        bindings += model.bind_property ("rotation", rotation_debug.z_spinbutton, "value",
                                         BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            transform_vector_to_z_component,
            transform_double_to_z_component);
    }

    static bool transform_double_to_x_component (Binding binding, Value srcval, ref Value targetval) {
        double x = (double)srcval;
        var old_source = Value (typeof (Vec3));
        ((Model)binding.source).get_property (binding.source_property, ref old_source);
        Vec3 vector = (Vec3)old_source;
        vector.x = (float)x;
        targetval = vector;
        return true;
    }

    static bool transform_vector_to_x_component (Binding binding, Value srcval, ref Value targetval) {
        Vec3 vector = (Vec3)srcval;
        targetval = (double)vector.x;
        return true;
    }

    static bool transform_double_to_y_component (Binding binding, Value srcval, ref Value targetval) {
        double y = (double)srcval;
        var old_source = Value (typeof (Vec3));
        ((Model)binding.source).get_property (binding.source_property, ref old_source);
        Vec3 vector = (Vec3)old_source;
        vector.y = (float)y;
        targetval = vector;
        return true;
    }

    static bool transform_vector_to_y_component (Binding binding, Value srcval, ref Value targetval) {
        Vec3 vector = (Vec3)srcval;
        targetval = (double)vector.y;
        return true;
    }

    static bool transform_double_to_z_component (Binding binding, Value srcval, ref Value targetval) {
        double z = (double)srcval;
        var old_source = Value (typeof (Vec3));
        ((Model)binding.source).get_property (binding.source_property, ref old_source);
        Vec3 vector = (Vec3)old_source;
        vector.z = (float)z;
        targetval = vector;
        return true;
    }

    static bool transform_vector_to_z_component (Binding binding, Value srcval, ref Value targetval) {
        Vec3 vector = (Vec3)srcval;
        targetval = (double)vector.z;
        return true;
    }

    public class Vec3Field : Object {
        public Gtk.Widget widget { get; private set; }
        public Gtk.SpinButton x_spinbutton { get; private set; }
        public Gtk.SpinButton y_spinbutton { get; private set; }
        public Gtk.SpinButton z_spinbutton { get; private set; }

        public Vec3Field (string name) {
            var field = new Gtk.ListBox () {
                selection_mode = Gtk.SelectionMode.NONE,
                show_separators = true,
                css_classes = {"rich-list"}
            };

            var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
            field.append (vbox);

            vbox.append (new Gtk.Label (@"<b>$name</b>") {
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.START,
                hexpand = true,
                use_markup = true
            });

            var x_field = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            x_field.append (new Gtk.Label ("X") {
                xalign = 0,
                halign = Gtk.Align.START,
                valign = Gtk.Align.CENTER,
                hexpand = true
            });
            x_spinbutton = new Gtk.SpinButton.with_range (-1e5, 1e5, 0.001) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER
            };
            x_field.append (x_spinbutton);
            vbox.append (x_field);

            var y_field = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            y_field.append (new Gtk.Label ("X") {
                xalign = 0,
                halign = Gtk.Align.START,
                valign = Gtk.Align.CENTER,
                hexpand = true
            });
            y_spinbutton = new Gtk.SpinButton.with_range (-1e5, 1e5, 0.001) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER
            };
            y_field.append (y_spinbutton);
            vbox.append (y_field);

            var z_field = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            z_field.append (new Gtk.Label ("Z") {
                xalign = 0,
                halign = Gtk.Align.START,
                valign = Gtk.Align.CENTER,
                hexpand = true
            });
            z_spinbutton = new Gtk.SpinButton.with_range (-1e5, 1e5, 0.001) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.CENTER
            };
            z_field.append (z_spinbutton);
            vbox.append (z_field);

            widget = new Gtk.Frame (null) {
                child = field,
                margin_bottom = 15
            };
        }
    }
}
