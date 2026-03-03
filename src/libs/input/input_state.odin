package input


import "core:log"
import "libs:platform"
import util "libs:utilities"

Frame_Input_State :: struct {
    keyboard_state:   map[platform.Keys]Keyboard_Input_Set,
    mouse_state:      Mouse_State,
    controller_state: Controller_State,
}

Input_State :: struct {
    frame_state:     [2]Frame_Input_State,
    old_input_state: ^Frame_Input_State,
    new_input_state: ^Frame_Input_State,
}


make_input_state :: proc(allocator := context.allocator) -> ^Input_State {
    state := new(Input_State, allocator)
    for &i in state.frame_state {
        i.keyboard_state = make(map[platform.Keys]Keyboard_Input_Set, allocator)
    }
    state.old_input_state = &state.frame_state[0]
    state.new_input_state = &state.frame_state[1]
    return state
}
delete_input_state :: proc(state: ^Input_State) {
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
get_press_state :: proc(is_down: b8, is_hold: b8, is_up: b8) -> Keyboard_Input_Set {
    state: Keyboard_Input_Set
    if is_down {
        if !is_hold {
            state += {.Down, .Hold}
        } else {
            state += {.Hold}
        }
    }
    if is_up {
        state = {.Up}
    }
    return state
}

update_key_state :: proc(s: ^Input_State, e: platform.Keyboard_Input) {

    state := get_press_state(e.is_down, is_hold(s, e.key), e.is_up)
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
    state := get_press_state(e.is_down, is_hold(s, e.button), e.is_up)
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
