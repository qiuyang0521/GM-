extends CharacterBody2D

signal died

const SPEED = 150.0				#移动速度
const DASH_SPEED = 400.0		#冲刺速度
const DASH_DURATION = 0.25		#冲刺持续时间
const DASH_COOLDOWN = 1.0		#冲刺冷却时间
const MAX_HP = 100				#最大生命值
const DASH_DAMAGE = 20
const AUTO_AIM_RANGE  = 200.0  # 自动瞄准距离（像素）
const SHOOT_COOLDOWN  = 0.4    # 射击间隔（秒）
const BULLET_SCENE    = preload("res://scenes/bullet.tscn")			#冲刺伤害

var hp := MAX_HP
var health_bar: ProgressBar

var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector2.ZERO
var _dash_slimes_hit: Array = []

var is_injured := false
var injury_timer := 0.0
const INJURY_DURATION = 0.5

var shoot_timer := 0.0


func _ready() -> void:
	add_to_group("player")
	health_bar = ProgressBar.new()
	health_bar.max_value = MAX_HP
	health_bar.value = hp
	health_bar.show_percentage = false
	health_bar.position = Vector2(-16, -22)
	health_bar.size = Vector2(32, 5)
	add_child(health_bar)


func _physics_process(delta: float) -> void:
	var anim := $AnimatedSprite2D

	# 受伤动画计时
	if is_injured:
		injury_timer -= delta
		if injury_timer <= 0.0:
			is_injured = false

	# 冲刺冷却计时
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	# 冲刺持续计时
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			$Hitbox.monitoring = false
			_dash_slimes_hit.clear()
		else:
			# 翻滚期间检测是否碰到史莱姆 Hitbox
			for area in $Hitbox.get_overlapping_areas():
				var slime = area.get_parent()
				if slime != null and slime.has_method("take_damage") and not slime in _dash_slimes_hit:
					_dash_slimes_hit.append(slime)
					slime.take_damage(DASH_DAMAGE)
		velocity = dash_direction * DASH_SPEED
		move_and_slide()
		anim.play("dash")
		if dash_direction.x > 0:
			anim.flip_h = false
		elif dash_direction.x < 0:
			anim.flip_h = true
		return

	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	# 触发冲刺
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		if direction != Vector2.ZERO:
			dash_direction = direction.normalized()
		else:
			dash_direction = Vector2(-1 if anim.flip_h else 1, 0)
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		_dash_slimes_hit.clear()
		$Hitbox.monitoring = true
		return

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# 播放动画
	if is_injured:
		anim.play("injury")
	elif velocity != Vector2.ZERO:
		anim.play("move")
	else:
		anim.play("idle")

	if velocity.x > 0:
		anim.flip_h = false
	elif velocity.x < 0:
		anim.flip_h = true


func _process(delta: float) -> void:
	shoot_timer = max(0.0, shoot_timer - delta)
	_update_gun()


func _update_gun() -> void:
	var gun_pivot := $GunPivot
	var nearest := _get_nearest_slime()

	if nearest != null:
		# 自动瞄准最近的怪物
		gun_pivot.look_at(nearest.global_position)
		gun_pivot.scale.y = -1.0 if cos(gun_pivot.rotation) < 0 else 1.0
		# 自动射击
		if shoot_timer <= 0.0:
			_shoot(gun_pivot)
			shoot_timer = SHOOT_COOLDOWN
	else:
		# 跟随鼠标
		gun_pivot.look_at(get_global_mouse_position())
		gun_pivot.scale.y = -1.0 if cos(gun_pivot.rotation) < 0 else 1.0


func _get_nearest_slime() -> Node:
	var nearest: Node = null
	var nearest_dist := AUTO_AIM_RANGE
	for slime in get_tree().get_nodes_in_group("slimes"):
		if slime.get("is_dead") == true:
			continue
		var dist := global_position.distance_to(slime.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = slime
	return nearest


func _shoot(gun_pivot: Node2D) -> void:
	var bullet := BULLET_SCENE.instantiate()
	var dir := Vector2(cos(gun_pivot.global_rotation), sin(gun_pivot.global_rotation))
	bullet.direction = dir
	bullet.rotation  = dir.angle()
	var muzzle_pos: Vector2 = $GunPivot/Muzzle.global_position
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle_pos


func take_damage(amount: int) -> void:
	if is_dashing:
		return
	if hp <= 0:
		return
	hp -= amount
	hp = max(0, hp)
	health_bar.value = hp
	$HurtSound.play()
	is_injured = true
	injury_timer = INJURY_DURATION
	if hp <= 0:
		died.emit()
