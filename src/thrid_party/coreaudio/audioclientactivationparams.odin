package coreaudio
import "core:sys/windows"

AUDIO_SYSTEMEFFECTS_PROPERTYSTORE_TYPE :: enum i32 {
    Default  = 0,
    User     = 1,
    Volatile = 2,
}
AUDIOCLIENT_ACTIVATION_TYPE :: enum i32 {
    Default,
    PROCESS_LOOPBAC,
}
AUDIOCLIENT_ACTIVATION_PARAMS :: struct {
    ActivationType: AUDIOCLIENT_ACTIVATION_TYPE,
    DUMMYUNIONNAME: struct #raw_union {
        ProcessLoopbackParams: AUDIOCLIENT_PROCESS_LOOPBACK_PARAMS,
    },
}

AUDIOCLIENT_PROCESS_LOOPBACK_PARAMS :: struct {
    TargetProcessId:     windows.DWORD,
    ProcessLoopbackMode: PROCESS_LOOPBACK_MODE,
}

PROCESS_LOOPBACK_MODE :: enum i32 {
    INCLUDE_TARGET_PROCESS_TREE,
    EXCLUDE_TARGET_PROCESS_TREE,
}
