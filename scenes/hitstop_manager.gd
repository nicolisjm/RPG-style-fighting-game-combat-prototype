extends Node

## Near-zero time scale avoids GPU particle rendering glitches at exactly 0.
const FROZEN_TIME_SCALE: float = 0.001

var _active: bool = false


func trigger(duration: float) -> void:
	if _active:
		return
	_active = true
	Engine.time_scale = FROZEN_TIME_SCALE
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_active = false
