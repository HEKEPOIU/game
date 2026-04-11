package pipewire

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:reflect"
import "core:strings"

when !#exists("./spa-0.2/spa_impl.o") {
    #panic("spa_impl.o not found, please run gen_include.sh in spa-0.2 subfolder")
}

foreign import spa "./spa-0.2/spa_impl.o"


@(default_calling_convention = "c")
foreign spa {
    spa_dict_lookup :: proc(dict: ^spa_dict, key: cstring) -> cstring ---
    spa_dict_lookup_item :: proc(dict: ^spa_dict, key: cstring) -> ^spa_dict_item ---
    spa_hook_remove :: proc "c" (hook: ^spa_hook) ---
    spa_list_init :: proc "c" (list: ^spa_list) ---
    spa_list_is_initialized :: proc "c" (list: ^spa_list) -> bool ---
    spa_list_remove :: proc "c" (elem: ^spa_list) ---
    spa_list_insert :: proc "c" (list: ^spa_list, elem: ^spa_list) ---
    spa_pod_builder_get_state :: proc(b: ^spa_pod_builder, state: ^spa_pod_builder_state) ---
    spa_pod_builder_set_callbacks :: proc(b: ^spa_pod_builder, callbacks: ^spa_pod_builder_callbacks, data: rawptr) ---
    spa_pod_builder_reset :: proc(b: ^spa_pod_builder, state: ^spa_pod_builder_state) ---
    spa_pod_builder_init :: proc(b: ^spa_pod_builder, data: rawptr, size: u32) ---
    spa_pod_builder_deref :: proc(b: ^spa_pod_builder, offset: u32) -> ^spa_pod ---
    spa_pod_size :: #force_inline proc(pod: ^spa_pod) -> u32 ---
    spa_pod_builder_frame :: proc(b: ^spa_pod_builder, frame: ^spa_pod_frame) -> ^spa_pod ---
    spa_pod_builder_push :: proc(b: ^spa_pod_builder, frame: ^spa_pod_frame, pod: ^spa_pod, offset: u32) ---
    spa_pod_builder_raw :: proc(b: ^spa_pod_builder, data: rawptr, size: u32) -> i32 ---
    spa_pod_builder_pad :: proc(b: ^spa_pod_builder, size: u32) -> i32 ---
    spa_pod_builder_raw_padded :: proc(b: ^spa_pod_builder, data: rawptr, size: u32) -> i32 ---
    spa_pod_builder_pop :: proc(b: ^spa_pod_builder, frame: ^spa_pod_frame) -> ^spa_pod ---
    spa_pod_builder_primitive :: proc(b: ^spa_pod_builder, p: ^spa_pod) -> i32 ---
    spa_pod_builder_none :: proc(b: ^spa_pod_builder) -> i32 ---
    spa_pod_builder_child :: proc(b: ^spa_pod_builder, size: u32, type: spa_type) -> i32 ---
    spa_pod_builder_bool :: proc(b: ^spa_pod_builder, val: bool) -> i32 ---
    spa_pod_builder_id :: proc(b: ^spa_pod_builder, val: u32) -> i32 ---
    spa_pod_builder_int :: proc(b: ^spa_pod_builder, val: i32) -> int ---
    spa_pod_builder_long :: proc(b: ^spa_pod_builder, val: i64) -> i32 ---
    spa_pod_builder_float :: proc(b: ^spa_pod_builder, val: f32) -> i32 ---
    spa_pod_builder_double :: proc(b: ^spa_pod_builder, val: f64) -> i32 ---
    spa_pod_builder_write_string :: proc(b: ^spa_pod_builder, str: cstring, len: u32) -> i32 ---
    spa_pod_builder_string_len :: proc(b: ^spa_pod_builder, str: cstring, len: u32) -> i32 ---
    spa_pod_builder_string :: proc(b: ^spa_pod_builder, str: cstring) -> i32 ---
    spa_pod_builder_bytes :: proc(b: ^spa_pod_builder, bytes: rawptr, len: u32) -> i32 ---
    spa_pod_builder_reserve_bytes :: proc(b: ^spa_pod_builder, len: u32) -> rawptr ---
    spa_pod_builder_pointer :: proc(b: ^spa_pod_builder, type: u32, val: rawptr) -> int ---
    spa_pod_builder_fd :: proc(b: ^spa_pod_builder, fd: i64) -> i32 ---
    spa_pod_builder_rectangle :: proc(b: ^spa_pod_builder, w: u32, h: u32) -> i32 ---
    spa_pod_builder_fraction :: proc(b: ^spa_pod_builder, num: u32, denom: u32) -> i32 ---
    spa_pod_builder_push_array :: proc(b: ^spa_pod_builder, frame: ^spa_pod_frame) -> i32 ---
    spa_pod_builder_array :: proc(b: ^spa_pod_builder, child_size: u32, child_type: spa_type, n_elems: u32, elems: rawptr) -> i32 ---
    spa_pod_builder_push_choice :: proc(b: ^spa_pod_builder, frame: ^spa_pod_frame, type: spa_choice_type, flags: SPA_POD_BUILDER_FLAGS) -> i32 ---
    spa_pod_builder_push_struct :: proc(b: ^spa_pod_builder, frame: ^spa_pod_frame) -> i32 ---
    spa_pod_builder_push_object :: proc(b: ^spa_pod_builder, frame: ^spa_pod_frame, type: spa_type, id: spa_param_type) -> i32 ---
    spa_pod_builder_prop :: proc(b: ^spa_pod_builder, key: u32, flags: SPA_POD_BUILDER_FLAGS) -> i32 ---
    spa_pod_builder_push_sequence :: proc(b: ^spa_pod_builder, frame: ^spa_pod_frame, unit: u32) -> i32 ---
    spa_pod_builder_control :: proc(b: ^spa_pod_builder, offset: u32, type: spa_type) -> i32 ---
    spa_choice_from_id :: proc(id: u8) -> spa_choice_type ---
    spa_format_audio_raw_build :: proc(b: ^spa_pod_builder, id: spa_param_type, info: ^spa_audio_info_raw) -> ^spa_pod ---
    // spa_pod_builder_addv :: proc(b: ^spa_pod_builder,#c_vararg args: ..any) -> i32 ---
    // spa_pod_builder_add :: proc(b: ^spa_pod_builder, #c_vararg args: ..any) -> i32 ---
}


