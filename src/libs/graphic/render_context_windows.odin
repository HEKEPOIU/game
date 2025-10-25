package graphic

import "base:runtime"
import "core:log"
import "core:mem"
import win "core:sys/windows"
import "libs:utilities"
import "vendor:directx/d3d12"
import d3dc "vendor:directx/d3d_compiler"
import "vendor:directx/dxgi"

ensure_success :: utilities.ensure_success

FRAME_COUNT :: 2
TEXTURE_WIDTH :: 256
TEXTURE_HEIGHT :: 256
TEXTURE_PIXEL_SIZE :: 4

TEXTURE_SIZE :: TEXTURE_WIDTH * TEXTURE_HEIGHT * TEXTURE_PIXEL_SIZE


WaitForGpu :: proc(using ctx: ^Render_Context) {
    ensure_success(command_queue->Signal(fence, fence_value[frame_index]))
    ensure_success(fence->SetEventOnCompletion(fence_value[frame_index], fence_event))
    win.WaitForSingleObject(fence_event, win.INFINITE)

    fence_value[frame_index] += 1
}

move_to_next_frame :: proc(using ctx: ^Render_Context) {
    current_fence_value := fence_value[frame_index]
    // The Signal method not increment the fence immediately,
    // it append a signal operation to the end of command queue, after all the command in the queue is executed.
    ensure_success(command_queue->Signal(fence, current_fence_value))

    frame_index = swap_chain->GetCurrentBackBufferIndex()
    if fence->GetCompletedValue() < fence_value[frame_index] {
        ensure_success(fence->SetEventOnCompletion(fence_value[frame_index], fence_event))
        win.WaitForSingleObject(fence_event, win.INFINITE)
    }

    fence_value[frame_index] = current_fence_value + 1
}

//TODO: Pass own temp allocator and allocator to that it manage by render system
Render_Context :: struct {
    // TODO: Factory6 support start from windows 10 1803 (2018/04),
    //       We need to check support range of windows version,
    //       and maybe need to follow Dx12Example case that use Factory4 to Support more windows version.
    // TODO: Move out this
    get_asset:               Get_Asset_Func,
    factory:                 ^dxgi.IFactory6,
    device:                  ^d3d12.IDevice,
    command_queue:           ^d3d12.ICommandQueue,
    swap_chain:              ^dxgi.ISwapChain3,
    rtv_heap:                ^d3d12.IDescriptorHeap,
    srv_cbv_heap:            ^d3d12.IDescriptorHeap,
    command_allocator:       [FRAME_COUNT]^d3d12.ICommandAllocator,
    command_list:            ^d3d12.IGraphicsCommandList,
    bundle_allocator:        ^d3d12.ICommandAllocator,
    bundle:                  ^d3d12.IGraphicsCommandList,
    fence:                   ^d3d12.IFence,
    root_signature:          ^d3d12.IRootSignature,
    pipeline_state:          ^d3d12.IPipelineState,
    vertex_buffer:           ^d3d12.IResource,
    constant_buffer:         ^d3d12.IResource,
    cbv_data_begin:          ^byte,
    cbv_data:                Scene_Constant_Buffer,
    vertex_buffer_view:      d3d12.VERTEX_BUFFER_VIEW,
    render_targets:          [FRAME_COUNT]^d3d12.IResource,
    texture:                 ^d3d12.IResource,
    fence_value:             [FRAME_COUNT]u64,
    fence_event:             win.HANDLE,
    frame_index:             u32,
    rtv_descriptor_size:     win.UINT,
    srv_cbv_descriptor_size: win.UINT,
    aspect_ratio:            f32,
    current_width:           u32,
    current_height:          u32,
    is_initial:              b32,
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
    update_window_size(ctx, width, height)
    load_pipeline(ctx, hwd, height, width)
    load_assets(ctx)
    is_initial = true
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
                // debug_controller->SetEnableGPUBasedValidation(true)
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
        Type  = .DIRECT,
        Flags = {},
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

        swap_chain_flags: dxgi.SWAP_CHAIN

        {     // Check support tearing
            support_tearing: b32 = false
            factory->CheckFeatureSupport(
                .PRESENT_ALLOW_TEARING,
                &support_tearing,
                size_of(support_tearing),
            )
            if support_tearing {
                swap_chain_flags = {.ALLOW_TEARING}
            }
        }

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
            Scaling = .NONE,
            Flags = swap_chain_flags,
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

    // Reneder Target View(RTV), Shader Resource View(SRV)
    {     // Create descriptor heaps for RTV
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

        srv_heap_desc := d3d12.DESCRIPTOR_HEAP_DESC {
            NumDescriptors = 2,
            Type           = .CBV_SRV_UAV,
            Flags          = {.SHADER_VISIBLE},
        }

        ensure_success(
            device->CreateDescriptorHeap(
                &srv_heap_desc,
                d3d12.IDescriptorHeap_UUID,
                (^rawptr)(&srv_cbv_heap),
            ),
        )
        srv_cbv_descriptor_size = device->GetDescriptorHandleIncrementSize(.CBV_SRV_UAV)

    }
    update_rtv_view(ctx, FRAME_COUNT)

    for f: u32; f < FRAME_COUNT; f += 1 {
        ensure_success(
            device->CreateCommandAllocator(
                .DIRECT,
                d3d12.ICommandAllocator_UUID,
                (^rawptr)(&command_allocator[f]),
            ),
        )
    }


    ensure_success(
        device->CreateCommandAllocator(
            .BUNDLE,
            d3d12.ICommandAllocator_UUID,
            (^rawptr)(&bundle_allocator),
        ),
    )
}

