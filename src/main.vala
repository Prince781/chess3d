public class Ch3.App : Gtk.Application {
    // Member variables

    // Constructor
    public App () {
        Object (application_id: "com.github.prince781.Ch3",
                flags : GLib.ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var win = this.get_active_window ();
        if (win == null) {
            win = new MainWindow (this);
        }
        win.present ();
    }
}

int main (string[] args) {
    var my_app = new Ch3.App ();
    return my_app.run (args);
}
