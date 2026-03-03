package platform

import "core:time"

sleep :: #force_inline proc(d: time.Duration) {
    time.accurate_sleep(d)
}
