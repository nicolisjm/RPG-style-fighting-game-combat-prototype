extends Node

## Combo window after first slash (Skill 1 part 0) before part 1 can be triggered.
@export var combo_window_duration: float = 0.15

const SWORD_STARTER_SKILL_SCENE := preload("res://scenes/attacks/sword/sword_starter_skill.tscn")

var _combo_window_remaining: float = 0.0


func _physics_process(delta: float) -> void:
	if _combo_window_remaining > 0.0:
		_combo_window_remaining = maxf(0.0, _combo_window_remaining - delta)


func try_use_skill_1() -> bool:
	var player: CharacterBody3D = get_parent() as CharacterBody3D
	if not player:
		return false
	if player.state != CombatState.State.IDLE:
		return false

	var is_part_1: bool = _combo_window_remaining > 0.0
	var skill: Node = SWORD_STARTER_SKILL_SCENE.instantiate()
	if is_part_1:
		skill.set("attack_part", 1)
		_combo_window_remaining = 0.0
	else:
		skill.set("attack_part", 0)

	player.add_child(skill)
	skill.global_position = player.global_position + Vector3(0.0, 1.0, 0.0)
	_aim_skill_at_mouse(skill as Node3D)

	if is_part_1:
		skill.attack_finished.connect(_on_attack_finished.bind(player))
	else:
		skill.attack_finished.connect(_on_attack_finished_part0.bind(player))

	player.state = CombatState.State.STARTUP
	return true


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


func _on_attack_finished(player: CharacterBody3D) -> void:
	player.state = CombatState.State.IDLE


func _on_attack_finished_part0(player: CharacterBody3D) -> void:
	player.state = CombatState.State.IDLE
	_combo_window_remaining = combo_window_duration
