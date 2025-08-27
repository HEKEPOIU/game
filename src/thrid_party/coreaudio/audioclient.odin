package coreaudio
import "core:sys/windows"
// Bindings Produced by fendevel, and modified to use windows.IID, GUID, etc.
// Src: https://github.com/fendevel/odin-wasapi/blob/main/wasapi.odin

// base on fendevel's wasapi.odin, add some new interfaces
// but not all 
// list of function/interface are not add:
// ActivateAudioInterfaceAsync


AUDIO_EFFECT_STATE :: enum i32 {
    Off,
    On,
}

IAudioClient_UUID_STRING :: "1CB9AD4C-DBFA-4c32-B178-C2F568A703B2"
IAudioClient_UUID := &windows.IID {
    0x1CB9AD4C,
    0xDBFA,
    0x4c32,
    {0xB1, 0x78, 0xC2, 0xF5, 0x68, 0xA7, 0x03, 0xB2},
}
IAudioClient :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioClientVtbl,
}

@(private)
IAudioClientVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    Initialize:         proc "system" (
        this: ^IAudioClient,
        ShareMode: AUDCLNT_SHAREMODE,
        StreamFlags: Audio_Client_Stream_Flags,
        hnsBufferDuration: REFERENCE_TIME,
        hnsPeriodicity: REFERENCE_TIME,
        pFormat: ^windows.WAVEFORMATEX,
        AudioSessionGuid: windows.LPCGUID,
    ) -> windows.HRESULT,
    GetBufferSize:      proc "system" (
        this: ^IAudioClient,
        pNumBufferFrames: ^windows.UINT32,
    ) -> windows.HRESULT,
    GetStreamLatency:   proc "system" (
        this: ^IAudioClient,
        phnsLatency: ^REFERENCE_TIME,
    ) -> windows.HRESULT,
    GetCurrentPadding:  proc "system" (
        this: ^IAudioClient,
        pNumPaddingFrames: ^windows.UINT32,
    ) -> windows.HRESULT,
    IsFormatSupported:  proc "system" (
        this: ^IAudioClient,
        ShareMode: AUDCLNT_SHAREMODE,
        pFormat: ^windows.WAVEFORMATEX,
        ppClosestMatch: ^^windows.WAVEFORMATEX,
    ) -> windows.HRESULT,
    GetMixFormat:       proc "system" (
        this: ^IAudioClient,
        ppDeviceFormat: ^^windows.WAVEFORMATEX,
    ) -> windows.HRESULT,
    GetDevicePeriod:    proc "system" (
        this: ^IAudioClient,
        phnsDefaultDevicePeriod: ^REFERENCE_TIME,
        phnsMinimumDevicePeriod: ^REFERENCE_TIME,
    ) -> windows.HRESULT,
    Start:              proc "system" (this: ^IAudioClient) -> windows.HRESULT,
    Stop:               proc "system" (this: ^IAudioClient) -> windows.HRESULT,
    Reset:              proc "system" (this: ^IAudioClient) -> windows.HRESULT,
    SetEventHandle:     proc "system" (
        this: ^IAudioClient,
        eventHandle: windows.HANDLE,
    ) -> windows.HRESULT,
    GetService:         proc "system" (
        this: ^IAudioClient,
        riid: windows.REFIID,
        ppv: ^rawptr,
    ) -> windows.HRESULT,
}

IAudioClient2_UUID_STRING :: "726778CD-F60A-4eda-82DE-E47610CD78AA"
IAudioClient2_UUID := &windows.IID {
    0x726778CD,
    0xF60A,
    0x4eda,
    {0x82, 0xDE, 0xE4, 0x76, 0x10, 0xCD, 0x78, 0xAA},
}
IAudioClient2 :: struct #raw_union {
    #subtype iaudioclient: IAudioClient,
    using vtable: ^IAudioClient2Vtbl,
}

AudioClientProperties :: struct {
    cbSize:     windows.UINT32,
    bIsOffload: windows.BOOL,
    eCategory:  AUDIO_STREAM_CATEGORY,
    Options:    AUDCLNT_STREAMOPTIONS, // Start with windows 8.1
}
AUDIO_EFFECT :: struct {
    id:          windows.GUID,
    canSetState: windows.BOOL,
    state:       AUDIO_EFFECT_STATE,
}
AUDIO_DUCKING_OPTIONS :: enum i32 {
    Default,
    DoNotDuckOtherStreams,
}

