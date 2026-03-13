extends Area2D

const SPEED    = 500.0
const DAMAGE   = 15
const LIFETIME = 3.0

var direction  := Vector2.RIGHT
var _lifetime  := LIFETIME


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position += direction * SPEED * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# 碰到任何物理体（非玩家）均视为撞墙，销毁自身
	if not body.is_in_group("player"):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	# 碰到史莱姆的 Hitbox，扣血后销毁自身
	var parent := area.get_parent()
	if parent != null and parent.has_method("take_damage"):
		parent.take_damage(DAMAGE)
		queue_free()
