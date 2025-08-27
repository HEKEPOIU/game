// Bindings Produced by fendevel
// Src: https://github.com/fendevel/odin-wasapi/blob/main/enums.odin
package coreaudio
import "core:sys/windows"

REFERENCE_TIME :: windows.LONGLONG

Audio_Client_Stream_Flags :: bit_set[Audio_Client_Stream_Flag;windows.DWORD]
Audio_Client_Stream_Flag :: enum {
    Cross_Process             = 16,
    Loop_Back                 = 17,
    Event_Callback            = 18,
    No_Persist                = 19,
    Rate_Adjusted             = 20,
    Source_Default_Quality    = 27,
    Expire_When_Unowned       = 28,
    Display_Hide              = 29,
    Display_Hide_When_Expired = 30,
    Auto_Convert_PCM          = 31,
}

