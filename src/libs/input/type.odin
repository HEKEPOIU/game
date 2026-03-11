package input

import "core:math/linalg"
import "libs:platform"
import "thrid_party:sdl3"

Digit_Input :: enum u8 {
    Down,
    Up,
    Hold,
}

Dir :: enum u8 {
    Pos,
    Neg,
}

Mouse_State :: struct {
    mouse_button:   [platform.Mouse_Button]Keyboard_Input_Set,
    mouse_position: linalg.Vector2f32,
    mouse_delta:    linalg.Vector2f32,
    wheel_delta:    f32,
}

Gamepad_Button :: sdl3.GamepadButton
Gamepad_Axis :: sdl3.GamepadAxis
Axis_Max :: sdl3.JOYSTICK_AXIS_MAX
Axis_Min :: sdl3.JOYSTICK_AXIS_MIN
Controller :: sdl3.Gamepad

Controller_State :: struct {
    digitals: [Gamepad_Button]Digit_Input_Set,
    analogs:  [Gamepad_Axis]f32,
}

Keyboard_Input :: enum u8 {
    Down,
    Up,
    Hold,
    Alt,
    Ctrl,
    Shift,
    Command,
}

Digit_Input_Set :: bit_set[Digit_Input;u8]
Keyboard_Input_Set :: bit_set[Keyboard_Input;u8]

Keyboard_Modifier_Mask :: Keyboard_Input_Set{.Alt, .Ctrl, .Shift, .Command}


SDL_HS_Value :: enum u8 {
    None,
    North,
    East,
    South,
    West,
}
