package graphic

import "core:mem"
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

get_shader_bytecode :: proc(shader_blob: ^d3d12.IBlob) -> d3d12.SHADER_BYTECODE {
    return {
        pShaderBytecode = shader_blob->GetBufferPointer(),
        BytecodeLength = shader_blob->GetBufferSize(),
    }

}

get_default_rasterizer_state :: proc() -> d3d12.RASTERIZER_DESC {
    return {
        FillMode = .SOLID,
        CullMode = .BACK,
        FrontCounterClockwise = false,
        DepthBias = d3d12.DEFAULT_DEPTH_BIAS,
        DepthBiasClamp = d3d12.DEFAULT_DEPTH_BIAS_CLAMP,
        SlopeScaledDepthBias = d3d12.DEFAULT_SLOPE_SCALED_DEPTH_BIAS,
        DepthClipEnable = true,
        MultisampleEnable = false,
        AntialiasedLineEnable = false,
        ForcedSampleCount = 0,
        ConservativeRaster = .OFF,
    }
}

get_default_blend_state :: proc() -> (ret: d3d12.BLEND_DESC) {
    ret = {
        AlphaToCoverageEnable  = false,
        IndependentBlendEnable = false,
    }
    default_value := d3d12.RENDER_TARGET_BLEND_DESC {
        BlendEnable           = false,
        LogicOpEnable         = false,
        SrcBlend              = .ONE,
        DestBlend             = .ZERO,
        BlendOp               = .ADD,
        SrcBlendAlpha         = .ONE,
        DestBlendAlpha        = .ZERO,
        BlendOpAlpha          = .ADD,
        LogicOp               = .NOOP,
        RenderTargetWriteMask = u8(d3d12.COLOR_WRITE_ENABLE_ALL),
    }
    for &i in ret.RenderTarget {
        i = default_value
    }
    return
}

get_heap_properties :: proc(type: d3d12.HEAP_TYPE) -> d3d12.HEAP_PROPERTIES {
    return {
        Type                 = type,
        //following two value only used for custom heap
        CPUPageProperty      = .UNKNOWN,
        MemoryPoolPreference = .UNKNOWN,
    }
}

get_resource_buffer_desc :: proc(
    size: u64,
    flags: d3d12.RESOURCE_FLAGS = {},
    alignment: u64 = 0,
) -> d3d12.RESOURCE_DESC {
    return {
        Dimension = .BUFFER,
        Alignment = alignment,
        Width = size,
        Height = 1,
        DepthOrArraySize = 1,
        MipLevels = 1,
        Format = .UNKNOWN,
        SampleDesc = {Count = 1, Quality = 0},
        Layout = .ROW_MAJOR,
        Flags = flags,
    }
}

get_descriptor_range :: proc(
    range_type: d3d12.DESCRIPTOR_RANGE_TYPE,
    num_descriptors: u32,
    base_shader_register: u32,
    register_space: u32 = 0,
    flags: d3d12.DESCRIPTOR_RANGE_FLAGS = {},
    offset_in_descriptors_from_table_start: u32 = d3d12.DESCRIPTOR_RANGE_OFFSET_APPEND,
) -> d3d12.DESCRIPTOR_RANGE1 {
    return {
        RangeType = range_type,
        NumDescriptors = num_descriptors,
        BaseShaderRegister = base_shader_register,
        RegisterSpace = register_space,
        Flags = flags,
        OffsetInDescriptorsFromTableStart = offset_in_descriptors_from_table_start,
    }
}

get_descriptor_table :: proc(
    num_descriptor_ranges: u32,
    descriptor_ranges: ^d3d12.DESCRIPTOR_RANGE1,
    visibility: d3d12.SHADER_VISIBILITY = .ALL,
) -> d3d12.ROOT_PARAMETER1 {
    return {
        ParameterType = .DESCRIPTOR_TABLE,
        ShaderVisibility = visibility,
        DescriptorTable = {
            NumDescriptorRanges = num_descriptor_ranges,
            pDescriptorRanges = descriptor_ranges,
        },
    }

}

