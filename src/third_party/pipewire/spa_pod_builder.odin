package pipewire

import "base:runtime"
import "core:mem"

// spa_json are not implement, use odin core/encoding/json instead

SPA_POD_BUILDER_BITS :: enum {
    BODY  = 1 << 0,
    FIRST = 1 << 1,
}

SPA_POD_BUILDER_FLAGS :: bit_set[SPA_POD_BUILDER_BITS;u32]

spa_pod :: struct {
    size: u32,
    type: spa_type,
}

spa_pod_bool :: struct {
    pod:      spa_pod,
    value:    i32,
    _padding: i32,
}

spa_pod_id :: struct {
    pod:      spa_pod,
    value:    u32,
    _padding: i32,
}

spa_pod_int :: struct {
    pod:      spa_pod,
    value:    i32,
    _padding: i32,
}

spa_pod_long :: struct {
    pod:   spa_pod,
    value: i64,
}

spa_pod_float :: struct {
    pod:      spa_pod,
    value:    f32,
    _padding: i32,
}

spa_pod_double :: struct {
    pod:   spa_pod,
    value: f64,
}

spa_pod_string :: struct {
    pod: spa_pod,
    /* value here */
}

spa_pod_bytes :: struct {
    pod: spa_pod,
    /* value here */
}

spa_rectangle :: struct {
    w: u32,
    h: u32,
}

spa_pod_rectangle :: struct {
    pod:   spa_pod,
    value: spa_rectangle,
}

spa_fraction :: struct {
    num:   u32,
    denom: u32,
}

spa_pod_fraction :: struct {
    pod:   spa_pod,
    value: spa_fraction,
}

spa_pod_bitmap :: struct {
    pod: spa_pod,
    /* array of uint8_t follows with the bitmap */
}

spa_pod_object_body :: struct {
    type: spa_type,
    id:   spa_param_type,
}

spa_pod_object :: struct {
    pod:  spa_pod,
    body: spa_pod_object_body,
}

spa_pod_array_body :: struct {
    child: spa_pod,
}

spa_pod_array :: struct {
    pod:  spa_pod,
    body: spa_pod_array_body,
}

spa_choice_type :: enum u32 {
    SPA_CHOICE_None,
    SPA_CHOICE_Range,
    SPA_CHOICE_Step,
    SPA_CHOICE_Enum,
    SPA_CHOICE_Flags,
}

spa_pod_choice_body :: struct {
    type:  spa_choice_type,
    flags: SPA_POD_BUILDER_FLAGS,
    child: spa_pod,
}

spa_pod_choice :: struct {
    pod:  spa_pod,
    body: spa_pod_choice_body,
}

spa_pod_struct :: struct {
    pod: spa_pod,
}

spa_pod_pointer_body :: struct {
    type:     u32,
    _padding: u32,
    value:    rawptr,
}

spa_pod_pointer :: struct {
    pod:  spa_pod,
    body: spa_pod_pointer_body,
}

spa_pod_fd :: struct {
    pod:   spa_pod,
    value: i64,
}

spa_pod_prop :: struct {
    key:   u32,
    flags: u32,
    value: spa_pod,
}

spa_pod_control :: struct {
    offset: u32,
    type:   u32,
    value:  spa_pod,
}

spa_pod_sequence_body :: struct {
    unit: u32,
    pad:  u32,
}

spa_pod_sequence :: struct {
    pod:  spa_pod,
    body: spa_pod_sequence_body,
}

spa_pod_builder :: struct {
    data:      rawptr,
    size:      u32,
    _padding:  u32,
    state:     spa_pod_builder_state,
    callbacks: spa_callbacks,
}

spa_pod_builder_state :: struct {
    offset: u32,
    flags:  SPA_POD_BUILDER_FLAGS,
    frame:  ^spa_pod_frame,
}

spa_pod_builder_callbacks :: struct {
    version:  u32,
    overflow: proc(data: rawptr, size: u32) -> int,
}

spa_pod_frame :: struct {
    pod:    spa_pod,
    parent: ^spa_pod_frame,
    offset: u32,
    flags:  SPA_POD_BUILDER_FLAGS,
}

SPA_AUDIO_MAX_CHANNELS :: 64

