package graphic

import "base:intrinsics"
import "core:log"
import "core:mem"
import win "core:sys/windows"
import "vendor:directx/d3d12"


//NOTE:
// The Uploader module is to upload data via intermediate buffer to the gpu.
// This class should not be exposed to render engine api users,
// because platform have UMA architecture may not need upload heap(Need to check).

@(private)
Upload_Item_Map :: map[^d3d12.IResource]Upload_Item

@(private)
Upload_Item :: struct {
    subresources:  [dynamic]d3d12.SUBRESOURCE_DATA,
    resource_type: d3d12.RESOURCE_STATES,
    total_size:    u64,
}

@(private)
Resource_Uploader :: struct {
    intermediate_heap: ^d3d12.IResource,
    upload_map:        Upload_Item_Map,
    transition_map:    map[^d3d12.IResource]d3d12.RESOURCE_STATES,
    allocator:         mem.Allocator,
}

@(private)
create_upload_buffer :: proc(
    device: ^d3d12.IDevice,
    upload_heap_size: u64,
    resource: ^^d3d12.IResource,
) -> (
    ok: bool,
) {
    upload_heap_prop := get_heap_properties(.UPLOAD)

    // The Upload buffer always 1 dimensional
    resource_buffer_desc := get_buffer_resource_desc(upload_heap_size)
    return(
        device->CreateCommittedResource(
            &upload_heap_prop,
            {},
            &resource_buffer_desc,
            d3d12.RESOURCE_STATE_GENERIC_READ,
            nil,
            d3d12.IResource_UUID,
            (^rawptr)(resource),
        ) ==
        win.S_OK \
    )
}


@(private)
init_uploader :: proc(
    device: ^d3d12.IDevice,
    uploader: ^Resource_Uploader,
    size: u64,
    allocator := context.allocator,
) {
    ensure(create_upload_buffer(device, size, &uploader.intermediate_heap))
    uploader.allocator = allocator
    uploader.upload_map = {}
    uploader.transition_map = {}
}

@(private)
push_item :: proc(
    uploader: ^Resource_Uploader,
    resource: ^d3d12.IResource,
    subresource: d3d12.SUBRESOURCE_DATA,
    data_size: u64,
) {
    context.allocator = uploader.allocator
    target: ^Upload_Item
    if resource not_in uploader.upload_map {
        uploader.upload_map[resource] = {}
        target = &uploader.upload_map[resource]
        target.subresources = make([dynamic]d3d12.SUBRESOURCE_DATA)
    }

    append(&target.subresources, subresource)
    target.total_size += data_size
}

@(private)
set_resource_transition :: proc(
    uploader: ^Resource_Uploader,
    resource: ^d3d12.IResource,
    transition: d3d12.RESOURCE_STATES,
) {
    assert(resource not_in uploader.transition_map)
    uploader.transition_map[resource] = transition
}

@(private)
upload_resources :: proc(
    device: ^d3d12.IDevice,
    command_list: ^d3d12.IGraphicsCommandList,
    uploader: ^Resource_Uploader,
) {
    assert(len(uploader.upload_map) == len(uploader.transition_map))
    offset: u64 = 0
    for k, v in uploader.upload_map {
        update_subresources_from_stack(
            command_list,
            k,
            uploader.intermediate_heap,
            offset,
            0,
            u32(len(v.subresources)),
            v.subresources[:],
        )
        offset += v.total_size

        barrier := transition(k, {.COPY_DEST}, v.resource_type)
        command_list->ResourceBarrier(1, &barrier)
    }
}

@(private)
flush_resources :: #force_inline proc(
    device: ^d3d12.IDevice,
    command_list: ^d3d12.IGraphicsCommandList,
    uploader: ^Resource_Uploader,
) {
    upload_resources(device, command_list, uploader)
    clear(&uploader.upload_map)
    clear(&uploader.transition_map)
}

@(private)
release_uploader :: proc(uploader: ^Resource_Uploader) {
    uploader.intermediate_heap->Release()
    for k, v in uploader.upload_map {
        delete(v.subresources)
    }
    delete(uploader.upload_map)
    delete(uploader.transition_map)
}