spa_dict :: struct {
    flags:   SPA_DICT_FLAGS,
    n_items: u32,
    items:   [^]spa_dict_item,
}

SPA_DICT_FLAGS :: bit_set[SPA_DICT_FLAG;u32]

SPA_DICT_FLAG :: enum {
    SORT,
}

spa_dict_item :: struct {
    key:   cstring,
    value: cstring,
}

spa_chunk :: struct {
    offset: u32,
    size:   u32,
    stride: i32,
    flags:  Spa_Chunk_Flags,
}

Spa_Chunk_Flags :: bit_set[Spa_Chunk_Flag;i32]
Spa_Chunk_Flag :: enum {
    KEY,
    VAL,
}

spa_hook_list :: struct {
    list: spa_list,
}

spa_list :: struct {
    next: ^spa_list,
    prev: ^spa_list,
}


spa_support :: struct {
    type: cstring,
    data: rawptr,
}

spa_system :: struct {
    iface: spa_interface,
}

spa_loop :: struct {
    iface: spa_interface,
}

spa_loop_control :: struct {
    iface: spa_interface,
}

spa_loop_utils :: struct {
    iface: spa_interface,
}

spa_hook :: struct {
    link:    spa_list,
    cb:      spa_callbacks,
    removed: proc "c" (hook: ^spa_hook),
    priv:    rawptr,
}

spa_callbacks :: struct {
    funcs: rawptr,
    data:  rawptr,
}

spa_interface :: struct {
    type:    cstring,
    version: u32,
    cb:      spa_callbacks,
}

spa_type_info :: struct {
    type:   spa_param_type,
    parent: spa_type,
    name:   cstring,
    values: ^spa_type_info,
}

spa_command :: struct {
    pod:  spa_pod,
    body: spa_command_body,
}

spa_command_body :: struct {
    body: spa_pod_object_body,
}
spa_meta :: struct {
    type: u32, /**< metadata type, one of enum spa_meta_type */
    size: u32, /**< size of metadata */
    data: rawptr, /**< pointer to metadata */
}

spa_data_flag :: enum {
    READABLE, /**< data is readable */
    WRITABLE, /**< data is writable */
    DYNAMIC, /**< data pointer can be changed */
    MAPPABLE, /**< data is mappable with simple mmap/munmap. Some memory*/
}

spa_data_flags :: bit_set[spa_data_flag;u32]


SPA_DATA_FLAG_READWRITE :: spa_data_flags{.READABLE, .WRITABLE}

spa_direction :: enum i32 {
    INPUT,
    OUTPUT,
}


