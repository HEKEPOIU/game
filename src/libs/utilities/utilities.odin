package utilities

import "base:intrinsics"
import "core:os"
import "core:simd"
import "core:sys/info"

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:path/filepath"
import "core:strconv"
import "core:strings"
import "core:sys/linux"


get_exe_dir :: proc(
    allocator := context.temp_allocator,
) -> (
    res: string,
    err: mem.Allocator_Error,
) {
    defer if allocator != context.temp_allocator {
        free_all(context.temp_allocator)
    }
    when ODIN_OS == .Windows {
        buf: [win.MAX_PATH]u16
        len := win.GetModuleFileNameW(nil, &buf[0], win.MAX_PATH)
        res = win.utf16_to_utf8_alloc(buf[:len], context.temp_allocator) or_return
        res = filepath.dir(res, allocator)
        return
    } else when ODIN_OS == .Linux {
        FILE_NAME_MAX :: 4096
        buf: [FILE_NAME_MAX]u8
        len, _ := linux.readlink("/proc/self/exe", buf[:])
        res = strings.clone_from(buf[:], context.temp_allocator) or_return
        res = filepath.dir(res, allocator)
        return
    } else {
        #panic("Not Implement for current platform")
    }
}

swap :: #force_inline proc(a: ^$T, b: ^T) {
    temp := a^
    a^ = b^
    b^ = temp
}


// only use for launching actual game that have different feature(simd, avx2, avx512...).
dynamic_check_feature :: proc(feature: info.CPU_Feature) -> bool {
    features := info.cpu.features.? or_return
    return feature in features
}

// Target sse4.2 are because arm neon only support 128 bit
// we provide a generic version for all target
// and if someday we need more performance, we can change it base on target.
// the attribure enable_target_feature not useful for now, just for the search purpose.
// and remind me when we compile in arm target.
// if use avx2, it will auto add vzeroupper at end of function.
@(enable_target_feature = "sse4.2")
count_bytes :: proc "contextless" (data: []byte, c: byte) -> int #no_bounds_check {
    i, l := 0, len(data)

    sum := 0


    // Still use avx2 size are because odin will simulate not support instruction.
    // Like currently use sse instruction to simulate avx2 instruction.
    // and i found use u8x32(256) in sse4.2 are faster then use sse native u8x16(128)
    // they are because for loop overhead, and that also thy use #no_bounds_check.
    // (you can remove #no_bounds_check to see speed different)
    AVX2_SIMD_SIZE :: 32
    if l < AVX2_SIMD_SIZE {
        for ; i < l; i += 1 {
            if data[i] == c {
                sum += 1
            }
        }
        return sum
    }
    c_vec_256: simd.u8x32 = c

    s_vecs: [4]simd.u8x32 = ---
    c_vecs: [4]simd.u8x32 = ---
    m_vec: [4]u8 = ---
    // Scan 128-byte chunks, using 256-bit SIMD.
    for nr_blocks := l / (4 * AVX2_SIMD_SIZE); nr_blocks > 0; nr_blocks -= 1 {
        #unroll for j in 0 ..< 4 {
            s_vecs[j] = intrinsics.unaligned_load(
                cast(^simd.u8x32)raw_data(data[i + j * AVX2_SIMD_SIZE:]),
            )
            c_vecs[j] = simd.lanes_eq(s_vecs[j], c_vec_256)
        }
        #unroll for j in 0 ..< 4 {
            // example:
            // [0,0,0,0,0b11111111] -> [0,0,0,0,8]
            // count the number of ones in each lane
            // so we need divide by 8.
            // we must do count_ones rather then
            // reduce_add_bisect(c_vecs[j])/255 to avoid overflow(u8)
            ones := simd.count_ones(c_vecs[j])
            sum += int(simd.reduce_add_bisect(ones))
        }

        i += 4 * AVX2_SIMD_SIZE
    }

    for nr_blocks := (l - i) / AVX2_SIMD_SIZE; nr_blocks > 0; nr_blocks -= 1 {
        s0 := intrinsics.unaligned_load(cast(^simd.u8x32)raw_data(data[i:]))
        c0 := simd.lanes_eq(s0, c_vec_256)
        ones := simd.count_ones(c0)
        sum += int(simd.reduce_add_bisect(ones))
        i += AVX2_SIMD_SIZE
    }

    sum /= 8

    for ; i < l; i += 1 {
        if data[i] == c {
            sum += 1
        }
    }

    return sum
}


// ?: why not buildin one:
// our count byte more effective, and buildin one are more general.
split_by_char :: proc(
    data: string,
    sep: byte,
    allocator := context.allocator,
    loc := #caller_location,
) -> (
    res: []string,
    err: mem.Allocator_Error,
) {

    data := data
    count := count_bytes(transmute([]byte)data, sep)
    res = make([]string, count + 1, allocator, loc) or_return


    for i := 0; i < count; i += 1 {
        // Odin index_byte use SIMD when data size > 128bit if possible,
        breakPos := strings.index_byte(data, sep)
        res[i] = data[:breakPos]
        data = data[breakPos + 1:]
    }
    res[count] = data

    return res[:], nil
}

parse_u16_from_hex :: proc(data: string) -> (u16, bool) {
    assert(len(data) == 4)
    v_1 := strconv._digit_value(rune(data[0]))
    v_2 := strconv._digit_value(rune(data[1]))
    v_3 := strconv._digit_value(rune(data[2]))
    v_4 := strconv._digit_value(rune(data[3]))
    if v_1 > 15 || v_2 > 15 || v_3 > 15 || v_4 > 15 {
        return 0, false
    }
    b_1 := v_1 * 16 + v_2
    b_2 := v_3 * 16 + v_4
    return u16(b_2 << 8 | b_1), true
}


