package graphic

import "core:log"
import "core:math/linalg"
import "core:mem"
import win "core:sys/windows"
import "libs:utilities"
import "vendor:directx/d3d12"
import d3dc "vendor:directx/d3d_compiler"
import "vendor:directx/dxgi"
import "base:runtime"

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

//TODO: Pass own temp allocator and allocator to that it manage by render system
Render_Context :: struct {
    // TODO: Factory6 support start from windows 10 1803 (2018/04),
    //       We need to check support range of windows version,
    //       and maybe need to follow Dx12Example case that use Factory4 to Support more windows version.
    // TODO: Move out this
    get_asset:           Get_Asset_Func,
    factory:             ^dxgi.IFactory6,
    device:              ^d3d12.IDevice,
    command_queue:       ^d3d12.ICommandQueue,
    swap_chain:          ^dxgi.ISwapChain3,
    rtv_heap:            ^d3d12.IDescriptorHeap,
    command_allocator:   ^d3d12.ICommandAllocator,
    command_list:        ^d3d12.IGraphicsCommandList,
    fence:               ^d3d12.IFence,
    root_signature:      ^d3d12.IRootSignature,
    pipeline_state:      ^d3d12.IPipelineState,
    vertex_buffer:       ^d3d12.IResource,
    vertex_buffer_view:  d3d12.VERTEX_BUFFER_VIEW,
    viewport:            d3d12.VIEWPORT,
    scissor_rect:        d3d12.RECT,
    render_targets:      [FRAME_COUNT]^d3d12.IResource,
    fence_value:         u64,
    fence_event:         win.HANDLE,
    frame_index:         u32,
    rtv_descriptor_size: win.UINT,
    aspect_ratio:        f32,
}

Get_Asset_Func :: proc(
    asset: string,
    allocator := context.allocator,
) -> (
    res: string,
    err: mem.Allocator_Error,
)


init_render_context :: proc(
    using ctx: ^Render_Context,
    hwd: win.HWND,
    get_asset_func: Get_Asset_Func,
    height: u32,
    width: u32,
) {
    get_asset = get_asset_func
    aspect_ratio = f32(width) / f32(height)
    viewport = {
        Width  = f32(width),
        Height = f32(height),
    }
    scissor_rect = {
        right  = i32(width),
        bottom = i32(height),
    }
    load_pipeline(ctx, hwd, height, width)
    load_assets(ctx)
}

