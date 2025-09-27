package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import vmem "core:mem/virtual"
import "core:slice"
import "core:strings"
import win "core:sys/windows"
import "core:time"
import input "libs:input"
import util "libs:utilities"
import "thrid_party:coreaudio"

running := true

Registed_Device :: struct {
    is_initialized:   b8,
    is_value_vaild:   b8,
    id:               input.Controller_Id,
    handle:           win.HANDLE,
    preparsed_data:   win.PHIDP_PREPARSED_DATA,
    caps:             win.HIDP_CAPS,
    // Use dynamic array only for notice the dev NEED to free the memory
    button_caps:      [dynamic]win.HIDP_BUTTON_CAPS,
    value_caps:       [dynamic]win.HIDP_VALUE_CAPS,
    value_slice:      []win.HIDP_VALUE_CAPS,
    hat_switch_slice: []win.HIDP_VALUE_CAPS,
}

delete_registered_device :: proc(registered_device: ^Registed_Device) {
    registered_device.handle = nil
    registered_device.is_initialized = false
    free(registered_device.preparsed_data)
    clear(&registered_device.button_caps)
    clear(&registered_device.value_caps)
}

GAudioManager :: struct {
    #subtype immnotificationclient: coreaudio.IMMNotificationClient,
    selected_device:       ^coreaudio.IMMDevice,
    audio_client:          ^coreaudio.IAudioClient3,
    audio_render_client:   ^coreaudio.IAudioRenderClient,
    buffer_ready_handle:   win.HANDLE,
    buffer_size:           u32,
    ref_count:             u32, // TODO: Test can we just don't use atomic
    is_initialized:        b8,
}

release_AudioManager :: proc(manager: ^GAudioManager) {
    manager.is_initialized = false
    manager.audio_client->Stop()
    manager.audio_client->Release()
    manager.audio_render_client->Release()
    manager.selected_device->Release()
    win.CloseHandle(manager.buffer_ready_handle)
}

try_get_default_audio_device :: proc(
    notify_client: ^GAudioManager,
    device_enumerator: ^coreaudio.IMMDeviceEnumerator,
) -> bool {
    result := device_enumerator->GetDefaultAudioEndpoint(
        .eRender,
        .eConsole,
        &notify_client.selected_device,
    )
    if result != win.S_OK do return false
    result = notify_client.selected_device->Activate(
        coreaudio.IAudioClient3_UUID,
        win.CLSCTX_INPROC_SERVER,
        nil,
        (^rawptr)(&notify_client.audio_client),
    )
    if result != win.S_OK do return false
    defalut_period: coreaudio.REFERENCE_TIME = 0
    minimum_period: coreaudio.REFERENCE_TIME = 0

    result = notify_client.audio_client->GetDevicePeriod(&defalut_period, &minimum_period)
    if result != win.S_OK do return false

    mix_format: ^win.WAVEFORMATEX = ---
    {
        result = notify_client.audio_client->GetMixFormat(&mix_format)
        ensure(result == win.S_OK, "Failed to get mix format")
        result = notify_client.audio_client->Initialize(
            .SHARED,
            {.Event_Callback},
            minimum_period, // minimum Buffer Requested
            0, // Use defalut period
            mix_format,
            nil,
        )
        // ensure(result == win.S_OK, "Failed to initialize audio client")
    }

    notify_client.audio_client->GetService(
        coreaudio.IAudioRenderClient_UUID,
        (^rawptr)(&notify_client.audio_render_client),
    )

    // WARN: currently we only fill the defalut_period long buffer (in current machine are 10 ms),
    // and singal thread means that if 1000ms/fps < defalut_period will cause glitch.
    // NOTE:: left 1 ms for safety
    notify_client.buffer_size = u32(
        (f32(defalut_period * 100) / f32(time.Second)) * f32(mix_format.nSamplesPerSec),
    )

    notify_client.buffer_ready_handle = win.CreateEventW(nil, false, false, nil)
    notify_client.audio_client->SetEventHandle(notify_client.buffer_ready_handle)
    notify_client.audio_client->Start()
    notify_client.is_initialized = true

    return true
}


