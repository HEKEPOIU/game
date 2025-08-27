package coreaudio
import "core:sys/windows"

IAudioSessionControl_UUID_STRING :: "F4B1A599-7266-4319-A8CA-E70ACB11E8CD"
IAudioSessionControl_UUID := &windows.IID {
    0xF4B1A599,
    0x7266,
    0x4319,
    {0xA8, 0xCA, 0xE7, 0x0A, 0xCB, 0x11, 0xE8, 0xCD},
}
IAudioSessionControl :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioSessionControlVtbl,
}

AudioSessionDisconnectReason :: enum i32 {
    DeviceRemoval,
    ServerShutdown,
    FormatChanged,
    SessionLogoff,
    SessionDisconnected,
    ExclusiveModeOverride,
}
@(private)
IAudioSessionControlVtbl :: struct {
    using IUnKnownVtbl:                 windows.IUnknownVtbl,
    GetState:                           proc "system" (
        this: ^IAudioSessionControl,
        pRetVal: ^AudioSessionState,
    ) -> windows.HRESULT,
    GetDisplayName:                     proc "system" (
        this: ^IAudioSessionControl,
        pRetVal: ^windows.LPWSTR,
    ) -> windows.HRESULT,
    SetDisplayName:                     proc "system" (
        this: ^IAudioSessionControl,
        Value: windows.LPCWSTR,
        EventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    GetIconPath:                        proc "system" (
        this: ^IAudioSessionControl,
        pRetVal: ^windows.LPWSTR,
    ) -> windows.HRESULT,
    SetIconPath:                        proc "system" (
        this: ^IAudioSessionControl,
        Value: windows.LPCWSTR,
        EventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    GetGroupingParam:                   proc "system" (
        this: ^IAudioSessionControl,
        pRetVal: ^windows.LPWSTR,
    ) -> windows.HRESULT,
    SetGroupingParam:                   proc "system" (
        this: ^IAudioSessionControl,
        Override: windows.LPCWSTR,
        EventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    RegisterAudioSessionNotification:   proc "system" (
        this: ^IAudioSessionControl,
        NewNotifications: ^IAudioSessionEvents,
    ) -> windows.HRESULT,
    UnregisterAudioSessionNotification: proc "system" (
        this: ^IAudioSessionControl,
        NewNotifications: ^IAudioSessionEvents,
    ) -> windows.HRESULT,
}

IAudioSessionEvents_UUID_STRING :: "24918ACC-64B3-37C1-8CA9-74A66E9957A8"
IAudioSessionEvents_UUID := &windows.IID {
    0x24918ACC,
    0x64B3,
    0x37C1,
    {0x8C, 0xA9, 0x74, 0xA6, 0x6E, 0x99, 0x57, 0xA8},
}
IAudioSessionEvents :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioSessionEventsVtbl,
}
@(private)
IAudioSessionEventsVtbl :: struct {
    using IUnKnownVtbl:     windows.IUnknownVtbl,
    OnDisplayNameChanged:   proc "system" (
        this: ^IAudioSessionEvents,
        NewDisplayName: windows.LPCWSTR,
        EventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    OnIconPathChanged:      proc "system" (
        this: ^IAudioSessionEvents,
        NewIconPath: windows.LPCWSTR,
        EventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    OnSimpleVolumeChanged:  proc "system" (
        this: ^IAudioSessionEvents,
        NewVolume: f32,
        NewMute: windows.BOOL,
        EventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    OnChannelVolumeChanged: proc "system" (
        this: ^IAudioSessionEvents,
        ChannelCount: windows.UINT32,
        NewChannelVolumes: ^f32,
        ChangedChannel: windows.DWORD,
        EventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    OnGroupingParamChanged: proc "system" (
        this: ^IAudioSessionEvents,
        NewGroupingParam: windows.LPCWSTR,
        EventContext: windows.LPCGUID,
    ) -> windows.HRESULT,
    OnStateChanged:         proc "system" (
        this: ^IAudioSessionEvents,
        NewState: AudioSessionState,
    ) -> windows.HRESULT,
    OnSessionDisconnected:  proc "system" (
        this: ^IAudioSessionEvents,
        DisconnectReason: AudioSessionDisconnectReason,
    ) -> windows.HRESULT,
}

IAudioSessionControl2_UUID_STRING :: "bfb7ff88-7239-4fc9-8fa2-07c950be9c6d"
IAudioSessionControl2_UUID := &windows.IID {
    0xBFB7FF88,
    0x7239,
    0x4FC9,
    {0x8F, 0xA2, 0x07, 0xC9, 0x50, 0xBE, 0x9C, 0x6D},
}
IAudioSessionControl2 :: struct #raw_union {
    #subtype iaudiosessioncontrol: IAudioSessionControl,
    using vtable:         ^IAudioSessionControl2Vtbl,
}
@(private)
IAudioSessionControl2Vtbl :: struct {
    using IAudioSessionControlVtbl: IAudioSessionControlVtbl,
    GetSessionIdentifier:           proc "system" (
        this: ^IAudioSessionControl2,
        pRetVal: ^windows.LPWSTR,
    ) -> windows.HRESULT,
    GetSessionInstanceIdentifier:   proc "system" (
        this: ^IAudioSessionControl2,
        pRetVal: ^windows.LPWSTR,
    ) -> windows.HRESULT,
    GetProcessId:                   proc "system" (
        this: ^IAudioSessionControl2,
        pRetVal: ^windows.DWORD,
    ) -> windows.HRESULT,
    IsSystemSoundsSession:          proc "system" (
        this: ^IAudioSessionControl2,
    ) -> windows.HRESULT,
    SetDuckingPreference:           proc "system" (
        this: ^IAudioSessionControl2,
        optOut: windows.BOOL,
    ) -> windows.HRESULT,
}

IAudioSessionEnumerator_UUID_STRING :: "E2F5BB11-0570-40CA-ACDD-3AA01277DEE8"
IAudioSessionEnumerator_UUID := &windows.IID {
    0xE2F5BB11,
    0x0570,
    0x40CA,
    {0xAC, 0xDD, 0x3A, 0xA0, 0x12, 0x77, 0xDE, 0xE8},
}
IAudioSessionEnumerator :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioSessionEnumeratorVtbl,
}
@(private)
IAudioSessionEnumeratorVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    GetCount:           proc "system" (
        this: ^IAudioSessionEnumerator,
        SessionCount: ^windows.UINT32,
    ) -> windows.HRESULT,
    GetSession:         proc "system" (
        this: ^IAudioSessionEnumerator,
        SessionCount: windows.UINT32,
        Session: ^^IAudioSessionControl,
    ) -> windows.HRESULT,
}

IAudioSessionManager_UUID_STRING :: "BFA971F1-4D5E-40BB-935E-967039BFBEE4"
IAudioSessionManager_UUID := &windows.IID {
    0xBFA971F1,
    0x4D5E,
    0x40BB,
    {0x93, 0x5E, 0x96, 0x70, 0x39, 0xBF, 0xBE, 0xE4},
}
IAudioSessionManager :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioSessionManagerVtbl,
}
@(private)
IAudioSessionManagerVtbl :: struct {
    using IUnKnownVtbl:     windows.IUnknownVtbl,
    GetAudioSessionControl: proc "system" (
        this: ^IAudioSessionManager,
        AudioSessionGuid: windows.LPCWSTR,
        StreamFlags: windows.DWORD,
        SessionControl: ^^IAudioSessionControl,
    ) -> windows.HRESULT,
    GetSimpleAudioVolume:   proc "system" (
        this: ^IAudioSessionManager,
        AudioSessionGuid: windows.LPCWSTR,
        StreamFlags: windows.DWORD,
        AudioVolume: ^^ISimpleAudioVolume,
    ) -> windows.HRESULT,
}

IAudioSessionManager2_UUID_STRING :: "77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F"
IAudioSessionManager2_UUID := &windows.IID {
    0x77AA99A0,
    0x1BD6,
    0x484F,
    {0x8B, 0xC7, 0x2C, 0x65, 0x4C, 0x9A, 0x9B, 0x6F},
}
IAudioSessionManager2 :: struct #raw_union {
    #subtype iaudiosessionmanager: IAudioSessionManager,
    using vtable:         ^IAudioSessionManager2Vtbl,
}
@(private)
IAudioSessionManager2Vtbl :: struct {
    using IAudioSessionManagerVtbl: IAudioSessionManagerVtbl,
    GetSessionEnumerator:           proc "system" (
        this: ^IAudioSessionManager2,
        SessionEnum: ^^IAudioSessionEnumerator,
    ) -> windows.HRESULT,
    RegisterSessionNotification:    proc "system" (
        this: ^IAudioSessionManager2,
        SessionNotification: ^IAudioSessionEvents,
    ) -> windows.HRESULT,
    UnregisterSessionNotification:  proc "system" (
        this: ^IAudioSessionManager2,
        SessionNotification: ^IAudioSessionEvents,
    ) -> windows.HRESULT,
    RegisterDuckNotification:       proc "system" (
        this: ^IAudioSessionManager2,
        sessionID: windows.LPCWSTR,
        duckNotification: ^IAudioVolumeDuckNotification,
    ) -> windows.HRESULT,
    UnregisterDuckNotification:     proc "system" (
        this: ^IAudioSessionManager2,
        duckNotification: ^IAudioVolumeDuckNotification,
    ) -> windows.HRESULT,
}
IAudioSessionNotification_UUID_STRING :: "641DD20B-4D41-49CC-ABA3-174B9477BB08"
IAudioSessionNotification_UUID := &windows.IID {
    0x641DD20B,
    0x4D41,
    0x49CC,
    {0xAB, 0xA3, 0x17, 0x4B, 0x94, 0x77, 0xBB, 0x08},
}
IAudioSessionNotification :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioSessionNotificationVtbl,
}
@(private)
IAudioSessionNotificationVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    OnSessionCreated:   proc "system" (
        this: ^IAudioSessionNotification,
        NewSession: ^IAudioSessionControl,
    ) -> windows.HRESULT,
}


IAudioVolumeDuckNotification_UUID_STRING :: "C3B284D4-6D39-4359-B3CF-B56DDB3BB39C"
IAudioVolumeDuckNotification_UUID := &windows.IID {
    0xC3B284D4,
    0x6D39,
    0x4359,
    {0xB3, 0xCF, 0xB5, 0x6D, 0xDB, 0x3B, 0xB3, 0x9C},
}
IAudioVolumeDuckNotification :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IAudioVolumeDuckNotificationVtbl,
}
@(private)
IAudioVolumeDuckNotificationVtbl :: struct {
    using IUnKnownVtbl:         windows.IUnknownVtbl,
    OnVolumeDuckNotification:   proc "system" (
        this: ^IAudioVolumeDuckNotification,
        sessionID: windows.LPCWSTR,
        countCommunicationSessions: windows.UINT32,
    ) -> windows.HRESULT,
    OnVolumeUnduckNotification: proc "system" (
        this: ^IAudioVolumeDuckNotification,
        sessionID: windows.LPCWSTR,
    ) -> windows.HRESULT,
}
