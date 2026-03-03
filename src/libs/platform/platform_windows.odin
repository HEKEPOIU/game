package platform

import win "core:sys/windows"
import "core:time"

sleep :: #force_inline proc(d: time.Duration) {
    win.timeBeginPeriod(1)
    time.accurate_sleep(target_duration - ms_elapsed)
    win.timeEndPeriod(1)
}
