package main

import "base:runtime"
import "core:log"
import l "core:math/linalg"
import win "core:sys/windows"
import input "libs:input"
import util "libs:utilities"

running := true


main :: proc() {
    when ODIN_DEBUG {
        // TODO: Implement In Game console logger, to replace the OS console logger.
        //       so that we can build game with  subsystem:windows
        context.logger = log.create_console_logger(
            opt = {.Level, .Terminal_Color, .Short_File_Path, .Procedure, .Line},
        )
        defer log.destroy_console_logger(context.logger)
    }

    instance := win.HINSTANCE(win.GetModuleHandleW(nil))
    ensure(instance != nil, "Cant fetch current instance")
    class_name := win.L("game window")
    cls := win.WNDCLASSW {
        lpfnWndProc   = win_proc,
        lpszClassName = class_name,
        hInstance     = instance,
        hCursor       = win.LoadCursorA(nil, win.IDC_ARROW),
    }

    class := win.RegisterClassW(&cls)
    ensure(class != 0, "WNDCLASS create failed")
    hwd := win.CreateWindowW(
        class_name,
        class_name,
        win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
        100,
        100,
        1200,
        720,
        nil,
        nil,
        instance,
        nil,
    )
    ensure(hwd != nil, "Window creation Failed")


    kb_mouse_input := [2]input.Keyboard_Mouse_State{}
    old_kb_mouse_state := &kb_mouse_input[0]
    new_kb_mouse_state := &kb_mouse_input[1]

    for running {
        new_kb_mouse_state^ = {}
        for prev_key, i in old_kb_mouse_state.data {
            new_kb_mouse_state.data[i] += (prev_key & {.Hold})
        }
        new_kb_mouse_state.mouse_position = old_kb_mouse_state.mouse_position

        update_input_state(new_kb_mouse_state)
        // TODO: Pass into game layer
        // move_input: input.input_2D = {
        //     input.make_input_1D_from_keyboard(
        //         {.Pos = new_keyboard_state.D, .Neg = new_keyboard_state.A},
        //     ),
        //     input.make_input_1D_from_keyboard(
        //         {.Pos = new_keyboard_state.W, .Neg = new_keyboard_state.S},
        //     ),
        // }
        // log.debugf("move_input: %v", move_input)

        if new_kb_mouse_state.wheel_delta != 0 {
            log.debugf("mouse_input: %v", new_kb_mouse_state.wheel_delta)
        }

        util.swap(&old_kb_mouse_state, &new_kb_mouse_state)
    }

}


win_proc :: proc "stdcall" (
    hwnd: win.HWND,
    msg: win.UINT,
    wparam: win.WPARAM,
    lparam: win.LPARAM,
) -> win.LRESULT {
    result: win.LRESULT
    switch (msg) {
    case win.WM_DESTROY, win.WM_QUIT:
        //NOTE: Must be here, since window directed messages are not dispatched.
        running = false
    case win.WM_KEYDOWN, win.WM_KEYUP:
        runtime.print_string("[Error]: Keyboard Input came in through a non-dispatch message")
        runtime.trap()
    case win.WM_PAINT:
        fallthrough
    case:
        result = win.DefWindowProcW(hwnd, msg, wparam, lparam)
    }
    return result
}

