package main

import "base:runtime"
import "core:log"
import win "core:sys/windows"
import input "libs:input"
import util "libs:utilities"

running := true

main :: proc() {
    context.logger = log.create_console_logger(
        opt = {.Level, .Terminal_Color, .Short_File_Path, .Procedure, .Line},
    )
    defer log.destroy_console_logger(context.logger)
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


    keyboard_input := [2]input.keyboard_state{}
    old_keyboard_state := &keyboard_input[0]
    new_keyboard_state := &keyboard_input[1]

    msg: win.MSG
    for running {

        new_keyboard_state^ = {}
        for prev_key, i in old_keyboard_state.data {
            new_keyboard_state.data[i] += (prev_key & {.Hold})
        }

        //NOTE: GetMessage will block utill a message is received.
        //      and PeekMessage just check if there is a message in the queue.
        for win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE) {
            switch (msg.message) {
            // NOTE: Using Message Loop to handle keyboard input rather then GetAsyncKeyState
            //       because GetAsyncKeyState will be miss user keyboard input when delay happen.
            case win.WM_KEYDOWN, win.WM_KEYUP, win.WM_SYSKEYDOWN, win.WM_SYSKEYUP:
                // NOTE: Following two will be Change after KeyInput Message be removed from queue(PeekMessage)
                // win.GetKeyState()
                // win.GetKeyboardState(raw_data(&k))
                vk_code := msg.wParam
                key_flags := win.HIWORD(msg.lParam)
                was_down := ((key_flags & win.KF_REPEAT) == win.KF_REPEAT)
                is_down := ((key_flags & win.KF_UP) == 0)

                // TODO: When it need to do something like editor shortcut, need to add it here.
                is_alt_down: u8 = u8((win.GetKeyState(win.VK_MENU) & (1 << 8)) != 0)
                is_ctrl_down: u8 = u8((win.GetKeyState(win.VK_CONTROL) & (1 << 8)) != 0)
                is_shift_down: u8 = u8((win.GetKeyState(win.VK_SHIFT) & (1 << 8)) != 0)
                is_Lcommand_down: u8 = u8((win.GetKeyState(win.VK_LWIN) & (1 << 8)) != 0)
                is_Rcommand_down: u8 = u8((win.GetKeyState(win.VK_RWIN) & (1 << 8)) != 0)
                shortcut_set: input.keyboard_input_set = transmute(input.keyboard_input_set)(is_alt_down <<
                        u8(input.keyboard_input.Alt) |
                    is_ctrl_down << u8(input.keyboard_input.Ctrl) |
                    is_shift_down << u8(input.keyboard_input.Shift) |
                    ((is_Lcommand_down | is_Rcommand_down) << u8(input.keyboard_input.Command)))

                update_keyboard_input(new_keyboard_state, vk_code, is_down, was_down, shortcut_set)

            case:
                win.TranslateMessage(&msg)
                win.DispatchMessageW(&msg)
            }
        }
        // TODO: Pass into game layer
        move_input: input.input_2D = {
            input.make_input_1D_from_keyboard(
                {.Pos = new_keyboard_state.D, .Neg = new_keyboard_state.A},
            ),
            input.make_input_1D_from_keyboard(
                {.Pos = new_keyboard_state.W, .Neg = new_keyboard_state.S},
            ),
        }

        util.swap(&old_keyboard_state, &new_keyboard_state)
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
    using keyboard_state: ^input.keyboard_state,
    vk_code: win.WPARAM,
    is_down: bool,
    was_down: bool,
    shortcut_set: input.keyboard_input_set,
) {
    if vk_code == win.VK_W {
        W = input.make_keyboard_input(is_down, was_down, shortcut_set)
    }
    if vk_code == win.VK_S {
        S = input.make_keyboard_input(is_down, was_down, shortcut_set)
    }
    if vk_code == win.VK_D {
        D = input.make_keyboard_input(is_down, was_down, shortcut_set)
    }
    if vk_code == win.VK_A {
        A = input.make_keyboard_input(is_down, was_down, shortcut_set)
    }
}
