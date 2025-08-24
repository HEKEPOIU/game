package input

import "core:log"
import "core:mem"
import "core:strconv"
import "core:strings"
import util "libs:utilities"

get_controller_varient :: proc(
    controller_state: ^Controller_State,
    k: Controller_Known_Value,
) -> (
    value: Controller_Variant,
) {
    switch k {
    case .DPad_Up ..= .Paddle_4:
        value.digital = &controller_state.digitals[k]
    case .Left_Trigger ..= .Right_Stick_Y:
        value.analog = &controller_state.analogs[get_analogs_index(k)]
    }
    return
}


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
    key_state = {}
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
get_hs_array :: #force_inline proc "contextless" (hs_value: SDL_HS_Value) -> (target_arr: [3]u8) {
    switch hs_value {
    case .North:
        target_arr = [3]u8{HatSwitch_N, HatSwitch_NE, HatSwitch_NW}
    case .East:
        target_arr = [3]u8{HatSwitch_NE, HatSwitch_E, HatSwitch_SE}
    case .South:
        target_arr = [3]u8{HatSwitch_SE, HatSwitch_S, HatSwitch_SW}
    case .West:
        target_arr = [3]u8{HatSwitch_SW, HatSwitch_W, HatSwitch_NW}
    case .None:
        target_arr = [3]u8{}
    }
    return
}

get_value_min_max :: #force_inline proc "contextless" (prop: Source_Dir) -> (min: f32, max: f32) {
    switch prop {
    case .Pos:
        min = 0
        max = 1
    case .Neg:
        min = 0
        max = -1
    case .None:
        min = -1
        max = 1
    }
    return
}

