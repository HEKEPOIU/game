#+feature using-stmt
#+private
package graphic

import "base:intrinsics"
import "core:log"
import "core:mem"
import win "core:sys/windows"
import "vendor:directx/d3d12"


//NOTE:
// The Uploader module is to upload data via intermediate buffer to the gpu.
// This class should not be exposed to render engine api users,
// because some computer or system(mac) have UMA architecture may not need upload heap(Need to profile the performance).

// This Uploader use intermediate_heap as liner arena to store all the data,
// and Currently it only support submit at a time.

Upload_Item_Map :: map[^d3d12.IResource]Upload_Item

Upload_Item :: struct {
    subresources:  [dynamic]d3d12.SUBRESOURCE_DATA,
    resource_type: d3d12.RESOURCE_STATES,
    total_size:    u64,
}

Resource_Uploader :: struct {
    copy_queue:            ^d3d12.ICommandQueue,
    copy_allocator:        ^d3d12.ICommandAllocator,
    copy_command_list:     ^d3d12.IGraphicsCommandList,
    copy_fence:            ^d3d12.IFence,
    next_fence_value:      u64,
    on_flight_fence_value: u64,
    copy_fence_event:      win.HANDLE,
    intermediate_heap:     ^d3d12.IResource,
    upload_map:            Upload_Item_Map,
    transition_map:        map[^d3d12.IResource]d3d12.RESOURCE_STATES,
    data_allocator:        mem.Allocator,
    used_buffer_size:      u64,
    total_buffer_size:     u64,
}

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


init_uploader :: proc(
    using uploader: ^Resource_Uploader,
    device: ^d3d12.IDevice,
    size: u64,
    allocator := context.allocator,
) {

    copy_queue_desc := d3d12.COMMAND_QUEUE_DESC {
        Type = .COPY,
    }
    ensure_success(
        device->CreateCommandQueue(
            &copy_queue_desc,
            d3d12.ICommandQueue_UUID,
            (^rawptr)(&copy_queue),
        ),
    )

    ensure_success(
        device->CreateCommandAllocator(
            .COPY,
            d3d12.ICommandAllocator_UUID,
            (^rawptr)(&copy_allocator),
        ),
    )

    ensure_success(
        device->CreateCommandList(
            0,
            .COPY,
            copy_allocator,
            nil,
            d3d12.IGraphicsCommandList_UUID,
            (^rawptr)(&copy_command_list),
        ),
    )
    copy_command_list->Close()

    ensure_success(
        device->CreateFence(
            0, // Initial value
            {},
            d3d12.IFence_UUID,
            (^rawptr)(&copy_fence),
        ),
    )

    copy_fence_event = win.CreateEventW(nil, false, false, nil)
    if copy_fence_event == nil {
        log.errorf("{}", win.HRESULT_FROM_WIN32(win.GetLastError()))
        ensure(false, "Failed to create fence event")
    }


    next_fence_value = 1
    total_buffer_size = size
    ensure(create_upload_buffer(device, total_buffer_size, &intermediate_heap))
    data_allocator = allocator
}

push_item :: proc(
    using uploader: ^Resource_Uploader,
    resource: ^d3d12.IResource,
    subresource: d3d12.SUBRESOURCE_DATA,
    data_size: u64,
) {
    if !is_finished(uploader, on_flight_fence_value) {
        update_uploader(uploader)
    }

    assert(used_buffer_size + data_size <= uploader.total_buffer_size, "buffer is full")

    resource->AddRef()
    context.allocator = data_allocator
    target: ^Upload_Item
    if resource not_in upload_map {
        upload_map[resource] = {}
        target = &upload_map[resource]
        target.subresources = make([dynamic]d3d12.SUBRESOURCE_DATA)
    }

    append(&target.subresources, subresource)
    target.total_size += data_size
    used_buffer_size += data_size

}

set_resource_transition :: proc(
    using uploader: ^Resource_Uploader,
    resource: ^d3d12.IResource,
    transition: d3d12.RESOURCE_STATES,
) {
    assert(resource not_in transition_map)
    transition_map[resource] = transition
}

@(private = "file")
upload_resources :: proc(using uploader: ^Resource_Uploader, device: ^d3d12.IDevice) {
    assert(len(uploader.upload_map) == len(uploader.transition_map))

    ensure_success(copy_allocator->Reset())
    ensure_success(copy_command_list->Reset(copy_allocator, nil))
    offset: u64 = 0
    for k, v in uploader.upload_map {
        update_subresources_from_stack(
            copy_command_list,
            k,
            uploader.intermediate_heap,
            offset,
            0,
            u32(len(v.subresources)),
            v.subresources[:],
        )
        offset += v.total_size

        barrier := transition(k, {.COPY_DEST}, v.resource_type)
        copy_command_list->ResourceBarrier(1, &barrier)
    }

    ensure_success(copy_command_list->Close())
    command_lists := []^d3d12.ICommandList{copy_command_list}
    copy_queue->ExecuteCommandLists(u32(len(command_lists)), raw_data(command_lists))
}

// check fence value is completed, must be call somewhere, whatever update function or in separate thread
update_uploader :: proc(using uploader: ^Resource_Uploader) {
    complete_fence_value := copy_fence->GetCompletedValue()
    if complete_fence_value >= next_fence_value {
        next_fence_value = complete_fence_value + 1
        clear_uploader(uploader)
    }
}

flush_resources_block :: #force_inline proc(
    using uploader: ^Resource_Uploader,
    device: ^d3d12.IDevice,
) {
    if !is_finished(uploader, on_flight_fence_value) {
        update_uploader(uploader)
    }
    upload_resources(uploader, device)

    WaitForGpu(copy_queue, copy_fence, &next_fence_value, copy_fence_event)

    clear_uploader(uploader)
}

flush_resources :: #force_inline proc(
    using uploader: ^Resource_Uploader,
    device: ^d3d12.IDevice,
) -> u64 {
    if !is_finished(uploader, on_flight_fence_value) {
        update_uploader(uploader)
    }

    upload_resources(uploader, device)

    on_flight_fence_value = next_fence_value
    ensure_success(copy_queue->Signal(copy_fence, on_flight_fence_value))
    ensure_success(copy_fence->SetEventOnCompletion(on_flight_fence_value, copy_fence_event))

    return on_flight_fence_value
}

@(private = "file")
clear_uploader :: proc(using uploader: ^Resource_Uploader) {
    for k, v in upload_map {
        k->Release()
    }
    clear(&upload_map)
    clear(&transition_map)
    used_buffer_size = 0
}

is_finished :: proc(using uploader: ^Resource_Uploader, handle: u64) -> bool {
    return uploader.next_fence_value > handle
}

release_uploader :: proc(using uploader: ^Resource_Uploader) {
    WaitForGpu(copy_queue, copy_fence, &next_fence_value, copy_fence_event)
    intermediate_heap->Release()
    for k, v in upload_map {
        k->Release()
        delete(v.subresources)
    }
    delete(upload_map)
    delete(transition_map)
    win.CloseHandle(copy_fence_event)
    copy_fence->Release()
    copy_command_list->Release()
    copy_allocator->Release()
    copy_queue->Release()
}
