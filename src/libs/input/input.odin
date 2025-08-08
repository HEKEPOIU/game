package input

import l "core:math/linalg"


digit_input :: enum u8 {
    Down,
    Up,
    Hold,
}

Dir :: enum u8 {
    Pos,
    Neg,
}
Axis :: enum u8 {
    X,
    Y,
}

//TODO: fill all keyboard key state
keyboard_state :: struct #raw_union {
    data:    [4]keyboard_input_set,
    using _: struct {
        A: keyboard_input_set,
        D: keyboard_input_set,
        W: keyboard_input_set,
        S: keyboard_input_set,
    },
}

keyboard_input :: enum u8 {
    Down,
    Up,
    Hold,
    Alt,
    Ctrl,
    Shift,
    Command,
}

digit_input_set :: bit_set[digit_input;u8]
keyboard_input_set :: bit_set[keyboard_input;u8]

// range from -1 to 1
input_1D :: f32
input_2D :: [2]input_1D

is_down :: #force_inline proc(input: digit_input_set) -> b8 {
    return .Down in input
}
is_up :: #force_inline proc(input: digit_input_set) -> b8 {
    return .Up in input
}
is_hold :: #force_inline proc(input: digit_input_set) -> b8 {
    return .Hold in input
}


make_input_1D_from_digit :: #force_inline proc(input: [Dir]digit_input_set) -> input_1D {
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

make_input_1D_from_keyboard :: #force_inline proc(input: [Dir]keyboard_input_set) -> input_1D {
    return make_input_1D_from_digit(
        {.Pos = as_digit_input(input[.Pos]), .Neg = as_digit_input(input[.Neg])},
    )
}


as_digit_input :: #force_inline proc(input: keyboard_input_set) -> digit_input_set {
    return transmute(digit_input_set)input
}

make_digit_input :: proc(is_down: bool, was_down: bool) -> (key_state: digit_input_set) {
    if is_down && !was_down {
        key_state = {.Down, .Hold}
    } else if is_down && was_down {
        key_state = {.Hold}
    } else if !is_down && was_down {
        key_state = {.Up}
    }
    return
}


make_keyboard_input :: #force_inline proc(
    is_down: bool,
    was_down: bool,
    shortcut_set: keyboard_input_set,
) -> (
    key_state: keyboard_input_set,
) {
    key_state = transmute(keyboard_input_set)make_digit_input(is_down, was_down)
    key_state = key_state + shortcut_set
    return
}
