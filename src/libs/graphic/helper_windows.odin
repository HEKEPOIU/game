package graphic

import win "core:sys/windows"
import "vendor:directx/d3d12"
import "vendor:directx/dxgi"


@(private)
offset_desc_handle :: proc(base: ^d3d12.CPU_DESCRIPTOR_HANDLE, offset: i32, increment_size: u32) {
    base^ = d3d12.CPU_DESCRIPTOR_HANDLE {
        ptr = win.SIZE_T(i64(base.ptr) + i64(offset) * i64(increment_size)),
    }
}

@(private)
transition :: proc(
    resource: ^d3d12.IResource,
    before_state: d3d12.RESOURCE_STATES,
    after_state: d3d12.RESOURCE_STATES,
    subresource: u32 = d3d12.RESOURCE_BARRIER_ALL_SUBRESOURCES,
    flags: d3d12.RESOURCE_BARRIER_FLAGS = {},
) -> d3d12.RESOURCE_BARRIER {
    barrier := d3d12.RESOURCE_BARRIER {
        Type = .TRANSITION,
        Flags = flags,
        Transition = {
            pResource = resource,
            StateBefore = before_state,
            StateAfter = after_state,
            Subresource = subresource,
        },
    }
    return barrier
}
