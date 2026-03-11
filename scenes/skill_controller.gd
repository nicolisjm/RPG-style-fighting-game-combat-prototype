extends Node

const SWORD_STARTER_SKILL_SCENE := preload("res://scenes/attacks/sword/sword_starter_skill.tscn")
const POMMEL_STRIKE_SKILL_SCENE := preload("res://scenes/attacks/sword/pommel_strike_skill.tscn")
const HEAVY_SLASH_SKILL_SCENE := preload("res://scenes/attacks/sword/heavy_slash_skill.tscn")

const SKILL_SCENES := {
	1: "res://scenes/attacks/sword/sword_starter_skill.tscn",
	2: "res://scenes/attacks/sword/pommel_strike_skill.tscn",
	3: "res://scenes/attacks/sword/heavy_slash_skill.tscn",
}

var SKILL_TAGS := {
	1: CombatState.SkillTag.STARTER,
	2: CombatState.SkillTag.EXTENDER,
	3: CombatState.SkillTag.ENDER,
}

@export var can_dash_on_starter: bool = true
@export var can_dash_on_extender: bool = true
@export var can_dash_on_ender: bool = true

var _active_skill: Node = null
var _active_skill_id: int = -1
var _active_skill_part: int = 0
var _active_tag: int = -1
var _hit_confirmed: bool = false
var _dash_used_this_combo: bool = false


func try_use_skill(skill_id: int) -> bool:
	var player: CharacterBody3D = get_parent() as CharacterBody3D
	if not player:
		return false

	var to_tag: int = SKILL_TAGS.get(skill_id, -1)
	if to_tag == -1:
		return false

	if player.state == CombatState.State.IDLE:
		return _spawn_skill(player, skill_id, to_tag, 0)

	if player.state == CombatState.State.STARTUP and _hit_confirmed:
		var is_same_skill: bool = (skill_id == _active_skill_id)
		var is_later_part: bool = false
		var new_part: int = 0

		if is_same_skill and skill_id == 1:
			new_part = _active_skill_part + 1
			is_later_part = new_part > _active_skill_part and new_part <= 1
			if not is_later_part:
				return false

		if not _can_cancel(_active_tag, to_tag, is_same_skill, is_later_part):
			return false

		_kill_active_skill()
		return _spawn_skill(player, skill_id, to_tag, new_part)

	return false


func try_dash() -> bool:
	var player: CharacterBody3D = get_parent() as CharacterBody3D
	if not player:
		return false
	if player.state != CombatState.State.STARTUP:
		return false
	if not _hit_confirmed or _dash_used_this_combo:
		return false

	match _active_tag:
		CombatState.SkillTag.STARTER:
			if not can_dash_on_starter:
				return false
		CombatState.SkillTag.EXTENDER:
			if not can_dash_on_extender:
				return false
		CombatState.SkillTag.ENDER:
			if not can_dash_on_ender:
				return false

	_dash_used_this_combo = true
	_kill_active_skill()
	player.start_dash()
	return true


func reset_combo_tracking() -> void:
	_dash_used_this_combo = false


func _can_cancel(from_tag: int, to_tag: int, is_same_skill: bool, is_later_part: bool) -> bool:
	match from_tag:
		CombatState.SkillTag.STARTER:
			if is_same_skill and not is_later_part:
				return false
			return true
		CombatState.SkillTag.EXTENDER:
			return to_tag == CombatState.SkillTag.EXTENDER or to_tag == CombatState.SkillTag.ENDER
		CombatState.SkillTag.ENDER:
			return false
	return false


func _spawn_skill(player: CharacterBody3D, skill_id: int, tag: int, part: int) -> bool:
	var scene_path: String = SKILL_SCENES.get(skill_id, "")
	if scene_path.is_empty():
		return false

	var packed: PackedScene = load(scene_path)
	var skill: Node = packed.instantiate()

	if skill_id == 1:
		skill.set("attack_part", part)

	player.add_child(skill)
	skill.global_position = player.global_position + Vector3(0.0, 1.0, 0.0)
	_aim_skill_at_mouse(skill as Node3D)

	skill.attack_finished.connect(_on_attack_finished.bind(player))
	skill.hit_confirmed.connect(_on_hit_confirmed)

	_active_skill = skill
	_active_skill_id = skill_id
	_active_skill_part = part
	_active_tag = tag
	_hit_confirmed = false

	player.state = CombatState.State.STARTUP
	return true


func _kill_active_skill() -> void:
	if _active_skill and is_instance_valid(_active_skill):
		_active_skill.queue_free()
	_active_skill = null
	_active_skill_id = -1
	_active_skill_part = 0
	_active_tag = -1
	_hit_confirmed = false


func _on_hit_confirmed() -> void:
	_hit_confirmed = true


func _on_attack_finished(player: CharacterBody3D) -> void:
	_active_skill = null
	_active_skill_id = -1
	_active_skill_part = 0
	_active_tag = -1
	_hit_confirmed = false
	player.state = CombatState.State.IDLE


func _aim_skill_at_mouse(skill: Node3D) -> void:
	var viewport := get_viewport()
	var camera: Camera3D = viewport.get_camera_3d()
	if not camera:
		return
	var mouse_pos := viewport.get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, skill.global_position.y)
	var aim_point: Variant = plane.intersects_ray(ray_origin, ray_dir)
	if aim_point != null:
		var dir := Vector3(aim_point.x - skill.global_position.x, 0.0, aim_point.z - skill.global_position.z)
		if dir.length_squared() > 0.0001:
			dir = dir.normalized()
			skill.rotation.y = atan2(dir.x, dir.z)


func _get_mouse_direction(from: Vector3) -> Vector3:
	var viewport := get_viewport()
	var camera: Camera3D = viewport.get_camera_3d()
	if not camera:
		return Vector3.FORWARD
	var mouse_pos := viewport.get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, from.y)
	var aim_point: Variant = plane.intersects_ray(ray_origin, ray_dir)
	if aim_point != null:
		var dir := Vector3(aim_point.x - from.x, 0.0, aim_point.z - from.z)
		if dir.length_squared() > 0.0001:
			return dir.normalized()
	return Vector3.FORWARD
