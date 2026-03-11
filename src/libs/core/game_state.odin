package core
import "core:time"
import "libs:platform"

Game_State :: struct {
    target_fps:       u64,
    current_frame:    u64,
    total_time:       time.Duration,
    delta_time:       time.Duration,
    frame_start_time: time.Tick,
}

start_frame :: proc(s: ^Game_State) {
    s.frame_start_time = time.tick_now()
}

end_frame :: proc(s: ^Game_State) {
    ms_elapsed := time.tick_since(s.frame_start_time)
    target_duration := time.Second / time.Duration(s.target_fps)
    platform.sleep(target_duration - ms_elapsed)


    s.delta_time = time.tick_since(s.frame_start_time)
    s.total_time += s.delta_time
    s.current_frame += 1
}
