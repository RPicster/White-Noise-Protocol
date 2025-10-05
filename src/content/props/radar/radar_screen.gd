extends Node2D

@onready var content: Node2D = $Content
@onready var scanline_1: Sprite2D = $Content/Scanline1
@onready var scanline_2: Sprite2D = $Content/Scanline2
@onready var scanline_3: Sprite2D = $Content/Scanline3

var text := "> Signal Station %s
>
> Reboot Code
> %s"

func enable_screen():
	$Content/Label.visible_ratio = 0.0
	content.show()
	var t := create_tween()
	t.tween_property($Content/Label, "visible_ratio", 1.0, 3.0).set_delay(1.0)

func set_station_id(id:int):
	$Content/Label.text = text % [id, _G.STATION_CODES[id]]

func disable_screen():
	content.hide()

func _process(delta: float) -> void:
	if not content.visible:
		return
	scanline_1.position.y = wrapf(scanline_1.position.y+delta*10.0, -16.0, 150.0)
	scanline_2.position.y = wrapf(scanline_2.position.y+delta*70.0, -4.0, 150.0)
	scanline_3.position.y = wrapf(scanline_3.position.y+delta*30.0, -50.0, 150.0)