// WARN: ONLY USE THIS, IF YOU SURE THE LIFETIME OF TARGET ARE ENTIRE PROGRAM
@(disabled = !ODIN_DEBUG)
debug_delete :: #force_inline proc(target: $T) {
    delete(target)
}

// WARN: ONLY USE THIS, IF YOU SURE THE LIFETIME OF TARGET ARE ENTIRE PROGRAM
@(disabled = !ODIN_DEBUG)
debug_free :: #force_inline proc(target: $T) {
    delete(target)
}

@(disabled = !ODIN_DEBUG)
debug_printf_cond :: #force_inline proc(
    cond: bool,
    fmt_str: string,
    args: ..any,
    location := #caller_location,
) {
    if cond {
        log.debugf(fmt_str, ..args, location = location)
    }
}

@(disabled = !ODIN_DEBUG)
debug_printf :: #force_inline proc(fmt_str: string, args: ..any, location := #caller_location) {
    log.debugf(fmt_str, ..args, location = location)
}


/* TODO: put it in the test file.
    brenchmark code:
    // this for not let cache effect timing result.
    bytes_3 := util.count_bytes_sse_32(transmute([]byte)data, '\n')
    bytes_1 := util.count_bytes_sse_32(transmute([]byte)data, '\n')


    bytes_16_diff: time.Duration
    {
        time.SCOPED_TICK_DURATION(&bytes_16_diff)

        bytes_16_count = util.count_bytes_sse_16(transmute([]byte)data, '\n')
    }

    log.debugf("byte_16_count: {}", bytes_16_diff)

    bytes_32_diff: time.Duration
    {
        time.SCOPED_TICK_DURATION(&bytes_32_diff)
        bytes_32_count = util.count_bytes_sse_32(transmute([]byte)data, '\n')
    }
    log.debugf("byte_32_count: {}", bytes_32_diff)
*/


// @(enable_target_feature = "sse4.2")
// count_bytes_sse_16 :: proc(data: []byte, c: byte) -> int {
//     i, l := 0, len(data)
//
//     sum := 0
//
//
//     // Use still avx2 are because odin will simulate the avx2 instruction,
//     // if the compile target don't support it.
//     // Like current use sse instruction to simulate avx2 instruction.
//     // and i found use u8x32(256) in sse4.2 are faster then use sse native u8x16(128)
//     // currently guess the asm code
//     AVX2_SIMD_SIZE :: 16
//     c_vec_256: simd.u8x16 = c
//
//     s_vecs: [4]simd.u8x16 = ---
//     c_vecs: [4]simd.u8x16 = ---
//     m_vec: [4]u8 = ---
//     // Scan 128-byte chunks, using 256-bit SIMD.
//     for nr_blocks := l / (4 * AVX2_SIMD_SIZE); nr_blocks > 0; nr_blocks -= 1 {
//         #unroll for j in 0 ..< 4 {
//             s_vecs[j] = intrinsics.unaligned_load(
//                 cast(^simd.u8x16)raw_data(data[i + j * AVX2_SIMD_SIZE:]),
//             )
//             c_vecs[j] = simd.lanes_eq(s_vecs[j], c_vec_256)
//         }
//         #unroll for j in 0 ..< 4 {
//             // example:
//             // [0,0,0,0,0b11111111] -> [0,0,0,0,8]
//             // count the number of ones in each lane
//             ones := simd.count_ones(c_vecs[j])
//             sum += int(simd.reduce_add_bisect(ones))
//         }
//
//         i += 4 * AVX2_SIMD_SIZE
//     }
//
//     for nr_blocks := (l - i) / AVX2_SIMD_SIZE; nr_blocks > 0; nr_blocks -= 1 {
//         s0 := intrinsics.unaligned_load(cast(^simd.u8x16)raw_data(data[i:]))
//         c0 := simd.lanes_eq(s0, c_vec_256)
//         ones := simd.count_ones(c0)
//         sum += int(simd.reduce_add_bisect(ones))
//         i += AVX2_SIMD_SIZE
//     }
//
//     sum /= 8
//
//     for ; i < l; i += 1 {
//         if data[i] == c {
//             sum += 1
//         }
//     }
//
//     return sum
// }


setup_context :: proc() -> (result: runtime.Context) {
    // TODO: Implement In Game console logger, to replace the OS console logger.
    //       so that we can build game with  subsystem:windows
    result = context

    when ODIN_DEBUG {
        result.user_ptr = new(mem.Tracking_Allocator)
        track := (^mem.Tracking_Allocator)(result.user_ptr)
        mem.tracking_allocator_init(track, context.allocator)
        result.allocator = mem.tracking_allocator(track)
    }

    result.logger = log.create_console_logger(
        opt = {.Level, .Terminal_Color, .Short_File_Path, .Procedure, .Line},
        allocator = result.allocator,
    )

    return result
}

delete_context :: proc(cc: ^runtime.Context) {
    log.destroy_console_logger(cc.logger)
    when ODIN_DEBUG {
        track := (^mem.Tracking_Allocator)(cc.user_ptr)
        if len(track.allocation_map) > 0 {
            for _, entry in track.allocation_map {
                fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
            }
        }

        mem.tracking_allocator_destroy(track)
    }
}