update_keyboard_input :: proc(
    keyboard_state: ^input.Keyboard_Mouse_Keys_State,
    vk_code: win.WPARAM,
    is_down: bool,
    was_down: bool,
    shortcut_set: input.Keyboard_Input_Set,
) {
    if vk_code == win.VK_ESCAPE {
        keyboard_state.ESC = input.make_keyboard_input(is_down, was_down, shortcut_set)
        return
    }
    if vk_code == win.VK_TAB {
        keyboard_state.TAB = input.make_keyboard_input(is_down, was_down, shortcut_set)
        return
    }
    if (vk_code >= win.VK_0) && (vk_code <= win.VK_9) {
        keyboard_state.data[offset_of(keyboard_state.KEY_0) + uintptr(vk_code - win.VK_0)] =
            input.make_keyboard_input(is_down, was_down, shortcut_set)
        return
    }
    if (vk_code >= win.VK_A) && (vk_code <= win.VK_Z) {
        keyboard_state.data[offset_of(keyboard_state.A) + uintptr(vk_code - win.VK_A)] =
            input.make_keyboard_input(is_down, was_down, shortcut_set)
        return
    }
    // SHIFT, CONTROL, ALT
    if (vk_code >= win.VK_SHIFT) && (vk_code <= win.VK_MENU) {
        keyboard_state.data[offset_of(keyboard_state.SHIFT) + uintptr(vk_code - win.VK_SHIFT)] =
            input.make_keyboard_input(is_down, was_down, shortcut_set)
        return
    }
}
// NOTE: Following two will be Change after KeyInput Message be removed from queue(PeekMessage)
// win.GetKeyState()
// win.GetKeyboardState(raw_data(&k))
get_shortcut_set :: #force_inline proc "contextless" (
) -> (
    shortcut_set: input.Keyboard_Input_Set,
) {
    is_alt_down: u8 = u8((win.GetKeyState(win.VK_MENU) & (1 << 8)) != 0)
    is_ctrl_down: u8 = u8((win.GetKeyState(win.VK_CONTROL) & (1 << 8)) != 0)
    is_shift_down: u8 = u8((win.GetKeyState(win.VK_SHIFT) & (1 << 8)) != 0)
    is_Lcommand_down: u8 = u8((win.GetKeyState(win.VK_LWIN) & (1 << 8)) != 0)
    is_Rcommand_down: u8 = u8((win.GetKeyState(win.VK_RWIN) & (1 << 8)) != 0)
    shortcut_set =
    transmute(input.Keyboard_Input_Set)(is_alt_down << u8(input.Keyboard_Input.Alt) |
        is_ctrl_down << u8(input.Keyboard_Input.Ctrl) |
        is_shift_down << u8(input.Keyboard_Input.Shift) |
        ((is_Lcommand_down | is_Rcommand_down) << u8(input.Keyboard_Input.Command)))
    return
}


update_input_state :: proc(new_kb_mouse_state: ^input.Keyboard_Mouse_State) {
    msg: win.MSG = ---
    //NOTE: GetMessage will block utill a message is received.
    //      and PeekMessage just check if there is a message in the queue.
    for win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE) {
        switch (msg.message) {
        // NOTE: Using Message Loop to handle keyboard input rather then GetAsyncKeyState
        //       because GetAsyncKeyState will be miss user keyboard input when delay happen.
        case win.WM_KEYDOWN, win.WM_KEYUP, win.WM_SYSKEYDOWN, win.WM_SYSKEYUP:
            vk_code := msg.wParam
            key_flags := win.HIWORD(msg.lParam)
            was_down := ((key_flags & win.KF_REPEAT) == win.KF_REPEAT)
            is_down := ((key_flags & win.KF_UP) == 0)
            update_keyboard_input(
                &new_kb_mouse_state.keyboard_mouse_key,
                vk_code,
                is_down,
                was_down,
                get_shortcut_set(),
            )
        case win.WM_LBUTTONDOWN:
            new_kb_mouse_state.MOUSE_LEFT = input.make_keyboard_input(
                true,
                false,
                get_shortcut_set(),
            )
        case win.WM_LBUTTONUP:
            new_kb_mouse_state.MOUSE_LEFT = input.make_keyboard_input(
                false,
                true,
                get_shortcut_set(),
            )
        case win.WM_RBUTTONDOWN:
            new_kb_mouse_state.MOUSE_RIGHT = input.make_keyboard_input(
                true,
                false,
                get_shortcut_set(),
            )
        case win.WM_RBUTTONUP:
            new_kb_mouse_state.MOUSE_RIGHT = input.make_keyboard_input(
                false,
                true,
                get_shortcut_set(),
            )
        case win.WM_MBUTTONDOWN:
            new_kb_mouse_state.MOUSE_MIDDLE = input.make_keyboard_input(
                true,
                false,
                get_shortcut_set(),
            )
        case win.WM_MBUTTONUP:
            new_kb_mouse_state.MOUSE_MIDDLE = input.make_keyboard_input(
                false,
                true,
                get_shortcut_set(),
            )
        case win.WM_MOUSEMOVE:
            xPos := win.GET_X_LPARAM(msg.lParam)
            yPos := win.GET_Y_LPARAM(msg.lParam)
            // FIXME: This will cause first mouse delta vary large, not sure how to handle this?
            temp := new_kb_mouse_state.mouse_position
            new_kb_mouse_state.mouse_position = {
                .X = xPos,
                .Y = yPos,
            }
            new_kb_mouse_state.mouse_delta = temp - new_kb_mouse_state.mouse_position
        case win.WM_MOUSEWHEEL:
            delta := win.GET_WHEEL_DELTA_WPARAM(msg.wParam)
            new_kb_mouse_state.wheel_delta = f32(delta / win.WHEEL_DELTA)
        case:
            win.TranslateMessage(&msg)
            win.DispatchMessageW(&msg)
        }
    }

}