get_viewport :: proc(width: u32, height: u32) -> d3d12.VIEWPORT {
    return {Width = f32(width), Height = f32(height)}
}
get_scissor_rect :: proc(width: u32, height: u32) -> d3d12.RECT {
    return {right = i32(width), bottom = i32(height)}
}

update_window_size :: proc(using ctx: ^Render_Context, width: u32, height: u32) {
    aspect_ratio = f32(width) / f32(height)
    MIN_WINDOW_WIDTH :: 200
    MIN_WINDOW_HEIGHT :: 200
    current_width = max(width, MIN_WINDOW_WIDTH)
    current_height = max(height, MIN_WINDOW_HEIGHT)
}

update_rtv_view :: proc(using ctx: ^Render_Context, frame_count: u32) {
    rtv_handle: d3d12.CPU_DESCRIPTOR_HANDLE
    // On C++ binding, this use return value not out parameter
    rtv_heap->GetCPUDescriptorHandleForHeapStart(&rtv_handle)
    for f: u32; f < frame_count; f += 1 {
        ensure_success(
            swap_chain->GetBuffer(f, d3d12.IResource_UUID, (^rawptr)(&render_targets[f])),
        )
        device->CreateRenderTargetView(render_targets[f], nil, rtv_handle)
        offset_desc_handle(&rtv_handle, 1, rtv_descriptor_size)
    }
}

resize :: proc(using ctx: ^Render_Context, width: u32, height: u32) {
    if (width == current_width && height == current_height) do return
    update_window_size(ctx, width, height)
    if !is_initial do return
    WaitForGpu(ctx)
    for f: u32; f < FRAME_COUNT; f += 1 {
        render_targets[f]->Release()
        // fence_value[f] = fence_value[frame_index]
    }
    old_swapchain_desc := dxgi.SWAP_CHAIN_DESC{}
    ensure_success(swap_chain->GetDesc(&old_swapchain_desc))
    ensure_success(
        swap_chain->ResizeBuffers(
            FRAME_COUNT,
            current_width,
            current_height,
            old_swapchain_desc.BufferDesc.Format,
            old_swapchain_desc.Flags,
        ),
    )
    frame_index = swap_chain->GetCurrentBackBufferIndex()
    update_rtv_view(ctx, FRAME_COUNT)
}