spa_audio_format :: enum u32 {
    UNKNOWN,
    ENCODED,

    /* interleaved formats */
    START_Interleaved = 0x100,
    S8,
    U8,
    S16_LE,
    S16_BE,
    U16_LE,
    U16_BE,
    S24_32_LE,
    S24_32_BE,
    U24_32_LE,
    U24_32_BE,
    S32_LE,
    S32_BE,
    U32_LE,
    U32_BE,
    S24_LE,
    S24_BE,
    U24_LE,
    U24_BE,
    S20_LE,
    S20_BE,
    U20_LE,
    U20_BE,
    S18_LE,
    S18_BE,
    U18_LE,
    U18_BE,
    F32_LE,
    F32_BE,
    F64_LE,
    F64_BE,
    ULAW,
    ALAW,

    /* planar formats */
    START_Planar = 0x200,
    U8P,
    S16P,
    S24_32P,
    S32P,
    S24P,
    F32P,
    F64P,
    S8P,

    /* other formats start here */
    START_Other = 0x400,

    /* Aliases */

    /* DSP formats */
    DSP_S32 = S24_32P,
    DSP_F32 = F32P,
    DSP_F64 = F64P,
    /* native endian */
}
when ODIN_ENDIAN == .Big {
    SPA_AUDIO_FORMAT_S16 :: spa_audio_format.S16_BE
    SPA_AUDIO_FORMAT_U16 :: spa_audio_format.U16_BE
    SPA_AUDIO_FORMAT_S24_32 :: spa_audio_format.S24_32_BE
    SPA_AUDIO_FORMAT_U24_32 :: spa_audio_format.U24_32_BE
    SPA_AUDIO_FORMAT_S32 :: spa_audio_format.S32_BE
    SPA_AUDIO_FORMAT_U32 :: spa_audio_format.U32_BE
    SPA_AUDIO_FORMAT_S24 :: spa_audio_format.S24_BE
    SPA_AUDIO_FORMAT_U24 :: spa_audio_format.U24_BE
    SPA_AUDIO_FORMAT_S20 :: spa_audio_format.S20_BE
    SPA_AUDIO_FORMAT_U20 :: spa_audio_format.U20_BE
    SPA_AUDIO_FORMAT_S18 :: spa_audio_format.S18_BE
    SPA_AUDIO_FORMAT_U18 :: spa_audio_format.U18_BE
    SPA_AUDIO_FORMAT_F32 :: spa_audio_format.F32_BE
    SPA_AUDIO_FORMAT_F64 :: spa_audio_format.F64_BE
    SPA_AUDIO_FORMAT_S16_OE :: spa_audio_format.S16_LE
    SPA_AUDIO_FORMAT_U16_OE :: spa_audio_format.U16_LE
    SPA_AUDIO_FORMAT_S24_32_OE :: spa_audio_format.S24_32_LE
    SPA_AUDIO_FORMAT_U24_32_OE :: spa_audio_format.U24_32_LE
    SPA_AUDIO_FORMAT_S32_OE :: spa_audio_format.S32_LE
    SPA_AUDIO_FORMAT_U32_OE :: spa_audio_format.U32_LE
    SPA_AUDIO_FORMAT_S24_OE :: spa_audio_format.S24_LE
    SPA_AUDIO_FORMAT_U24_OE :: spa_audio_format.U24_LE
    SPA_AUDIO_FORMAT_S20_OE :: spa_audio_format.S20_LE
    SPA_AUDIO_FORMAT_U20_OE :: spa_audio_format.U20_LE
    SPA_AUDIO_FORMAT_S18_OE :: spa_audio_format.S18_LE
    SPA_AUDIO_FORMAT_U18_OE :: spa_audio_format.U18_LE
    SPA_AUDIO_FORMAT_F32_OE :: spa_audio_format.F32_LE
    SPA_AUDIO_FORMAT_F64_OE :: spa_audio_format.F64_LE
} else {
    SPA_AUDIO_FORMAT_S16 :: spa_audio_format.S16_LE
    SPA_AUDIO_FORMAT_U16 :: spa_audio_format.U16_LE
    SPA_AUDIO_FORMAT_S24_32 :: spa_audio_format.S24_32_LE
    SPA_AUDIO_FORMAT_U24_32 :: spa_audio_format.U24_32_LE
    SPA_AUDIO_FORMAT_S32 :: spa_audio_format.S32_LE
    SPA_AUDIO_FORMAT_U32 :: spa_audio_format.U32_LE
    SPA_AUDIO_FORMAT_S24 :: spa_audio_format.S24_LE
    SPA_AUDIO_FORMAT_U24 :: spa_audio_format.U24_LE
    SPA_AUDIO_FORMAT_S20 :: spa_audio_format.S20_LE
    SPA_AUDIO_FORMAT_U20 :: spa_audio_format.U20_LE
    SPA_AUDIO_FORMAT_S18 :: spa_audio_format.S18_LE
    SPA_AUDIO_FORMAT_U18 :: spa_audio_format.U18_LE
    SPA_AUDIO_FORMAT_F32 :: spa_audio_format.F32_LE
    SPA_AUDIO_FORMAT_F64 :: spa_audio_format.F64_LE
    SPA_AUDIO_FORMAT_S16_OE :: spa_audio_format.S16_BE
    SPA_AUDIO_FORMAT_U16_OE :: spa_audio_format.U16_BE
    SPA_AUDIO_FORMAT_S24_32_OE :: spa_audio_format.S24_32_BE
    SPA_AUDIO_FORMAT_U24_32_OE :: spa_audio_format.U24_32_BE
    SPA_AUDIO_FORMAT_S32_OE :: spa_audio_format.S32_BE
    SPA_AUDIO_FORMAT_U32_OE :: spa_audio_format.U32_BE
    SPA_AUDIO_FORMAT_S24_OE :: spa_audio_format.S24_BE
    SPA_AUDIO_FORMAT_U24_OE :: spa_audio_format.U24_BE
    SPA_AUDIO_FORMAT_S20_OE :: spa_audio_format.S20_BE
    SPA_AUDIO_FORMAT_U20_OE :: spa_audio_format.U20_BE
    SPA_AUDIO_FORMAT_S18_OE :: spa_audio_format.S18_BE
    SPA_AUDIO_FORMAT_U18_OE :: spa_audio_format.U18_BE
    SPA_AUDIO_FORMAT_F32_OE :: spa_audio_format.F32_BE
    SPA_AUDIO_FORMAT_F64_OE :: spa_audio_format.F64_BE
}


