extends CharacterBody3D

const HIT_SOUNDS := [
	"res://sfx/hitflesh1.mp3",
	"res://sfx/hitflesh2.mp3",
	"res://sfx/hitflesh3.mp3",
]

const GRAVITY: float = 19.6
const FRICTION: float = 8.0
## Horizontal knockback is multiplied by this when the enemy is airborne (weaker horizontal push in the air)
const AIRBORNE_KNOCKBACK_SCALE: float = 0.8

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var hit_player: AudioStreamPlayer3D = $HitSound

signal combo_changed(count: int)

var state: CombatState.State = CombatState.State.IDLE
var hitstun_remaining: float = 0.0
var combo_count: int = 0
var airborne_hit_count: int = 0
var _kb_velocity: Vector3 = Vector3.ZERO
var _original_color: Color = Color(0.9, 0.2, 0.2)
var _mat: StandardMaterial3D = null


func _ready() -> void:
	add_to_group("enemy")
	# Duplicate material so each enemy instance is independent
	if mesh_instance and mesh_instance.mesh.get_surface_count() > 0:
		var src: Material = mesh_instance.get_surface_override_material(0)
		if not src:
			src = mesh_instance.mesh.surface_get_material(0)
		if src is StandardMaterial3D:
			_mat = src.duplicate() as StandardMaterial3D
			mesh_instance.set_surface_override_material(0, _mat)
			_original_color = _mat.albedo_color


func _physics_process(delta: float) -> void:
	# Gravity
	_kb_velocity.y -= GRAVITY * delta

	# Horizontal friction
	var horiz := Vector3(_kb_velocity.x, 0.0, _kb_velocity.z)
	var friction_amount := FRICTION * delta
	if horiz.length() <= friction_amount:
		_kb_velocity.x = 0.0
		_kb_velocity.z = 0.0
	else:
		var braked := horiz - horiz.normalized() * friction_amount
		_kb_velocity.x = braked.x
		_kb_velocity.z = braked.z

	velocity = _kb_velocity
	move_and_slide()
	_kb_velocity = velocity

	# State transitions
	match state:
		CombatState.State.HITSTUN:
			hitstun_remaining -= delta
			if hitstun_remaining <= 0.0 and is_on_floor():
				_set_state(CombatState.State.IDLE)
		CombatState.State.AIRBORNE:
			if is_on_floor():
				_set_state(CombatState.State.IDLE)


func _set_state(new_state: CombatState.State) -> void:
	if state == new_state:
		return
	state = new_state
	if state == CombatState.State.IDLE:
		airborne_hit_count = 0
		if combo_count > 0:
			combo_count = 0
			combo_changed.emit(0)
	_update_color()


func _update_color() -> void:
	if _mat == null:
		return
	match state:
		CombatState.State.AIRBORNE:
			_mat.albedo_color = Color(0.2, 0.9, 0.3)
		CombatState.State.HITSTUN:
			_mat.albedo_color = Color(0.9, 0.7, 0.2)
		_:
			_mat.albedo_color = _original_color


## Returns a multiplier (approaching but never reaching 0) for juggle force.
## First JUGGLE_GRACE_HITS have no penalty; each hit after multiplies by JUGGLE_DECAY_FACTOR.
const JUGGLE_GRACE_HITS: int = 3
const JUGGLE_DECAY_FACTOR: float = 0.9

func _get_juggle_decay() -> float:
	if airborne_hit_count <= JUGGLE_GRACE_HITS:
		return 1.0
	var penalty_hits: int = airborne_hit_count - JUGGLE_GRACE_HITS
	return pow(JUGGLE_DECAY_FACTOR, penalty_hits)


func hit(_amount: float, source: Node, knockback: float = 5.0, hitstun: float = 0.3, launch: float = 0.0, juggle: float = 0.0) -> void:
	_play_hit_sound()

	var dir: Vector3 = (global_position - source.global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
	else:
		dir = Vector3.FORWARD

	var is_airborne: bool = state == CombatState.State.AIRBORNE

	if is_airborne:
		airborne_hit_count += 1
		_kb_velocity.x = dir.x * knockback * AIRBORNE_KNOCKBACK_SCALE
		_kb_velocity.z = dir.z * knockback * AIRBORNE_KNOCKBACK_SCALE
		var juggle_scale: float = _get_juggle_decay()
		_kb_velocity.y = juggle * juggle_scale
		_set_state(CombatState.State.AIRBORNE)
	else:
		_kb_velocity.x = dir.x * knockback
		_kb_velocity.z = dir.z * knockback
		if launch > 0.0:
			_kb_velocity.y = launch
			_set_state(CombatState.State.AIRBORNE)
		else:
			_set_state(CombatState.State.HITSTUN)

	hitstun_remaining = hitstun
	combo_count += 1
	combo_changed.emit(combo_count)
	_update_color()
	_do_hit_flash()


func _play_hit_sound() -> void:
	var idx := randi() % HIT_SOUNDS.size()
	hit_player.stream = load(HIT_SOUNDS[idx]) as AudioStream
	hit_player.play()


func _do_hit_flash() -> void:
	if _mat == null:
		return
	var current_color: Color = _mat.albedo_color
	_mat.albedo_color = Color(1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(_mat, "albedo_color", current_color, 0.08).set_delay(0.02)