AUDCLNT_BUFFERFLAGS :: bit_set[AUDCLNT_BUFFERFLAG;windows.DWORD]
AUDCLNT_BUFFERFLAG :: enum {
    DATA_DISCONTINUITY,
    SILENT,
    TIMESTAMP_ERROR,
}

AUDCLNT_STREAMOPTIONS :: bit_set[AUDCLNT_STREAMOPTION;u32]
AUDCLNT_STREAMOPTION :: enum {
    None,
    RAW,
    MATCH_FORMAT,
    AMBISONICS,
    // Post_Volume_Loopback = 8, // Only supported in Windows 10 version 1709 and later
}

@(private)
IAudioClient2Vtbl :: struct {
    using iaudioclientVtbl: IAudioClientVtbl,
    IsOffloadCapable:       proc "system" (
        this: ^IAudioClient2,
        Category: AUDIO_STREAM_CATEGORY,
        pbOffloadCapable: ^windows.BOOL,
    ) -> windows.HRESULT,
    SetClientProperties:    proc "system" (
        this: ^IAudioClient2,
        pProperties: ^AudioClientProperties,
    ) -> windows.HRESULT,
    GetBufferSizeLimits:    proc "system" (
        this: ^IAudioClient2,
        pFormat: ^windows.WAVEFORMATEX,
        bEventDriven: windows.BOOL,
        phnsMinBufferDuration: ^REFERENCE_TIME,
        phnsMaxBufferDuration: ^REFERENCE_TIME,
    ) -> windows.HRESULT,
}

IAudioClient3_UUID_STRING :: "7ED4EE07-8E67-4CD4-8C1A-2B7A5987AD42"
IAudioClient3_UUID := &windows.IID {
    0x7ED4EE07,
    0x8E67,
    0x4CD4,
    {0x8C, 0x1A, 0x2B, 0x7A, 0x59, 0x87, 0xAD, 0x42},
}
IAudioClient3 :: struct #raw_union {
    #subtype iaudioclient2: IAudioClient2,
    using vtable:  ^IAudioClient3Vtbl,
}

@(private)
IAudioClient3Vtbl :: struct {
    using iaudioclient2Vtbl:          IAudioClient2Vtbl,
    GetSharedModeEnginePeriod:        proc "system" (
        this: ^IAudioClient3,
        pFormat: ^windows.WAVEFORMATEX,
        pDefaultPeriodInFrames: ^windows.UINT32,
        pFundamentalPeriodInFrames: ^windows.UINT32,
        pMinPeriodInFrames: ^windows.UINT32,
        pMaxPeriodInFrames: ^windows.UINT32,
    ) -> windows.HRESULT,
    GetCurrentSharedModeEnginePeriod: proc "system" (
        this: ^IAudioClient3,
        ppFormat: ^^windows.WAVEFORMATEX,
        pCurrentPeriodInFrames: ^windows.UINT32,
    ) -> windows.HRESULT,
    InitializeSharedAudioStream:      proc "system" (
        this: ^IAudioClient3,
        StreamFlags: windows.DWORD,
        PeriodInFrames: windows.UINT32,
        pFormat: ^windows.WAVEFORMATEX,
        AudioSessionGuid: windows.LPCGUID,
    ) -> windows.HRESULT,
}


IAudioRenderClient_UUID_STRING :: "F294ACFC-3146-4483-A7BF-ADDCA7C260E2"
IAudioRenderClient_UUID := &windows.IID {
    0xF294ACFC,
    0x3146,
    0x4483,
    {0xA7, 0xBF, 0xAD, 0xDC, 0xA7, 0xC2, 0x60, 0xE2},
}
IAudioRenderClient :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioRenderClientVtbl,
}
@(private)
IAudioRenderClientVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    GetBuffer:          proc "system" (
        this: ^IAudioRenderClient,
        NumFramesRequested: windows.UINT32,
        ppData: ^^byte,
    ) -> windows.HRESULT,
    ReleaseBuffer:      proc "system" (
        this: ^IAudioRenderClient,
        NumFramesWritten: windows.UINT32,
        dwFlags: AUDCLNT_BUFFERFLAGS,
    ) -> windows.HRESULT,
}

