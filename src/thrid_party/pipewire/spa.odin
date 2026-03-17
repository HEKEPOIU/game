package pipewire

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:reflect"
import "core:slice"
import "core:strings"

spa_dict :: struct {
    flags:   SPA_DICT_FLAGS,
    n_items: u32,
    items:   [^]spa_dict_item,
}

SPA_DICT_FLAGS :: bit_set[SPA_DICT_FLAG]

SPA_DICT_FLAG :: enum u32 {
    SORT = 1 << 0,
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

Spa_Chunk_Flags :: bit_set[Spa_Chunk_Flag]
Spa_Chunk_Flag :: enum i32 {
    NONE = 0,
    KEY  = 1 << 0,
    VAL  = 1 << 1,
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

spa_param_type :: enum u32 {
    SPA_PARAM_Invalid,
    SPA_PARAM_PropInfo,
    SPA_PARAM_Props,
    SPA_PARAM_EnumFormat,
    SPA_PARAM_Format,
    SPA_PARAM_Buffers,
    SPA_PARAM_Meta,
    SPA_PARAM_IO,
    SPA_PARAM_EnumProfile,
    SPA_PARAM_Profile,
    SPA_PARAM_EnumPortConfig,
    SPA_PARAM_PortConfig,
    SPA_PARAM_EnumRoute,
    SPA_PARAM_Route,
    SPA_PARAM_Control,
    SPA_PARAM_Latency,
    SPA_PARAM_ProcessLatency,
    SPA_PARAM_Tag,
}

spa_type :: enum u32 {
    SPA_TYPE_START = 0x00000,
    SPA_TYPE_None,
    SPA_TYPE_Bool,
    SPA_TYPE_Id,
    SPA_TYPE_Int,
    SPA_TYPE_Long,
    SPA_TYPE_Float,
    SPA_TYPE_Double,
    SPA_TYPE_String,
    SPA_TYPE_Bytes,
    SPA_TYPE_Rectangle,
    SPA_TYPE_Fraction,
    SPA_TYPE_Bitmap,
    SPA_TYPE_Array,
    SPA_TYPE_Struct,
    SPA_TYPE_Object,
    SPA_TYPE_Sequence,
    SPA_TYPE_Pointer,
    SPA_TYPE_Fd,
    SPA_TYPE_Choice,
    SPA_TYPE_Pod,
    _SPA_TYPE_LAST, /**< not part of ABI */

    /* Pointers */
    SPA_TYPE_POINTER_START = 0x10000,
    SPA_TYPE_POINTER_Buffer,
    SPA_TYPE_POINTER_Meta,
    SPA_TYPE_POINTER_Dict,
    _SPA_TYPE_POINTER_LAST, /**< not part of ABI */

    /* Events */
    SPA_TYPE_EVENT_START = 0x20000,
    SPA_TYPE_EVENT_Device,
    SPA_TYPE_EVENT_Node,
    _SPA_TYPE_EVENT_LAST, /**< not part of ABI */

    /* Commands */
    SPA_TYPE_COMMAND_START = 0x30000,
    SPA_TYPE_COMMAND_Device,
    SPA_TYPE_COMMAND_Node,
    _SPA_TYPE_COMMAND_LAST, /**< not part of ABI */

    /* Objects */
    SPA_TYPE_OBJECT_START = 0x40000,
    SPA_TYPE_OBJECT_PropInfo,
    SPA_TYPE_OBJECT_Props,
    SPA_TYPE_OBJECT_Format,
    SPA_TYPE_OBJECT_ParamBuffers,
    SPA_TYPE_OBJECT_ParamMeta,
    SPA_TYPE_OBJECT_ParamIO,
    SPA_TYPE_OBJECT_ParamProfile,
    SPA_TYPE_OBJECT_ParamPortConfig,
    SPA_TYPE_OBJECT_ParamRoute,
    SPA_TYPE_OBJECT_Profiler,
    SPA_TYPE_OBJECT_ParamLatency,
    SPA_TYPE_OBJECT_ParamProcessLatency,
    SPA_TYPE_OBJECT_ParamTag,
    _SPA_TYPE_OBJECT_LAST, /**< not part of ABI */

    /* vendor extensions */
    SPA_TYPE_VENDOR_PipeWire = 0x02000000,
    SPA_TYPE_VENDOR_Other = 0x7f000000,
}

spa_type_param_info :: [?]spa_type_info {
    {.SPA_PARAM_Invalid, .SPA_TYPE_None, "Spa:Enum:ParamId:Invalid", nil},
    {.SPA_PARAM_PropInfo, .SPA_TYPE_OBJECT_PropInfo, "Spa:Enum:ParamId:PropInfo", nil},
    {.SPA_PARAM_Props, .SPA_TYPE_OBJECT_Props, "Spa:Enum:ParamId:Props", nil},
    {.SPA_PARAM_EnumFormat, .SPA_TYPE_OBJECT_Format, "Spa:Enum:ParamId:EnumFormat", nil},
    {.SPA_PARAM_Format, .SPA_TYPE_OBJECT_Format, "Spa:Enum:ParamId:Format", nil},
    {.SPA_PARAM_Buffers, .SPA_TYPE_OBJECT_ParamBuffers, "Spa:Enum:ParamId:Buffers", nil},
    {.SPA_PARAM_Meta, .SPA_TYPE_OBJECT_ParamMeta, "Spa:Enum:ParamId:Meta", nil},
    {.SPA_PARAM_IO, .SPA_TYPE_OBJECT_ParamIO, "Spa:Enum:ParamId:IO", nil},
    {.SPA_PARAM_EnumProfile, .SPA_TYPE_OBJECT_ParamProfile, "Spa:Enum:ParamId:EnumProfile", nil},
    {.SPA_PARAM_Profile, .SPA_TYPE_OBJECT_ParamProfile, "Spa:Enum:ParamId:Profile", nil},
    {
        .SPA_PARAM_EnumPortConfig,
        .SPA_TYPE_OBJECT_ParamPortConfig,
        "Spa:Enum:ParamId:EnumPortConfig",
        nil,
    },
    {.SPA_PARAM_PortConfig, .SPA_TYPE_OBJECT_ParamPortConfig, "Spa:Enum:ParamId:PortConfig", nil},
    {.SPA_PARAM_EnumRoute, .SPA_TYPE_OBJECT_ParamRoute, "Spa:Enum:ParamId:EnumRoute", nil},
    {.SPA_PARAM_Route, .SPA_TYPE_OBJECT_ParamRoute, "Spa:Enum:ParamId:Route", nil},
    {.SPA_PARAM_Control, .SPA_TYPE_Sequence, "Spa:Enum:ParamId:Control", nil},
    {.SPA_PARAM_Latency, .SPA_TYPE_OBJECT_ParamLatency, "Spa:Enum:ParamId:Latency", nil},
    {
        .SPA_PARAM_ProcessLatency,
        .SPA_TYPE_OBJECT_ParamProcessLatency,
        "Spa:Enum:ParamId:ProcessLatency",
        nil,
    },
    {.SPA_PARAM_Tag, .SPA_TYPE_OBJECT_ParamTag, "Spa:Enum:ParamId:Tag", nil},
}

spa_type_info_from_type :: proc(type: spa_param_type) -> (spa_type_info, bool) {
    for info in spa_type_param_info {
        if info.type == type {
            return info, true
        }
    }
    return spa_type_param_info[0], false
}

spa_list_init :: proc "c" (list: ^spa_list) {
    list^ = {list, list}
}

spa_list_is_initialized :: proc "c" (list: ^spa_list) -> bool {
    return list.prev != nil
}

spa_list_remove :: proc "c" (elem: ^spa_list) {
    elem.prev.next = elem.next
    elem.next.prev = elem.prev
}

spa_list_insert :: proc "c" (list: ^spa_list, elem: ^spa_list) {
    elem.prev = list
    elem.next = list.next
    list.next.prev = elem
    list.next = elem
}

spa_list_append :: #force_inline proc "c" (list: ^spa_list, elem: ^spa_list) {
    spa_list_insert(list.prev, elem)
}
list_iterator :: struct {
    index: int,
    root:  ^spa_list,
    curr:  ^spa_list,
    next:  ^spa_list,
}

make_spa_list_iterator :: proc(list: ^spa_list) -> list_iterator {
    return list_iterator{0, list, list, list.next}
}

spa_list_iterator :: proc(
    iter: ^list_iterator,
) -> (
    curr: ^spa_list,
    next: ^spa_list,
    index: int,
    c: bool,
) {

    index = iter.index

    iter.curr = iter.next
    iter.next = iter.curr.next
    iter.index += 1
    c = iter.curr != iter.root

    curr = iter.curr
    next = iter.next
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


spa_hook_remove :: proc "c" (hook: ^spa_hook) {
    if spa_list_is_initialized(&hook.link) {
        spa_list_remove(&hook.link)
    }
    if (hook.removed != nil) {
        hook.removed(hook)
    }
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

spa_dict_lookup_item :: proc(dict: ^spa_dict, key: cstring) -> ^spa_dict_item {

    item_slice := slice.from_ptr(dict.items, int(dict.n_items))

    if .SORT in dict.flags && dict.n_items > 0 {
        index, found := slice.binary_search_by(item_slice, key, proc(item: spa_dict_item, key: cstring) -> slice.Ordering {
            if key > item.key do return .Greater
            else if key < item.key do return .Less
            else do return .Equal

        })
        return &item_slice[index]
    } else {
        for &i in item_slice {
            if i.key == key do return &i
        }

    }

    return nil
}

spa_dict_lookup :: proc(dict: ^spa_dict, key: cstring) -> cstring {
    item := spa_dict_lookup_item(dict, key)
    return item != nil ? item.value : nil
}