//WARN: Should not use this in ship build,
//      you can embed binary Controller_Map in your game binary.
read_SDL_database :: proc(
    load_platform: Platform,
    allocator := context.allocator,
    loc := #caller_location,
) -> (
    c_map: Controller_Map,
    err: mem.Allocator_Error,
) {
    // it load the file as string at compile time,
    // if you want to use this trick it at other laguage,
    // you need to use some tool to preprocess the file and codegen the array of string.

    // And i decide to do it at compile time,
    // because i don't want pack the SDL_GameControllerDB.txt on shipping.
    // but it will increasing the size of the binary, i think it's not a big deal or now.
    // if someday we care about it, we can parse the file and compress it.
    ensure(ODIN_DEBUG, "You should not use this in ship build!!!")
    data := #load("./gamecontrollerdb.txt", string)

    context.allocator = context.temp_allocator
    line_count := util.count_bytes(transmute([]byte)data, '\n')


    line_arr := util.split_by_char(data, '\n') or_return
    defer free_all(context.temp_allocator)
    line_arr = line_arr[3:]


    platform_arr: []string
    for i := 0; i < len(line_arr) + 1; i += 1 {
        if i == len(line_arr) || line_arr[i] == "" {
            p_map := line_arr[:i]
            platform, ok := get_platform(p_map[0][2:])
            assert(
                ok,
                "Contains unknown platform or format not correct, please add it in the Platform enum",
            )
            if platform == load_platform {
                platform_arr = p_map[1:]
                break
            }
            if i == len(line_arr) do break
            line_arr = line_arr[i + 1:]
            i = 0
        }
    }
    assert(platform_arr != nil, "Target Platform not exist")
    c_map = make(Controller_Map, len(platform_arr), allocator, loc) or_return
    defer if err != nil do delete(c_map)

    for i in platform_arr {
        m_arr := util.split_by_char(i[:len(i) - 1], ',') or_return
        m_arr = m_arr[:len(m_arr) - 1]
        // i don't know how can i check is device is xinput in hid
        // and also if it support xinput, we can just use it, so ignore it.
        if m_arr[0] == "xinput" do continue
        // SDL_GUID :: struct {
        //     // from SDL code docs.
        //     // * 16-bit bus
        //     // * 16-bit CRC16 of the joystick name (can be zero)
        //     // * 16-bit vendor ID
        //     // * 16-bit zero
        //     // * 16-bit product ID
        //     // * 16-bit zero
        //     // * 16-bit product version
        //     // * 8-bit driver identifier ('h' for HIDAPI, 'x' for XInput, etc.)
        //     // * 8-bit driver-dependent type info
        //     bus:               u16,
        //     crc:               u16,
        //     vendor_id:         u16,
        //     _:                 u16,
        //     product_id:        u16,
        //     _:                 u16,
        //     version:           u16,
        //     driver_identifier: u8,
        //     driver_type:       u8,
        // }
        // Currently we only deal with those 3 value, other need handle when we need it.
        // and ignore unknown value.
        id: Controller_Id = ---
        {
            vendor_id, ok := util.parse_u16_from_hex(m_arr[0][8:12])
            assert(ok, "Contains not a hex value in GUID")
            id.vendor_id = vendor_id
        }

        {
            product_id, ok := util.parse_u16_from_hex(m_arr[0][16:20])
            assert(ok, "Contains not a hex value in GUID")
            id.product_id = product_id
        }

        {
            version, ok := util.parse_u16_from_hex(m_arr[0][24:28])
            assert(ok, "Contains not a hex value in GUID")
            id.version = version
        }
        assert(id not_in c_map)
        // TODO: Parse name for hack vibration controller(PS5)
        c_map[id] = {}
        for &map_string in m_arr[2:] {


            source_prop: Source_Dir = nil
            switch map_string[0] {
            case '+':
                source_prop = .Pos
                map_string = map_string[1:]
            case '-':
                source_prop = .Neg
                map_string = map_string[1:]
            }

            bi := strings.index(map_string, ":")
            t := map_string[:bi]

            map_string = map_string[bi + 1:]
            switch t {
            case "a":
                add_map(&c_map[id], .Button_1, map_string, source_prop)
            case "b":
                add_map(&c_map[id], .Button_2, map_string, source_prop)
            case "x":
                add_map(&c_map[id], .Button_3, map_string, source_prop)
            case "y":
                add_map(&c_map[id], .Button_4, map_string, source_prop)
            case "paddle1":
                add_map(&c_map[id], .Paddle_1, map_string, source_prop)
            case "paddle2":
                add_map(&c_map[id], .Paddle_2, map_string, source_prop)
            case "paddle3":
                add_map(&c_map[id], .Paddle_3, map_string, source_prop)
            case "paddle4":
                add_map(&c_map[id], .Paddle_4, map_string, source_prop)
            case "back":
                add_map(&c_map[id], .Back, map_string, source_prop)
            case "guide":
                add_map(&c_map[id], .Guide, map_string, source_prop)
            case "dpdown":
                add_map(&c_map[id], .DPad_Down, map_string, source_prop)
            case "dpleft":
                add_map(&c_map[id], .DPad_Left, map_string, source_prop)
            case "dpright":
                add_map(&c_map[id], .DPad_Right, map_string, source_prop)
            case "dpup":
                add_map(&c_map[id], .DPad_Up, map_string, source_prop)
            case "leftshoulder":
                add_map(&c_map[id], .Left_Shoulder, map_string, source_prop)
            case "leftstick":
                add_map(&c_map[id], .Left_Stick, map_string, source_prop)
            case "lefttrigger":
                add_map(&c_map[id], .Left_Trigger, map_string, source_prop)
            case "rightshoulder":
                add_map(&c_map[id], .Right_Shoulder, map_string, source_prop)
            case "rightstick":
                add_map(&c_map[id], .Right_Stick, map_string, source_prop)
            case "righttrigger":
                add_map(&c_map[id], .Right_Trigger, map_string, source_prop)
            case "misc1":
                add_map(&c_map[id], .Misc_1, map_string, source_prop)
            case "misc2":
                add_map(&c_map[id], .Misc_2, map_string, source_prop)
            case "start":
                add_map(&c_map[id], .Start, map_string, source_prop)
            case "touchpad":
                add_map(&c_map[id], .Touchpad, map_string, source_prop)
            case "leftx":
                add_map(&c_map[id], .Left_Stick_X, map_string, source_prop)
            case "lefty":
                add_map(&c_map[id], .Left_Stick_Y, map_string, source_prop)
            case "rightx":
                add_map(&c_map[id], .Right_Stick_X, map_string, source_prop)
            case "righty":
                add_map(&c_map[id], .Right_Stick_Y, map_string, source_prop)
            case:
                assert(false, "Unknown usage, please add it in the Controller_Map")
            }

        }
    }

    return c_map, nil
}