spa_audio_channel :: enum {
    SPA_AUDIO_CHANNEL_UNKNOWN,
    SPA_AUDIO_CHANNEL_NA,
    SPA_AUDIO_CHANNEL_MONO,
    SPA_AUDIO_CHANNEL_FL,
    SPA_AUDIO_CHANNEL_FR,
    SPA_AUDIO_CHANNEL_FC,
    SPA_AUDIO_CHANNEL_LFE,
    SPA_AUDIO_CHANNEL_SL,
    SPA_AUDIO_CHANNEL_SR,
    SPA_AUDIO_CHANNEL_FLC,
    SPA_AUDIO_CHANNEL_FRC,
    SPA_AUDIO_CHANNEL_RC,
    SPA_AUDIO_CHANNEL_RL,
    SPA_AUDIO_CHANNEL_RR,
    SPA_AUDIO_CHANNEL_TC,
    SPA_AUDIO_CHANNEL_TFL,
    SPA_AUDIO_CHANNEL_TFC,
    SPA_AUDIO_CHANNEL_TFR,
    SPA_AUDIO_CHANNEL_TRL,
    SPA_AUDIO_CHANNEL_TRC,
    SPA_AUDIO_CHANNEL_TRR,
    SPA_AUDIO_CHANNEL_RLC,
    SPA_AUDIO_CHANNEL_RRC,
    SPA_AUDIO_CHANNEL_FLW,
    SPA_AUDIO_CHANNEL_FRW,
    SPA_AUDIO_CHANNEL_LFE2,
    SPA_AUDIO_CHANNEL_FLH,
    SPA_AUDIO_CHANNEL_FCH,
    SPA_AUDIO_CHANNEL_FRH,
    SPA_AUDIO_CHANNEL_TFLC,
    SPA_AUDIO_CHANNEL_TFRC,
    SPA_AUDIO_CHANNEL_TSL,
    SPA_AUDIO_CHANNEL_TSR,
    SPA_AUDIO_CHANNEL_LLFE,
    SPA_AUDIO_CHANNEL_RLFE,
    SPA_AUDIO_CHANNEL_BC,
    SPA_AUDIO_CHANNEL_BLC,
    SPA_AUDIO_CHANNEL_BRC,
    SPA_AUDIO_CHANNEL_START_Aux = 0x1000,
    SPA_AUDIO_CHANNEL_AUX0 = SPA_AUDIO_CHANNEL_START_Aux,
    SPA_AUDIO_CHANNEL_AUX1,
    SPA_AUDIO_CHANNEL_AUX2,
    SPA_AUDIO_CHANNEL_AUX3,
    SPA_AUDIO_CHANNEL_AUX4,
    SPA_AUDIO_CHANNEL_AUX5,
    SPA_AUDIO_CHANNEL_AUX6,
    SPA_AUDIO_CHANNEL_AUX7,
    SPA_AUDIO_CHANNEL_AUX8,
    SPA_AUDIO_CHANNEL_AUX9,
    SPA_AUDIO_CHANNEL_AUX10,
    SPA_AUDIO_CHANNEL_AUX11,
    SPA_AUDIO_CHANNEL_AUX12,
    SPA_AUDIO_CHANNEL_AUX13,
    SPA_AUDIO_CHANNEL_AUX14,
    SPA_AUDIO_CHANNEL_AUX15,
    SPA_AUDIO_CHANNEL_AUX16,
    SPA_AUDIO_CHANNEL_AUX17,
    SPA_AUDIO_CHANNEL_AUX18,
    SPA_AUDIO_CHANNEL_AUX19,
    SPA_AUDIO_CHANNEL_AUX20,
    SPA_AUDIO_CHANNEL_AUX21,
    SPA_AUDIO_CHANNEL_AUX22,
    SPA_AUDIO_CHANNEL_AUX23,
    SPA_AUDIO_CHANNEL_AUX24,
    SPA_AUDIO_CHANNEL_AUX25,
    SPA_AUDIO_CHANNEL_AUX26,
    SPA_AUDIO_CHANNEL_AUX27,
    SPA_AUDIO_CHANNEL_AUX28,
    SPA_AUDIO_CHANNEL_AUX29,
    SPA_AUDIO_CHANNEL_AUX30,
    SPA_AUDIO_CHANNEL_AUX31,
    SPA_AUDIO_CHANNEL_AUX32,
    SPA_AUDIO_CHANNEL_AUX33,
    SPA_AUDIO_CHANNEL_AUX34,
    SPA_AUDIO_CHANNEL_AUX35,
    SPA_AUDIO_CHANNEL_AUX36,
    SPA_AUDIO_CHANNEL_AUX37,
    SPA_AUDIO_CHANNEL_AUX38,
    SPA_AUDIO_CHANNEL_AUX39,
    SPA_AUDIO_CHANNEL_AUX40,
    SPA_AUDIO_CHANNEL_AUX41,
    SPA_AUDIO_CHANNEL_AUX42,
    SPA_AUDIO_CHANNEL_AUX43,
    SPA_AUDIO_CHANNEL_AUX44,
    SPA_AUDIO_CHANNEL_AUX45,
    SPA_AUDIO_CHANNEL_AUX46,
    SPA_AUDIO_CHANNEL_AUX47,
    SPA_AUDIO_CHANNEL_AUX48,
    SPA_AUDIO_CHANNEL_AUX49,
    SPA_AUDIO_CHANNEL_AUX50,
    SPA_AUDIO_CHANNEL_AUX51,
    SPA_AUDIO_CHANNEL_AUX52,
    SPA_AUDIO_CHANNEL_AUX53,
    SPA_AUDIO_CHANNEL_AUX54,
    SPA_AUDIO_CHANNEL_AUX55,
    SPA_AUDIO_CHANNEL_AUX56,
    SPA_AUDIO_CHANNEL_AUX57,
    SPA_AUDIO_CHANNEL_AUX58,
    SPA_AUDIO_CHANNEL_AUX59,
    SPA_AUDIO_CHANNEL_AUX60,
    SPA_AUDIO_CHANNEL_AUX61,
    SPA_AUDIO_CHANNEL_AUX62,
    SPA_AUDIO_CHANNEL_AUX63,
    SPA_AUDIO_CHANNEL_LAST_Aux = 0x1fff,
    SPA_AUDIO_CHANNEL_START_Custom = 0x10000,
}