get_root_signature_1_1 :: proc(
    num_parameters: u32,
    parameters: ^d3d12.ROOT_PARAMETER1,
    num_static_samplers: u32 = 0,
    static_samplers: ^d3d12.STATIC_SAMPLER_DESC = nil,
    flags: d3d12.ROOT_SIGNATURE_FLAGS = {},
) -> d3d12.VERSIONED_ROOT_SIGNATURE_DESC {
    return {
        Version = ._1_1,
        Desc_1_1 = {
            NumParameters = num_parameters,
            pParameters = parameters,
            NumStaticSamplers = num_static_samplers,
            pStaticSamplers = static_samplers,
            Flags = flags,
        },
    }
}

get_required_intermediate_size :: proc(
    resource: ^d3d12.IResource,
    first_subresource: u32,
    num_subresources: u32,
) -> u64 {
    assert(resource != nil)
    desc: d3d12.RESOURCE_DESC
    resource->GetDesc(&desc)
    result: u64 = 0

    device: ^d3d12.IDevice
    resource->GetDevice(d3d12.IDevice_UUID, (^rawptr)(&device))
    device->GetCopyableFootprints(
        &desc,
        first_subresource,
        num_subresources,
        0,
        nil,
        nil,
        nil,
        &result,
    )
    device->Release()

    return result
}

generate_checkerboard_texture :: proc() -> (ret: [TEXTURE_SIZE]u8) {
    row_pitch: u32 = TEXTURE_WIDTH * TEXTURE_PIXEL_SIZE
    cell_pitch: u32 = row_pitch >> 3 // /8
    cell_height: u32 = TEXTURE_WIDTH >> 3

    for n: u32 = 0; n < TEXTURE_SIZE; n += TEXTURE_PIXEL_SIZE {
        x := n % row_pitch
        y := n / row_pitch
        i := x / cell_pitch
        j := y / cell_height

        if i % 2 == j % 2 {
            ret[n] = 0x00 // R
            ret[n + 1] = 0x00 // G
            ret[n + 2] = 0x00 // B
            ret[n + 3] = 0xff // A
        } else {
            ret[n] = 0xff // R
            ret[n + 1] = 0xff // G
            ret[n + 2] = 0xff // B
            ret[n + 3] = 0xff // A
        }
    }
    return
}

mem_copy_subresource :: proc(
    dest: ^d3d12.MEMCPY_DEST,
    src: ^d3d12.SUBRESOURCE_DATA,
    row_size_in_bytes: int,
    num_rows: u32,
    num_slices: u32,
) {

    for z := u32(0); z < num_slices; z += 1 {
        dest_slice := mem.ptr_offset((^byte)((uintptr)(dest.pData)), int(u32(dest.SlicePitch) * z))
        src_slice := mem.ptr_offset((^byte)((uintptr)(src.pData)), int(u32(src.SlicePitch) * z))
        for y := u32(0); y < num_rows; y += 1 {
            d := mem.ptr_offset(dest_slice, uint(y) * dest.RowPitch)
            s := mem.ptr_offset(src_slice, i64(y) * src.RowPitch)
            mem.copy(d, s, row_size_in_bytes)
        }
    }
}
get_texture_copy_location :: proc {
    get_texture_copy_location_from_footprint,
    get_texture_copy_location_from_index,
}
get_texture_copy_location_from_index :: proc(
    resource: ^d3d12.IResource,
    index: u32,
) -> d3d12.TEXTURE_COPY_LOCATION {
    return {pResource = resource, Type = .SUBRESOURCE_INDEX, SubresourceIndex = index}
}

get_texture_copy_location_from_footprint :: proc(
    resource: ^d3d12.IResource,
    footprint: d3d12.PLACED_SUBRESOURCE_FOOTPRINT,
) -> d3d12.TEXTURE_COPY_LOCATION {
    return {pResource = resource, Type = .PLACED_FOOTPRINT, PlacedFootprint = footprint}
}


