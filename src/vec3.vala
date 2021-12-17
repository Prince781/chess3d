public struct Ch3.Vec3 {
    public float x;
    public float y;
    public float z;

    public Vec3 (float x = 0, float y = 0, float z = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public Vec3 normalized () {
        return Vec3 (x/length, y/length, z/length);
    }

    public float length {
        get { return Math.sqrtf (x*x + y*y + z*z); }
    }

    public string to_string () {
        return @"<$x,$y,$z>";
    }
}