spa_data :: struct {
    type:      u32, /**< memory type, one of enum spa_data_type, when
					  *  allocating memory, the type contains a bitmask
					  *  of allowed types. SPA_ID_INVALID is a special
					  *  value for the allocator to indicate that the
					  *  other side did not explicitly specify any
					  *  supported data types. It should probably use
					  *  a memory type that does not require special
					  *  handling in addition to simple mmap/munmap. 
					  *  types are not simply mappable (DmaBuf) unless explicitly
					  *  specified with this flag. */
    flags:     spa_data_flags, /**< data flags */
    fd:        i64, /**< optional fd for data */
    mapoffset: u32, /**< offset to map fd at, this is page aligned */
    maxsize:   u32, /**< max size of data */
    data:      rawptr, /**< optional data pointer */
    chunk:     ^spa_chunk, /**< valid chunk of memory */
}


spa_buffer :: struct {
    n_metas: u32, /**< number of metadata */
    n_datas: u32, /**< number of data members */
    metas:   ^spa_meta, /**< array of metadata */
    datas:   ^spa_data, /**< array of data members */
}

spa_invoke_func_t :: #type proc "c" (
    loop: ^loop,
    async: bool,
    seq: u32,
    data: rawptr,
    size: uint,
    user_data: rawptr,
) -> i32

spa_prop_info :: enum u32 {
    SPA_PROP_INFO_START,
    SPA_PROP_INFO_id,
    SPA_PROP_INFO_name,
    SPA_PROP_INFO_type,
    SPA_PROP_INFO_labels,
    SPA_PROP_INFO_container,
    SPA_PROP_INFO_params,
    SPA_PROP_INFO_description,
}

spa_prop :: enum u32 {
    SPA_PROP_START,
    SPA_PROP_unknown,
    SPA_PROP_START_Device = 0x100,
    SPA_PROP_device,
    SPA_PROP_deviceName,
    SPA_PROP_deviceFd,
    SPA_PROP_card,
    SPA_PROP_cardName,
    SPA_PROP_minLatency,
    SPA_PROP_maxLatency,
    SPA_PROP_periods,
    SPA_PROP_periodSize,
    SPA_PROP_periodEvent,
    SPA_PROP_live,
    SPA_PROP_rate,
    SPA_PROP_quality,
    SPA_PROP_bluetoothAudioCodec,
    SPA_PROP_bluetoothOffloadActive,
    SPA_PROP_START_Audio = 0x10000,
    SPA_PROP_waveType,
    SPA_PROP_frequency,
    SPA_PROP_volume,
    SPA_PROP_mute,
    SPA_PROP_patternType,
    SPA_PROP_ditherType,
    SPA_PROP_truncate,
    SPA_PROP_channelVolumes,
    SPA_PROP_volumeBase,
    SPA_PROP_volumeStep,
    SPA_PROP_channelMap,
    SPA_PROP_monitorMute,
    SPA_PROP_monitorVolumes,
    SPA_PROP_latencyOffsetNsec,
    SPA_PROP_softMute,
    SPA_PROP_softVolumes,
    SPA_PROP_iec958Codecs,
    SPA_PROP_volumeRampSamples,
    SPA_PROP_volumeRampStepSamples,
    SPA_PROP_volumeRampTime,
    SPA_PROP_volumeRampStepTime,
    SPA_PROP_volumeRampScale,
    SPA_PROP_START_Video = 0x20000,
    SPA_PROP_brightness,
    SPA_PROP_contrast,
    SPA_PROP_saturation,
    SPA_PROP_hue,
    SPA_PROP_gamma,
    SPA_PROP_exposure,
    SPA_PROP_gain,
    SPA_PROP_sharpness,
    SPA_PROP_START_Other = 0x80000,
    SPA_PROP_params,
    SPA_PROP_START_CUSTOM = 0x1000000,
}
spa_format :: enum u32 {
    START,
    mediaType,
    mediaSubtype,
    START_Audio = 0x10000,
    AUDIO_format,
    AUDIO_flags,
    AUDIO_rate,
    AUDIO_channels,
    AUDIO_position,
    AUDIO_iec958Codec,
    AUDIO_bitorder,
    AUDIO_interleave,
    AUDIO_bitrate,
    AUDIO_blockAlign,
    AUDIO_AAC_streamFormat,
    AUDIO_WMA_profile,
    AUDIO_AMR_bandMode,
    AUDIO_MP3_channelMode,
    AUDIO_DTS_extType,
    START_Video = 0x20000,
    VIDEO_format,
    VIDEO_modifier,
    VIDEO_size,
    VIDEO_framerate,
    VIDEO_maxFramerate,
    VIDEO_views,
    VIDEO_interlaceMode,
    VIDEO_pixelAspectRatio,
    VIDEO_multiviewMode,
    VIDEO_multiviewFlags,
    VIDEO_chromaSite,
    VIDEO_colorRange,
    VIDEO_colorMatrix,
    VIDEO_transferFunction,
    VIDEO_colorPrimaries,
    VIDEO_profile,
    VIDEO_level,
    VIDEO_H264_streamFormat,
    VIDEO_H264_alignment,
    VIDEO_H265_streamFormat,
    VIDEO_H265_alignment,
    VIDEO_deviceId,
    START_Image = 0x30000,
    START_Binary = 0x40000,
    START_Stream = 0x50000,
    START_Application = 0x60000,
    CONTROL_types,
}


