package utilities

import "core:mem"
import "core:path/filepath"
import win "core:sys/windows"


ensure_success :: #force_inline proc(
    hresult: win.HRESULT,
    message := #caller_expression(hresult),
    loc := #caller_location,
) {
    ensure(win.SUCCEEDED(hresult), message, loc)
}


get_exe_dir_win :: proc(
    allocator := context.temp_allocator,
) -> (
    res: string,
    err: mem.Allocator_Error,
) {
    buf: [win.MAX_PATH]u16
    len := win.GetModuleFileNameW(nil, &buf[0], win.MAX_PATH)
    res = win.utf16_to_utf8_alloc(buf[:len], allocator) or_return
    res = filepath.dir(res, allocator)
    return
}

