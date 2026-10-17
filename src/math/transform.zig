const Vec3f = @import("_vec.zig").Vec3f;
const Vec4f = @import("_vec.zig").Vec4f;
const Mat4f = @import("_mat.zig").Mat4f;
const Quatf = @import("quat.zig").Quatf;
const mat = @import("_mat.zig");

pub fn makeTransform(
    translation: Vec3f,
    rotation: Quatf,
    scale: Vec3f,
) Mat4f {
    const translation_mat = mat.translate(translation);
    const scale_mat = mat.scaling(scale);

    return Mat4f.mul(
        Mat4f.mul(translation_mat, 4, rotation.toMat4()),
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
