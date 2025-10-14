package utilities

import "core:mem"
import "core:path/filepath"
import "core:strconv"
import "core:strings"
import win "core:sys/windows"


ensure_success :: #force_inline proc(
    hresult: win.HRESULT,
    message := #caller_expression(hresult),
    loc := #caller_location,
) {
    ensure(win.SUCCEEDED(hresult), message, loc)
}


get_exe_dir_win :: proc() -> (res: string, err: mem.Allocator_Error) {
    @(static) result: string
    if len(result) == 0 {
        buf: [win.MAX_PATH]u16
        len := win.GetModuleFileNameW(nil, &buf[0], win.MAX_PATH)
        result = win.utf16_to_utf8_alloc(buf[:len], context.temp_allocator) or_return
        result = filepath.dir(result)  
    }
    return result, .None
}