spa_param_type :: enum u32 {
    Invalid,
    PropInfo,
    Props,
    EnumFormat,
    Format,
    Buffers,
    Meta,
    IO,
    EnumProfile,
    Profile,
    EnumPortConfig,
    PortConfig,
    EnumRoute,
    Route,
    Control,
    Latency,
    ProcessLatency,
    Tag,
}

spa_media_type :: enum u32 {
    unknown,
    audio,
    video,
    image,
    binary,
    stream,
    application,
}

spa_media_subtype :: enum u32 {
    unknown,
    raw,
    dsp,
    iec958, /** S/PDIF */
    dsd,
    START_Audio = 0x10000,
    mp3,
    aac,
    vorbis,
    wma,
    ra,
    sbc,
    adpcm,
    g723,
    g726,
    g729,
    amr,
    gsm,
    alac, /** since 0.3.65 */
    flac, /** since 0.3.65 */
    ape, /** since 0.3.65 */
    opus, /** since 0.3.68 */
    ac3, /** since 1.5.1 */
    eac3, /** since 1.5.1 */
    truehd, /** since 1.5.1 */
    dts, /** since 1.5.1 */
    mpegh, /** since 1.5.1 */
    START_Video = 0x20000,
    h264,
    mjpg,
    dv,
    mpegts,
    h263,
    mpeg1,
    mpeg2,
    mpeg4,
    xvid,
    vc1,
    vp8,
    vp9,
    bayer,
    h265,
    START_Image = 0x30000,
    jpeg,
    START_Binary = 0x40000,
    START_Stream = 0x50000,
    midi,
    START_Application = 0x60000,
    control,
}


spa_type :: enum u32 {
    START = 0x00000,
    None,
    Bool,
    Id,
    Int,
    Long,
    Float,
    Double,
    String,
    Bytes,
    Rectangle,
    Fraction,
    Bitmap,
    Array,
    Struct,
    Object,
    Sequence,
    Pointer,
    Fd,
    Choice,
    Pod,
    _LAST, /**< not part of ABI */

    /* Pointers */
    POINTER_START = 0x10000,
    POINTER_Buffer,
    POINTER_Meta,
    POINTER_Dict,
    _POINTER_LAST, /**< not part of ABI */

    /* Events */
    EVENT_START = 0x20000,
    EVENT_Device,
    EVENT_Node,
    _EVENT_LAST, /**< not part of ABI */

    /* Commands */
    COMMAND_START = 0x30000,
    COMMAND_Device,
    COMMAND_Node,
    _COMMAND_LAST, /**< not part of ABI */

    /* Objects */
    OBJECT_START = 0x40000,
    OBJECT_PropInfo,
    OBJECT_Props,
    OBJECT_Format,
    OBJECT_ParamBuffers,
    OBJECT_ParamMeta,
    OBJECT_ParamIO,
    OBJECT_ParamProfile,
    OBJECT_ParamPortConfig,
    OBJECT_ParamRoute,
    OBJECT_Profiler,
    OBJECT_ParamLatency,
    OBJECT_ParamProcessLatency,
    OBJECT_ParamTag,
    _OBJECT_LAST, /**< not part of ABI */

    /* vendor extensions */
    VENDOR_PipeWire = 0x02000000,
    VENDOR_Other = 0x7f000000,
}

