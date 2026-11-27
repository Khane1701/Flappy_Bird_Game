extends Area2D

signal hit
signal scored

var breakable : bool = false
var hp : int = 3

func _on_body_entered(body):
	hit.emit()

func _on_score_zone_body_entered(body):
	scored.emit()

func take_hit():
	if not breakable:
		return
	hp -= 1
	if hp <= 0:
		queue_free()
