package input


import "core:log"
import "core:math"
import "libs:platform"
import util "libs:utilities"
import "thrid_party:sdl3"

Frame_Input_State :: struct {
    keyboard_state:   map[platform.Keys]Keyboard_Input_Set,
    mouse_state:      Mouse_State,
    controller_state: Controller_State,
}

Input_State :: struct {
    controller:      ^Controller,
    frame_state:     [2]Frame_Input_State,
    old_input_state: ^Frame_Input_State,
    new_input_state: ^Frame_Input_State,
}


create_input_state :: proc(allocator := context.allocator) -> ^Input_State {
    state := new(Input_State, allocator)
    for &i in state.frame_state {
        i.keyboard_state = make(map[platform.Keys]Keyboard_Input_Set, allocator)
    }
    state.old_input_state = &state.frame_state[0]
    state.new_input_state = &state.frame_state[1]
    return state
}
destroy_input_state :: proc(state: ^Input_State) {
    for i in state.frame_state {
        delete(i.keyboard_state)
    }
    free(state)
}


next_frame :: proc(s: ^Input_State) {
    util.swap(&s.old_input_state, &s.new_input_state)
    clear(&s.new_input_state.keyboard_state)
    s.new_input_state.controller_state = {}
    s.new_input_state.mouse_state = {}
    for k, prev_state in s.old_input_state.keyboard_state {
        s.new_input_state.keyboard_state[k] = (prev_state & {.Hold})
    }

    for prev_state, k in s.old_input_state.mouse_state.mouse_button {
        s.new_input_state.mouse_state.mouse_button[k] = (prev_state & {.Hold})
    }

    for i, k in s.old_input_state.controller_state.digitals {
        s.new_input_state.controller_state.digitals[k] = (i & {.Hold})
    }
    for i, k in s.old_input_state.controller_state.analogs {
        s.new_input_state.controller_state.analogs[k] = i
    }

    s.new_input_state.mouse_state.mouse_position = s.old_input_state.mouse_state.mouse_position

}

@(private)
get_press_state :: proc(
    $T: typeid,
    is_down: b8,
    is_hold: b8,
) -> T where T == Keyboard_Input_Set ||
    T == Digit_Input_Set {
    state: T
    if is_down {
        if !is_hold {
            state += {.Down, .Hold}
        } else {
            state += {.Hold}
        }
    } else {
        state = {.Up}
    }
    return state
}

update_key_state :: proc(s: ^Input_State, e: platform.Keyboard_Input) {

    state := get_press_state(Keyboard_Input_Set, e.is_down, is_hold(s, e.key))
    state += quary_modifier_state(s)
    s.new_input_state.keyboard_state[e.key] = state
}

@(private)
quary_modifier_state :: proc(s: ^Input_State) -> Keyboard_Input_Set {
    state: Keyboard_Input_Set
    if is_hold(s, platform.Keys.Left_Alt) || is_hold(s, platform.Keys.Right_Alt) do state += {.Alt}
    if is_hold(s, platform.Keys.Left_Control) || is_hold(s, platform.Keys.Right_Control) do state += {.Ctrl}
    if is_hold(s, platform.Keys.Left_Shift) || is_hold(s, platform.Keys.Right_Shift) do state += {.Shift}
    if is_hold(s, platform.Keys.Left_Super) || is_hold(s, platform.Keys.Right_Super) do state += {.Command}
    return state
}


update_mousebutton_state :: proc(s: ^Input_State, e: platform.MouseButton_Input) {
    state := get_press_state(Keyboard_Input_Set, e.is_down, is_hold(s, e.button))
    state += quary_modifier_state(s)
    s.new_input_state.mouse_state.mouse_button[e.button] = state
}

update_mouse_move :: proc(s: ^Input_State, e: platform.Mouse_Move) {
    s.new_input_state.mouse_state.mouse_delta =
        e.position - s.old_input_state.mouse_state.mouse_position
    s.new_input_state.mouse_state.mouse_position = e.position
}

update_mouse_wheel :: proc(s: ^Input_State, e: platform.Mouse_Wheel) {
    s.new_input_state.mouse_state.wheel_delta = e.delta
}