spa_type_param_info :: [?]spa_type_info {
    {.Invalid, .None, "Spa:Enum:ParamId:Invalid", nil},
    {.PropInfo, .OBJECT_PropInfo, "Spa:Enum:ParamId:PropInfo", nil},
    {.Props, .OBJECT_Props, "Spa:Enum:ParamId:Props", nil},
    {.EnumFormat, .OBJECT_Format, "Spa:Enum:ParamId:EnumFormat", nil},
    {.Format, .OBJECT_Format, "Spa:Enum:ParamId:Format", nil},
    {.Buffers, .OBJECT_ParamBuffers, "Spa:Enum:ParamId:Buffers", nil},
    {.Meta, .OBJECT_ParamMeta, "Spa:Enum:ParamId:Meta", nil},
    {.IO, .OBJECT_ParamIO, "Spa:Enum:ParamId:IO", nil},
    {.EnumProfile, .OBJECT_ParamProfile, "Spa:Enum:ParamId:EnumProfile", nil},
    {.Profile, .OBJECT_ParamProfile, "Spa:Enum:ParamId:Profile", nil},
    {.EnumPortConfig, .OBJECT_ParamPortConfig, "Spa:Enum:ParamId:EnumPortConfig", nil},
    {.PortConfig, .OBJECT_ParamPortConfig, "Spa:Enum:ParamId:PortConfig", nil},
    {.EnumRoute, .OBJECT_ParamRoute, "Spa:Enum:ParamId:EnumRoute", nil},
    {.Route, .OBJECT_ParamRoute, "Spa:Enum:ParamId:Route", nil},
    {.Control, .Sequence, "Spa:Enum:ParamId:Control", nil},
    {.Latency, .OBJECT_ParamLatency, "Spa:Enum:ParamId:Latency", nil},
    {
        .ProcessLatency,
        .OBJECT_ParamProcessLatency,
        "Spa:Enum:ParamId:ProcessLatency",
        nil,
    },
    {.Tag, .OBJECT_ParamTag, "Spa:Enum:ParamId:Tag", nil},
}

spa_type_info_from_type :: proc(type: spa_param_type) -> (spa_type_info, bool) {
    for info in spa_type_param_info {
        if info.type == type {
            return info, true
        }
    }
    return spa_type_param_info[0], false
}


spa_list_empty :: proc(list: ^spa_list) -> bool {
    assert(spa_list_is_initialized(list))
    return list.next == list.prev
}

spa_list_append :: #force_inline proc "c" (list: ^spa_list, elem: ^spa_list) {
    spa_list_insert(list.prev, elem)
}
list_iterator :: struct($T: typeid) {
    root:   ^spa_list,
    curr:   ^spa_list,
    offset: uintptr,
    index:  int,
}

make_spa_list_iterator :: proc(
    $T: typeid,
    $field_name: string,
    list: ^spa_list,
) -> list_iterator(T) where intrinsics.type_has_field(T, field_name),
    intrinsics.type_field_type(T, field_name) ==
    spa_list {
    return {list, list.next, offset_of_by_string(T, field_name), 0}
}

spa_list_iterator :: proc(iter: ^list_iterator($T)) -> (curr: ^T, index: int, c: bool) {
    index = iter.index
    iter.index += 1
    c = iter.curr != iter.root
    curr = (^T)(uintptr(iter.curr) - iter.offset)
    iter.curr = iter.curr.next
    return
}


spa_list_find :: proc(
    list: ^spa_list,
    $list_field_name: string,
    func: proc(item: ^$T) -> bool,
) -> ^T {

    it := pipewire.make_spa_list_iterator(&list)
    for curr in pipewire.spa_list_iterator(&it) {
        item := container_of(curr, T, list_field_name)
        if func(item) {
            return item
        }
    }
    return nil
}

spa_list_remove_func :: proc(
    $type: typeid,
    list: ^spa_list,
    $list_field_name: string,
    func: proc(item: ^$T) -> bool,
) {
    item := spa_list_find(list, list_field_name, func)

    s_info :: reflect.struct_field_by_name(type, list_field_name)
    link := (^spa_list)(uintptr(&item) + s_info.offset)
    spa_list_remove(link)
}


spa_dict_to_string :: proc(
    dict: ^spa_dict,
    allocator := context.allocator,
    temp_allocator := context.temp_allocator,
) -> string {
    builder: strings.Builder
    strings.builder_init(&builder, allocator)
    for item, idx in dict.items[:dict.n_items] {
        if idx != 0 {
            strings.write_string(&builder, ", ")
        }
        item_str := fmt.aprintf("%#v", item, allocator = temp_allocator)
        strings.write_string(&builder, item_str)
    }

    return strings.to_string(builder)
}

spa_dict_get :: proc(dict: ^spa_dict, key: cstring) -> cstring {
    for item in dict.items[:dict.n_items] {
        if item.key == key {
            return item.value
        }
    }

    return nil
}

