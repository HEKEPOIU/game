package main


// USAGE : odin run tools/gen_controllermap_from_db.odin -file -- src/thrid_party/sdl3/gamecontrollerdb.txt ./src/libs/input (On Project Root Dir)
import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"


Platform :: enum {
    None,
    Windows,
    Linux,
    Mac,
}

WINDOWS :: "Windows"
LINUX :: "Linux"
MAC :: "Mac OS X"

get_platform_form_string :: proc(s: string) -> Platform {
    if s == WINDOWS {
        return .Windows
    } else if s == LINUX {
        return .Linux
    } else if s == MAC {
        return .Mac
    }
    return .None
}

get_plat_ODIN_OS_STRING :: proc(p: Platform) -> string {
    switch p {
    case .Windows:
        return "Windows"
    case .Linux:
        return "Linux"
    case .Mac:
        return "Darwin"
    case .None:
        panic("Invalid platform")
    }
    return ""
}

start_platform :: proc(o: ^os.File, plat: Platform) {
    plat_string := get_plat_ODIN_OS_STRING(plat)

    fmt.fprintfln(o, "when ODIN_OS == .{} {}", plat_string, "{")
    fmt.fprintln(o, "    map_data :: []cstring {")
}

end_platform :: proc(o: ^os.File, plat: Platform) {
    plat_string := get_plat_ODIN_OS_STRING(plat)

    fmt.fprintln(o, "    }")
    fmt.fprint(o, "}")

    fmt.fprintfln(o, " else when ODIN_OS == .{} {}", plat_string, "{")
    fmt.fprintln(o, "    map_data :: []cstring {")
}


output_name :: "controllermap_gen.odin"

main :: proc() {
    context.logger = log.create_console_logger()
    args := os.args
    if len(args) != 3 {
        log.panic(
            "Usage: odin run gen_controllermap_from_db.odin -file -- <db_file> <platform: Windows, Linux, Mac, Android, IOS>",
        )
    }
    db_file := args[1]
    output_dir := args[2]

    o: ^os.File
    {
        output_file, j_err := os.join_path({output_dir, output_name}, context.allocator)
        if j_err != .None do log.panicf("Failed to join the path: {}, Error: {}", output_dir, j_err)
        file, err := os.open(output_file, {.Create, .Trunc, .Write}, os.perm_number(0o664))
        if err != os.General_Error.None do log.panicf("Failed to open the file from path: {}, Error: {}", output_file, err)
        o = file
    }
    defer os.close(o)
    fmt.fprintln(o, "package input")
    fmt.fprintln(
        o,
        "// This file are GENERATEED!! Use tools/gen_controllermap_from_db.odin to generate the file",
    )

    smap: string
    {
        map_data, err := os.read_entire_file_from_path(db_file, context.allocator)
        if err != os.General_Error.None do log.panicf("Failed to read the file from path: {}, Error: {}", db_file, err)
        smap = string(map_data)
    }

    lines, err := strings.split_lines(smap, context.allocator)
    if err != .None do log.panicf("Failed to split the string: {}, Error: {}", smap, err)


    current: Platform

    for l in lines {
        if strings.starts_with(l, "#") || l == "" {
            continue
        }
        parts := strings.split(l, ",")
        current_plat := parts[len(parts) - 2][9:]

        if current_plat == WINDOWS || current_plat == LINUX || current_plat == MAC {
            new_plat := get_platform_form_string(current_plat)
            if current == .None {
                start_platform(o, new_plat)

            } else if current != new_plat {
                end_platform(o, new_plat)
            }
            current = new_plat
            fmt.fprintfln(o, "        \"{}\",", l)


        } else {
            continue
        }
    }
    fmt.fprintln(o, "    }")
    fmt.fprintln(o, "}")


}
