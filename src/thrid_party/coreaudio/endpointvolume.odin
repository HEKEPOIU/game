package coreaudio
import "core:sys/windows"

AUDIO_VOLUME_NOTIFICATION_DATA :: struct {
    guidEventContext: windows.GUID,
    bMuted:           windows.BOOL,
    fMasterVolume:    f32,
    nChannels:        windows.UINT32,
    afChannelVolumes: [1]f32,
}
PAUDIO_VOLUME_NOTIFICATION_DATA :: ^AUDIO_VOLUME_NOTIFICATION_DATA

IAudioEndpointVolume_UUID_STRING :: "5CDF2C82-841E-4546-9722-0CF74078229A"
IAudioEndpointVolume_UUID := &windows.IID {
    0x5CDF2C82,
    0x841E,
    0x4546,
    {0x97, 0x22, 0x0C, 0xF7, 0x40, 0x78, 0x22, 0x9A},
}
IAudioEndpointVolume :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioEndpointVolumeVtbl,
}
@(private)
IAudioEndpointVolumeVtbl :: struct {
    using IUnKnownVtbl:            windows.IUnknownVtbl,
    RegisterControlChangeNotify:   proc "system" (
        this: ^IAudioEndpointVolume,
        pNotify: ^IAudioEndpointVolumeCallback,
    ) -> windows.HRESULT,
    UnregisterControlChangeNotify: proc "system" (
        this: ^IAudioEndpointVolume,
        pNotify: ^IAudioEndpointVolumeCallback,
    ) -> windows.HRESULT,
    GetChannelCount:               proc "system" (
        this: ^IAudioEndpointVolume,
        pnChannelCount: ^windows.UINT,
    ) -> windows.HRESULT,
    SetMasterVolumeLevel:          proc "system" (
        this: ^IAudioEndpointVolume,
        fLevelDB: f32,
        pguidEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    SetMasterVolumeLevelScalar:    proc "system" (
        this: ^IAudioEndpointVolume,
        fLevel: f32,
        pguidEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    GetMasterVolumeLevel:          proc "system" (
        this: ^IAudioEndpointVolume,
        pfLevelDB: ^f32,
    ) -> windows.HRESULT,
    GetMasterVolumeLevelScalar:    proc "system" (
        this: ^IAudioEndpointVolume,
        pfLevel: ^f32,
    ) -> windows.HRESULT,
    SetChannelVolumeLevel:         proc "system" (
        this: ^IAudioEndpointVolume,
        nChannel: windows.UINT,
        fLevelDB: f32,
        pguidEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    SetChannelVolumeLevelScalar:   proc "system" (
        this: ^IAudioEndpointVolume,
        nChannel: windows.UINT,
        fLevel: f32,
        pguidEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    GetChannelVolumeLevel:         proc "system" (
        this: ^IAudioEndpointVolume,
        nChannel: windows.UINT,
        pfLevelDB: ^f32,
    ) -> windows.HRESULT,
    GetChannelVolumeLevelScalar:   proc "system" (
        this: ^IAudioEndpointVolume,
        nChannel: windows.UINT,
        pfLevel: ^f32,
    ) -> windows.HRESULT,
    SetMute:                       proc "system" (
        this: ^IAudioEndpointVolume,
        bMute: windows.BOOL,
        pguidEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    GetMute:                       proc "system" (
        this: ^IAudioEndpointVolume,
        pbMute: ^windows.BOOL,
    ) -> windows.HRESULT,
    GetVolumeStepInfo:             proc "system" (
        this: ^IAudioEndpointVolume,
        pnStep: ^windows.UINT32,
        pnStepCount: ^windows.UINT32,
    ) -> windows.HRESULT,
    VolumeStepUp:                  proc "system" (
        this: ^IAudioEndpointVolume,
        pguidEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    VolumeStepDown:                proc "system" (
        this: ^IAudioEndpointVolume,
        pguidEventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    QueryHardwareSupport:          proc "system" (
        this: ^IAudioEndpointVolume,
        pdwHardwareSupportMask: ^windows.DWORD,
    ) -> windows.HRESULT,
    GetVolumeRange:                proc "system" (
        this: ^IAudioEndpointVolume,
        pflVolumeMindB: ^f32,
        pflVolumeMaxdB: ^f32,
        pflVolumeIncrementdB: ^f32,
    ) -> windows.HRESULT,
}


IAudioEndpointVolumeCallback_UUID_STRING :: "657804FA-D6AD-4496-8A60-352752AF4F89"
IAudioEndpointVolumeCallback_UUID := &windows.IID {
    0x657804FA,
    0xD6AD,
    0x4496,
    {0x8A, 0x60, 0x35, 0x27, 0x52, 0xAF, 0x4F, 0x89},
}
IAudioEndpointVolumeCallback :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioEndpointVolumeCallbackVtbl,
}
@(private)
IAudioEndpointVolumeCallbackVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    OnNotify:           proc "system" (
        this: ^IAudioEndpointVolumeCallback,
        pNotify: PAUDIO_VOLUME_NOTIFICATION_DATA,
    ) -> windows.HRESULT,
}

IAudioEndpointVolumeEx_UUID_STRING :: "66E11784-F695-4F28-A505-A7080081A78F"
IAudioEndpointVolumeEx_UUID := &windows.IID {
    0x66E11784,
    0xF695,
    0x4F28,
    {0xA5, 0x05, 0xA7, 0x08, 0x00, 0x81, 0xA7, 0x8F},
}
IAudioEndpointVolumeEx :: struct #raw_union {
    #subtype iaudioendpointvolume: IAudioEndpointVolume,
    using vtable:         ^IAudioEndpointVolumeExVtbl,
}
@(private)
IAudioEndpointVolumeExVtbl :: struct {
    using IAudioEndpointVolumeVtbl: IAudioEndpointVolumeVtbl,
    GetVolumeRangeChannel:          proc "system" (
        this: ^IAudioEndpointVolumeEx,
        nChannel: windows.UINT,
        pflVolumeMindB: ^f32,
        pflVolumeMaxdB: ^f32,
        pflVolumeIncrementdB: ^f32,
    ) -> windows.HRESULT,
}

IAudioMeterInformation_UUID_STRING :: "C02216F6-8C67-4B5B-9D00-D008E73E0064"
IAudioMeterInformation_UUID := &windows.IID {
    0xC02216F6,
    0x8C67,
    0x4B5B,
    {0x9D, 0x00, 0xD0, 0x08, 0xE7, 0x3E, 0x00, 0x64},
}
IAudioMeterInformation :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioMeterInformationVtbl,
}
@(private)
IAudioMeterInformationVtbl :: struct {
    using IUnKnownVtbl:      windows.IUnknownVtbl,
    GetPeakValue:            proc "system" (
        this: ^IAudioMeterInformation,
        pfPeak: ^f32,
    ) -> windows.HRESULT,
    GetMeteringChannelCount: proc "system" (
        this: ^IAudioMeterInformation,
        pnChannelCount: ^windows.UINT,
    ) -> windows.HRESULT,
    GetChannelsPeakValues:   proc "system" (
        this: ^IAudioMeterInformation,
        u32ChannelCount: windows.UINT32,
        afPeakValues: ^f32,
    ) -> windows.HRESULT,
    QueryHardwareSupport:    proc "system" (
        this: ^IAudioMeterInformation,
        pdwHardwareSupportMask: ^windows.DWORD,
    ) -> windows.HRESULT,
}
