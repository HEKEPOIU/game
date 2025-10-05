package graphic

import "core:log"
import win "core:sys/windows"
import "libs:utilities"
import "vendor:directx/d3d12"
import "vendor:directx/dxgi"

ensure_success :: utilities.ensure_success

FRAME_COUNT :: 2
wait_for_previous_frame :: proc(
    swapchain: ^dxgi.ISwapChain3,
    command_queue: ^d3d12.ICommandQueue,
    fence: ^d3d12.IFence,
    fence_event: win.HANDLE,
    fence_value: ^u64,
    frame_index: ^u32,
) {

    temp_fence := fence_value^
    ensure_success((command_queue->Signal(fence, temp_fence)))
    fence_value^ += 1
    if (fence->GetCompletedValue() < temp_fence) {
        ensure_success((fence->SetEventOnCompletion(temp_fence, fence_event)))
        win.WaitForSingleObject(fence_event, win.INFINITE)
    }
    frame_index^ = swapchain->GetCurrentBackBufferIndex()
}

render_context :: struct {
    // TODO: Factory6 support start from windows 10 1803 (2018/04),
    //       We need to check support range of windows version,
    //       and maybe need to follow Dx12Example case that use Factory4 to Support more windows version.
    factory:             ^dxgi.IFactory6,
    device:              ^d3d12.IDevice,
    command_queue:       ^d3d12.ICommandQueue,
    swap_chain:          ^dxgi.ISwapChain3,
    rtv_heap:            ^d3d12.IDescriptorHeap,
    command_allocator:   ^d3d12.ICommandAllocator,
    command_list:        ^d3d12.IGraphicsCommandList,
    fence:               ^d3d12.IFence,
    render_targets:      [FRAME_COUNT]^d3d12.IResource,
    fence_value:         u64,
    fence_event:         win.HANDLE,
    frame_index:         u32,
    rtv_descriptor_size: win.UINT,
}


init_render_context :: proc(using ctx: ^render_context, hwd: win.HWND) {
    load_pipeline(ctx, hwd)
    load_assets(ctx)
}

load_pipeline :: proc(using ctx: ^render_context, hwd: win.HWND) {
    dxgi_factory_flags: dxgi.CREATE_FACTORY = {}
    when ODIN_DEBUG {
        {
            debug_controller: ^d3d12.IDebug5
            if win.SUCCEEDED(
                d3d12.GetDebugInterface(d3d12.IDebug5_UUID, (^rawptr)(&debug_controller)),
            ) {
                defer debug_controller->Release()
                debug_controller->EnableDebugLayer()
                debug_controller->SetEnableGPUBasedValidation(true)
                debug_controller->SetEnableSynchronizedCommandQueueValidation(true)
                debug_controller->SetEnableAutoName(true)
                dxgi_factory_flags = {.DEBUG}
            }
        }
    }

    ensure_success(
        dxgi.CreateDXGIFactory2(dxgi_factory_flags, dxgi.IFactory6_UUID, (^rawptr)(&factory)),
        "Failed to create IFactory6",
    )

    {     // Get Device
        hardware_adapter: ^dxgi.IAdapter4
        temp_adapter: ^dxgi.IAdapter4
        target_feature_level := d3d12.FEATURE_LEVEL._11_1
        for i := win.UINT(0);
            win.SUCCEEDED(
                factory->EnumAdapterByGpuPreference(
                    i,
                    dxgi.GPU_PREFERENCE.HIGH_PERFORMANCE,
                    dxgi.IAdapter4_UUID,
                    (^rawptr)(&temp_adapter),
                ),
            );
            i += 1 {
            defer temp_adapter->Release()
            desc: dxgi.ADAPTER_DESC3
            temp_adapter->GetDesc3(&desc)
            if (.SOFTWARE in desc.Flags) {
                continue
            }
            if (win.SUCCEEDED(
                       d3d12.CreateDevice(
                           temp_adapter,
                           target_feature_level,
                           d3d12.IDevice_UUID,
                           nil,
                       ),
                   )) {
                log.infof("Select GPU: {}", cstring16(&desc.Description[0]))
                hardware_adapter = temp_adapter
                hardware_adapter->AddRef()
                break
            }
        }
        ensure_success(
            d3d12.CreateDevice(
                hardware_adapter,
                target_feature_level,
                d3d12.IDevice_UUID,
                (^rawptr)(&device),
            ),
        )

        hardware_adapter->Release()
    }
    queue_desc := d3d12.COMMAND_QUEUE_DESC {
        Flags = {},
        Type  = .DIRECT,
    }
    ensure_success(
        device->CreateCommandQueue(
            &queue_desc,
            d3d12.ICommandQueue_UUID,
            (^rawptr)(&command_queue),
        ),
        "Failed to create command queue",
    )
    {
        temp_swap_chain: ^dxgi.ISwapChain1
        swap_chain_desc := dxgi.SWAP_CHAIN_DESC1 {
            BufferCount = 2,
            // Width = WIDTH,
            // Height = HEIGHT,
            Format = .R8G8B8A8_UNORM, // Sine normalize interger
            BufferUsage = {.RENDER_TARGET_OUTPUT},
            SwapEffect = .FLIP_DISCARD,
            // Based on docs, SampleDesc only useful for bit-block transfer (bitblt) model swap chains.
            // So we set it to default value from docs.
            SampleDesc = {Count = 1},
        }
        ensure_success(
            factory->CreateSwapChainForHwnd(
                command_queue,
                hwd,
                &swap_chain_desc,
                nil,
                nil,
                &temp_swap_chain,
            ),
            "Failed to create swap chain, maybe out of memory or other unknown error",
        )

        defer temp_swap_chain->Release()
        factory->MakeWindowAssociation(hwd, {.NO_ALT_ENTER})
        ensure_success(
            temp_swap_chain->QueryInterface(dxgi.ISwapChain3_UUID, (^rawptr)(&swap_chain)),
            "Device not support SwapChain3",
        )

    }
    frame_index = swap_chain->GetCurrentBackBufferIndex()

    // Reneder Target View(RTV)
    {     // Create descriptor heaps
        rtv_heap_desc := d3d12.DESCRIPTOR_HEAP_DESC {
            NumDescriptors = FRAME_COUNT,
            Type           = .RTV,
            Flags          = {},
        }
        ensure_success(
            device->CreateDescriptorHeap(
                &rtv_heap_desc,
                d3d12.IDescriptorHeap_UUID,
                (^rawptr)(&rtv_heap),
            ),
        )
        rtv_descriptor_size = device->GetDescriptorHandleIncrementSize(.RTV)
    }
    {
        rtv_handle: d3d12.CPU_DESCRIPTOR_HANDLE
        // On C++ binding, this use return value not out parameter
        rtv_heap->GetCPUDescriptorHandleForHeapStart(&rtv_handle)

        for f: u32; f < FRAME_COUNT; f += 1 {
            ensure_success(
                swap_chain->GetBuffer(f, d3d12.IResource_UUID, (^rawptr)(&render_targets[f])),
            )

            device->CreateRenderTargetView(render_targets[f], nil, rtv_handle)
            offset_desc_handle(&rtv_handle, 1, rtv_descriptor_size)
        }

    }

    ensure_success(
        device->CreateCommandAllocator(
            .DIRECT,
            d3d12.ICommandAllocator_UUID,
            (^rawptr)(&command_allocator),
        ),
    )
}
load_assets :: proc(using ctx: ^render_context) {
    ensure_success(
        device->CreateCommandList(
            0,
            .DIRECT,
            command_allocator,
            nil,
            d3d12.IGraphicsCommandList_UUID,
            (^rawptr)(&command_list),
        ),
    )
    // Record commands in between
    command_list->Close()
    {
        ensure_success(device->CreateFence(0, {}, d3d12.IFence_UUID, (^rawptr)(&fence)))
    }
    fence_value = 1

    fence_event = win.CreateEventW(nil, false, false, nil)
    if fence_event == nil {
        log.errorf("{}", win.HRESULT_FROM_WIN32(win.GetLastError()))
        ensure(false, "Failed to create fence event")
    }
}

