# 2D Renderer

## Goal

Mainly focus on ui rendering(2d Rendering features currently not considered)

our goal is to make an IMGUI api to render ui, and make it cross platform.



## decisions

### 2D coordinates system 
We need to decide 2d coordinates system
     -> top left is 0, 0, bottom right is width, height

why : Because it same as windows coordinate system


## API need to support:

```odin

// Does it need to put here or implement in IMGUI api?
Style_Context :: struct {
    font: Maybe(Font),
    border_color: Maybe(Color),
    border_width: Maybe(i32), // in pixel and grow from outside
    border_radius: Maybe(f32), // in pixel
    filled_color: Maybe(Color),
}

set_global_style :: proc(using ctx: ^Render_Context, style: ^Style_Context)
set_scope_style :: proc(using ctx: ^Render_Context, style: ^Style_Context)

draw_box :: proc(using ctx: ^Render_Context,
position: linalg.Vector2f32, 
width: f32, height: f32, style_override: Style_Context)


draw_circle :: proc(using ctx: ^Render_Context,
position: linalg.Vector2f32, 
radius: f32, style_override: Style_Context)
```

