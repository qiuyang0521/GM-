extends Area2D

const SPEED    = 500.0
const DAMAGE   = 15
const LIFETIME = 1.0

var direction     := Vector2.RIGHT
var extra_velocity := Vector2.ZERO  # 继承自玩家的初速度
var _lifetime     := LIFETIME


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += (direction * SPEED + extra_velocity) * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
		return
	# 通过 RayCast2D 检测前方墙体（物理帧内同步更新，最为可靠）
	if $RayCast2D.is_colliding():
		var collider: Node2D = $RayCast2D.get_collider()
		if collider != null and not collider.is_in_group("player") and not collider.is_in_group("slimes"):
			queue_free()


func _on_area_entered(area: Area2D) -> void:
	# 碰到史莱姆的 Hitbox，扣血后销毁自身（排除玩家）
	var parent := area.get_parent()
	if parent != null and parent.has_method("take_damage") and not parent.is_in_group("player"):
		parent.take_damage(DAMAGE)
		queue_free()
