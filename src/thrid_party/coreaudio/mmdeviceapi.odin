package coreaudio
import "core:sys/windows"

ERole :: enum i32 {
    eConsole,
    eMultimedia,
    eCommunications,
}

EDataFlow :: enum i32 {
    eRender,
    eCapture,
    eAll,
}

DEVICE_STATE_ACTIVE :: 0x00000001
DEVICE_STATE_DISABLED :: 0x00000002
DEVICE_STATE_NOTPRESENT :: 0x00000004
DEVICE_STATE_UNPLUGGED :: 0x00000008
DEVICE_STATEMASK_ALL :: 0x0000000f

IActivateAudioInterfaceAsyncOperation_UUID_STRING :: "72A22D78-CDE4-431D-B8CC-843A71199B6D"
IActivateAudioInterfaceAsyncOperation_UUID := &windows.IID {
    0x72A22D78,
    0xCDE4,
    0x431D,
    {0xB8, 0xCC, 0x84, 0x3A, 0x71, 0x19, 0x9B, 0x6D},
}
@(private)
IActivateAudioInterfaceAsyncOperationVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    GetActivateResult:  proc "system" (
        this: ^IActivateAudioInterfaceAsyncOperation,
        activateResult: ^windows.HRESULT,
        activationInterface: ^^windows.IUnknown,
    ) -> windows.HRESULT,
}
IActivateAudioInterfaceAsyncOperation :: struct #raw_union {
    #subtype IUnknown: windows.IUnknown,
    using vtable: ^IActivateAudioInterfaceAsyncOperationVtbl,
}

IActivateAudioInterfaceCompletionHandler_UUID_STRING :: "41D949AB-9862-444A-80F6-C261334DA5EB"
IActivateAudioInterfaceCompletionHandler_UUID := &windows.IID {
    0x41D949AB,
    0x9862,
    0x444A,
    {0x80, 0xF6, 0xC2, 0x61, 0x33, 0x4D, 0xA5, 0xEB},
}
@(private)
IActivateAudioInterfaceCompletionHandlerVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    ActivateCompleted:  proc "system" (
        this: ^IActivateAudioInterfaceCompletionHandler,
        activateOperation: ^IActivateAudioInterfaceAsyncOperation,
    ) -> windows.HRESULT,
}
IActivateAudioInterfaceCompletionHandler :: struct #raw_union {
    #subtype IUnknown: windows.IUnknown,
    using vtable: ^IActivateAudioInterfaceCompletionHandlerVtbl,
}


IAudioSystemEffectsPropertyChangeNotificationClient_UUID_STRING :: "20049D40-56D5-400E-A2EF-385599FEED49"
IAudioSystemEffectsPropertyChangeNotificationClient_UUID := &windows.IID {
    0x20049D40,
    0x56D5,
    0x400E,
    {0xA2, 0xEF, 0x38, 0x55, 0x99, 0xFE, 0xED, 0x49},
}
@(private)
IAudioSystemEffectsPropertyChangeNotificationClientVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    OnPropertyChanged:  proc "system" (
        this: ^IAudioSystemEffectsPropertyChangeNotificationClient,
        type: AUDIO_SYSTEMEFFECTS_PROPERTYSTORE_TYPE,
        propKey: windows.PROPERTYKEY,
    ) -> windows.HRESULT,
}
IAudioSystemEffectsPropertyChangeNotificationClient :: struct #raw_union {
    #subtype IUnknown: windows.IUnknown,
    using vtable: ^IAudioSystemEffectsPropertyChangeNotificationClientVtbl,
}