load_assets :: proc(using ctx: ^Render_Context) {
    {     // Create empty root signature

        feature_data := d3d12.FEATURE_DATA_ROOT_SIGNATURE{._1_1}
        if (win.FAILED(
                   device->CheckFeatureSupport(
                       .ROOT_SIGNATURE,
                       &feature_data,
                       size_of(feature_data),
                   ),
               )) {
            feature_data = d3d12.FEATURE_DATA_ROOT_SIGNATURE{._1_0}
        }

        ranges := [2]d3d12.DESCRIPTOR_RANGE1 {
            get_descriptor_range(.SRV, 1, 0, 0, {.DATA_STATIC}),
            get_descriptor_range(.CBV, 1, 0, 0, {.DATA_STATIC}),
        }
        root_parameters := [2]d3d12.ROOT_PARAMETER1 {
            get_descriptor_table(1, &ranges[0], .PIXEL),
            get_descriptor_table(1, &ranges[1], .VERTEX),
        }

        sampler := d3d12.STATIC_SAMPLER_DESC {
            Filter           = .MIN_MAG_MIP_POINT,
            AddressU         = .BORDER,
            AddressV         = .BORDER,
            AddressW         = .BORDER,
            MipLODBias       = 0,
            MaxAnisotropy    = 0,
            ComparisonFunc   = .NEVER,
            BorderColor      = .TRANSPARENT_BLACK,
            MinLOD           = 0,
            MaxLOD           = max(f32),
            ShaderRegister   = 0,
            RegisterSpace    = 0,
            ShaderVisibility = .PIXEL,
        }

        root_signature_desc := get_root_signature_1_1(
        u32(len(root_parameters)),
        &root_parameters[0],
        1,
        &sampler,
        {
            .ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT,
            .DENY_DOMAIN_SHADER_ROOT_ACCESS,
            .DENY_GEOMETRY_SHADER_ROOT_ACCESS,
            .DENY_HULL_SHADER_ROOT_ACCESS,
            // .DENY_PIXEL_SHADER_ROOT_ACCESS,
        },
        )

        signature: ^d3d12.IBlob
        error: ^d3d12.IBlob
        ensure_success(
            d3d12.SerializeVersionedRootSignature(&root_signature_desc, &signature, &error),
        )
        defer signature->Release()
        defer {
            if error != nil {
                error->Release()
            }
        }
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
        shader_path, err := get_asset("texture_constant_buffer.hlsl", context.temp_allocator)
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
                SemanticName = "TEXCOORD",
                SemanticIndex = 0,
                Format = .R32G32_FLOAT,
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
            command_allocator[frame_index],
            pipeline_state,
            d3d12.IGraphicsCommandList_UUID,
            (^rawptr)(&command_list),
        ),
    )

    {     // Create Vertex buffer
        vertices := [3]Vertex {
            {position = {0, 0.25 * aspect_ratio, 0}, uv = {0.5, 0}},
            {position = {0.25, -0.25 * aspect_ratio, 0}, uv = {1, 1}},
            {position = {-0.25, -0.25 * aspect_ratio, 0}, uv = {0, 1}},
        }
        vertex_buffer_size: u64 = size_of(vertices)

        upload_heap_properties := get_heap_properties(.UPLOAD)
        resource_buffer_desc := get_resource_buffer_desc(vertex_buffer_size)
        ensure_success(
            device->CreateCommittedResource(
                &upload_heap_properties,
                {},
                &resource_buffer_desc,
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

    {     // Create Constant Buffer
        cb_size: u64 = size_of(Scene_Constant_Buffer)

        upload_heap_properties := get_heap_properties(.UPLOAD)
        resource_buffer_desc := get_resource_buffer_desc(cb_size)
        ensure_success(
            device->CreateCommittedResource(
                &upload_heap_properties,
                {},
                &resource_buffer_desc,
                d3d12.RESOURCE_STATE_GENERIC_READ,
                nil,
                d3d12.IResource_UUID,
                (^rawptr)(&constant_buffer),
            ),
        )
        cbv_desc := d3d12.CONSTANT_BUFFER_VIEW_DESC {
            BufferLocation = constant_buffer->GetGPUVirtualAddress(),
            SizeInBytes    = u32(cb_size),
        }
        handle: d3d12.CPU_DESCRIPTOR_HANDLE
        srv_cbv_heap->GetCPUDescriptorHandleForHeapStart(&handle)
        offset_desc_handle(&handle, 1, srv_cbv_descriptor_size)
        device->CreateConstantBufferView(&cbv_desc, handle)

        read_range := d3d12.RANGE{}
        ensure_success(constant_buffer->Map(0, &read_range, (^rawptr)(&cbv_data_begin)))
        mem.copy(cbv_data_begin, &cbv_data, size_of(Scene_Constant_Buffer))

    }

    texture_upload_heap: ^d3d12.IResource
    defer texture_upload_heap->Release()

    {     // Texture Create

        texture_desc := d3d12.RESOURCE_DESC {
            MipLevels = 1,
            Format = .R8G8B8A8_UNORM,
            Width = TEXTURE_WIDTH,
            Height = TEXTURE_HEIGHT,
            Flags = {},
            DepthOrArraySize = 1,
            SampleDesc = {Count = 1},
            Dimension = .TEXTURE2D,
        }

        default_heap_properties := get_heap_properties(.DEFAULT)
        ensure_success(
            device->CreateCommittedResource(
                &default_heap_properties,
                {},
                &texture_desc,
                {.COPY_DEST},
                nil,
                d3d12.IResource_UUID,
                (^rawptr)(&texture),
            ),
        )

        upload_heap_prop := get_heap_properties(.UPLOAD)
        upload_buffer_size := get_required_intermediate_size(texture, 0, 1)
        resource_buffer_desc := get_resource_buffer_desc(upload_buffer_size)
        ensure_success(
            device->CreateCommittedResource(
                &upload_heap_prop,
                {},
                &resource_buffer_desc,
                d3d12.RESOURCE_STATE_GENERIC_READ,
                nil,
                d3d12.IResource_UUID,
                (^rawptr)(&texture_upload_heap),
            ),
        )

        texture_data := generate_checkerboard_texture()

        texture_subresource_data := d3d12.SUBRESOURCE_DATA {
            pData      = &texture_data[0],
            RowPitch   = TEXTURE_WIDTH * TEXTURE_PIXEL_SIZE,
            SlicePitch = TEXTURE_SIZE,
        }
        subresources := [1]d3d12.SUBRESOURCE_DATA{texture_subresource_data}
        ensure(
            update_subresources_from_stack(
                command_list,
                texture,
                texture_upload_heap,
                0,
                0,
                1,
                subresources[:],
            ),
        )

        barrier := transition(texture, {.COPY_DEST}, {.PIXEL_SHADER_RESOURCE})
        command_list->ResourceBarrier(1, &barrier)

        srv_desc := d3d12.SHADER_RESOURCE_VIEW_DESC {
            Shader4ComponentMapping = d3d12.DEFAULT_SHADER_4_COMPONENT_MAPPING,
            Format = texture_desc.Format,
            ViewDimension = .TEXTURE2D,
            Texture2D = {MipLevels = 1},
        }

        heap_handle: d3d12.CPU_DESCRIPTOR_HANDLE
        srv_cbv_heap->GetCPUDescriptorHandleForHeapStart(&heap_handle)
        device->CreateShaderResourceView(texture, &srv_desc, heap_handle)
    }

    ensure_success(command_list->Close())
    command_lists := []^d3d12.ICommandList{command_list}
    command_queue->ExecuteCommandLists(u32(len(command_lists)), raw_data(command_lists))

    {
        ensure_success(
            device->CreateCommandList(
                0,
                .BUNDLE,
                bundle_allocator,
                pipeline_state,
                d3d12.IGraphicsCommandList_UUID,
                (^rawptr)(&bundle),
            ),
        )
        bundle->SetGraphicsRootSignature(root_signature)
        heaps := []^d3d12.IDescriptorHeap{srv_cbv_heap}
        // must match the calling command list descriptor heap
        bundle->SetDescriptorHeaps(u32(len(heaps)), raw_data(heaps))

        {     // srv set
            handle: d3d12.GPU_DESCRIPTOR_HANDLE
            srv_cbv_heap->GetGPUDescriptorHandleForHeapStart(&handle)
            bundle->SetGraphicsRootDescriptorTable(0, handle)
        }

        {     // cbv set
            handle: d3d12.GPU_DESCRIPTOR_HANDLE
            srv_cbv_heap->GetGPUDescriptorHandleForHeapStart(&handle)
            offset_desc_handle(&handle, 1, srv_cbv_descriptor_size)
            bundle->SetGraphicsRootDescriptorTable(1, handle)
        }


        bundle->IASetPrimitiveTopology(.TRIANGLELIST)
        bundle->IASetVertexBuffers(0, 1, &vertex_buffer_view)
        bundle->DrawInstanced(3, 1, 0, 0)
        ensure_success(bundle->Close())
    }

    {     // Create Synchronization objects
        ensure_success(
            device->CreateFence(
                fence_value[frame_index], // Initial value
                {},
                d3d12.IFence_UUID,
                (^rawptr)(&fence),
            ),
        )

        fence_value[frame_index] += 1

        fence_event = win.CreateEventW(nil, false, false, nil)
        if fence_event == nil {
            log.errorf("{}", win.HRESULT_FROM_WIN32(win.GetLastError()))
            ensure(false, "Failed to create fence event")
        }
        WaitForGpu(ctx)
    }
}

populate_command_list :: proc(using ctx: ^Render_Context) {
    ensure_success(command_allocator[frame_index]->Reset())
    ensure_success(command_list->Reset(command_allocator[frame_index], pipeline_state))


    command_list->SetGraphicsRootSignature(root_signature)
    heaps := []^d3d12.IDescriptorHeap{srv_cbv_heap}
    // must match the calling command list descriptor heap
    command_list->SetDescriptorHeaps(u32(len(heaps)), raw_data(heaps))

    {     // srv set
        handle: d3d12.GPU_DESCRIPTOR_HANDLE
        srv_cbv_heap->GetGPUDescriptorHandleForHeapStart(&handle)
        command_list->SetGraphicsRootDescriptorTable(0, handle)
    }

    {     // cbv set
        handle: d3d12.GPU_DESCRIPTOR_HANDLE
        srv_cbv_heap->GetGPUDescriptorHandleForHeapStart(&handle)
        offset_desc_handle(&handle, 1, srv_cbv_descriptor_size)
        command_list->SetGraphicsRootDescriptorTable(1, handle)
    }

    viewport := get_viewport(current_width, current_height)
    scissor_rect := get_scissor_rect(current_width, current_height)
    command_list->RSSetViewports(1, &viewport)
    command_list->RSSetScissorRects(1, &scissor_rect)

    barrier_to_render_target := transition(render_targets[frame_index], {}, {.RENDER_TARGET})
    command_list->ResourceBarrier(1, &barrier_to_render_target)

    rtv_handle: d3d12.CPU_DESCRIPTOR_HANDLE
    rtv_heap->GetCPUDescriptorHandleForHeapStart(&rtv_handle)
    offset_desc_handle(&rtv_handle, (i32)(frame_index), rtv_descriptor_size)

    @(rodata)
    @(static)
    clear_Color := [4]f32{0.0, 0.2, 0.4, 1.0}
    command_list->ClearRenderTargetView(rtv_handle, &clear_Color, 0, nil)

    command_list->OMSetRenderTargets(1, &rtv_handle, false, nil)
    command_list->ExecuteBundle(bundle)

    barrier_to_present := transition(render_targets[frame_index], {.RENDER_TARGET}, {})
    command_list->ResourceBarrier(1, &barrier_to_present)
    ensure_success(command_list->Close())
}

render :: proc(using ctx: ^Render_Context) {
    populate_command_list(ctx)
    command_lists := []^d3d12.ICommandList{command_list}
    command_queue->ExecuteCommandLists(u32(len(command_lists)), raw_data(command_lists))

    ensure_success(swap_chain->Present(0, {}))
    move_to_next_frame(ctx)
}

update :: proc(using ctx: ^Render_Context) {
    translation_speed: f32 = 0.005
    offset_bounds: f32 = 1.25

    cbv_data.offset.x += translation_speed
    if (cbv_data.offset.x > offset_bounds) {
        cbv_data.offset.x = -offset_bounds
    }
    mem.copy(cbv_data_begin, &cbv_data, size_of(Scene_Constant_Buffer))
}

destroy_render_context :: proc(using ctx: ^Render_Context) {
    WaitForGpu(ctx)
    win.CloseHandle(fence_event)
    vertex_buffer->Release()
    fence->Release()
    command_list->Release()
    constant_buffer->Release()
    bundle->Release()
    bundle_allocator->Release()
    for f: u32; f < FRAME_COUNT; f += 1 {
        command_allocator[f]->Release()
        render_targets[f]->Release()

    }
    texture->Release()
    pipeline_state->Release()
    root_signature->Release()
    srv_cbv_heap->Release()
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