populate_command_list :: proc(using ctx: ^render_context) {
    ensure_success(command_allocator->Reset())
    ensure_success(command_list->Reset(command_allocator, nil))

    barrier_to_render_target := transition(render_targets[frame_index], {}, {.RENDER_TARGET})
    command_list->ResourceBarrier(1, &barrier_to_render_target)

    rtv_handle: d3d12.CPU_DESCRIPTOR_HANDLE
    rtv_heap->GetCPUDescriptorHandleForHeapStart(&rtv_handle)
    offset_desc_handle(&rtv_handle, (i32)(frame_index), rtv_descriptor_size)

    clear_Color := [4]f32{0.0, 0.2, 0.4, 1.0}
    command_list->ClearRenderTargetView(rtv_handle, &clear_Color, 0, nil)

    barrier_to_present := transition(render_targets[frame_index], {.RENDER_TARGET}, {})
    command_list->ResourceBarrier(1, &barrier_to_present)
    ensure_success(command_list->Close())
}

render :: proc(using ctx: ^render_context) {
    populate_command_list(ctx)
    command_lists := []^d3d12.ICommandList{command_list}
    command_queue->ExecuteCommandLists(u32(len(command_lists)), raw_data(command_lists))

    ensure_success(swap_chain->Present(0, {}))

    wait_for_previous_frame(
        swap_chain,
        command_queue,
        fence,
        fence_event,
        &fence_value,
        &frame_index,
    )
}

destroy_render_context :: proc(using ctx: ^render_context) {
    wait_for_previous_frame(
        swap_chain,
        command_queue,
        fence,
        fence_event,
        &fence_value,
        &frame_index,
    )
    win.CloseHandle(fence_event)
    fence->Release()
    command_list->Release()
    command_allocator->Release()
    for f: u32; f < FRAME_COUNT; f += 1 {
        render_targets[f]->Release()
    }
    rtv_heap->Release()
    swap_chain->Release()
    command_queue->Release()
    debugDevice: ^d3d12.IDebugDevice1
    if (win.SUCCEEDED(device->QueryInterface(d3d12.IDebugDevice1_UUID, (^rawptr)(&debugDevice)))) {
        debugDevice->ReportLiveDeviceObjects({.IGNORE_INTERNAL, .DETAIL})
        debugDevice->Release()
    }
    device->Release()
    factory->Release()
}
