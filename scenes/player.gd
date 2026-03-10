extends CharacterBody3D

## Movement speed in m/s.
@export var speed: float = 5.0

var state: CombatState.State = CombatState.State.IDLE


func _physics_process(delta: float) -> void:
	if state != CombatState.State.IDLE:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		velocity.y -= delta * 9.8
		move_and_slide()
		return

	var input_dir := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	
	var direction := Vector3(input_dir.x, 0, input_dir.y)
	direction = direction.normalized()
	# Compensate Z for isometric perspective
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
	if state != CombatState.State.IDLE:
		return
	if event.is_action_pressed(&"Skill 1"):
		$SkillController.try_use_skill_1()
	elif event.is_action_pressed(&"Skill 2"):
		$SkillController.try_use_skill_2()
	elif event.is_action_pressed(&"Skill 3"):
		$SkillController.try_use_skill_3()
