/**
 * Any animation of a specific property.
 */
public class Ch3.Animation : Object {
    /**
     * The frame time when the animation started.
     */
    private int64? _begin_frame_time;

    /**
     * The length of the animation, in seconds.
     */
    public float length { get; construct set; default = 1.0f; }

    private float _progress;

    /**
     * The animation's progress, in seconds.
     */
    public float progress {
        get { return _progress; }
        set {
            if (repeat) {
                _progress = Math.fmodf (value, length);
            } else {    // saturate progress
                _progress = Math.fminf (Math.fmaxf(value, 0), length);
            }
        }
    }

    /**
     * The initial value.
     */
    public float init_val { get; construct; }

    /**
     * Returns an interpolated value based on the current progress.
     */
    public float current_val {
        get {
            // linearly interpolated (TODO: other kinds of interpolation)
            return init_val + (final_val - init_val) * progress / length;
        }
    }
    
    /**
     * The final value.
     */
    public float final_val { get; construct; }

    private bool _repeat;

    /**
     * Whether the animation loops.
     */
    public bool repeat {
        get { return _repeat; }
        set {
            if (!_repeat && value)
                progress = 0;   // reset progress
            _repeat = value;
        }
    }

    /**
     * Whether the animation is finished.
     */
    public bool finished {
        get { return !repeat && progress >= length; }
    }

    /**
     * Create a new animation between a starting and ending value.
     *
     * @param init_val  the initial value
     * @param final_val the final value
     * @param length    the animation length, in seconds
     * @param repeat    whether the animation loops
     */
    public Animation (float init_val, float final_val, float length, bool repeat = false)
        requires (length >= 0) {
        Object (init_val: init_val, final_val: final_val,
                length: length, repeat: repeat);
    }

    /**
     * Start the animation or reset it.
     *
     * @param frame_time        the current frame time, in microseconds
     * @see Gdk.FrameClock.get_frame_time
     */
    public void start (int64 frame_time) {
        this._begin_frame_time = frame_time;
    }

    /**
     * Update the animation.
     *
     * @param frame_time        the current frame time, in microseconds
     * @see Gdk.FrameClock.get_frame_time
     */
    public void update (int64 frame_time) {
        if (_begin_frame_time == null)
            start (frame_time);

        if (!this.finished) {
            this.progress = (frame_time - _begin_frame_time) / 1000000f;
            // debug (@"frame_time = $frame_time, _begin_frame_time = $_begin_frame_time");
            // debug ("progress = %f", progress);
        }
    }
}
