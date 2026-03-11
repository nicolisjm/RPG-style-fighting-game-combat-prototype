extends Node3D

## Height of the camera rig (View) in world space. Only XZ follows the player.
@export var camera_height: float = 12

@onready var _player: CharacterBody3D = $Player
@onready var _view: Node3D = $View
@onready var _enemy: CharacterBody3D = $Enemy

var _combo_label: Label
var _combo_tween: Tween


func _ready() -> void:
	_setup_combo_hud()
	if _enemy and _enemy.has_signal("combo_changed"):
		_enemy.combo_changed.connect(_on_combo_changed)


func _setup_combo_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_combo_label = Label.new()
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_combo_label.anchor_left = 1.0
	_combo_label.anchor_right = 1.0
	_combo_label.anchor_top = 0.0
	_combo_label.anchor_bottom = 0.0
	_combo_label.offset_left = -220
	_combo_label.offset_right = -20
	_combo_label.offset_top = 40
	_combo_label.offset_bottom = 140

	_combo_label.add_theme_font_size_override("font_size", 48)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
	_combo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_combo_label.add_theme_constant_override("shadow_offset_x", 2)
	_combo_label.add_theme_constant_override("shadow_offset_y", 2)

	_combo_label.text = ""
	layer.add_child(_combo_label)


func _on_combo_changed(count: int) -> void:
	if count <= 0:
		_combo_label.text = ""
		_combo_label.scale = Vector2.ONE
		_player.get_node("SkillController").reset_combo_tracking()
		return

	if count == 1:
		_combo_label.text = "%d HIT" % count
	else:
		_combo_label.text = "%d HITS" % count

	# Punch scale on each new hit
	if _combo_tween and _combo_tween.is_running():
		_combo_tween.kill()
	_combo_label.scale = Vector2(1.3, 1.3)
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)


func _process(_delta: float) -> void:
	#if not is_instance_valid(_player) or not is_instance_valid(_view):
		#return
	#var p := _player.global_position
	#_view.global_position = Vector3(p.x, camera_height, p.z)
	return