IAcousticEchoCancellationController_UUID_STRING :: "f4ae25b5-aaa3-437d-b6b3-dbbe2d0e9549"
IAcousticEchoCancellationController_UUID := &windows.IID {
    0xF4AE25B5,
    0xAAA3,
    0x437D,
    {0xB6, 0xB3, 0xDB, 0xBE, 0x2D, 0x0E, 0x95, 0x49},
}
IAcousticEchoCancellationController :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAcousticEchoCancellationControllerVtbl,
}
@(private)
IAcousticEchoCancellationControllerVtbl :: struct {
    using IUnKnownVtbl:                windows.IUnknownVtbl,
    SetEchoCancellationRenderEndpoint: proc "system" (
        this: ^IAcousticEchoCancellationController,
        endpointId: windows.LPWSTR,
    ) -> windows.HRESULT,
}

IAudioCaptureClient_UUID_STRING :: "C8ADBD64-E71E-48a0-A4DE-185C395CD317"
IAudioCaptureClient_UUID := &windows.IID {
    0xC8ADBD64,
    0xE71E,
    0x48a0,
    {0xA4, 0xDE, 0x18, 0x5C, 0x39, 0x5C, 0xD3, 0x17},
}
IAudioCaptureClient :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioCaptureClientVtbl,
}
@(private)
IAudioCaptureClientVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    GetBuffer:          proc "system" (
        this: ^IAudioCaptureClient,
        ppData: ^^windows.BYTE,
        pNumFramesToRead: ^windows.UINT32,
        pdwFlags: ^windows.DWORD,
        pu64DevicePosition: ^windows.UINT64,
        pu64QPCPosition: ^windows.UINT64,
    ) -> windows.HRESULT,
    ReleaseBuffer:      proc "system" (
        this: ^IAudioCaptureClient,
        NumFramesRead: windows.UINT32,
    ) -> windows.HRESULT,
    GetNextPacketSize:  proc "system" (
        this: ^IAudioCaptureClient,
        pNumFramesInNextPacket: ^windows.UINT32,
    ) -> windows.HRESULT,
}

IAudioClientDuckingControl_UUID_STRING :: "C789D381-A28C-4168-B28F-D3A837924DC3"
IAudioClientDuckingControl_UUID := &windows.IID {
    0xC789D381,
    0xA28C,
    0x4168,
    {0xB2, 0x8F, 0xD3, 0xA8, 0x37, 0x92, 0x4D, 0xC3},
}
IAudioClientDuckingControl :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioClientDuckingControlVtbl,
}
@(private)
IAudioClientDuckingControlVtbl :: struct {
    using IUnKnownVtbl:                windows.IUnknownVtbl,
    SetDuckingOptionsForCurrentStream: proc "system" (
        this: ^IAudioClientDuckingControl,
        options: AUDIO_DUCKING_OPTIONS,
    ) -> windows.HRESULT,
}
IAudioClock_UUID_STRING :: "CD63314F-3FBA-4a1b-812C-EF96358728E7"
IAudioClock_UUID := &windows.IID {
    0xCD63314F,
    0x3FBA,
    0x4a1b,
    {0x81, 0x2C, 0xEF, 0x96, 0x35, 0x87, 0x28, 0xE7},
}
IAudioClock :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioClockVtbl,
}
@(private)
IAudioClockVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    GetFrequency:       proc "system" (
        this: ^IAudioClock,
        pu64Frequency: ^windows.UINT64,
    ) -> windows.HRESULT,
    GetPosition:        proc "system" (
        this: ^IAudioClock,
        pu64Position: ^windows.UINT64,
        pu64QPCPosition: ^windows.UINT64,
    ) -> windows.HRESULT,
    GetCharacteristics: proc "system" (
        this: ^IAudioClock,
        pdwCharacteristics: ^windows.DWORD,
    ) -> windows.HRESULT,
}

