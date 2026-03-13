extends Node2D

var coin_count := 0
var reset_hold_timer := 0.0


func _ready() -> void:
	# 将游戏世界节点设置为可暂停，保证 get_tree().paused 生效
	$background.process_mode     = PROCESS_MODE_PAUSABLE
	$wall.process_mode           = PROCESS_MODE_PAUSABLE
	$ground.process_mode         = PROCESS_MODE_PAUSABLE
	$MainCharactor.process_mode  = PROCESS_MODE_PAUSABLE

	# 初始隐藏视图层
	$DeathScreen.hide()
	$PauseMenu.hide()
	$VictoryScreen.hide()

	# 连接玩家死亡信号
	$MainCharactor.died.connect(_on_player_died)

	# 连接按钮悬停动画
	_setup_button($DeathScreen/Center/VBox/RespawnButton)
	_setup_button($PauseMenu/Center/VBox/RestartButton)
	_setup_button($PauseMenu/Center/VBox/QuitButton)
	_setup_button($VictoryScreen/Center/VBox/RestartButton)
	_setup_button($VictoryScreen/Center/VBox/QuitButton)

	# 连接按钮点击事件
	$DeathScreen/Center/VBox/RespawnButton.pressed.connect(_on_respawn_pressed)
	$PauseMenu/Center/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	$PauseMenu/Center/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	$VictoryScreen/Center/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	$VictoryScreen/Center/VBox/QuitButton.pressed.connect(_on_quit_pressed)

	# 初始化音量滑块
	$PauseMenu/Center/VBox/VolumeSlider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	$PauseMenu/Center/VBox/VolumeSlider.value_changed.connect(_on_volume_changed)

	# 重置进度条初始化
	$CoinHUD/ResetBar.hide()

	# 延迟连接硬币信号（确保硬币实例已加入 "coins" 组）
	call_deferred("_connect_coins")
	# 延迟连接史莱姆死亡检测
	call_deferred("_connect_slimes")


func _process(delta: float) -> void:
	if Input.is_action_pressed("reset"):
		reset_hold_timer += delta
		$CoinHUD/ResetBar.show()
		$CoinHUD/ResetBar.value = reset_hold_timer
		if reset_hold_timer >= 1.0:
			reset_hold_timer = 0.0
			get_tree().paused = false
			get_tree().reload_current_scene()
	else:
		if reset_hold_timer > 0.0:
			reset_hold_timer = 0.0
			$CoinHUD/ResetBar.value = 0.0
			$CoinHUD/ResetBar.hide()


func _connect_coins() -> void:
	for coin in get_tree().get_nodes_in_group("coins"):
		if not coin.collected.is_connected(_on_coin_collected):
			coin.collected.connect(_on_coin_collected)


func _on_coin_collected() -> void:
	coin_count += 1
	$CoinHUD/CoinLabel.text = "硬币: %d" % coin_count


func _connect_slimes() -> void:
	for slime in get_tree().get_nodes_in_group("slimes"):
		if not slime.tree_exited.is_connected(_on_slime_removed):
			slime.tree_exited.connect(_on_slime_removed)


func _on_slime_removed() -> void:
	# 当某只史莱姆从场景中移除后，检查是否所有史莱姆都已消灭
	if get_tree().get_nodes_in_group("slimes").is_empty():
		_show_victory()


func _show_victory() -> void:
	get_tree().paused = true
	$VictoryScreen.show()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if $PauseMenu.visible:
			_resume()
		elif not $DeathScreen.visible and not $VictoryScreen.visible:
			_show_pause_menu()


# ── 死亡 ─────────────────────────────────────────────
func _on_player_died() -> void:
	get_tree().paused = true
	$DeathScreen.show()


# ── 暂停 ─────────────────────────────────────────────
func _show_pause_menu() -> void:
	get_tree().paused = true
	$PauseMenu.show()


func _resume() -> void:
	get_tree().paused = false
	$PauseMenu.hide()


# ── 按钮回调 ──────────────────────────────────────────
func _on_respawn_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_volume_changed(value: float) -> void:
	var db := linear_to_db(value) if value > 0.0 else -80.0
	AudioServer.set_bus_volume_db(0, db)


# ── 按鈕悬停动画（与 start_menu.gd 一致）────────────────
func _setup_button(button: Button) -> void:
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_unhover.bind(button))


func _on_button_hover(button: Button) -> void:
	button.pivot_offset = button.size / 2.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(button, "scale",    Vector2(1.2, 1.2),    0.12)
	tween.tween_property(button, "modulate", Color(1.5, 1.5, 1.5), 0.12)


func _on_button_unhover(button: Button) -> void:
	button.pivot_offset = button.size / 2.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(button, "scale",    Vector2(1.0, 1.0),    0.12)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0), 0.12)