main :: proc() {
    when ODIN_DEBUG {
        // TODO: Implement In Game console logger, to replace the OS console logger.
        //       so that we can build game with  subsystem:windows

        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                for _, entry in track.allocation_map {
                    fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
                }
            }
            mem.tracking_allocator_destroy(&track)
        }
        context.logger = log.create_console_logger(
            opt = {.Level, .Terminal_Color, .Short_File_Path, .Procedure, .Line},
        )
        defer log.destroy_console_logger(context.logger)
    }

    // We Use temp allocator for frame lifetime allocator

    instance := win.HINSTANCE(win.GetModuleHandleW(nil))
    ensure(instance != nil, "Cant fetch current instance")
    class_name: cstring16 = "game window"
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

    {
        result := win.CoInitializeEx(nil, .MULTITHREADED | .DISABLE_OLE1DDE)
        ensure(result == win.S_OK, "Failed to initialize COM")
    }

    iunknown_vtable: win.IUnknown_VTable = {}

    // TODO: Handle when user unplug device, on now we can't test it properly.
    notify_client: GAudioManager = {
        immnotificationclient = {
            vtable = &{
                IUnKnownVtbl = {
                    QueryInterface = proc "system" (
                        This: ^win.IUnknown,
                        riid: win.REFIID,
                        ppvObject: ^rawptr,
                    ) -> win.HRESULT {
                        if riid == win.IUnknown_UUID {
                            This->AddRef()
                            ppvObject^ = (^win.IUnknown)(This)
                        } else if riid == coreaudio.IMMNotificationClient_UUID {
                            This->AddRef()
                            ppvObject^ = (^coreaudio.IMMNotificationClient)(This)
                        } else {
                            ppvObject^ = nil
                            return win.HRESULT_FROM_WIN32(win.E_NOINTERFACE)
                        }
                        return win.S_OK
                    },
                    AddRef = proc "system" (This: ^win.IUnknown) -> u32 {
                        ref_self := (^GAudioManager)(This)
                        ref_self.ref_count += 1
                        return ref_self.ref_count
                    },
                    Release = proc "system" (This: ^win.IUnknown) -> u32 {
                        ref_self := (^GAudioManager)(This)
                        ref_self.ref_count -= 1
                        if ref_self.ref_count == 0 {
                            // context = runtime.default_context()
                            // free(This) // Is it need?
                            return 0
                        }
                        return ref_self.ref_count
                    },
                },
                OnDeviceStateChanged = proc "system" (
                    This: ^coreaudio.IMMNotificationClient,
                    pwstrDeviceId: win.LPCWSTR,
                    dwnewState: coreaudio.Device_State_flags,
                ) -> win.HRESULT {
                    context = runtime.default_context()
                    log.info("OnDeviceStateChanged")
                    return win.S_OK
                },
                OnDeviceAdded = proc "system" (
                    This: ^coreaudio.IMMNotificationClient,
                    pwstrDeviceId: win.LPCWSTR,
                ) -> win.HRESULT {
                    return win.S_OK
                },
                OnDeviceRemoved = proc "system" (
                    This: ^coreaudio.IMMNotificationClient,
                    pwstrDefaultDeviceId: ^win.LPCWSTR,
                ) -> win.HRESULT {
                    return win.S_OK
                },
                OnDefaultDeviceChanged = proc "system" (
                    This: ^coreaudio.IMMNotificationClient,
                    flow: coreaudio.EDataFlow,
                    role: coreaudio.ERole,
                    pwstrDefaultDeviceId: ^win.LPWSTR,
                ) -> win.HRESULT {
                    // TODO: Test existing game will not change output when default device changed.
                    return win.S_OK
                },
                OnPropertyValueChanged = proc "system" (
                    This: ^coreaudio.IMMNotificationClient,
                    pwstrDeviceId: ^win.LPWSTR,
                    key: win.PROPERTYKEY,
                ) -> win.HRESULT {
                    return win.S_OK
                },
            },
        },
    }


    // TODO: Use separate thread to handle audio.
    // WARN: Currently are not handle the case that user unplug the audio device.
    device_enumerator: ^coreaudio.IMMDeviceEnumerator
    {
        result := win.CoCreateInstance(
            &coreaudio.CLSID_MMDeviceEnumerator,
            nil,
            win.CLSCTX_INPROC_SERVER,
            coreaudio.IMMDeviceEnumerator_UUID,
            (^rawptr)(&device_enumerator),
        )
        ensure(result == win.S_OK, "Failed to create device_enumerator")
    }
    defer device_enumerator->Release()

    {
        result := device_enumerator->RegisterEndpointNotificationCallback(&notify_client)
        ensure(result == win.S_OK, "Failed to register endpoint notification callback")
    }
    defer device_enumerator->UnregisterEndpointNotificationCallback(&notify_client)


    registed_device: Registed_Device
    defer {
        when ODIN_DEBUG {
            delete_registered_device(&registed_device)
        }
    }
    controller_map, is_controller_map_available := input.read_SDL_database(.Windows)
    if is_controller_map_available == .None {
        game_pad_rid: [2]win.RAWINPUTDEVICE = {
            {
                hwndTarget = hwd,
                usUsagePage = win.HID_USAGE_PAGE_GENERIC,
                usUsage = win.HID_USAGE_GENERIC_GAMEPAD,
                dwFlags = win.RIDEV_DEVNOTIFY,
            },
            {
                hwndTarget = hwd,
                usUsagePage = win.HID_USAGE_PAGE_GENERIC,
                usUsage = win.HID_USAGE_GENERIC_JOYSTICK,
                dwFlags = win.RIDEV_DEVNOTIFY,
            },
        }
        // Use Rawinput for now, because new GameInput API need Redistribution.
        // I just don't want user to install something extra.
        if win.RegisterRawInputDevices(&game_pad_rid[0], 2, size_of(win.RAWINPUTDEVICE)) ==
           win.FALSE {
            log.warn("To register gamepad")
        } else do log.info("Register gamepad successfully")
    } else {
        log.warn("Controller Map is not available, skip registering gamepad")
    }
    defer util.debug_delete(controller_map)

    input_state := [2]input.Input_State{}
    old_input_state := &input_state[0]
    new_input_state := &input_state[1]


    output_builder: strings.Builder
    strings.builder_init(&output_builder)
    output_stream := strings.to_writer(&output_builder)
    target_fps :: 144 // 144f/s
    target_duration := time.Second / (target_fps)
    // ensure(
    //     time.duration_nanoseconds(target_duration) / 100 <= defalut_period,
    //     "Plesae increase audio buffer size.",
    // )


    total_frames := 0
    total_time: f32 = 0.

    try_get_default_audio_device(&notify_client, device_enumerator)


    defer release_AudioManager(&notify_client)

    for running {
        start_time := time.tick_now()
        new_input_state^ = {}
        for prev_key, i in old_input_state.kbm_key.data {
            new_input_state.kbm_key.data[i] = (prev_key & {.Hold})
        }
        for i, k in old_input_state.controller_state.digitals {
            new_input_state.controller_state.digitals[k] = (i & {.Hold})
        }
        for i, k in old_input_state.controller_state.analogs {
            new_input_state.controller_state.analogs[k] = i
        }
        new_input_state.mouse_state.mouse_position = old_input_state.mouse_state.mouse_position

        update_input_state(new_input_state, controller_map, &registed_device)

        if new_input_state.mouse_state.wheel_delta != 0 {
            util.debug_printf("mouse_input: %v", new_input_state.mouse_state.wheel_delta)
        }
        // for i in input.Controller_Known_Value.DPad_Up ..= input.Controller_Known_Value.Paddle_4 {
        //     v := input.get_controller_varient(&new_input_state.controller_state, i).digital^
        //     pv := false
        //     if v != {} do pv = true
        //     output_text := fmt.aprintf("{}: {}, ", i, pv)
        //     io.write_string(output_stream, output_text)
        // }
        // util.debug_printf(string(output_builder.buf[:]))
        // strings.builder_reset(&output_builder)
        // for i in input.Controller_Known_Value.Left_Trigger ..= input.Controller_Known_Value.Right_Stick_Y {
        //     v := input.get_controller_varient(&new_input_state.controller_state, i).analog^
        //
        //     output_text := fmt.aprintf("{}: {:.2f}, ", i, v)
        //     io.write_string(output_stream, output_text)
        // }
        // util.debug_printf(string(output_builder.buf[:]))
        // strings.builder_reset(&output_builder)

        if win.WaitForSingleObject(notify_client.buffer_ready_handle, 0) == win.WAIT_OBJECT_0 {
            buffer_padding: u32

            notify_client.audio_client->GetCurrentPadding(&buffer_padding)

            frameCount := notify_client.buffer_size - buffer_padding
            buffer: [^]f32
            if (notify_client.audio_render_client->GetBuffer(frameCount, (^^u8)(&buffer)) ==
                   win.S_OK) {
                defer notify_client.audio_render_client->ReleaseBuffer(frameCount, {})
                for i in 0 ..< frameCount {
                    sine := math.sin_f32(total_time)
                    buffer[0] = sine * 0.1
                    buffer[1] = sine * 0.1
                    buffer = &buffer[2]
                    total_time += 0.05
                }
            }
        }


        ms_elapsed := time.tick_since(start_time)
        if ms_elapsed < target_duration {
            win.timeBeginPeriod(1)
            time.accurate_sleep(target_duration - ms_elapsed)
            win.timeEndPeriod(1)
        }


        util.swap(&old_input_state, &new_input_state)
        total_time := time.tick_since(start_time)
        // log.infof("FPS: {:.2f}", 1. / time.duration_seconds(total_time))
        total_frames += 1
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
    case win.WM_INPUT_DEVICE_CHANGE:
        // WARN: When user plug in controller between exe start and windows actually open,
        //       it will cause message came in through a non-dispatch message
        //       currently I don't think we need to handle this problem, just ignore it.
        runtime.print_string("[Error]: Controller Input came in through a non-dispatch message")
        fallthrough
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
    shortcut_set = transmute(input.Keyboard_Input_Set)(is_alt_down <<
            u8(input.Keyboard_Input.Alt) |
        is_ctrl_down << u8(input.Keyboard_Input.Ctrl) |
        is_shift_down << u8(input.Keyboard_Input.Shift) |
        ((is_Lcommand_down | is_Rcommand_down) << u8(input.Keyboard_Input.Command)))
    return
}


