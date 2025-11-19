#+private
package graphic
import win "core:sys/windows"
import "vendor:directx/d3d12"

WaitForGpu :: proc(
    command_queue_to_wait: ^d3d12.ICommandQueue,
    fence_to_used: ^d3d12.IFence,
    fence_value: ^u64,
    fence_event: win.HANDLE,
) {
    ensure_success(command_queue_to_wait->Signal(fence_to_used, fence_value^))
    ensure_success(fence_to_used->SetEventOnCompletion(fence_value^, fence_event))
    win.WaitForSingleObject(fence_event, win.INFINITE)
    fence_value^ += 1
}
