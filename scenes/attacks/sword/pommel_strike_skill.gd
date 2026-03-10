extends Node3D

signal attack_finished

@export var startup_duration: float = 0.1
@export var active_start: float = 0.1
@export var active_end: float = 0.15
@export var total_duration: float = 0.5
## Time until the player can move again.
@export var lock_duration: float = 0.5
@export var damage: float = 5.0
@export var hitstun_duration: float = 0.4
@export var knockback_force: float = 2.0
## Duration of the stun applied on first hit per combo
@export var stun_duration: float = 1.0
## Brief freeze on hit for impact feel
@export var hitstop_duration: float = 0.1

var _elapsed: float = 0.0
var _hit_bodies: Array[Node3D] = []
var _shapes_enabled_once: bool = false
var _lock_emitted: bool = false
var _visual: Area3D = null

const VISUAL_SCENE := preload("res://scenes/attacks/sword/pommel_strike.tscn")


func _set_visual_shapes_disabled(disabled: bool) -> void:
	if _visual == null:
		return
	for child in _visual.get_children():
		if child is CollisionShape3D:
			child.set_disabled(disabled)


func _ready() -> void:
	var visual_node: Node = VISUAL_SCENE.instantiate()
	if not visual_node is Area3D:
		push_error("[PommelStrikeSkill] Visual scene root must be Area3D")
		return
	_visual = visual_node as Area3D
	add_child(_visual)

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
		body.hit(damage, self, knockback_force, hitstun_duration, 0.0, 0.0, stun_duration)
		if hitstop_duration > 0.0:
			HitstopManager.trigger(hitstop_duration)
