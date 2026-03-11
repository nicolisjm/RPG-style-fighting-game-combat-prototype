extends CharacterBody3D

## Movement speed in m/s.
@export var speed: float = 5.0
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.12

var state: CombatState.State = CombatState.State.IDLE
var _dash_remaining: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO


func start_dash() -> void:
	var input_dir := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	if direction.length_squared() > 0.001:
		direction.z *= 1.414
		direction = direction.rotated(Vector3.UP, +PI / 4).normalized()
		_dash_direction = direction
	else:
		_dash_direction = $SkillController._get_mouse_direction(global_position)

	_dash_remaining = dash_duration
	velocity = _dash_direction * dash_speed
	state = CombatState.State.DASHING


func _physics_process(delta: float) -> void:
	if state == CombatState.State.DASHING:
		_dash_remaining -= delta
		if _dash_remaining <= 0.0:
			state = CombatState.State.IDLE
			velocity = Vector3.ZERO
		velocity.y -= delta * 9.8
		move_and_slide()
		return

	if state != CombatState.State.IDLE:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		velocity.y -= delta * 9.8
		move_and_slide()
		return

	var input_dir := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	
	var direction := Vector3(input_dir.x, 0, input_dir.y)
	direction = direction.normalized()
	direction.z *= 1.414
	direction = direction.rotated(Vector3.UP, +PI / 4)
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	velocity.y -= delta * 9.8
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"Dash"):
		$SkillController.try_dash()
		return
	if event.is_action_pressed(&"Skill 1"):
		$SkillController.try_use_skill(1)
	elif event.is_action_pressed(&"Skill 2"):
		$SkillController.try_use_skill(2)
	elif event.is_action_pressed(&"Skill 3"):
		$SkillController.try_use_skill(3)
