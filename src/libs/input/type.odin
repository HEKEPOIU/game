package input

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

Mouse_State :: struct {
    mouse_position: [Axis]i32,
    mouse_delta:    [Axis]i32,
    wheel_delta:    f32,
}

Keyboard_Mouse_Keys :: struct {
    // Move 0..9 together, so that loop assign won't be break
    KEY_0:        Keyboard_Input_Set,
    KEY_1:        Keyboard_Input_Set,
    KEY_2:        Keyboard_Input_Set,
    KEY_3:        Keyboard_Input_Set,
    KEY_4:        Keyboard_Input_Set,
    KEY_5:        Keyboard_Input_Set,
    KEY_6:        Keyboard_Input_Set,
    KEY_7:        Keyboard_Input_Set,
    KEY_8:        Keyboard_Input_Set,
    KEY_9:        Keyboard_Input_Set,

    // Move A..Z together, so that loop assign won't be break
    A:            Keyboard_Input_Set,
    B:            Keyboard_Input_Set,
    C:            Keyboard_Input_Set,
    D:            Keyboard_Input_Set,
    E:            Keyboard_Input_Set,
    F:            Keyboard_Input_Set,
    G:            Keyboard_Input_Set,
    H:            Keyboard_Input_Set,
    I:            Keyboard_Input_Set,
    J:            Keyboard_Input_Set,
    K:            Keyboard_Input_Set,
    L:            Keyboard_Input_Set,
    M:            Keyboard_Input_Set,
    N:            Keyboard_Input_Set,
    O:            Keyboard_Input_Set,
    P:            Keyboard_Input_Set,
    Q:            Keyboard_Input_Set,
    R:            Keyboard_Input_Set,
    S:            Keyboard_Input_Set,
    T:            Keyboard_Input_Set,
    U:            Keyboard_Input_Set,
    V:            Keyboard_Input_Set,
    W:            Keyboard_Input_Set,
    X:            Keyboard_Input_Set,
    Y:            Keyboard_Input_Set,
    Z:            Keyboard_Input_Set,

    // Move Shift..Alt together, so that loop assign won't be break
    SHIFT:        Keyboard_Input_Set,
    CONTROL:      Keyboard_Input_Set,
    ALT:          Keyboard_Input_Set,
    ESC:          Keyboard_Input_Set,
    TAB:          Keyboard_Input_Set,
    MOUSE_LEFT:   Keyboard_Input_Set,
    MOUSE_RIGHT:  Keyboard_Input_Set,
    MOUSE_MIDDLE: Keyboard_Input_Set,
}

Keyboard_Mouse_Keys_State :: struct #raw_union {
    data:    [size_of(Keyboard_Mouse_Keys)]Keyboard_Input_Set,
    using _: Keyboard_Mouse_Keys,
}

Input_State :: struct {
    using kbm_state:  Keyboard_Mouse_State,
    controller_state: Controller_State,
}

Keyboard_Mouse_State :: struct {
    kbm_key:     Keyboard_Mouse_Keys_State,
    mouse_state: Mouse_State,
}

Controller_State :: struct {
    digitals:
    [Controller_Known_Value.Left_Trigger -
    Controller_Known_Value.DPad_Up]Digit_Input_Set,
    analogs: 
    [Controller_Known_Value.Right_Stick_Y -
    Controller_Known_Value.Paddle_4]Input_1D,
}

Controller_Variant :: struct #raw_union {
    digital: ^Digit_Input_Set,
    analog:  ^Input_1D,
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


HAT_SWITCH_ID :: 0x39
HAT_SWITCH_RANGE_MIN :: 1
HAT_SWITCH_RANGE_MAX :: 8
CONTROLLER_DEAD_ZONE :: 0.1 // in range -1 to 1
TRIGGER_DEAD_ZONE :: 0.05 // in range -1 to 1


HatSwitch_N :: 1
HatSwitch_NE :: 2
HatSwitch_E :: 3
HatSwitch_SE :: 4
HatSwitch_S :: 5
HatSwitch_SW :: 6
HatSwitch_W :: 7
HatSwitch_NW :: 8

Controller_Known_Value :: enum u8 {
    DPad_Up,
    DPad_Down,
    DPad_Left,
    DPad_Right,
    Left_Stick,
    Right_Stick,
    Left_Shoulder,
    Right_Shoulder,
    Start,
    Back,
    Guide,
    Touchpad,
    Button_1, // A for Xbox, X for PS 
    Button_2, // B for Xbox, O for PS
    Button_3, // X for Xbox, Square for PS, 
    Button_4, // Y for Xbox, Triangle for PS
    Misc_1, // mute button for PS, not sure about xbox
    Misc_2, // Switch 2 Pro seem have this button, but i don't know what that.
    // TODO: Paddle seems buttons on back of controller, avliable on switch controller?
    //       check others one controllers for test.
    Paddle_1,
    Paddle_2,
    Paddle_3,
    Paddle_4,
    Left_Trigger, // 0 to 1
    Right_Trigger, // 0 to 1
    Left_Stick_X, // -1 to 1
    Left_Stick_Y, // -1 to 1
    Right_Stick_X, // -1 to 1
    Right_Stick_Y, // -1 to 1
}


Controller_data_type :: enum u8 {
    Unknown   = 0,
    Button    = 1,
    Value     = 2,
    HatSwitch = 3,
}

Controller_Map :: map[Controller_Id]([Controller_Known_Value]Controller_Source)

Controller_Source :: struct {
    exist:    b8,
    is_split: b8,
    type:     Controller_data_type,
    using _:  struct #raw_union {
        single: struct {
            loc:         u8,
            prop:        Source_Dir,
            hs_value:    SDL_HS_Value,
            is_inverted: b8,
        },
        due:    struct {
            loc_pos:         u8,
            prop_pos:        Source_Dir,
            loc_neg:         u8,
            prop_neg:        Source_Dir,
            hs_value_pos:    SDL_HS_Value,
            hs_value_neg:    SDL_HS_Value,
            is_inverted_pos: b8,
            is_inverted_neg: b8,
        },
    },
    //TODO: SDL db seems have something like rightx:a3~, need to check source code for more info.
}


Source_Dir :: enum u8 {
    None = 0,
    Pos  = 1,
    Neg  = 2,
}

SDL_HS_Value :: enum u8 {
    None,
    North,
    East,
    South,
    West,
}


Controller_Id :: struct {
    vendor_id:  u16,
    product_id: u16,
    version:    u16,
}

Platform :: enum u8 {
    Windows = 1,
    MacOSX,
    Linux,
    Android,
    IOS,
}