@(private)
add_map :: proc(
    current_arr: ^[Controller_Known_Value]Controller_Source,
    to: Controller_Known_Value,
    map_string: string,
    source_prop: Source_Dir,
) -> mem.Allocator_Error {
    assert(to >= .Left_Stick_X || source_prop == nil)

    map_string := map_string

    source := &current_arr[to]
    if source.exist == false {
        source.exist = true
    }

    location := Source_Dir.None
    switch map_string[0] {
    case '+':
        location = .Pos
        map_string = map_string[1:]
    case '-':
        location = .Neg
        map_string = map_string[1:]
    }

    type := get_type(map_string[0])
    assert(type != .Unknown)
    source.type = type

    map_string = map_string[1:]
    nums := util.split_by_char(map_string, '.') or_return
    is_inverted: b8 = false
    if nums[0][len(nums[0]) - 1] == '~' {
        is_inverted = true
        nums[0] = nums[0][:len(nums[0]) - 1]
    }
    parse_loc, parse_loc_ok := strconv.parse_i64_of_base(nums[0], 10)
    assert(parse_loc_ok, "Failed to parse int")
    map_string = map_string[len(nums[0]):]
    hat_switch_value: SDL_HS_Value = .None
    if type == .HatSwitch {
        assert(is_inverted == false, "Cannot have inverted hat switch")
        h, hat_switch_ok := strconv.parse_i64_of_base(nums[1], 10)
        assert(hat_switch_ok, "Failed to parse int")
        SDL_North :: 1
        SDL_East :: 2
        SDL_South :: 4
        SDL_West :: 8
        switch h {
        case SDL_North:
            hat_switch_value = .North
        case SDL_East:
            hat_switch_value = .East
        case SDL_South:
            hat_switch_value = .South
        case SDL_West:
            hat_switch_value = .West
        }
        map_string = map_string[:len(nums[1]) + 1]
    }

    source.is_split = true if source_prop != nil else false
    switch source_prop {
    case .Pos:
        source.due.loc_pos = u8(parse_loc)
        source.due.prop_pos = location
        source.due.is_inverted_pos = is_inverted
        source.due.hs_value_pos = hat_switch_value
    case .Neg:
        source.due.loc_neg = u8(parse_loc)
        source.due.prop_neg = location
        source.due.is_inverted_neg = is_inverted
        source.due.hs_value_neg = hat_switch_value
    case .None:
        source.single.loc = u8(parse_loc)
        source.single.prop = location
        source.single.is_inverted = is_inverted
        source.single.hs_value = hat_switch_value
    }
    return nil
}

@(private)
get_analogs_index :: #force_inline proc "contextless" (k: Controller_Known_Value) -> (target: i8) {
    target = -1
    switch k {
    case .DPad_Up ..= .Paddle_4:
        return
    case .Left_Trigger ..= .Right_Stick_Y:
        target = i8(k) - i8(Controller_Known_Value.Paddle_4) - 1
    }
    return
}

@(private)
get_platform :: #force_inline proc "contextless" (sdl_platform_name: string) -> (Platform, bool) {
    switch sdl_platform_name {
    case "Windows":
        return Platform.Windows, true
    case "Mac OS X":
        return Platform.MacOSX, true
    case "Linux":
        return Platform.Linux, true
    case "Android":
        return Platform.Android, true
    case "iOS":
        return Platform.IOS, true
    case:
        return nil, false
    }
}
@(private)
get_type :: #force_inline proc "contextless" (s: u8) -> (t: Controller_data_type) {
    t = .Unknown
    switch s {
    case 'b':
        t = .Button
    case 'a':
        t = .Value
    case 'h':
        t = .HatSwitch
    }
    return
}
