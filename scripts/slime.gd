extends CharacterBody2D


const SPEED = 100.0
const ATTACK_RANGE = 40.0
const ATTACK_DAMAGE = 10
const ATTACK_COOLDOWN = 1.0
const LUNGE_SPEED = 400.0
const LUNGE_DURATION = 0.15
const WINDUP_DURATION = 0.2
const MAX_HP = 30
const ACCELERATION = 12.0  # 速度插值系数，越大响应越快
const BOUNCE_DURATION = 0.6  # 碰墙后反向移动的持续时间（秒）

var attack_timer := 0.0
var player: Node = null
var is_attacking := false
var lunge_timer := 0.0
var lunge_direction := Vector2.ZERO
var windup_timer := 0.0
var is_winding_up := false
var has_lunge_hit := false
var hp := MAX_HP
var health_bar: ProgressBar
var is_dead := false
var bounce_timer    := 0.0
var bounce_direction := Vector2.ZERO


func _ready() -> void:
	process_mode = PROCESS_MODE_PAUSABLE
	add_to_group("slimes")
	player = get_parent().get_node("MainCharactor")
	health_bar = ProgressBar.new()
	health_bar.max_value = MAX_HP
	health_bar.value = hp
	health_bar.show_percentage = false
	health_bar.position = Vector2(-12, -18)
	health_bar.size = Vector2(24, 5)
	add_child(health_bar)
	# 确保 death 动画非循环
	$AnimatedSprite2D.sprite_frames.set_animation_loop("death", false)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if player == null:
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance := to_player.length()

	if lunge_timer > 0.0:
		lunge_timer -= delta
		velocity = lunge_direction * LUNGE_SPEED
		if not has_lunge_hit:
			for area in $Hitbox.get_overlapping_areas():
				if area.get_parent() == player:
					has_lunge_hit = true
					_attack_player()
					break
		if lunge_timer <= 0.0:
			$Hitbox.monitoring = false
	elif is_winding_up:
		velocity = velocity.lerp(Vector2.ZERO, ACCELERATION * delta)
		windup_timer -= delta
		if windup_timer <= 0.0:
			is_winding_up = false
			lunge_timer = LUNGE_DURATION
			has_lunge_hit = false
			$Hitbox.monitoring = true
			$JumpSound.play()
	elif distance <= ATTACK_RANGE:
		is_attacking = true
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = ATTACK_COOLDOWN
			lunge_direction = (player.global_position - global_position).normalized()
			windup_timer = WINDUP_DURATION
			is_winding_up = true
		velocity = velocity.lerp(Vector2.ZERO, ACCELERATION * delta)
		bounce_timer = 0.0  # 进入攻击范围后清除反弹状态
	else:
		is_attacking = false
		attack_timer = 0.0
		if bounce_timer > 0.0:
			# 反弹阶段：沿墙壁法线方向退离
			bounce_timer -= delta
			velocity = velocity.lerp(bounce_direction * SPEED, ACCELERATION * delta)
		else:
			var target_vel: Vector2
			if abs(to_player.x) >= abs(to_player.y):
				target_vel = Vector2(sign(to_player.x), 0) * SPEED
			else:
				target_vel = Vector2(0, sign(to_player.y)) * SPEED
			velocity = velocity.lerp(target_vel, ACCELERATION * delta)

	move_and_slide()

	# 追踪阶段碰墙时触发反弹（取墙壁法线作为退离方向）
	if is_on_wall() and bounce_timer <= 0.0 and not is_attacking and not is_winding_up and lunge_timer <= 0.0:
		var normal := Vector2.ZERO
		for i in get_slide_collision_count():
			normal += get_slide_collision(i).get_normal()
		bounce_direction = normal.normalized() if normal.length_squared() > 0.0 else -velocity.normalized()
		bounce_timer = BOUNCE_DURATION

	var anim := $AnimatedSprite2D
	if is_attacking:
		anim.play("attack")
	else:
		anim.play("idle")


func _attack_player() -> void:
	if player.has_method("take_damage"):
		player.take_damage(ATTACK_DAMAGE)


func take_damage(amount: int) -> void:
	if is_dead:
		return
	hp -= amount
	hp = max(0, hp)
	health_bar.value = hp
	$HurtSound.play()
	if hp <= 0:
		_die()


func _die() -> void:
	is_dead = true
	$CollisionShape2D.set_deferred("disabled", true)
	$Hitbox.monitoring = false
	$Hitbox.monitorable = false
	health_bar.hide()
	$AnimatedSprite2D.play("death")
	$AnimatedSprite2D.animation_finished.connect(queue_free)
