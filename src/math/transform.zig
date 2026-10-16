const Vec3f = @import("vec.zig").Vec3f;
const Vec4f = @import("vec.zig").Vec4f;
const Mat4f = @import("mat.zig").Mat4f;
const mat = @import("mat.zig");

pub fn makeTransform(
    translation: Vec3f,
    rotation: Vec3f,
    scale: Vec3f,
) Mat4f {
    const translation_mat = mat.translate(translation);
    const rotation_z_mat = mat.rotateZ(rotation.data[2]);
    const rotation_y_mat = mat.rotateY(rotation.data[1]);
    const rotation_x_mat = mat.rotateX(rotation.data[0]);
    const scale_mat = mat.scaling(scale);

    const rotation_mat = Mat4f.mul(
        Mat4f.mul(rotation_z_mat, 4, rotation_y_mat),
        4,
        rotation_x_mat,
    );
    return Mat4f.mul(
        Mat4f.mul(translation_mat, 4, rotation_mat),
        4,
        scale_mat,
    );
}

pub fn transformPoint(
    matrix: Mat4f,
    position: Vec3f,
) Vec3f {
    const p4 = Mat4f.mulVec(matrix, Vec4f.init(position.data ++ [1]f32{1}));

    return Vec3f.init(p4.data[0..3].*);
}