update_controller_state :: proc(s: ^Input_State) {
    sdl_event: sdl3.Event
    for sdl3.PollEvent(&sdl_event) {
        #partial switch sdl_event.type {
        case .GAMEPAD_ADDED:
            if s.controller != nil do continue
            gamepad_id := sdl_event.gdevice.which
            s.controller = sdl3.OpenGamepad(gamepad_id)
            if s.controller == nil {
                log.warnf("error to open gamepad: {}, error: {}", gamepad_id, sdl3.GetError())
            }
        case .GAMEPAD_REMOVED:
            if s.controller == nil && sdl_event.gdevice.which == sdl3.GetGamepadID(s.controller) do continue
            sdl3.CloseGamepad(s.controller)
            s.controller = nil
        case .GAMEPAD_BUTTON_DOWN, .GAMEPAD_BUTTON_UP:
            e_button := sdl_event.gbutton
            if e_button.which != sdl3.GetGamepadID(s.controller) do continue
            button_type := Gamepad_Button(e_button.button)
            state := get_press_state(Digit_Input_Set, b8(e_button.down), is_hold(s, button_type))
            s.new_input_state.controller_state.digitals[button_type] = state
        case .GAMEPAD_AXIS_MOTION:
            e_axis := sdl_event.gaxis
            if e_axis.which != sdl3.GetGamepadID(s.controller) do continue
            axis_type := Gamepad_Axis(e_axis.axis)
            switch axis_type {
            case .LEFTX ..< .LEFT_TRIGGER:
                s.new_input_state.controller_state.analogs[axis_type] =
                    f32(e_axis.value) / Axis_Max
            case .LEFT_TRIGGER, .RIGHT_TRIGGER:
                s.new_input_state.controller_state.analogs[axis_type] =
                    ((f32(e_axis.value) - Axis_Min) / (Axis_Max - Axis_Min) - 0.5) * 2
            case .INVALID:
                log.warn("invalid Axis")
            }
        }
    }

    // Update Controller DeadZone
    AXIS_DEADZONE :: 0.08
    Trigger_DEADZONE :: 0.01

    update_cross_deadzone(
        &s.new_input_state.controller_state.analogs[.LEFTX],
        &s.new_input_state.controller_state.analogs[.LEFTY],
        AXIS_DEADZONE,
        AXIS_DEADZONE,
    )
    update_cross_deadzone(
        &s.new_input_state.controller_state.analogs[.RIGHTX],
        &s.new_input_state.controller_state.analogs[.RIGHTY],
        AXIS_DEADZONE,
        AXIS_DEADZONE,
    )

    if s.new_input_state.controller_state.analogs[.LEFT_TRIGGER] < Trigger_DEADZONE {
        s.new_input_state.controller_state.analogs[.LEFT_TRIGGER] = 0
    }
    if s.new_input_state.controller_state.analogs[.RIGHT_TRIGGER] < Trigger_DEADZONE {
        s.new_input_state.controller_state.analogs[.RIGHT_TRIGGER] = 0
    }

}

@(private = "file")
update_circle_deadzone :: proc(value_x: ^f32, value_y: ^f32, deadzone: f32) {
    x := value_x^
    y := value_y^
    len_sqrt2 := x * x + y * y
    if len_sqrt2 < deadzone * deadzone {
        value_x^ = 0
        value_y^ = 0
    }
}

@(private = "file")
update_cross_deadzone :: proc(value_x: ^f32, value_y: ^f32, deadzone_x: f32, deadzone_y: f32) {
    x := value_x^
    y := value_y^

    if math.abs(x) < deadzone_x {
        value_x^ = 0
    }
    if math.abs(y) < deadzone_y {
        value_y^ = 0
    }
}


is_down_keyboard_state :: #force_inline proc(
    s: ^Input_State,
    key: platform.Keys,
    state: Keyboard_Input_Set = {},
) -> b8 {
    return is_down_keyboard(s.new_input_state.keyboard_state[key], state)
}

is_up_keyboard_state :: #force_inline proc(
    s: ^Input_State,
    key: platform.Keys,
    state: Keyboard_Input_Set = {},
) -> b8 {
    return is_up_keyboard(s.new_input_state.keyboard_state[key], state)
}
is_hold_keyboard_state :: #force_inline proc(
    s: ^Input_State,
    key: platform.Keys,
    state: Keyboard_Input_Set = {},
) -> b8 {
    return is_hold_keyboard(s.new_input_state.keyboard_state[key], state)
}


is_down_mouse_state :: #force_inline proc(
    s: ^Input_State,
    key: platform.Mouse_Button,
    state: Keyboard_Input_Set = {},
) -> b8 {
    return is_down_keyboard(s.new_input_state.mouse_state.mouse_button[key], state)
}

is_up_mouse_state :: #force_inline proc(
    s: ^Input_State,
    key: platform.Mouse_Button,
    state: Keyboard_Input_Set = {},
) -> b8 {
    return is_up_keyboard(s.new_input_state.mouse_state.mouse_button[key], state)
}
is_hold_mouse_state :: #force_inline proc(
    s: ^Input_State,
    key: platform.Mouse_Button,
    state: Keyboard_Input_Set = {},
) -> b8 {
    return is_hold_keyboard(s.new_input_state.mouse_state.mouse_button[key], state)
}

is_down_controller_state :: #force_inline proc(s: ^Input_State, button: Gamepad_Button) -> b8 {
    return is_down(s.new_input_state.controller_state.digitals[button])
}


is_up_controller_state :: #force_inline proc(s: ^Input_State, button: Gamepad_Button) -> b8 {
    return is_up(s.new_input_state.controller_state.digitals[button])
}


is_hold_controller_state :: #force_inline proc(s: ^Input_State, button: Gamepad_Button) -> b8 {
    return is_hold(s.new_input_state.controller_state.digitals[button])
}

get_axis_value :: #force_inline proc(s: ^Input_State, axis: Gamepad_Axis) -> f32 {
    return s.new_input_state.controller_state.analogs[axis]
}
