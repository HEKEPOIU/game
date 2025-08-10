package input

import l "core:math/linalg"


Digit_Input :: enum u8 {
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

Keyboard_Keys :: struct {
    // Move 0..9 together, so that loop assign won't be break
    KEY_0:   Keyboard_Input_Set,
    KEY_1:   Keyboard_Input_Set,
    KEY_2:   Keyboard_Input_Set,
    KEY_3:   Keyboard_Input_Set,
    KEY_4:   Keyboard_Input_Set,
    KEY_5:   Keyboard_Input_Set,
    KEY_6:   Keyboard_Input_Set,
    KEY_7:   Keyboard_Input_Set,
    KEY_8:   Keyboard_Input_Set,
    KEY_9:   Keyboard_Input_Set,

    // Move A..Z together, so that loop assign won't be break
    A:       Keyboard_Input_Set,
    B:       Keyboard_Input_Set,
    C:       Keyboard_Input_Set,
    D:       Keyboard_Input_Set,
    E:       Keyboard_Input_Set,
    F:       Keyboard_Input_Set,
    G:       Keyboard_Input_Set,
    H:       Keyboard_Input_Set,
    I:       Keyboard_Input_Set,
    J:       Keyboard_Input_Set,
    K:       Keyboard_Input_Set,
    L:       Keyboard_Input_Set,
    M:       Keyboard_Input_Set,
    N:       Keyboard_Input_Set,
    O:       Keyboard_Input_Set,
    P:       Keyboard_Input_Set,
    Q:       Keyboard_Input_Set,
    R:       Keyboard_Input_Set,
    S:       Keyboard_Input_Set,
    T:       Keyboard_Input_Set,
    U:       Keyboard_Input_Set,
    V:       Keyboard_Input_Set,
    W:       Keyboard_Input_Set,
    X:       Keyboard_Input_Set,
    Y:       Keyboard_Input_Set,
    Z:       Keyboard_Input_Set,

    // Move Shift..Alt together, so that loop assign won't be break
    SHIFT:   Keyboard_Input_Set,
    CONTROL: Keyboard_Input_Set,
    ALT:     Keyboard_Input_Set,

    ESC:     Keyboard_Input_Set,
    TAB:     Keyboard_Input_Set,
}


//TODO: fill all keyboard key state
Keyboard_State :: struct #raw_union {
    data:    [size_of(Keyboard_Keys)]Keyboard_Input_Set,
    using _: Keyboard_Keys
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

// range from -1 to 1
Input_1D :: f32
Input_2D :: [2]Input_1D

is_down :: #force_inline proc "contextless" (input: Digit_Input_Set) -> b8 {
    return .Down in input
}
is_up :: #force_inline proc "contextless" (input: Digit_Input_Set) -> b8 {
    return .Up in input
}
is_hold :: #force_inline proc "contextless" (input: Digit_Input_Set) -> b8 {
    return .Hold in input
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

make_digit_input :: proc "contextless" (
    is_down: bool,
    was_down: bool,
) -> (
    key_state: Digit_Input_Set,
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
    shortcut_set: Keyboard_Input_Set,
) -> (
    key_state: Keyboard_Input_Set,
) {
    key_state = transmute(Keyboard_Input_Set)make_digit_input(is_down, was_down)
    key_state = key_state + shortcut_set
    return
}
