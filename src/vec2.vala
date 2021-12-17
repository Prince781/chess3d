public struct Ch3.Vec2 {
    public float x;
    public float y;

    public Vec2 (float x = 0, float y = 0) {
        this.x = x;
        this.y = y;
    }

    public string to_string () {
        return @"<$x,$y>";
    }
}