update_subresources :: proc(
    cmd_list: ^d3d12.IGraphicsCommandList,
    destination_resource: ^d3d12.IResource,
    intermediate: ^d3d12.IResource,
    first_subresource: u32,
    num_sub_resources: u32,
    required_size: u64,
    layouts: []d3d12.PLACED_SUBRESOURCE_FOOTPRINT,
    num_rows: []u32,
    row_sizes_in_bytes: []u64,
    src_data: []d3d12.SUBRESOURCE_DATA,
) -> (
    ok: bool,
) #no_bounds_check {
    assert(int(num_sub_resources) == len(layouts))
    assert(int(num_sub_resources) == len(num_rows))
    assert(int(num_sub_resources) == len(row_sizes_in_bytes))
    assert(int(num_sub_resources) == len(src_data))
    intermediate_desc: d3d12.RESOURCE_DESC = ---
    destination_desc: d3d12.RESOURCE_DESC = ---
    intermediate->GetDesc(&intermediate_desc)
    destination_resource->GetDesc(&destination_desc)
    if (intermediate_desc.Dimension != .BUFFER ||
           intermediate_desc.Width < required_size + layouts[0].Offset ||
           (destination_desc.Dimension == .BUFFER &&
                   (first_subresource != 0 || num_sub_resources != 1))) {
        return false
    }

    data: ^byte
    result := intermediate->Map(0, nil, (^rawptr)(&data))
    if (win.FAILED(result)) do return true
    for i: u32; i < num_sub_resources; i += 1 {
        start := mem.ptr_offset(data, layouts[i].Offset)
        dest_data: d3d12.MEMCPY_DEST = {
            pData      = start,
            RowPitch   = uint(layouts[i].Footprint.RowPitch),
            SlicePitch = uint(layouts[i].Footprint.RowPitch * layouts[i].Footprint.Height),
        }
        mem_copy_subresource(
            &dest_data,
            &src_data[i],
            int(row_sizes_in_bytes[i]),
            num_rows[i],
            layouts[i].Footprint.Depth,
        )
    }
    intermediate->Unmap(0, nil)

    if destination_desc.Dimension == .BUFFER {

        cmd_list->CopyBufferRegion(
            destination_resource,
            0,
            intermediate,
            layouts[0].Offset,
            u64(layouts[0].Footprint.Width),
        )
    } else {
        for i: u32; i < num_sub_resources; i += 1 {
            dest := get_texture_copy_location(destination_resource, i + first_subresource)
            src := get_texture_copy_location(intermediate, layouts[i])
            cmd_list->CopyTextureRegion(&dest, 0, 0, 0, &src, nil)
        }
    }
    return true
}

update_subresources_from_stack :: proc(
    cmd_list: ^d3d12.IGraphicsCommandList,
    destination_resource: ^d3d12.IResource,
    intermediate: ^d3d12.IResource,
    intermediate_offset: u64,
    first_subresource: u32,
    $num_sub_resources: u32,
    src_data: []d3d12.SUBRESOURCE_DATA,
) -> (
    err: bool,
) #no_bounds_check {
    assert(int(num_sub_resources) == len(src_data))
    require_size: u64 = 0
    layout: [num_sub_resources]d3d12.PLACED_SUBRESOURCE_FOOTPRINT
    num_rows: [num_sub_resources]u32
    row_sizes_in_bytes: [num_sub_resources]u64

    desc : d3d12.RESOURCE_DESC
    destination_resource->GetDesc(&desc)
    device: ^d3d12.IDevice = ---
    destination_resource->GetDevice(d3d12.IDevice_UUID, (^rawptr)(&device))
    device->GetCopyableFootprints(
        &desc,
        first_subresource,
        num_sub_resources,
        intermediate_offset,
        raw_data(layout[:]),
        raw_data(num_rows[:]),
        raw_data(row_sizes_in_bytes[:]),
        &require_size,
    )
    device->Release()

    return update_subresources(
        cmd_list,
        destination_resource,
        intermediate,
        first_subresource,
        num_sub_resources,
        require_size,
        layout[:],
        num_rows[:],
        row_sizes_in_bytes[:],
        src_data,
    )
}
