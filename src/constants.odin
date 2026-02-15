package main

import "core:mem"
import "core:path/filepath"
import util "libs:utilities"

ASSET_PATH :: "assets"

get_asset_path :: proc(
    asset: string,
    allocator := context.allocator,
) -> (
    res: string,
    err: mem.Allocator_Error,
) {
    s := util.get_exe_dir() or_return
    defer if allocator != context.temp_allocator {
        free_all(context.temp_allocator)
    }
    paths := [3]string{s, ASSET_PATH, asset}
    res = filepath.join(paths[:], allocator)
    return
}
