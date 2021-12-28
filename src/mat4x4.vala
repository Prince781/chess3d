/**
 * A 4-by-4 matrix useful in OpenGL matrix operations.
 */
public struct Ch3.Mat4x4 {
    public float data[4*4];
    
    /**
     * Create a new matrix with a value along its diagonal.
     */
    public Mat4x4 (float diagonal_value) {
        for (int i = 0; i < 4; i++)
            this[i, i] = diagonal_value;
    }

    public Mat4x4.identity () {
        this (1.0f);
    }

    /**
     * Construct a perspective transform.
     *
     * @param fov               field of view, angle in radians
     * @param aspect_ratio      width / height
     * @param near              distance to near plane along the z axis
     * @param far               distance to far plane along the z axis
     */
    public Mat4x4.perspective (float fov, float aspect_ratio, float near, float far) {
        // see http://www.songho.ca/opengl/gl_projectionmatrix.html

        float height_2 = Math.tanf (fov / 2) * near;
        float width_2 = aspect_ratio * height_2;

        this[0, 0] = near / width_2;

        this[1, 1] = near / height_2;

        this[2, 2] = -(far + near) / (far - near);
        this[2, 3] = -2 * far * near / (far - near);

        this[3, 2] = -1;
    }

    /**
     * Constructs a transformation matrix for a camera looking at `target` from
     * `position`.
     *
     * @param position  the position of the camera
     * @param target    what the camera is looking at
     * @param up        a direction that represents "up"
     */
    public Mat4x4.look_at (Vec3 position, Vec3 target, Vec3 up) {
        // see https://learnopengl.com/Getting-started/Camera

        up = up.normalized ();
        var direction = position.subtract (target).normalized ();
        var right = up.cross (direction).normalized ();
        up = direction.cross (right).normalized ();

        this[0, 0] = right.x;
        this[0, 1] = right.y;
        this[0, 2] = right.z;
        this[0, 3] = right.x * (-position.x) + right.y + (-position.y) + right.z * (-position.z);

        this[1, 0] = up.x;
        this[1, 1] = up.y;
        this[1, 2] = up.z;
        this[1, 3] = up.x * (-position.x) + up.y * (-position.y) + up.z * (-position.z);

        this[2, 0] = direction.x;
        this[2, 1] = direction.y;
        this[2, 2] = direction.z;
        this[2, 3] = direction.x * (-position.x) + direction.y * (-position.y) + direction.z * (-position.z);

        this[3, 3] = 1;
    }

    public void set (int row, int col, float value) {
        data[col*4 + row] = value;
    }

    public float get (int row, int col) {
        return data[col*4 + row];
    }

    public Mat4x4 write (int row, int col, float value) {
        var copy = this;
        copy[row, col] = value;
        return copy;
    }

    public Mat4x4 rotateX (float radians) {
        // see https://learnopengl.com/Getting-started/Transformations 
        var copy = this;
        // rotate around x axis
        float sin_x, cos_x;
        Math.sincosf (radians, out sin_x, out cos_x);
        for (int col = 0; col < 4; col++) {
            // copy[0, col] = this[0, col];
            copy[1, col] = cos_x * this[1, col] - sin_x * this[2, col];
            copy[2, col] = sin_x * this[1, col] + cos_x * this[2, col];
            // copy[3, col] = this[3, col];
        }
        return copy;
    }

    public Mat4x4 rotateY (float radians) {
        var copy = this;
        // rotate around y axis
        float sin_y, cos_y;
        Math.sincosf (radians, out sin_y, out cos_y);
        for (int col = 0; col < 4; col++) {
            copy[0, col] = cos_y * this[0, col] + sin_y * this[2, col];
            // copy[1, col] = this[1, col];
            copy[2, col] = -sin_y * this[0, col] + cos_y * this[2, col];
            // copy[3, col] = this[3, col];
        }
        return copy;
    }

    public Mat4x4 rotateZ (float radians) {
        var copy = this;
        // rotate around z axis
        float sin_z, cos_z;
        Math.sincosf (radians, out sin_z, out cos_z);
        for (int col = 0; col < 4; col++) {
            copy[0, col] = cos_z * this[0, col] - sin_z * this[1, col];
            copy[1, col] = sin_z * this[0, col] + cos_z * this[1, col];
            // copy[2, col] = this[2, col];
            // copy[3, col] = this[3, col];
        }
        return copy;
    }

    public Mat4x4 scale (float x, float y, float z) {
        var copy = this;
        copy[0, 0] *= x;
        copy[1, 1] *= y;
        copy[2, 2] *= z;
        return copy;
    }

    public Mat4x4 translate (float x, float y, float z) {
        var copy = this;
        copy[0, 3] += x;
        copy[1, 3] += y;
        copy[2, 3] += z;
        return copy;
    }

    public Mat4x4 multiply (Mat4x4 other) {
        var result = Mat4x4 (0);

        // this x other = result
        for (int row = 0; row < 4; row++)
            for (int col = 0; col < 4; col++)
                for (int k = 0; k < 4; k++)     // FIXME: codegen with result[row, col] += ... versus = ... + ...
                    result[row, col] = result[row, col] + this[row, k] * other[k, col];

        return result;
    }

    public string to_string (string format = "%f") {
        string vals[4*4];
        int maxlen = 0;

        for (int row = 0; row < 4; row++) {
            for (int col = 0; col < 4; col++) {
                vals[col*4 + row] = this[row, col].to_string (format);
                var len = vals[col*4 + row].length;
                if (len > maxlen)
                    maxlen = len;
            }
        }

        var sb = new StringBuilder ();
        for (int row = 0; row < 4; row++) {
            sb.append ("| ");
            for (int col = 0; col < 4; col++) {
                var len = vals[col*4 + row].length;
                sb.append (vals[col*4 + row]);
                for (int i = 0; i < maxlen - len; i++)
                    sb.append_c (' ');
                if (col < 3)
                    sb.append_c (' ');
            }
            sb.append (" |\n");
        }
        return sb.str;
    }
}