IAudioClock2_UUID_STRING :: "6f49ff73-6727-49ac-a008-d98cf5e70048"
IAudioClock2_UUID := &windows.IID {
    0x6F49FF73,
    0x6727,
    0x49AC,
    {0xA0, 0x08, 0xD9, 0x8C, 0xF5, 0xE7, 0x00, 0x48},
}
IAudioClock2 :: struct #raw_union {
    #subtype iaudioclock: windows.IUnknown,
    using vtable: ^IAudioClock2Vtbl,
}
@(private)
IAudioClock2Vtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    GetDevicePosition:  proc "system" (
        this: ^IAudioClock2,
        DevicePosition: ^windows.UINT64,
        QPCPosition: ^windows.UINT64,
    ) -> windows.HRESULT,
}

IAudioClockAdjustment_UUID_STRING :: "f6e4c0a0-46d9-4fb8-be21-57a3ef2b626c"
IAudioClockAdjustment_UUID := &windows.IID {
    0xF6E4C0A0,
    0x46D9,
    0x4FB8,
    {0xBE, 0x21, 0x57, 0xA3, 0xEF, 0x2B, 0x62, 0x6C},
}
IAudioClockAdjustment :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioClockAdjustmentVtbl,
}
@(private)
IAudioClockAdjustmentVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    SetSampleRate:      proc "system" (
        this: ^IAudioClockAdjustment,
        SampleRate: f32,
    ) -> windows.HRESULT,
}
IAudioEffectsChangedNotificationClient_UUID_STRING :: "A5DED44F-3C5D-4B2B-BD1E-5DC1EE20BBF6"
IAudioEffectsChangedNotificationClient_UUID := &windows.IID {
    0xA5DED44F,
    0x3C5D,
    0x4B2B,
    {0xBD, 0x1E, 0x5D, 0xC1, 0xEE, 0x20, 0xBB, 0xF6},
}
IAudioEffectsChangedNotificationClient :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioEffectsChangedNotificationClientVtbl,
}
@(private)
IAudioEffectsChangedNotificationClientVtbl :: struct {
    using IUnKnownVtbl:    windows.IUnknownVtbl,
    OnAudioEffectsChanged: proc "system" (
        this: ^IAudioEffectsChangedNotificationClient,
    ) -> windows.HRESULT,
}

IAudioEffectsManager_UUID_STRING :: "4460B3AE-4B44-4527-8676-7548A8ACD260"
IAudioEffectsManager_UUID := &windows.IID {
    0x4460B3AE,
    0x4B44,
    0x4527,
    {0x86, 0x76, 0x75, 0x48, 0xA8, 0xAC, 0xD2, 0x60},
}
IAudioEffectsManager :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioEffectsManagerVtbl,
}
@(private)
IAudioEffectsManagerVtbl :: struct {
    using IUnKnownVtbl:                                windows.IUnknownVtbl,
    RegisterAudioEffectsChangedNotificationCallback:   proc "system" (
        this: ^IAudioEffectsManager,
        client: ^IAudioEffectsChangedNotificationClient,
    ) -> windows.HRESULT,
    UnregisterAudioEffectsChangedNotificationCallback: proc "system" (
        this: ^IAudioEffectsManager,
        client: ^IAudioEffectsChangedNotificationClient,
    ) -> windows.HRESULT,
    GetAudioEffects:                                   proc "system" (
        this: ^IAudioEffectsManager,
        ppEffects: ^^AUDIO_EFFECT,
        numEffects: ^windows.UINT32,
    ) -> windows.HRESULT,
    SetAudioEffectState:                               proc "system" (
        this: ^IAudioEffectsManager,
        effectId: windows.GUID,
        state: AUDIO_EFFECT_STATE,
    ) -> windows.HRESULT,
}

