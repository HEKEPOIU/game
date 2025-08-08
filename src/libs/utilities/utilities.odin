package utilities


swap :: #force_inline proc(a: ^$T, b: ^T) {
    temp := a^
    a^ = b^
    b^ = temp
}
