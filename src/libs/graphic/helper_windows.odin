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

get_resource_buffer :: proc(
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
        SampleDesc = {
            Count = 1,
            Quality = 0,
        },
        Layout = .ROW_MAJOR,
        Flags = flags,
    }
}
