package audio

import "base:runtime"
import "core:log"
import "vendor:miniaudio"

// The audio format are f32LE or f32BE depend on the platform
DEFAULT_AUDIO_SAMPLE_RATE :: 48000
DEFAULT_AUDIO_FRAME_SAMPLES :: 512
DEFAULT_AUDIO_CHANNELS :: 2
DEFAULT_AUDIO_FORMAT :: miniaudio.format.f32


Internal_Audio_State :: struct {
    device:   miniaudio.device,
    mini_ctx: miniaudio.context_type,
    log:      miniaudio.log,
    ctx:      runtime.Context,
}

Audio_State :: struct {}

as: Internal_Audio_State


audio_callback :: proc "c" (pDevice: ^miniaudio.device, pOutput, pInput: rawptr, frameCount: u32) {
    s := (^Internal_Audio_State)(pDevice.pUserData)
    context = s.ctx

    frame_size := size_of(f32) * DEFAULT_AUDIO_CHANNELS
    buf := ([^]u8)(pOutput)[:frameCount * u32(frame_size)]
    log.debugf("audio_callback: buf size {}", len(buf))
    runtime.memset(raw_data(buf), 0, len(buf))
}

log_callback :: proc "c" (pUserData: rawptr, level: u32, pMessage: cstring) {
    s := (^Internal_Audio_State)(pUserData)
    context = s.ctx
    switch level {
    case u32(miniaudio.log_level.LOG_LEVEL_DEBUG):
        log.debug(pMessage)
    case u32(miniaudio.log_level.LOG_LEVEL_INFO):
        log.info(pMessage)
    case u32(miniaudio.log_level.LOG_LEVEL_WARNING):
        log.warn(pMessage)
    case u32(miniaudio.log_level.LOG_LEVEL_ERROR):
        log.error(pMessage)
    case:
        log.errorf("Unknown log level: {}, msg: {}", level, pMessage)
    }

}

init_audio :: proc() -> Audio_State {
    as.ctx = context

    context_config := miniaudio.context_config_init()
    miniaudio.log_init(nil, &as.log)
    miniaudio.log_register_callback(&as.log, miniaudio.log_callback_init(log_callback, &as))
    context_config.pLog = &as.log

    miniaudio.context_init(nil, 0, &context_config, &as.mini_ctx)

    device_config := miniaudio.device_config_init(.playback)
    device_config.playback.format = DEFAULT_AUDIO_FORMAT
    device_config.playback.channels = DEFAULT_AUDIO_CHANNELS
    device_config.sampleRate = DEFAULT_AUDIO_SAMPLE_RATE
    device_config.periodSizeInFrames = DEFAULT_AUDIO_FRAME_SAMPLES / DEFAULT_AUDIO_CHANNELS
    device_config.dataCallback = audio_callback
    device_config.pUserData = &as

    ensure(miniaudio.device_init(&as.mini_ctx, &device_config, &as.device) == .SUCCESS)
    miniaudio.device_start(&as.device)
    return {}
}

destroy_audio :: proc() {
    miniaudio.device_uninit(&as.device)
}