spa_audio_flags :: bit_set[spa_audio_flag;u32]

spa_audio_flag :: enum {
    UNPOSITIONED,
}


spa_audio_info_raw :: struct {
    format:   spa_audio_format, /*< format, one of enum spa_audio_format */
    flags:    spa_audio_flags, /*< extra flags */
    rate:     u32, /*< sample rate */
    channels: u32, /*< number of channels. This can be more than SPA_AUDIO_MAX_CHANNELS
	   		 *  and you may assume there is enough padding for the extra
	   		 *  channel positions. */
    position: [SPA_AUDIO_MAX_CHANNELS]u32, /*< channel position from enum spa_audio_channel */
}















SPA_POD_ID_INIT :: #force_inline proc(val: u32) -> spa_pod_id {
    return spa_pod_id{{size_of(u32), .Id}, val, 0}
}

SPA_POD_BOOL_INIT :: #force_inline proc(val: bool) -> spa_pod_bool {
    return spa_pod_bool{{size_of(u32), .Bool}, val ? 1 : 0, 0}
}

SPA_POD_INT_INIT :: #force_inline proc(val: i32) -> spa_pod_int {
    return spa_pod_int{{size_of(i32), .Int}, val, 0}
}

SPA_POD_LONG_INIT :: #force_inline proc(val: i64) -> spa_pod_long {
    return spa_pod_long{{size_of(i64), .Long}, val}
}

