extends CanvasLayer

signal finished

const INPUT_DELAY_MS : int = 600  # so panic-clicking at death doesn't skip lines

var _lines : PackedStringArray
var _i : int = 0
var _accept_at : int = 0

func _ready():
	hide()

func play(lines: PackedStringArray):
	_lines = lines
	_i = 0
	$label.text = _lines[0]
	_accept_at = Time.get_ticks_msec() + INPUT_DELAY_MS
	show()

func _input(event):
	if not visible or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() < _accept_at:
		return
	_i += 1
	if _i < _lines.size():
		$label.text = _lines[_i]
	else:
		hide()
		finished.emit()
