extends Node

# CLASSIC: plain flappy bird. First death plays the intro dialogue and switches to SHOOTER for good.
enum Mode { CLASSIC, SHOOTER }

@export var pipe_scene : PackedScene
@export var laser_scene : PackedScene
@export var enemy_scene : PackedScene
@export var pickup_scene : PackedScene
@export var shooter_intro : PackedStringArray = [
	"...",
	"This is boring.",
	"Why should I avoid pipes?",
	"I have LASERS.",
]

var mode : Mode = Mode.CLASSIC
var game_running : bool
var game_over : bool
var scroll
var score
const SCROLL_SPEED : int = 4
var screen_size : Vector2i
var ground_height : int
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200

# Shooter tuning
const FIRE_DELAY : float = 0.35       # seconds between lasers
const MIN_FIRE_DELAY : float = 0.08
const PIPE_BREAK_SCORE : int = 10     # lasers break pipes from this score on
const PICKUP_DROP_CHANCE : float = 0.25
const PICKUP_KINDS : Array[String] = ["rapid_fire"]

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = Vector2i(get_viewport().get_visible_rect().size)
	ground_height = $ground.get_node("Sprite2D").texture.get_height()
	new_game()

func new_game():
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	$score_label.text = str(score)
	$game_over.hide()
	get_tree().call_group("pipes", "queue_free")
	for e in $entities.get_children():
		e.queue_free()
	$entities.process_mode = Node.PROCESS_MODE_INHERIT
	$shoot_timer.wait_time = FIRE_DELAY
	generate_pipes()
	$bird.reset()

func _input(event):
	if game_over == false:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if game_running == false:
					start_game()
				else:
					if $bird.flying:
						$bird.flap()
						check_top()

func start_game():
	game_running = true
	$bird.flying = true
	$bird.flap()
	$pipe_timer.start()
	if mode == Mode.SHOOTER:
		$shoot_timer.start()
		$enemy_timer.start()
		$pickup_timer.start()


func _process(delta):
	if game_running:
		scroll += SCROLL_SPEED
		if scroll >= screen_size.x:
			scroll = 0
		$ground.position.x = -scroll
		for pipe in get_tree().get_nodes_in_group("pipes"):
			pipe.position.x -= SCROLL_SPEED
			if pipe.position.x < -100:
				pipe.queue_free()

func _on_pipe_timer_timeout():
	generate_pipes()

func generate_pipes():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) / 2 + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.breakable = mode == Mode.SHOOTER and score >= PIPE_BREAK_SCORE
	pipe.hit.connect(bird_hit)
	pipe.scored.connect(scored)
	add_child(pipe)

func scored():
	score += 1
	$score_label.text = str(score)

func check_top():
	if $bird.position.y < 0:
		$bird.falling = true
		stop_game()

func stop_game():
	if game_over:
		return
	game_over = true
	game_running = false
	$bird.flying = false
	for t in [$pipe_timer, $shoot_timer, $enemy_timer, $pickup_timer]:
		t.stop()
	$entities.process_mode = Node.PROCESS_MODE_DISABLED
	if mode == Mode.CLASSIC:
		mode = Mode.SHOOTER
		$dialogue.play(shooter_intro)
		await $dialogue.finished
		new_game()
	else:
		$game_over.show()

func bird_hit():
	$bird.falling = true
	stop_game()

func _on_ground_hit():
	$bird.falling = false
	stop_game()

func _on_game_over_restart():
	new_game()

# --- Shooter systems ---

# Deferred add: spawns often happen inside physics callbacks.
func spawn(scene: PackedScene, pos: Vector2) -> Node:
	var node = scene.instantiate()
	node.position = pos
	$entities.add_child.call_deferred(node)
	return node

func _on_shoot_timer_timeout():
	spawn(laser_scene, $bird.position + Vector2(40, 0))

func _on_enemy_timer_timeout():
	var y = randf_range(100, screen_size.y - ground_height - 100)
	var enemy = spawn(enemy_scene, Vector2(screen_size.x + 50, y))
	enemy.hit.connect(bird_hit)
	enemy.killed.connect(_on_enemy_killed)

func _on_enemy_killed(pos: Vector2):
	scored()
	if randf() < PICKUP_DROP_CHANCE:
		spawn_pickup(pos)

func _on_pickup_timer_timeout():
	spawn_pickup(Vector2(randf_range(screen_size.x * 0.4, screen_size.x), -30))

func spawn_pickup(pos: Vector2):
	var pickup = spawn(pickup_scene, pos)
	pickup.kind = PICKUP_KINDS.pick_random()
	pickup.collected.connect(apply_pickup)

# Add new pickup effects here, then list the kind in PICKUP_KINDS.
func apply_pickup(kind: String):
	match kind:
		"rapid_fire":
			$shoot_timer.wait_time = max(MIN_FIRE_DELAY, $shoot_timer.wait_time * 0.75)
		_:
			push_warning("Unknown pickup: %s" % kind)
