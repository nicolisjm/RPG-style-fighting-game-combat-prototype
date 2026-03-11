extends Node3D

signal attack_finished
signal hit_confirmed

@export var skill_tag: int = CombatState.SkillTag.STARTER
@export var startup_duration: float = 0.0
@export var active_start: float = 0.1
@export var active_end: float = 0.2
@export var total_duration: float = 0.7
## Time until the player can move again for the first slash. Can be less than total_duration.
@export var lock_duration_part0: float = 0.25
## Time until the player can move again for the second slash.
@export var lock_duration_part1: float = 0.5
@export var damage: float = 10.0
@export var hitstun_duration: float = 0.4
@export var knockback_force: float = 3.0
## Tilts the slash visual toward the camera so it's visible from all aim directions (degrees)
@export var camera_tilt: float = 0
## Upward launch force applied by part 1 (enables juggle)
@export var launch_force_part1: float = 0
## Vertical force applied when the enemy is already airborne (juggle pop-up)
@export var juggle_force: float = 5.0
## Brief freeze on hit for impact feel
@export var hitstop_duration: float = 0.05
## Part 0 = first slash (top-right to bottom-left), Part 1 = second slash (opposite). Set by player before add_child.
var attack_part: int = 0
var _elapsed: float = 0.0
var _hit_bodies: Array[Node3D] = []
var _shapes_enabled_once: bool = false
var _lock_emitted: bool = false
var _visual: Area3D = null

const VISUAL_SCENE := preload("res://scenes/attacks/sword/sword_starter.tscn")


func _set_visual_shapes_disabled(disabled: bool) -> void:
	if _visual == null:
		return
	for child in _visual.get_children():
		if child is CollisionShape3D:
			child.set_disabled(disabled)


func _ready() -> void:
	var visual_node: Node = VISUAL_SCENE.instantiate()
	if not visual_node is Area3D:
		push_error("[SwordStarterSkill] Visual scene root must be Area3D")
		return
	_visual = visual_node as Area3D
	add_child(_visual)

	_visual.rotation.x = deg_to_rad(camera_tilt)
	if attack_part == 0:
		_visual.rotation.z = deg_to_rad(-5)
	else:
		_visual.rotation.z = deg_to_rad(175)

	_set_visual_shapes_disabled(true)
	_visual.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_elapsed += delta

	if _elapsed >= active_start:
		if not _shapes_enabled_once:
			_shapes_enabled_once = true
		_set_visual_shapes_disabled(false)

	if _elapsed >= active_end:
		_set_visual_shapes_disabled(true)

	var lock_duration: float = lock_duration_part1 if attack_part == 1 else lock_duration_part0
	if not _lock_emitted and _elapsed >= lock_duration:
		_lock_emitted = true
		attack_finished.emit()

	if _elapsed >= total_duration:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("enemy"):
		return
	if body in _hit_bodies:
		return
	_hit_bodies.append(body)
	if body.has_method("hit"):
		var launch_up: float = launch_force_part1 if attack_part == 1 else 0.0
		body.hit(damage, self, knockback_force, hitstun_duration, launch_up, juggle_force)
		if hitstop_duration > 0.0:
			HitstopManager.trigger(hitstop_duration)
	if _hit_bodies.size() == 1:
		hit_confirmed.emit()
