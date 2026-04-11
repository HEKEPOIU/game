package sdl3

LINK_SAHARD :: #config(SDL_LINK_SHARED, false)

when ODIN_OS == .Windows {
    when LINK_SAHARD {
        @(export)
        foreign import lib "lib/SDL3-shared.lib"
    } else {
        @(export)
        foreign import lib "lib/SDL3-static.lib"
    }
} else when ODIN_OS == .Linux || ODIN_OS == .Darwin {
    when LINK_SAHARD {
        @(export)
        foreign import lib "lib/libSDL3.so"
    } else {
        @(export)
        foreign import lib "lib/libSDL3.a"
    }
}

