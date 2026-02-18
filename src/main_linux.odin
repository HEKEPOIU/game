package main

import util "libs/utilities"


main :: proc() {
    custom_context := util.setup_context()
    context = custom_context
    defer util.delete_context(&custom_context)

}