load_pipeline :: proc(using ctx: ^Render_Context, hwd: win.HWND, height: u32, width: u32) {
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
            Width = width,
            Height = height,
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


load_assets :: proc(using ctx: ^Render_Context) {
    {     // Create empty root signature
        root_signature_desc := d3d12.ROOT_SIGNATURE_DESC {
            Flags = {.ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT},
        }
        signature: ^d3d12.IBlob
        ensure_success(d3d12.SerializeRootSignature(&root_signature_desc, ._1, &signature, nil))
        defer signature->Release()
        ensure_success(
            device->CreateRootSignature(
                0,
                signature->GetBufferPointer(),
                signature->GetBufferSize(),
                d3d12.IRootSignature_UUID,
                (^rawptr)(&root_signature),
            ),
        )
    }

    {
        //WARN: This buildin function only work for default temp allocator
        runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
        vertex_shader: ^d3d12.IBlob
        pixel_shader: ^d3d12.IBlob

        compile_flags: d3dc.D3DCOMPILE
        when ODIN_DEBUG {
            compile_flags = {.DEBUG, .SKIP_OPTIMIZATION}
        }
        shader_path, err := get_asset("base_shader.hlsl", context.temp_allocator)
        ensure(err == .None, "Failed to get shader")
        p := win.utf8_to_utf16_alloc(shader_path)
        ensure_success(
            d3dc.CompileFromFile(
                raw_data(p),
                nil,
                nil,
                "VSMain",
                "vs_5_0",
                transmute(u32)(compile_flags),
                0,
                &vertex_shader,
                nil,
            ),
        )
        ensure_success(
            d3dc.CompileFromFile(
                raw_data(p),
                nil,
                nil,
                "PSMain",
                "ps_5_0",
                transmute(u32)(compile_flags),
                0,
                &pixel_shader,
                nil,
            ),
        )
        defer vertex_shader->Release()
        defer pixel_shader->Release()

        input_element_descs := []d3d12.INPUT_ELEMENT_DESC {
            {
                SemanticName         = "POSITION", // vertex shader input Binding
                SemanticIndex        = 0,
                Format               = .R32G32B32_FLOAT,
                InputSlot            = 0,
                AlignedByteOffset    = 0,
                InputSlotClass       = .PER_VERTEX_DATA,
                InstanceDataStepRate = 0,
            },
            {
                SemanticName = "COLOR",
                SemanticIndex = 0,
                Format = .R32G32B32A32_FLOAT,
                InputSlot = 0,
                AlignedByteOffset = d3d12.APPEND_ALIGNED_ELEMENT,
                InputSlotClass = .PER_VERTEX_DATA,
                InstanceDataStepRate = 0,
            },
        }

        pso_desc := d3d12.GRAPHICS_PIPELINE_STATE_DESC {
            InputLayout = {
                pInputElementDescs = raw_data(input_element_descs),
                NumElements = u32(len(input_element_descs)),
            },
            pRootSignature = root_signature,
            VS = get_shader_bytecode(vertex_shader),
            PS = get_shader_bytecode(pixel_shader),
            RasterizerState = get_default_rasterizer_state(),
            BlendState = get_default_blend_state(),
            DepthStencilState = {DepthEnable = false, StencilEnable = false},
            SampleMask = max(win.UINT),
            PrimitiveTopologyType = .TRIANGLE,
            NumRenderTargets = 1,
            RTVFormats = {},
            SampleDesc = {Count = 1},
        }
        pso_desc.RTVFormats[0] = .R8G8B8A8_UNORM

        ensure_success(
            device->CreateGraphicsPipelineState(
                &pso_desc,
                d3d12.IPipelineState_UUID,
                (^rawptr)(&pipeline_state),
            ),
        )

    }


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
    ensure_success(command_list->Close())

    {     // Create Vertex buffer
        vertices := [3]Vertex {
            {position = {0, 0.25 * aspect_ratio, 0}, color = {1, 0, 0, 1}},
            {position = {0.25, -0.25 * aspect_ratio, 0}, color = {0, 1, 0, 1}},
            {position = {-0.25, -0.25 * aspect_ratio, 0}, color = {0, 0, 1, 1}},
        }
        vertex_buffer_size: u64 = size_of(vertices)

        upload_heap_properties := get_heap_properties(.UPLOAD)
        resource_buffer := get_resource_buffer(vertex_buffer_size)
        ensure_success(
            device->CreateCommittedResource(
                &upload_heap_properties,
                {},
                &resource_buffer,
                d3d12.RESOURCE_STATE_GENERIC_READ,
                nil,
                d3d12.IResource_UUID,
                (^rawptr)(&vertex_buffer),
            ),
        )


        data_begin: rawptr
        range := d3d12.RANGE{}
        vertex_buffer->Map(0, &range, &data_begin)
        mem.copy(data_begin, &vertices[0], int(vertex_buffer_size))
        vertex_buffer->Unmap(0, nil)
        vertex_buffer_view = {
            BufferLocation = vertex_buffer->GetGPUVirtualAddress(),
            StrideInBytes  = size_of(Vertex),
            SizeInBytes    = u32(vertex_buffer_size),
        }

    }


    {     // Create Synchronization objects
        ensure_success(device->CreateFence(0, {}, d3d12.IFence_UUID, (^rawptr)(&fence)))

        fence_value = 1

        fence_event = win.CreateEventW(nil, false, false, nil)
        if fence_event == nil {
            log.errorf("{}", win.HRESULT_FROM_WIN32(win.GetLastError()))
            ensure(false, "Failed to create fence event")
        }
        wait_for_previous_frame(
            swap_chain,
            command_queue,
            fence,
            fence_event,
            &fence_value,
            &frame_index,
        )
    }
}

populate_command_list :: proc(using ctx: ^Render_Context) {
    ensure_success(command_allocator->Reset())
    ensure_success(command_list->Reset(command_allocator, pipeline_state))

    command_list->SetGraphicsRootSignature(root_signature)
    command_list->RSSetViewports(1, &viewport)
    command_list->RSSetScissorRects(1, &scissor_rect)

    barrier_to_render_target := transition(render_targets[frame_index], {}, {.RENDER_TARGET})
    command_list->ResourceBarrier(1, &barrier_to_render_target)

    rtv_handle: d3d12.CPU_DESCRIPTOR_HANDLE
    rtv_heap->GetCPUDescriptorHandleForHeapStart(&rtv_handle)
    offset_desc_handle(&rtv_handle, (i32)(frame_index), rtv_descriptor_size)
    command_list->OMSetRenderTargets(1, &rtv_handle, false, nil)

    @(rodata)
    @(static)
    clear_Color := [4]f32{0.0, 0.2, 0.4, 1.0}
    command_list->ClearRenderTargetView(rtv_handle, &clear_Color, 0, nil)
    command_list->IASetPrimitiveTopology(.TRIANGLELIST)
    command_list->IASetVertexBuffers(0, 1, &vertex_buffer_view)
    command_list->DrawInstanced(3, 1, 0, 0)

    barrier_to_present := transition(render_targets[frame_index], {.RENDER_TARGET}, {})
    command_list->ResourceBarrier(1, &barrier_to_present)
    ensure_success(command_list->Close())
}

render :: proc(using ctx: ^Render_Context) {
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

destroy_render_context :: proc(using ctx: ^Render_Context) {
    wait_for_previous_frame(
        swap_chain,
        command_queue,
        fence,
        fence_event,
        &fence_value,
        &frame_index,
    )
    win.CloseHandle(fence_event)
    vertex_buffer->Release()
    fence->Release()
    command_list->Release()
    command_allocator->Release()
    for f: u32; f < FRAME_COUNT; f += 1 {
        render_targets[f]->Release()
    }
    pipeline_state->Release()
    root_signature->Release()
    rtv_heap->Release()
    swap_chain->Release()
    command_queue->Release()
    debugDevice: ^d3d12.IDebugDevice1
    if (win.SUCCEEDED(device->QueryInterface(d3d12.IDebugDevice1_UUID, (^rawptr)(&debugDevice)))) {
        debugDevice->ReportLiveDeviceObjects({.IGNORE_INTERNAL})
        debugDevice->Release()
    }
    device->Release()
    factory->Release()
}
