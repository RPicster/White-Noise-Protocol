extends Node3D


func _on_interaction_interacted() -> void:
	queue_free()
	_G.outside.game_over()


func _on_interaction_highlight_stopped() -> void:
	$blackbox/Blackbox.material_overlay = null


func _on_interaction_highlights_started() -> void:
	$blackbox/Blackbox.material_overlay = _G.HIGHLIGHT_MAT
