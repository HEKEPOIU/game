package input


gamepad_mapping :: #load("./gamecontrollerdb.txt", string)

get_controller_varient :: proc(
    controller_state: ^Controller_State,
    k: Controller_Known_Value,
) -> (
    value: Controller_Variant,
) {
    switch k {
    case .DPad_Up ..= .Paddle_4:
        value.digital = &controller_state.digitals[k]
    case .Left_Trigger ..= .Right_Stick_Y:
        value.analog = &controller_state.analogs[get_analogs_index(k)]
    }
    return
}

is_down :: proc {
    is_down_digit,
    is_down_keyboard_state,
    is_down_mouse_state,
}

is_hold :: proc {
    is_hold_digit,
    is_hold_keyboard_state,
    is_hold_mouse_state,
}

is_up :: proc {
    is_up_digit,
    is_up_keyboard_state,
    is_up_mouse_state,
}


is_down_digit :: #force_inline proc "contextless" (input: Digit_Input_Set) -> b8 {
    return is_down_keyboard(as_keyboard_input(input))
}

@(private)
is_down_keyboard :: #force_inline proc "contextless" (
    input: Keyboard_Input_Set,
    state: Keyboard_Input_Set = {},
) -> b8 {
    return .Down in input && (input & Keyboard_Modifier_Mask) == state
}


is_up_digit :: #force_inline proc "contextless" (input: Digit_Input_Set) -> b8 {
    return is_up_keyboard(as_keyboard_input(input))
}

@(private)
is_up_keyboard :: #force_inline proc "contextless" (
    input: Keyboard_Input_Set,
    state: Keyboard_Input_Set = {},
) -> b8 {
    return .Up in input && (input & Keyboard_Modifier_Mask) == state
}


is_hold_digit :: #force_inline proc "contextless" (input: Digit_Input_Set) -> b8 {
    return is_hold_keyboard(as_keyboard_input(input))
}

@(private)
is_hold_keyboard :: #force_inline proc "contextless" (
    input: Keyboard_Input_Set,
    state: Keyboard_Input_Set = {},
) -> b8 {
    return .Hold in input && (input & Keyboard_Modifier_Mask) == state
}

contain_state :: #force_inline proc "contextless" (
    input: Keyboard_Input_Set,
    key: Keyboard_Input_Set,
) -> b8 {
    return input >= key
}

make_input_1D_from_digit :: #force_inline proc "contextless" (
    input: [Dir]Digit_Input_Set,
) -> Input_1D {
    is_Pos := is_down(input[.Pos]) || is_hold(input[.Pos])
    is_Neg := is_down(input[.Neg]) || is_hold(input[.Neg])
    if is_Pos && !is_Neg {
        return 1
    }
    if is_Neg && !is_Pos {
        return -1
    }
    return 0
}

make_input_1D_from_keyboard :: #force_inline proc "contextless" (
    input: [Dir]Keyboard_Input_Set,
) -> Input_1D {
    return make_input_1D_from_digit(
        {.Pos = as_digit_input(input[.Pos]), .Neg = as_digit_input(input[.Neg])},
    )
}


as_digit_input :: #force_inline proc "contextless" (input: Keyboard_Input_Set) -> Digit_Input_Set {
    return transmute(Digit_Input_Set)input
}

as_keyboard_input :: #force_inline proc "contextless" (
    input: Digit_Input_Set,
) -> Keyboard_Input_Set {
    return transmute(Keyboard_Input_Set)input
}

@(private)
get_analogs_index :: #force_inline proc "contextless" (k: Controller_Known_Value) -> (target: i8) {
    target = -1
    switch k {
    case .DPad_Up ..= .Paddle_4:
        return
    case .Left_Trigger ..= .Right_Stick_Y:
        target = i8(k) - i8(Controller_Known_Value.Paddle_4) - 1
    }
    return
}