SPA_POD_FLOAT_INIT :: #force_inline proc(val: f32) -> spa_pod_float {
    return spa_pod_float{{size_of(f32), .Float}, val, 0}
}

SPA_POD_DOUBLE_INIT :: #force_inline proc(val: f64) -> spa_pod_double {
    return spa_pod_double{{size_of(f64), .Double}, val}
}

SPA_POD_STRING_INIT :: #force_inline proc(val: cstring, len: u32) -> spa_pod_string {
    return spa_pod_string{{len, .String}}
}

SPA_POD_BYTES_INIT :: #force_inline proc(val: rawptr, len: u32) -> spa_pod_bytes {
    return spa_pod_bytes{{len, .Bytes}}
}

SPA_POD_POINTER_INIT :: #force_inline proc(val: rawptr, type: u32) -> spa_pod_pointer {
    return spa_pod_pointer{{size_of(spa_pod_pointer_body), .Pointer}, {type, 0, val}}
}

SPA_POD_FD_INIT :: #force_inline proc(val: i64) -> spa_pod_fd {
    return spa_pod_fd{{size_of(i64), .Fd}, val}
}

SPA_POD_RECTANGLE_INIT :: #force_inline proc(val: spa_rectangle) -> spa_pod_rectangle {
    return spa_pod_rectangle{{size_of(spa_rectangle), .Rectangle}, val}
}

SPA_POD_FRACTION_INIT :: #force_inline proc(val: spa_fraction) -> spa_pod_fraction {
    return spa_pod_fraction{{size_of(spa_fraction), .Fraction}, val}
}

SPA_POD_STRUCT_INIT :: #force_inline proc(size: u32) -> spa_pod_struct {
    return spa_pod_struct{{size, .Struct}}
}

SPA_POD_OBJECT_INIT :: #force_inline proc(
    size: u32,
    type: spa_type,
    id: spa_param_type,
) -> spa_pod_object {
    return spa_pod_object{{size, .Object}, {type, id}}
}

SPA_POD_SEQUENCE_INIT :: #force_inline proc(size: u32, unit: u32) -> spa_pod_sequence {
    return spa_pod_sequence{{size, .Sequence}, {unit, 0}}
}
SPA_POD_ARRAY_INIT :: #force_inline proc(
    child_size: u32,
    n_child: u32,
    child_type: spa_type,
) -> spa_pod_array {

    return spa_pod_array {
        {(size_of(spa_pod_array_body) + n_child * child_size), .Array},
        {{child_size, child_type}},
    }
}