IAudioSystemEffectsPropertyStore_UUID_STRING :: "302AE7F9-D7E0-43E4-971B-1F8293613D2A"
IAudioSystemEffectsPropertyStore_UUID := &windows.IID {
    0x302AE7F9,
    0xD7E0,
    0x43E4,
    {0x97, 0x1B, 0x1F, 0x82, 0x93, 0x61, 0x3D, 0x2A},
}
@(private)
IAudioSystemEffectsPropertyStoreVtbl :: struct {
    using IUnKnownVtbl:                   windows.IUnknownVtbl,
    OpenDefaultPropertyStore:             proc "system" (
        stgmAccess: windows.DWORD,
        propStore: ^^windows.IPropertyStore,
    ) -> windows.HRESULT,
    OpenUserPropertyStore:                proc "system" (
        stgmAccess: windows.DWORD,
        propStore: ^^windows.IPropertyStore,
    ) -> windows.HRESULT,
    OpenVolatilePropertyStore:            proc "system" (
        stgmAccess: windows.DWORD,
        propStore: ^^windows.IPropertyStore,
    ) -> windows.HRESULT,
    ResetUserPropertyStore:               proc "system" (),
    ResetVolatilePropertyStore:           proc "system" (),
    RegisterPropertyChangeNotification:   proc "system" (
        callback: ^IAudioSystemEffectsPropertyChangeNotificationClient,
    ) -> windows.HRESULT,
    UnregisterPropertyChangeNotification: proc "system" (
        callback: ^IAudioSystemEffectsPropertyChangeNotificationClient,
    ) -> windows.HRESULT,
}

IAudioSystemEffectsPropertyStore :: struct #raw_union {
    #subtype IUnknown: windows.IUnknown,
    using vtable: ^IAudioSystemEffectsPropertyStoreVtbl,
}

IMMDevice_UUID_STRING :: "D666063F-1587-4E43-81F1-B948E807363F"
IMMDevice_UUID := &windows.IID {
    0xD666063F,
    0x1587,
    0x4E43,
    {0x81, 0xF1, 0xB9, 0x48, 0xE8, 0x07, 0x36, 0x3F},
}
IMMDevice :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IMMDeviceVtbl,
}
@(private)
IMMDeviceVtbl :: struct {
    using IUnknownVtbl: windows.IUnknownVtbl,
    Activate:           proc "system" (
        this: ^IMMDevice,
        iid: windows.REFIID,
        dwClsCtx: windows.DWORD,
        pActivateParams: ^windows.PROPVARIANT,
        ppInterface: ^rawptr,
    ) -> windows.HRESULT,
    OpenPropertyStore:  proc "system" (
        this: ^IMMDevice,
        stgmAccess: windows.DWORD,
        ppProperties: ^windows.IPropertyStore,
    ) -> windows.HRESULT,
    GetId:              proc "system" (
        this: ^IMMDevice,
        ppstrId: windows.LPWSTR,
    ) -> windows.HRESULT,
    GetState:           proc "system" (
        this: ^IMMDevice,
        pwState: ^windows.DWORD,
    ) -> windows.HRESULT,
}


IMMDeviceCollection_UUID_STRING :: "0BD7A1BE-7A1A-44DB-8397-CC5392387B5E"
IMMDeviceCollection_UUID := &windows.IID {
    0x0BD7A1BE,
    0x7A1A,
    0x44DB,
    {0x83, 0x97, 0xCC, 0x53, 0x92, 0x38, 0x7B, 0x5E},
}
IMMDeviceCollection :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IMMDeviceCollectionVtbl,
}
@(private)
IMMDeviceCollectionVtbl :: struct {
    using IUnknownVtbl: windows.IUnknownVtbl,
    GetCount:           proc "system" (
        this: ^IMMDeviceCollection,
        pcDevices: ^windows.UINT,
    ) -> windows.HRESULT,
    Item:               proc "system" (
        this: ^IMMDeviceCollection,
        nDevice: windows.UINT,
        device: ^^IMMDevice,
    ) -> windows.HRESULT,
}

IMMDeviceEnumerator_UUID_STRING :: "A95664D2-9614-4F35-A746-DE8DB63617E6"
IMMDeviceEnumerator_UUID := &windows.IID {
    0xA95664D2,
    0x9614,
    0x4F35,
    {0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6},
}
IMMDeviceEnumerator :: struct #raw_union {
    #subtype iunknown: windows.IUnknown,
    using vtable: ^IMMDeviceEnumeratorVtbl,
}

