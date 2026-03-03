package platform

Vec2f32 :: [2]f32

Event :: union {
    Window_Close,
    Keyboard_Input,
    MouseButton_Input,
    Mouse_Move,
    Mouse_Wheel,
}


Window_Close :: struct {}

Keyboard_Input :: struct {
    key:     Keys,
    is_down: b8,
    is_up:   b8,
}
MouseButton_Input :: struct {
    button:  Mouse_Button,
    is_down: b8,
    is_up:   b8,
}

Mouse_Move :: struct {
    position: Vec2f32,
}

Mouse_Wheel :: struct {
    delta: f32,
}

Window_Interface :: struct {
    init_window:    proc(ws: ^Window_State),
    destroy_window: proc(ws: ^Window_State),
    grab_event:     proc(ws: ^Window_State, events: ^[dynamic]Event),
}


// Based on Raylib / GLFW and add some godot skill.
// follow ascii
Keys :: enum u32 {
    None          = 0,
    // From godot source code
    // Special key: The strategy here is similar to the one used by toolkits,
    // which consists in leaving the 21 bits unicode range for printable
    // characters, and use the upper 11 bits for special keys and modifiers.
    // This way everything (char/keycode) can fit nicely in one 32-bit
    // integer (the enum's underlying type is `int` by default).
    SPECIAL       = (1 << 22),

    // Numeric keys (top row)
    N0            = 48,
    N1            = 49,
    N2            = 50,
    N3            = 51,
    N4            = 52,
    N5            = 53,
    N6            = 54,
    N7            = 55,
    N8            = 56,
    N9            = 57,

    // Letter keys
    A             = 65,
    B             = 66,
    C             = 67,
    D             = 68,
    E             = 69,
    F             = 70,
    G             = 71,
    H             = 72,
    I             = 73,
    J             = 74,
    K             = 75,
    L             = 76,
    M             = 77,
    N             = 78,
    O             = 79,
    P             = 80,
    Q             = 81,
    R             = 82,
    S             = 83,
    T             = 84,
    U             = 85,
    V             = 86,
    W             = 87,
    X             = 88,
    Y             = 89,
    Z             = 90,

    // Special characters
    Apostrophe    = 39,
    Comma         = 44,
    Minus         = 45,
    Period        = 46,
    Slash         = 47,
    Semicolon     = 59,
    Equal         = 61,
    Left_Bracket  = 91,
    Backslash     = 92,
    Right_Bracket = 93,
    Backtick      = 96,

    // Function keys, modifiers, caret control etc
    Space         = 32,
    Escape        = SPECIAL | 0x01,
    Enter         = SPECIAL | 0x02,
    Tab           = SPECIAL | 0x03,
    Backspace     = SPECIAL | 0x04,
    Insert        = SPECIAL | 0x05,
    Delete        = SPECIAL | 0x06,
    Right         = SPECIAL | 0x07,
    Left          = SPECIAL | 0x08,
    Down          = SPECIAL | 0x09,
    Up            = SPECIAL | 0x0A,
    Page_Up       = SPECIAL | 0x0B,
    Page_Down     = SPECIAL | 0x0C,
    Home          = SPECIAL | 0x0D,
    End           = SPECIAL | 0x0E,
    Caps_Lock     = SPECIAL | 0x0F,
    Scroll_Lock   = SPECIAL | 0x10,
    Num_Lock      = SPECIAL | 0x11,
    Print_Screen  = SPECIAL | 0x12,
    Pause         = SPECIAL | 0x13,
    F1            = SPECIAL | 0x14,
    F2            = SPECIAL | 0x15,
    F3            = SPECIAL | 0x16,
    F4            = SPECIAL | 0x17,
    F5            = SPECIAL | 0x18,
    F6            = SPECIAL | 0x19,
    F7            = SPECIAL | 0x1A,
    F8            = SPECIAL | 0x1B,
    F9            = SPECIAL | 0x1C,
    F10           = SPECIAL | 0x1D,
    F11           = SPECIAL | 0x1E,
    F12           = SPECIAL | 0x1F,
    Left_Shift    = SPECIAL | 0x20,
    Left_Control  = SPECIAL | 0x21,
    Left_Alt      = SPECIAL | 0x22,
    Left_Super    = SPECIAL | 0x23,
    Right_Shift   = SPECIAL | 0x24,
    Right_Control = SPECIAL | 0x25,
    Right_Alt     = SPECIAL | 0x26,
    Right_Super   = SPECIAL | 0x27,
    Menu          = SPECIAL | 0x28,

    // Numpad keys
    NP_0          = SPECIAL | 0x29,
    NP_1          = SPECIAL | 0x2A,
    NP_2          = SPECIAL | 0x2B,
    NP_3          = SPECIAL | 0x2C,
    NP_4          = SPECIAL | 0x2D,
    NP_5          = SPECIAL | 0x2E,
    NP_6          = SPECIAL | 0x2F,
    NP_7          = SPECIAL | 0x30,
    NP_8          = SPECIAL | 0x31,
    NP_9          = SPECIAL | 0x32,
    NP_Decimal    = SPECIAL | 0x33,
    NP_Divide     = SPECIAL | 0x34,
    NP_Multiply   = SPECIAL | 0x35,
    NP_Subtract   = SPECIAL | 0x36,
    NP_Add        = SPECIAL | 0x37,
    NP_Enter      = SPECIAL | 0x38,
    NP_Equal      = SPECIAL | 0x39,
}

Mouse_Button :: enum u8 {
    Left,
    Right,
    Middle,
}
