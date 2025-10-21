package graphic
import "core:math/linalg"


Vertex :: struct {
    position: linalg.Vector3f32,
    uv:    linalg.Vector2f32,
}

Scene_Constant_Buffer :: struct {
    offset: linalg.Vector4f32,
    padding: [60]f32,
}