CLSID_MMDeviceEnumerator := windows.CLSID {
    0xBCDE0395,
    0xE52F,
    0x467C,
    {0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E},
}

@(private)
IMMDeviceEnumeratorVtbl :: struct {
    using IUnknownVtbl:                     windows.IUnknownVtbl,
    EnumAudioEndpoints:                     proc "system" (
        this: ^IMMDeviceEnumerator,
        dataFlow: EDataFlow,
        dwStateMask: windows.DWORD,
        ppDevices: ^^IMMDeviceCollection,
    ) -> windows.HRESULT,
    GetDefaultAudioEndpoint:                proc "system" (
        this: ^IMMDeviceEnumerator,
        dataFlow: EDataFlow,
        role: ERole,
        ppEndpoint: ^^IMMDevice,
    ) -> windows.HRESULT,
    GetDevice:                              proc "system" (
        this: ^IMMDeviceEnumerator,
        pwstr: windows.LPWSTR,
        ppDevice: ^^IMMDevice,
    ) -> windows.HRESULT,
    RegisterEndpointNotificationCallback:   proc "system" (
        this: ^IMMDeviceEnumerator,
        pClient: rawptr,
    ) -> windows.HRESULT,
    UnregisterEndpointNotificationCallback: proc "system" (pClient: rawptr) -> windows.HRESULT,
}


IMMEndpoint_UUID_STRING :: "1BE09788-6894-4089-8586-9A2A6C265AC5"
IMMEndpoint_UUID := &windows.IID {
    0x1BE09788,
    0x6894,
    0x4089,
    {0x85, 0x86, 0x9A, 0x2A, 0x6C, 0x26, 0x5A, 0xC5},
}
@(private)
IMMEndpointVtbl :: struct {
    using IUnKnownVtbl: windows.IUnknownVtbl,
    GetDataFlow:        proc "system" (
        this: ^IMMEndpoint,
        pDataFlow: ^EDataFlow,
    ) -> windows.HRESULT,
}

IMMEndpoint :: struct #raw_union {
    #subtype IUnknown: windows.IUnknown,
    using vtable: ^IMMEndpointVtbl,
}

IMMNotificationClient_UUID_STRING :: "7991EEC9-7E89-4D85-8390-6C703CEC60C0"
IMMNotificationClient_UUID := &windows.IID {
    0x7991EEC9,
    0x7E89,
    0x4D85,
    {0x83, 0x90, 0x6C, 0x70, 0x3C, 0xEC, 0x60, 0xC0},
}
@(private)
IMMNotificationClientVtbl :: struct {
    using IUnKnownVtbl:     windows.IUnknownVtbl,
    OnDeviceStateChanged:   proc "system" (
        this: ^IMMNotificationClient,
        pwstrDeviceId: windows.LPCWSTR,
        dwnewState: windows.DWORD,
    ) -> windows.HRESULT,
    OnDeviceAdded:          proc "system" (
        this: ^IMMNotificationClient,
        pwstrDeviceId: windows.LPCWSTR,
    ) -> windows.HRESULT,
    OnDeviceRemoved:        proc "system" (
        this: ^IMMNotificationClient,
        pwstrDefaultDeviceId: ^windows.LPCWSTR,
    ) -> windows.HRESULT,
    OnDefaultDeviceChanged: proc "system" (
        this: ^IMMNotificationClient,
        flow: EDataFlow,
        role: ERole,
        pwstrDefaultDeviceId: ^windows.LPWSTR,
    ) -> windows.HRESULT,
    OnPropertyValueChanged: proc "system" (
        this: ^IMMNotificationClient,
        pwstrDeviceId: ^windows.LPWSTR,
        key: windows.PROPERTYKEY,
    ) -> windows.HRESULT,
}

IMMNotificationClient :: struct #raw_union {
    #subtype IUnknown: windows.IUnknown,
    using vtable: ^IMMNotificationClientVtbl,
}
