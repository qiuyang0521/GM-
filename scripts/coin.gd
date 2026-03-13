extends CharacterBody2D

signal collected


func _ready() -> void:
	add_to_group("coins")
	$PickupArea.body_entered.connect(_on_pickup_area_body_entered)


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$PickupArea.monitoring = false  # 立即禁止重复触发
		collected.emit()
		$AnimatedSprite2D.hide()
		$CollisionShape2D.set_deferred("disabled", true)
		$CoinSound.play()
		await $CoinSound.finished
		queue_free()
