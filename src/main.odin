package main

import "base:runtime"
import "core:log"
import "core:time"
import "libs:input"
import "libs:platform"
import util "libs:utilities"
import "thrid_party:sdl3"

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

    is_sdl_enable := sdl3.Init({.GAMEPAD})
    if !is_sdl_enable {
        log.panicf("SDL ERROR on Init : {}", sdl3.GetError())
    }

    sdl3.AddGamepadMappingsFromIO()

    windows_event: [dynamic]platform.Event


    target_fps :: 144 // 144f/s
    target_duration := time.Second / (target_fps)

    total_frames := 0
    total_time: f32 = 0.

    defer delete(windows_event)
    quited := false

    for !quited {
        start_time := time.tick_now()
        clear(&windows_event)


        input.next_frame(input_state)

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


        ms_elapsed := time.tick_since(start_time)
        if ms_elapsed < target_duration {
            platform.sleep(target_duration - ms_elapsed)
        }


        total_time := time.tick_since(start_time)
        total_frames += 1
    }
}
