package utilities

import win "core:sys/windows"


ensure_success :: #force_inline proc(
    hresult: win.HRESULT,
    message := #caller_expression(hresult),
    loc := #caller_location,
) {
    ensure(win.SUCCEEDED(hresult), message, loc)
}
