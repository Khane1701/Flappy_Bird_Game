extends CanvasLayer

signal restart

func _on_retry_button_pressed():
	restart.emit()
