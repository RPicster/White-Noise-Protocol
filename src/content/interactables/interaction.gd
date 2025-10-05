extends Area3D

signal highlights_started
signal highlight_stopped
signal interacted

var highlighted := false
@export var block := false:
	set(v):
		block = v
		if is_node_ready():
			$CollisionShape3D.set_deferred("disabled", block)
			if highlighted and block:
				stop_highlight()

func _ready() -> void:
	if block:
		$CollisionShape3D.set_deferred("disabled", true)

func start_highlight():
	if highlighted:
		return
	highlighted = true
	highlights_started.emit()

func try_interact():
	interacted.emit()

func stop_highlight():
	if not highlighted:
		return
	highlighted = false
	highlight_stopped.emit()
