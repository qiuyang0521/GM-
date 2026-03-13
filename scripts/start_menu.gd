extends Control


func _ready() -> void:
	var start_btn := $VBoxContainer/StartButton as Button
	var quit_btn  := $VBoxContainer/QuitButton  as Button

	start_btn.mouse_entered.connect(_on_button_hover.bind(start_btn))
	start_btn.mouse_exited.connect(_on_button_unhover.bind(start_btn))
	start_btn.pressed.connect(_on_start_pressed)

	quit_btn.mouse_entered.connect(_on_button_hover.bind(quit_btn))
	quit_btn.mouse_exited.connect(_on_button_unhover.bind(quit_btn))
	quit_btn.pressed.connect(_on_quit_pressed)


func _on_button_hover(button: Button) -> void:
	button.pivot_offset = button.size / 2.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(button, "scale",    Vector2(1.2, 1.2),      0.12)
	tween.tween_property(button, "modulate", Color(1.5, 1.5, 1.5),   0.12)


func _on_button_unhover(button: Button) -> void:
	button.pivot_offset = button.size / 2.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(button, "scale",    Vector2(1.0, 1.0),      0.12)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0),   0.12)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_scene.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
