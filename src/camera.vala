public class Ch3.Camera : Object {
    /**
     * The position of the camera
     */
    public Vec3 position { get; set; }

    /**
     * The direction the camera is facing.
     */
    public Vec3 direction { get; set; }

    public Camera (Vec3 position = Vec3 (), Vec3 direction = Vec3 (0, 0, -1)) {
        this.position = position;
        this.direction = direction;
    }
}