IAudioStreamVolume_UUID_STRING :: "93014887-242D-4068-8A15-CF5E93B90FE3"
IAudioStreamVolume_UUID := &windows.IID {
    0x93014887,
    0x242D,
    0x4068,
    {0x8A, 0x15, 0xCF, 0x5E, 0x93, 0xB9, 0x0F, 0xE3},
}
IAudioStreamVolume :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioStreamVolumeVtbl,
}
@(private)
IAudioStreamVolumeVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    GetChannelCount:    proc "system" (
        this: ^IAudioStreamVolume,
        channelCount: ^windows.UINT32,
    ) -> windows.HRESULT,
    SetChannelVolume:   proc "system" (
        this: ^IAudioStreamVolume,
        dwIndex: windows.UINT32,
        fLevel: f32,
    ) -> windows.HRESULT,
    GetChannelVolume:   proc "system" (
        this: ^IAudioStreamVolume,
        dwIndex: windows.UINT32,
        pfLevel: ^f32,
    ) -> windows.HRESULT,
    SetAllVolumes:      proc "system" (
        this: ^IAudioStreamVolume,
        dwCount: windows.UINT32,
        pfVolumes: ^f32,
    ) -> windows.HRESULT,
    GetAllVolumes:      proc "system" (
        this: ^IAudioStreamVolume,
        dwCount: windows.UINT32,
        pfVolumes: ^f32,
    ) -> windows.HRESULT,
}

IAudioViewManagerService_UUID_STRING :: "A7A7EF10-1F49-45E0-AD35-612057CC8F74"
IAudioViewManagerService_UUID := &windows.IID {
    0xA7A7EF10,
    0x1F49,
    0x45E0,
    {0xAD, 0x35, 0x61, 0x20, 0x57, 0xCC, 0x8F, 0x74},
}
IAudioViewManagerService :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioViewManagerServiceVtbl,
}
@(private)
IAudioViewManagerServiceVtbl :: struct {
    using IUnKnownVtbl:   windows.IUnknownVtbl,
    SetAudioStreamWindow: proc "system" (
        this: ^IAudioViewManagerService,
        hwnd: windows.HWND,
    ) -> windows.HRESULT,
}

IChannelAudioVolume_UUID_STRING :: "1C158861-B533-4B30-B1CF-E853E51C59B8"
IChannelAudioVolume_UUID := &windows.IID {
    0x1C158861,
    0xB533,
    0x4B30,
    {0xB1, 0xCF, 0xE8, 0x53, 0xE5, 0x1C, 0x59, 0xB8},
}
IChannelAudioVolume :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IChannelAudioVolumeVtbl,
}
@(private)
IChannelAudioVolumeVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    GetChannelCount:    proc "system" (
        this: ^IChannelAudioVolume,
        dwCount: ^windows.UINT32,
    ) -> windows.HRESULT,
    SetChannelVolume:   proc "system" (
        this: ^IChannelAudioVolume,
        dwIndex: windows.UINT32,
        fLevel: f32,
        pfEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    GetChannelVolume:   proc "system" (
        this: ^IChannelAudioVolume,
        dwIndex: windows.UINT32,
        pfLevel: ^f32,
    ) -> windows.HRESULT,
    SetAllVolumes:      proc "system" (
        this: ^IChannelAudioVolume,
        dwCount: windows.UINT32,
        pfVolumes: ^f32,
        pfEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    GetAllVolumes:      proc "system" (
        this: ^IChannelAudioVolume,
        dwCount: windows.UINT32,
        pfVolumes: ^f32,
    ) -> windows.HRESULT,
}

ISimpleAudioVolume_UUID_STRING :: "87CE5498-68D6-44E5-9215-6DA47EF883D8"
ISimpleAudioVolume_UUID := &windows.IID {
    0x87CE5498,
    0x68D6,
    0x44E5,
    {0x92, 0x15, 0x6D, 0xA4, 0x7E, 0xF8, 0x83, 0xD8},
}
ISimpleAudioVolume :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^ISimpleAudioVolumeVtbl,
}
@(private)
ISimpleAudioVolumeVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    SetMasterVolume:    proc "system" (
        this: ^ISimpleAudioVolume,
        fLevel: f32,
        pguidEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    GetMasterVolume:    proc "system" (
        this: ^ISimpleAudioVolume,
        pfLevel: ^f32,
    ) -> windows.HRESULT,
    SetMute:            proc "system" (
        this: ^ISimpleAudioVolume,
        bMute: windows.BOOL,
        pguidEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    GetMute:            proc "system" (
        this: ^ISimpleAudioVolume,
        pbMute: ^windows.BOOL,
    ) -> windows.HRESULT,
}
