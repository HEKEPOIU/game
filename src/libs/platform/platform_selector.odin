package platform


Window_State :: struct {
    using window: Window_Interface,
    state:        rawptr,
}


create_window_state :: proc() -> Window_State {

    when ODIN_OS == .Windows {
        #panic("Not Implement")
    } else when ODIN_OS == .Linux {
        return x11_create_window_state()
    } else {
        #panic("Not Support for Current Platform")
    }
}
