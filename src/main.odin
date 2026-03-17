package main

import "base:runtime"
import "core:log"
import "libs:core"
import "libs:input"
import "libs:platform"
import util "libs:utilities"
import "thrid_party/pipewire"

global_context: runtime.Context


pw_loop: ^pipewire.thread_loop
pw_context: ^pipewire.pw_context
pw_core: ^pipewire.core
pw_registry: ^pipewire.registry
registry_listener: pipewire.spa_hook
device_list: pipewire.spa_list


PW_Node :: struct {
    link: pipewire.spa_list,
    id:   u32,
    seq:  u32,
}

PW_Device :: struct {
    using node:         PW_Node,
    device_name:        cstring,
    device_description: cstring,
}

pw_events := pipewire.registry_events {
    version = pipewire.VERSION_REGISTRY,
    global = proc "c" (
        data: rawptr,
        id: u32,
        permissions: u32,
        type: cstring,
        version: u32,
        props: ^pipewire.spa_dict,
    ) {
        context = global_context
        if type == pipewire.TYPE_INTERFACE_Node {
            media_class := pipewire.spa_dict_lookup(props, pipewire.KEY_MEDIA_CLASS)
            if media_class == nil || media_class != "Audio/Sink" do return

            node_name := pipewire.spa_dict_lookup(props, pipewire.KEY_NODE_NAME)
            node_desc := pipewire.spa_dict_lookup(props, pipewire.KEY_NODE_DESCRIPTION)
            node := new(PW_Device)
            node.id = id
            node.device_name = node_name
            node.device_description = node_desc
            pipewire.spa_list_append(&device_list, &node.link)
        } else if type == pipewire.TYPE_INTERFACE_Metadata {
        } else if type == pipewire.TYPE_INTERFACE_Client {
        }
    },
    global_remove = proc "c" (data: rawptr, id: u32) {
        context = global_context
        device_to_remove: ^PW_Device

        it := pipewire.make_spa_list_iterator(&device_list)
        for curr in pipewire.spa_list_iterator(&it) {
            device := container_of(curr, PW_Device, "link")
            if device.id == id {
                device_to_remove = device
            }
        }

        if device_to_remove == nil do return

        pipewire.spa_list_remove(&device_to_remove.link)
        free(device_to_remove)
    },
}


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


    {
        pipewire.init(nil, nil)
        pw_loop = pipewire.thread_loop_new("Device detect thread_loop", nil)
        ensure(pw_loop != nil)

        pipewire.spa_list_init(&device_list)

        pw_context = pipewire.context_new(pipewire.thread_loop_get_loop(pw_loop), nil, 0)
        ensure(pw_context != nil)

        pw_core = pipewire.context_connect(pw_context, nil, 0)


        pw_registry = pipewire.core_get_registry(pw_core, pipewire.VERSION_REGISTRY, 0)
        pipewire.registry_add_listener(pw_registry, &registry_listener, &pw_events, nil)

        roundtrip_data :: struct {
            pending: i32,
            loop:    ^pipewire.thread_loop,
        }

        core_events := pipewire.core_events {
            version = pipewire.VERSION_CORE_EVENTS,
            done = proc "c" (data: rawptr, id: u32, seq: i32) {
                context = global_context
                d := (^roundtrip_data)(data)
                if id == pipewire.ID_CORE && seq == d.pending {
                    for node := device_list.next; node != &device_list; node = node.next {
                        device := container_of(node, PW_Device, "link")
                        log.infof(
                            "device name:{}, description:{}",
                            device.device_name,
                            device.device_description,
                        )
                    }
                    pipewire.thread_loop_stop(d.loop)
                }
            },
        }

        r_data := roundtrip_data {
            loop = pw_loop,
        }
        core_listener: pipewire.spa_hook
        pipewire.core_add_listener(pw_core, &core_listener, &core_events, &r_data)
        r_data.pending = pipewire.core_sync(pw_core, 0)


        res := pipewire.thread_loop_start(pw_loop)
        ensure(res == 0)

    }
    defer {
        pipewire.core_disconnect(pw_core)
        pipewire.context_destroy(pw_context)
        pipewire.thread_loop_destroy(pw_loop)
        it := pipewire.make_spa_list_iterator(&device_list)
        for curr in pipewire.spa_list_iterator(&it) {
            free(curr)
        }
    }

    // device_list: pipewire.spa_list
    // device_list.next == device_list.prev == device_list
    // after append
    // device_list.next -> new_node -> device_list <- device_list.prev


    // defer pipewire.thread_loop_stop(pw_loop)

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

