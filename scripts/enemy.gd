extends Area2D

signal hit           # touched the bird
signal killed(pos)   # destroyed by lasers

@export var hp : int = 1
@export var speed : float = 250.0
@export var wobble : float = 60.0

var _t : float = 0.0
var _base_y : float

func _ready():
	_base_y = position.y

func _physics_process(delta):
	_t += delta
	position.x -= speed * delta
	position.y = _base_y + sin(_t * 3.0) * wobble
	if position.x < -100:
		queue_free()

func take_hit():
	hp -= 1
	if hp <= 0:
		killed.emit(position)
		queue_free()

func _on_body_entered(_body):
	hit.emit()
