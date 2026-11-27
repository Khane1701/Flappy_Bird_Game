extends Area2D

const SPEED : float = 900.0

func _physics_process(delta):
	position.x += SPEED * delta
	if position.x > get_viewport_rect().size.x + 50:
		queue_free()

# Anything with take_hit() (pipes, enemies) absorbs the laser.
func _on_area_entered(area):
	if area.has_method("take_hit"):
		area.take_hit()
		queue_free()