update_input_state :: proc(
    input_state: ^input.Input_State,
    controller_map: input.Controller_Map,
    registered_device: ^Registed_Device,
) {

    msg: win.MSG = ---
    //NOTE: GetMessage will block until a message is received.
    //      and PeekMessage just check if there is a message in the queue.
    for win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE) {
        switch (msg.message) {
        // NOTE: Using Message Loop to handle keyboard input rather then GetAsyncKeyState
        //       because GetAsyncKeyState will be miss user keyboard input when delay happen.
        case win.WM_KEYDOWN, win.WM_KEYUP, win.WM_SYSKEYDOWN, win.WM_SYSKEYUP:
            vk_code := msg.wParam
            key_flags := win.WORD(msg.lParam >> 16)
            was_down := ((key_flags & win.KF_REPEAT) == win.KF_REPEAT)
            is_down := ((key_flags & win.KF_UP) == 0)
            update_keyboard_input(
                &input_state.kbm_key,
                vk_code,
                is_down,
                was_down,
                get_shortcut_set(),
            )
        case win.WM_LBUTTONDOWN:
            input_state.kbm_key.MOUSE_LEFT = input.make_keyboard_input(
                true,
                false,
                get_shortcut_set(),
            )
        case win.WM_LBUTTONUP:
            input_state.kbm_key.MOUSE_LEFT = input.make_keyboard_input(
                false,
                true,
                get_shortcut_set(),
            )
        case win.WM_RBUTTONDOWN:
            input_state.kbm_key.MOUSE_RIGHT = input.make_keyboard_input(
                true,
                false,
                get_shortcut_set(),
            )
        case win.WM_RBUTTONUP:
            input_state.kbm_key.MOUSE_RIGHT = input.make_keyboard_input(
                false,
                true,
                get_shortcut_set(),
            )
        case win.WM_MBUTTONDOWN:
            input_state.kbm_key.MOUSE_MIDDLE = input.make_keyboard_input(
                true,
                false,
                get_shortcut_set(),
            )
        case win.WM_MBUTTONUP:
            input_state.kbm_key.MOUSE_MIDDLE = input.make_keyboard_input(
                false,
                true,
                get_shortcut_set(),
            )
        case win.WM_MOUSEMOVE:
            xPos := win.GET_X_LPARAM(msg.lParam)
            yPos := win.GET_Y_LPARAM(msg.lParam)
            // FIXME: This will cause first mouse delta vary large, not sure how to handle this?
            temp := input_state.mouse_state.mouse_position
            input_state.mouse_state.mouse_position = {
                .X = xPos,
                .Y = yPos,
            }
            input_state.mouse_state.mouse_delta = temp - input_state.mouse_state.mouse_position
        case win.WM_MOUSEWHEEL:
            delta := win.GET_WHEEL_DELTA_WPARAM(msg.wParam)
            input_state.mouse_state.wheel_delta = f32(delta / win.WHEEL_DELTA)
        case win.WM_INPUT:
            if registered_device.handle == nil do continue
            arena: vmem.Arena
            buf: [512]byte
            err := vmem.arena_init_buffer(&arena, buf[:])
            ensure(err == .None, "stack arean init failed")
            arena_allocator := vmem.arena_allocator(&arena)
            // defer util.debug_printf(
            //     "arena_allocator: {}, used : {}",
            //     arena_allocator,
            //     arena.total_used,
            // )
            dwSize: win.UINT = ---
            if win.GetRawInputData(
                   win.HRAWINPUT(msg.lParam),
                   win.RID_INPUT,
                   nil,
                   &dwSize,
                   size_of(win.RAWINPUTHEADER),
               ) !=
               0 {
                assert(false, "Failed to initialize controller raw")
                continue
            }
            lpb := make([]u8, dwSize, arena_allocator)
            if win.GetRawInputData(
                   win.HRAWINPUT(msg.lParam),
                   win.RID_INPUT,
                   &lpb[0],
                   &dwSize,
                   size_of(win.RAWINPUTHEADER),
               ) !=
               dwSize {
                assert(false, "Failed to initialize controller raw")
                continue
            }
            raw := (^win.RAWINPUT)(&lpb[0])
            if !registered_device.is_initialized {
                // Ref: https://www.codeproject.com/Articles/185522/Using-the-Raw-Input-API-to-Process-Joystick-Input
                // Also go to see USB HID spec
                // And when this part is failed,it think we are nothing can do about it.
                // so we just ignore it.
                if (win.GetRawInputDeviceInfoW(
                           registered_device.handle,
                           win.RIDI_PREPARSEDDATA,
                           nil,
                           &dwSize,
                       ) !=
                       0) {
                    assert(false, "Failed to initialize controller preparsed_data")
                    continue
                }
                registered_device.preparsed_data = (win.PHIDP_PREPARSED_DATA)(
                    raw_data((make([]u8, dwSize))),
                )
                if (win.GetRawInputDeviceInfoW(
                           registered_device.handle,
                           win.RIDI_PREPARSEDDATA,
                           registered_device.preparsed_data,
                           &dwSize,
                       ) <
                       0) {
                    assert(false, "Failed to initialize controller preparsed_data")
                    continue
                }
                if (win.HidP_GetCaps(registered_device.preparsed_data, &registered_device.caps) !=
                       win.HIDP_STATUS_SUCCESS) {

                    assert(false, "Failed to initialize controller caps")
                    continue
                }

                cap_length := registered_device.caps.NumberInputButtonCaps
                resize(&registered_device.button_caps, cap_length)
                if (win.HidP_GetButtonCaps(
                           .Input,
                           raw_data(registered_device.button_caps),
                           &cap_length,
                           registered_device.preparsed_data,
                       ) !=
                       win.HIDP_STATUS_SUCCESS) {
                    assert(false, "Failed to initialize controller controller caps")
                    continue
                }

                cap_length = registered_device.caps.NumberInputValueCaps
                resize(&registered_device.value_caps, cap_length)
                if (win.HidP_GetValueCaps(
                           .Input,
                           raw_data(registered_device.value_caps),
                           &cap_length,
                           registered_device.preparsed_data,
                       ) !=
                       win.HIDP_STATUS_SUCCESS) {
                    assert(false, "Failed to initialize controller value caps")
                    continue
                }
                // TODO: Maybe need to handle range usage, but currently we can't determine when will range useful
                slice.sort_by_cmp(
                    registered_device.value_caps[:],
                    proc(a, b: win.HIDP_VALUE_CAPS) -> slice.Ordering {
                        return slice.cmp(a.NotRange.Usage, b.NotRange.Usage)
                    },
                )
                vc := registered_device.value_caps[:]
                hat_switch_start := -1
                value_start := -1
                // TODO: This place not that stable need more testing controller for stability.
                for vcap, i in registered_device.value_caps {
                    if vcap.UsagePage != 0x01 {
                        value_start = i
                        continue
                    }
                    if vcap.NotRange.Usage == input.HAT_SWITCH_ID {
                        registered_device.value_slice = registered_device.value_caps[value_start +
                        1:i]
                        registered_device.hat_switch_slice = registered_device.value_caps[i:len(
                            registered_device.value_caps,
                        )]
                        break
                    }
                }


                registered_device.is_initialized = true
                registered_device.is_value_vaild = true
                util.debug_printf("controller:{} initialized", registered_device.handle)
            }

            if !registered_device.is_value_vaild do continue

            button_states: []bool
            value_states: []f32
            hat_switch_states: []u32
            {     // Get Controller Buttons State.
                button_caps := registered_device.button_caps
                //TODO: it may more then one button caps, need to base on usage page isn't be Vendor Reserved one.
                buttons_num := button_caps[0].Range.UsageMax - button_caps[0].Range.UsageMin + 1
                button_states = make([]bool, buttons_num, arena_allocator) or_continue
                usage_length := u32(buttons_num)
                input_button_usage := make([]win.USAGE, usage_length, arena_allocator) or_continue
                if result := win.HidP_GetUsages(
                    .Input, // function set the button that is Pressed on input_button_usage
                    button_caps[0].UsagePage,
                    0,
                    raw_data(input_button_usage),
                    &usage_length,
                    registered_device.preparsed_data,
                    win.PCHAR(&raw.data.hid.bRawData[0]),
                    raw.data.hid.dwSizeHid,
                ); result != win.HIDP_STATUS_SUCCESS {
                    switch result {
                    case win.HIDP_STATUS_INVALID_REPORT_LENGTH:
                        fallthrough
                    case win.HIDP_STATUS_INVALID_REPORT_TYPE:
                        fallthrough
                    case win.HIDP_STATUS_INVALID_PREPARSED_DATA:
                        log.debug("Controller {} handle invalid", registered_device.handle)
                        registered_device.is_value_vaild = false
                        continue
                    case win.HIDP_STATUS_BUFFER_TOO_SMALL:
                        fallthrough
                    case win.HIDP_STATUS_USAGE_NOT_FOUND:
                        fallthrough
                    case win.HIDP_STATUS_INCOMPATIBLE_REPORT_ID:
                        assert(
                            false,
                            fmt.aprint("HidP_GetUsageValue failed: {}", result, arena_allocator),
                        )
                        continue
                    }
                    continue
                }
                if usage_length != 0 {
                    for i in 0 ..< usage_length {
                        button_states[input_button_usage[i] - button_caps[0].Range.UsageMin] = true
                    }
                }
            }
            {     // Get analog Values State.
                value_slice := registered_device.value_slice
                uvalue_states := get_usage_value(
                    registered_device,
                    raw,
                    value_slice,
                    arena_allocator,
                ) or_continue

                value_states = make([]f32, len(uvalue_states), arena_allocator) or_continue
                for v, i in uvalue_states {
                    value_usage := value_slice[i]
                    //TODO: Currently guess -1 means not set, need more controller to test.
                    if value_usage.LogicalMax == -1 {
                        value_states[i] = math.remap(
                            f32(v),
                            f32(value_usage.LogicalMin),
                            f32(u32(1 << value_usage.BitSize - 1)),
                            -1.,
                            1.,
                        )
                    } else {
                        value_states[i] = math.remap(
                            f32(v),
                            f32(value_usage.LogicalMin),
                            f32(value_usage.LogicalMax),
                            -1.,
                            1.,
                        )
                    }
                }
                //PS5 Controller, switch range is [0, 7] -> 8 is idle
                // Xbox One Controller, switch range is [1, 8] -> 0 is idle
                hat_switch_slice := registered_device.hat_switch_slice
                hat_switch_raw_states := get_usage_value(
                    registered_device,
                    raw,
                    hat_switch_slice,
                    arena_allocator,
                ) or_continue
                hat_switch_states = make(
                    []u32,
                    len(hat_switch_raw_states),
                    arena_allocator,
                ) or_continue

                for v, i in hat_switch_raw_states {
                    value_usage := hat_switch_slice[i]
                    assert(value_usage.LogicalMin != -1)
                    assert(value_usage.LogicalMax - value_usage.LogicalMin + 1 == 8)
                    hat_switch_states[i] = v
                    if value_usage.LogicalMin != input.HAT_SWITCH_RANGE_MIN &&
                       value_usage.LogicalMax != input.HAT_SWITCH_RANGE_MAX {
                        offset := value_usage.LogicalMin - input.HAT_SWITCH_RANGE_MIN
                        assert(offset == value_usage.LogicalMax - input.HAT_SWITCH_RANGE_MAX)
                        hat_switch_states[i] += u32(math.abs(offset))
                    }

                }
            }
            maps := controller_map[registered_device.id]
            for k in input.Controller_Known_Value.DPad_Up ..= input.Controller_Known_Value.Right_Stick_Y {
                m := maps[k]
                if !m.exist do continue
                target := input.get_controller_varient(&input_state.controller_state, k)
                switch m.type {
                case .Button:
                    if !m.is_split {
                        assert(m.single.prop == .None)
                        if int(m.single.loc) >= len(button_states) do continue

                        #partial switch k {
                        case .DPad_Up ..= .Paddle_4:
                            was_down := .Hold in input_state.controller_state.digitals[k]
                            target.digital^ = input.make_digit_input(
                                button_states[m.single.loc],
                                was_down,
                            )
                        case .Left_Trigger ..= .Right_Trigger:
                            value := u32(button_states[m.single.loc])
                            target.analog^ = f32(value) / 255.
                        }
                    } else {     // Only Possible when stick input
                        if int(m.due.loc_pos) >= len(button_states) ||
                           int(m.due.loc_neg) >= len(button_states) {continue}
                        v_pos := f32(u32(button_states[m.due.loc_pos])) / 255.
                        v_neg := f32(u32(button_states[m.due.loc_neg])) / 255.

                        target.analog^ = v_pos - v_neg
                    }
                case .Value:
                    if !m.is_split {
                        if int(m.single.loc) >= len(value_states) do continue
                        min, max: f32 = input.get_value_min_max(m.single.prop)
                        r_value := math.clamp(value_states[m.single.loc], min, max)

                        #partial switch k {
                        case .DPad_Up ..= .Paddle_4:
                            is_down := r_value > (max - min) / 2
                            input_set := input_state.controller_state.digitals[k]
                            was_down := .Hold in input_set
                            target.digital^ = input.make_digit_input(is_down, was_down)
                        case .Left_Trigger ..= .Right_Trigger:
                            value: f32
                            if m.single.is_inverted {
                                util.debug_printf("is_inverted")
                                value = math.remap(r_value, min, max, 0, 1)
                            } else {
                                value = math.remap(r_value, min, max, 1, 0)
                            }
                            if value < input.TRIGGER_DEAD_ZONE {value = 0}
                            target.analog^ = value
                        case .Left_Stick_X ..= .Right_Stick_Y:
                            value: f32
                            if m.single.is_inverted {
                                util.debug_printf("is_inverted")
                                value = math.remap(r_value, min, max, 1, -1)
                            } else {
                                value = math.remap(r_value, min, max, -1, 1)
                            }
                            if math.abs(value) < input.CONTROLLER_DEAD_ZONE {value = 0}
                            target.analog^ = value
                        }

                    } else {
                        if int(m.due.loc_pos) >= len(value_states) ||
                           int(m.due.loc_neg) >= len(value_states) {continue}
                        pos_min, pos_max: f32 = input.get_value_min_max(m.due.prop_pos)
                        neg_min, neg_max: f32 = input.get_value_min_max(m.due.prop_neg)
                        rv_pos := math.remap_clamped(
                            value_states[m.due.loc_pos],
                            pos_min,
                            pos_max,
                            0,
                            1,
                        )
                        rv_neg := math.remap_clamped(
                            value_states[m.due.loc_neg],
                            neg_min,
                            neg_max,
                            0,
                            1,
                        )
                        target.analog^ = rv_pos - rv_neg

                    }

                case .HatSwitch:
                    if !m.is_split {
                        assert(m.single.prop == .None)
                        assert(hat_switch_states[m.single.loc] <= 256)
                        if int(m.single.loc) >= len(hat_switch_states) do continue
                        hat_switch_value := u8(hat_switch_states[m.single.loc])
                        target_arr: [3]u8 = input.get_hs_array(m.single.hs_value)
                        is_down := slice.contains(target_arr[:], hat_switch_value)

                        #partial switch k {
                        case .DPad_Up ..= .Paddle_4:
                            was_down := .Hold in input_state.controller_state.digitals[k]
                            target.digital^ = input.make_digit_input(is_down, was_down)
                        case .Left_Trigger ..= .Right_Trigger:
                            value := u32(is_down)
                            target.analog^ = f32(value) / 255.
                        }

                    } else {
                        if int(m.due.loc_pos) >= len(hat_switch_states) ||
                           int(m.due.loc_neg) >= len(hat_switch_states) {continue}

                        hat_switch_value_pos := u8(hat_switch_states[m.due.loc_pos])
                        target_arr_pos: [3]u8 = input.get_hs_array(m.due.hs_value_pos)
                        value_pos :=
                            f32(u32(slice.contains(target_arr_pos[:], hat_switch_value_pos))) / 255

                        hat_switch_value_neg := u8(hat_switch_states[m.due.loc_neg])
                        target_arr_neg: [3]u8 = input.get_hs_array(m.due.hs_value_neg)
                        value_neg :=
                            f32(u32(slice.contains(target_arr_neg[:], hat_switch_value_neg))) / 255
                        target.analog^ = value_pos - value_neg

                    }
                case .Unknown:
                    // Block when load controller map
                    unreachable()
                }
            }
            log.debugf("Controller Button States : {}, len: {}", button_states, len(button_states))
        case win.WM_INPUT_DEVICE_CHANGE:
            handle := win.HANDLE(uintptr(msg.lParam))
            GIDC_ARRIVAL :: 1
            GIDC_REMOVAL :: 2
            is_added := msg.wParam == GIDC_ARRIVAL
            if !is_added {
                assert(msg.wParam == GIDC_REMOVAL)
                if registered_device.handle == handle {
                    util.debug_printf("controller:{} removed, unregistered", handle)
                    registered_device.handle = nil
                }
                continue
            }
            dwSize: win.UINT = ---
            if win.GetRawInputDeviceInfoW(handle, win.RIDI_DEVICEINFO, nil, &dwSize) != 0 do continue
            device_info: win.RID_DEVICE_INFO = ---
            if win.GetRawInputDeviceInfoW(handle, win.RIDI_DEVICEINFO, &device_info, &dwSize) < 0 do continue
            id := input.Controller_Id {
                vendor_id  = u16(device_info.hid.dwVendorId),
                product_id = u16(device_info.hid.dwProductId),
            }
            id_with_version := id
            id_with_version.version = u16(device_info.hid.dwVersionNumber)
            is_available: b8
            if (id_with_version in controller_map) {
                is_available = true
                registered_device.id = id_with_version
            } else if (id in controller_map) {
                is_available = true
                registered_device.id = id
            }
            util.debug_printf("controller id:{}, plugin", registered_device.id)
            if (is_available) {
                if registered_device.handle != nil && registered_device.is_value_vaild {
                    util.debug_printf(
                        "old controller still exist and valid, don't acept new controller: {}",
                        handle,
                    )
                    continue
                }
                util.debug_printf_cond(
                    !registered_device.is_value_vaild && registered_device.handle != nil,
                    "old controller:{} handle value invalid, replace it with new device: {}",
                    registered_device.handle,
                    handle,
                )
                delete_registered_device(registered_device)
                registered_device.handle = handle
                util.debug_printf("registered new controller: {}", handle)
            } else {
                util.debug_printf("you controller currently not support: {}", id_with_version)
            }

        case:
            win.TranslateMessage(&msg)
            win.DispatchMessageW(&msg)
        }
    }
}
get_usage_value :: proc(
    registered_device: ^Registed_Device,
    raw: ^win.RAWINPUT,
    value_slice: []win.HIDP_VALUE_CAPS,
    allocator: mem.Allocator,
) -> (
    uvalue_state: []u32,
    err: mem.Allocator_Error,
) {
    cap_length := len(value_slice)
    uvalue_state = make([]u32, cap_length, allocator) or_return
    for i in 0 ..< cap_length {
        value_usage := value_slice[i]
        if result := win.HidP_GetUsageValue(
            .Input,
            value_usage.UsagePage,
            0,
            value_usage.NotRange.Usage,
            &uvalue_state[i],
            registered_device.preparsed_data,
            (^u8)(&raw.data.hid.bRawData[0]),
            raw.data.hid.dwSizeHid,
        ); result != win.HIDP_STATUS_SUCCESS {
            switch result {
            case win.HIDP_STATUS_INVALID_REPORT_LENGTH:
                fallthrough
            case win.HIDP_STATUS_INVALID_REPORT_TYPE:
                fallthrough
            case win.HIDP_STATUS_INVALID_PREPARSED_DATA:
                log.debug("Controller {} handle invalid", registered_device.handle)
                registered_device.is_value_vaild = false
                continue
            case win.HIDP_STATUS_USAGE_NOT_FOUND:
                fallthrough
            case win.HIDP_STATUS_INCOMPATIBLE_REPORT_ID:
                assert(false, fmt.aprint("HidP_GetUsageValue failed: {}", result, allocator))
                continue
            }
            continue
        }
    }
    return
}
