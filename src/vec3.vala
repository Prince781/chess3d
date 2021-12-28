public struct Ch3.Vec3 {
    public float x;
    public float y;
    public float z;

    public Vec3 (float x = 0, float y = 0, float z = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public Vec3 normalized ()
        requires (length >= 1e-9)
    {
        return Vec3 (x/length, y/length, z/length);
    }

    public float length {
        get { return Math.sqrtf (x*x + y*y + z*z); }
    }

    public Vec3 add (Vec3 other) {
        return Vec3 (x + other.x, y + other.y, z + other.z);
    }

    public Vec3 subtract (Vec3 other) {
        return Vec3 (x - other.x, y - other.y, z - other.z);
    }

    public Vec3 cross (Vec3 other) {
        return Vec3 (y * other.z - z * other.y, -(x * other.z - z * other.x), x * other.y - y * other.x);
    }

    public string to_string () {
        return @"<$x,$y,$z>";
    }
}
