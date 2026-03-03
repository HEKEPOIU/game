
package platform
import "vendor:x11/xlib"


X11_Window_State :: struct {
    display:          ^xlib.Display,
    wm_delete_window: xlib.Atom,
}


x11_create_window_state :: proc() -> Window_State {
    return {
        window = {
            init_window = x11_init_window,
            destroy_window = x11_destroy_window,
            grab_event = x11_grab_event,
        },
        state = new(X11_Window_State),
    }
}

x11_init_window :: proc(ws: ^Window_State) {
    s := (^X11_Window_State)(ws.state)
    s.display = xlib.OpenDisplay(nil)
    ensure(s.display != nil)


    // when ODIN_DEBUG {
    //     xlib_error_handler :: proc "c" (display: ^xlib.Display, event: ^xlib.XErrorEvent) -> i32 {
    //         context = global_context
    //         error_text: [256]u8
    //         xlib.GetErrorText(display, i32(event.error_code), raw_data(error_text[:]), 256)
    //         log.errorf("{}", error_text)
    //         return 0
    //     }
    //     xlib.SetErrorHandler(xlib_error_handler)
    // }
    root := xlib.DefaultRootWindow(s.display)
    ensure(root != xlib.None)

    // On certain wm(like. tileing wm), the position and size are not important,
    // Because wm set the flag SubstructureRedirectMask and ResizeRedirectMask,
    // when span or tring to set the positon it will redirect to parent window, and it handle on it.
    // and MapWindow will send MapRequest to parent window(wm)
    window := xlib.CreateSimpleWindow(s.display, root, 0, 0, 800, 600, 0, 0, 0xffffffff)
    ensure(window != xlib.None)
    supported: b32
    //when user hold key, x11 default behavior is span is_down and is_up on same time wtf.
    // the following function disable that.
    xlib.XkbSetDetectableAutoRepeat(s.display, true, &supported)
    ensure(supported == true)
    xlib.SelectInput(
        s.display,
        window,
        {
            .KeyPress, // keyborad button
            .KeyRelease,
            .ButtonPress, // mouse button
            .ButtonRelease,
            .PointerMotion,
            // .StructureNotify,
            // .FocusChange,
        },
    )
    s.wm_delete_window = xlib.InternAtom(s.display, "WM_DELETE_WINDOW", false)
    xlib.SetWMProtocols(s.display, window, &s.wm_delete_window, 1)

    xlib.MapWindow(s.display, window)
}

x11_destroy_window :: proc(ws: ^Window_State) {
    s := (^X11_Window_State)(ws.state)
    xlib.CloseDisplay(s.display)
    free(s)
}


x11_grab_event :: proc(ws: ^Window_State, events: ^[dynamic]Event) {
    s := (^X11_Window_State)(ws.state)
    for xlib.Pending(s.display) > 0 {
        event: xlib.XEvent
        xlib.NextEvent(s.display, &event)
        #partial switch (event.type) {
        case .ClientMessage:
            if (xlib.Atom(event.xclient.data.l[0]) == s.wm_delete_window) {
                append(events, Window_Close{})
            }
        case .KeyPress:
            key := key_from_xkeycode(event.xkey.keycode)
            if (key != .None) {
                append(events, Keyboard_Input{key = key, is_down = true})
            }
        case .KeyRelease:
            key := key_from_xkeycode(event.xkey.keycode)
            if (key != .None) {
                append(events, Keyboard_Input{key = key, is_up = true})
            }

        case .ButtonPress:
            btn: Mouse_Button
            x11_button := event.xbutton.button
            if x11_button <= .Button3 {

                #partial switch x11_button {
                case .Button1:
                    btn = .Left
                case .Button2:
                    btn = .Right
                case .Button3:
                    btn = .Middle
                }
                append(events, MouseButton_Input{button = btn, is_down = true})
            } else {
                append(events, Mouse_Wheel{x11_button == .Button4 ? -1 : 1})
            }
        case .ButtonRelease:
            btn: Mouse_Button
            #partial switch event.xbutton.button {
            case .Button1:
                btn = .Left
            case .Button2:
                btn = .Right
            case .Button3:
                btn = .Middle
            }
            append(events, MouseButton_Input{button = btn, is_up = true})

        case .MotionNotify:
            append(events, Mouse_Move{position = {f32(event.xmotion.x), f32(event.xmotion.y)}})
        }
    }
}


@(private = "package")
key_from_xkeycode :: proc(kc: u32) -> Keys {
    if kc >= 255 {
        return .None
    }

    return KEY_FROM_XKEYCODE[u8(kc)]
}

@(private = "package")
KEY_FROM_XKEYCODE := [255]Keys {
    8   = .Space,
    9   = .Escape,
    10  = .N1,
    11  = .N2,
    12  = .N3,
    13  = .N4,
    14  = .N5,
    15  = .N6,
    16  = .N7,
    17  = .N8,
    18  = .N9,
    19  = .N0,
    20  = .Minus,
    21  = .Equal,
    22  = .Backspace,
    23  = .Tab,
    24  = .Q,
    25  = .W,
    26  = .E,
    27  = .R,
    28  = .T,
    29  = .Y,
    30  = .U,
    31  = .I,
    32  = .O,
    33  = .P,
    34  = .Left_Bracket,
    35  = .Right_Bracket,
    36  = .Enter,
    37  = .Left_Control,
    38  = .A,
    39  = .S,
    40  = .D,
    41  = .F,
    42  = .G,
    43  = .H,
    44  = .J,
    45  = .K,
    46  = .L,
    47  = .Semicolon,
    48  = .Apostrophe,
    49  = .Backtick,
    50  = .Left_Shift,
    51  = .Backslash,
    52  = .Z,
    53  = .X,
    54  = .C,
    55  = .V,
    56  = .B,
    57  = .N,
    58  = .M,
    59  = .Comma,
    60  = .Period,
    61  = .Slash,
    62  = .Right_Shift,
    63  = .NP_Multiply,
    64  = .Left_Alt,
    65  = .Space,
    66  = .Caps_Lock,
    67  = .F1,
    68  = .F2,
    69  = .F3,
    70  = .F4,
    71  = .F5,
    72  = .F6,
    73  = .F7,
    74  = .F8,
    75  = .F9,
    76  = .F10,
    77  = .Num_Lock,
    78  = .Scroll_Lock,
    82  = .NP_Subtract,
    86  = .NP_Add,
    95  = .F11,
    96  = .F12,
    104 = .NP_Enter,
    105 = .Right_Control,
    106 = .NP_Divide,
    107 = .Print_Screen,
    108 = .Right_Alt,
    110 = .Home,
    111 = .Up,
    112 = .Page_Up,
    113 = .Left,
    114 = .Right,
    115 = .End,
    116 = .Down,
    117 = .Page_Down,
    118 = .Insert,
    119 = .Delete,
    125 = .NP_Equal,
    127 = .Pause,
    129 = .NP_Decimal,
    133 = .Left_Super,
    134 = .Right_Super,
    135 = .Menu,
}
