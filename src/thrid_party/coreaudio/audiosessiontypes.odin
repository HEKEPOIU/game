package coreaudio

AUDCLNT_SHAREMODE :: enum i32 {
    SHARED,
    EXCLUSIVE,
}


AUDIO_STREAM_CATEGORY :: enum i32 {
    Other,
    ForegroundOnlyMedia,
    BackgroundCapableMedia,
    Communications,
    Alerts,
    SoundEffects,
    GameEffects,
    GameMedia,
    GameChat,
    Speech,
    Movie,
    Media,
    // below need windows 10 1909 after
    FarFieldSpeech,
    UniformSpeech,
    VoiceTyping,
}

AudioSessionState :: enum i32 {
    Inactive,
    Active,
    Expired,
}
