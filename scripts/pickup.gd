extends Area2D

signal collected(kind)

@export var kind : String = "rapid_fire"
@export var fall_speed : float = 150.0
@export var drift : float = 120.0

func _physics_process(delta):
	position += Vector2(-drift, fall_speed) * delta
	if position.y > get_viewport_rect().size.y + 50 or position.x < -50:
		queue_free()

func _on_body_entered(_body):
	collected.emit(kind)
	queue_free()