spa_pod_builder_collect :: proc(b: ^spa_pod_builder, type: u8, args: ^[]any) {
    switch type {
    case 'b':
        arg, _ := get_vararg_checked(args, bool)
        spa_pod_builder_bool(b, arg)
    case 'I':
        arg, _ := get_vararg_checked(args, u32)
        spa_pod_builder_id(b, arg)
    case 'i':
        arg, _ := get_vararg_checked(args, i32)
        spa_pod_builder_int(b, arg)
    case 'l':
        arg, _ := get_vararg_checked(args, i64)
        spa_pod_builder_long(b, arg)
    case 'f':
        arg, _ := get_vararg_checked(args, f64)
        spa_pod_builder_float(b, f32(arg))
    case 'd':
        arg, _ := get_vararg_checked(args, f64)
        spa_pod_builder_double(b, arg)
    case 's':
        strval, strval_err := get_vararg_checked(args, cstring)
        if !strval_err {
            len := len(strval)
            spa_pod_builder_string_len(b, strval, u32(len))
        } else {
            spa_pod_builder_none(b)
        }
    case 'S':
        strval, _ := get_vararg_checked(args, cstring)
        len, _ := get_vararg_checked(args, u32)
        spa_pod_builder_string_len(b, strval, len)
    case 'y':
        ptr, _ := get_vararg_checked(args, rawptr)
        len, _ := get_vararg_checked(args, u32)
        spa_pod_builder_bytes(b, ptr, len)
    case 'R':
        rectval, _ := get_vararg_checked(args, ^spa_rectangle)
        spa_pod_builder_rectangle(b, rectval.w, rectval.h)
    case 'F':
        fractval, _ := get_vararg_checked(args, ^spa_fraction)
        spa_pod_builder_rectangle(b, fractval.num, fractval.denom)
    case 'a':
        child_size, _ := get_vararg_checked(args, u32)
        child_type, _ := get_vararg_checked(args, spa_type)
        n_elems, _ := get_vararg_checked(args, u32)
        elems, _ := get_vararg_checked(args, rawptr)
        spa_pod_builder_array(b, child_size, child_type, n_elems, elems)
    case 'p':
        t, _ := get_vararg_checked(args, u32)
        ptr, _ := get_vararg_checked(args, rawptr)
        spa_pod_builder_pointer(b, t, ptr)
    case 'h':
        fd, _ := get_vararg_checked(args, i64)
        spa_pod_builder_fd(b, fd)
    case 'P', 'O', 'T', 'V':
        pod, pod_err := get_vararg_checked(args, ^spa_pod)
        if pod_err {
            spa_pod_builder_none(b)
        } else {
            spa_pod_builder_primitive(b, pod)
        }
    }
}



// spa_pod_builder_add_object :: proc(
//     b: ^spa_pod_builder,
//     type: spa_type,
//     id: spa_param_type,
//     args: ..any,
// ) {
//     f: spa_pod_frame
//     spa_pod_builder_push_object(b, &f, type, id)
//     spa_pod_builder_add(b, args)
//     spa_pod_builder_pop(b, &f)
// }
//
// spa_pod_builder_add_struct :: proc(b: ^spa_pod_builder, args: ..any) {
//     f: spa_pod_frame
//     spa_pod_builder_push_struct(b, &f)
//     spa_pod_builder_add(b, args)
//     spa_pod_builder_pop(b, &f)
// }
//
// spa_pod_builder_add_sequence :: proc(b: ^spa_pod_builder, unit: u32, args: ..any) {
//     f: spa_pod_frame
//     spa_pod_builder_push_sequence(b, &f, unit)
//     spa_pod_builder_add(b, args)
//     spa_pod_builder_pop(b, &f)
// }

spa_pod_copy :: proc(pod: ^spa_pod, allocator := context.allocator) -> ^spa_pod {
    size := spa_pod_size(pod)
    c, _ := mem.alloc(int(size), allocator = allocator)
    mem.copy(c, pod, int(size))
    return cast(^spa_pod)c
}

spa_ptroff :: #force_inline proc(ptr: rawptr, offset: u32, $T: typeid) -> ^T {
    return cast(^T)(uintptr(ptr) + uintptr(offset))
}

spa_round_up_n :: #force_inline proc(num: $T, align: T) -> T {
    return ((num - 1) | cast(type_of(num))(align - 1)) + 1
}

spa_pod_body :: #force_inline proc(pod: ^spa_pod) -> rawptr {
    return spa_ptroff(pod, size_of(spa_pod), struct {})
}

get_vararg_checked :: proc(args: ^[]any, $T: typeid) -> (T, bool) {
    if len(args) == 0 {
        return T{}, true
    }

    arg := args[0]
    args^ = args[1:]

    return get_any_checked(arg, T)
}

get_any_checked :: proc(v: any, $T: typeid) -> (T, bool) {
    v := v
    v.id = runtime.typeid_base(v.id)
    switch var in v {
    case T:
        return var, false
    case:
        res: T
        return res, false
    }
}

