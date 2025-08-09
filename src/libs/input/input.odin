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

keyboard_keys :: struct {
    // Move 0..9 together, so that loop assign won't be break
    KEY_0:   keyboard_input_set,
    KEY_1:   keyboard_input_set,
    KEY_2:   keyboard_input_set,
    KEY_3:   keyboard_input_set,
    KEY_4:   keyboard_input_set,
    KEY_5:   keyboard_input_set,
    KEY_6:   keyboard_input_set,
    KEY_7:   keyboard_input_set,
    KEY_8:   keyboard_input_set,
    KEY_9:   keyboard_input_set,

    // Move A..Z together, so that loop assign won't be break
    A:       keyboard_input_set,
    B:       keyboard_input_set,
    C:       keyboard_input_set,
    D:       keyboard_input_set,
    E:       keyboard_input_set,
    F:       keyboard_input_set,
    G:       keyboard_input_set,
    H:       keyboard_input_set,
    I:       keyboard_input_set,
    J:       keyboard_input_set,
    K:       keyboard_input_set,
    L:       keyboard_input_set,
    M:       keyboard_input_set,
    N:       keyboard_input_set,
    O:       keyboard_input_set,
    P:       keyboard_input_set,
    Q:       keyboard_input_set,
    R:       keyboard_input_set,
    S:       keyboard_input_set,
    T:       keyboard_input_set,
    U:       keyboard_input_set,
    V:       keyboard_input_set,
    W:       keyboard_input_set,
    X:       keyboard_input_set,
    Y:       keyboard_input_set,
    Z:       keyboard_input_set,

    // Move Ctrl..Alt together, so that loop assign won't be break
    CONTROL: keyboard_input_set,
    ALT:     keyboard_input_set,
    ESC:     keyboard_input_set,

    SHIFT:   keyboard_input_set,
    TAB:     keyboard_input_set,
}


//TODO: fill all keyboard key state
keyboard_state :: struct #raw_union {
    data:    [size_of(keyboard_keys)]keyboard_input_set,
    using _: keyboard_keys
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

is_down :: #force_inline proc "contextless" (input: digit_input_set) -> b8 {
    return .Down in input
}
is_up :: #force_inline proc "contextless" (input: digit_input_set) -> b8 {
    return .Up in input
}
is_hold :: #force_inline proc "contextless" (input: digit_input_set) -> b8 {
    return .Hold in input
}


make_input_1D_from_digit :: #force_inline proc "contextless" (
    input: [Dir]digit_input_set,
) -> input_1D {
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
    input: [Dir]keyboard_input_set,
) -> input_1D {
    return make_input_1D_from_digit(
        {.Pos = as_digit_input(input[.Pos]), .Neg = as_digit_input(input[.Neg])},
    )
}


as_digit_input :: #force_inline proc "contextless" (input: keyboard_input_set) -> digit_input_set {
    return transmute(digit_input_set)input
}

make_digit_input :: proc "contextless" (
    is_down: bool,
    was_down: bool,
) -> (
    key_state: digit_input_set,
) {
    if is_down && !was_down {
        key_state = {.Down, .Hold}
    } else if is_down && was_down {
        key_state = {.Hold}
    } else if !is_down && was_down {
        key_state = {.Up}
    }
    return
}


make_keyboard_input :: #force_inline proc "contextless" (
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
