package main

import "base:runtime"
import "libs:audio"
import "libs:core"
import "libs:input"
import "libs:platform"
import util "libs:utilities"
import "vendor:miniaudio"

global_context: runtime.Context


main :: proc() {
    global_context = util.setup_context()
    context = global_context
    defer util.delete_context(&global_context)

    window := platform.create_window_state()


    window.init_window(&window)
    defer window.destroy_window(&window)

    input_state := input.create_input_state()
    defer input.destroy_input_state(input_state)
    input.init_input_state(input_state)


    windows_event: [dynamic]platform.Event


    audio_state := audio.init_audio()

    game_state := core.Game_State {
        target_fps = 100,
    }

    defer delete(windows_event)
    quited := false

    for !quited {
        core.start_frame(&game_state)
        defer core.end_frame(&game_state)

        input.next_frame(input_state)

        clear(&windows_event)
        window.grab_event(&window, &windows_event)

        // process event
        for event in windows_event {
            switch e in event {
            case platform.Window_Close:
                quited = true
            case platform.Keyboard_Input:
                input.update_key_state(input_state, e)
            case platform.MouseButton_Input:
                input.update_mousebutton_state(input_state, e)
            case platform.Mouse_Move:
                input.update_mouse_move(input_state, e)
            case platform.Mouse_Wheel:
                input.update_mouse_wheel(input_state, e)
            }
        }
        input.update_controller_state(input_state)
    }
}

