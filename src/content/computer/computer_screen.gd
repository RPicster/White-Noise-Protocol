extends Node2D

signal computer_exit_request

@onready var scanline_1: Sprite2D = $Content/Scanline1
@onready var scanline_2: Sprite2D = $Content/Scanline2
@onready var scanline_3: Sprite2D = $Content/Scanline3

enum STATE {IDLE, START, HELP, UNKNOWN_COMMAND}

var state := STATE.IDLE
const VALID := [
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","1","2","3","4","5","6","7","8","9","0"
]
var screens := {
	"start" : "Welcome User %s!
	Enter Command (help)
	> %s",
	"help" : "Commands:
	HELP
	STATUS
	LOG
	EXIT
	
	Press any key to return.",
	"unknown_command" : "Unknown command:
	[ %s ]
	
	Press any key to return."
}
var user_id := "723"
var appendtimer := 0.0
var reveal := 0
var current_input := ""
var last_command := ""
@onready var label: Label = $Content/Label

func start_computer():
	change_state(STATE.START)

func exit_computer():
	change_state(STATE.IDLE)

func _input(event: InputEvent) -> void:
	if state == STATE.IDLE:
		return
	if event is InputEventKey and event.is_pressed():
		if state in [STATE.HELP, STATE.UNKNOWN_COMMAND]:
			enter_command()
			return
		var l := OS.get_keycode_string(event.get_key_label_with_modifiers())
		if "Shift" in l and l.count("+") == 1:
			l = l.remove_chars("+").remove_chars("Shift")
			current_input += l
		elif VALID.has(l):
			current_input += l.to_lower()
		elif l == "Enter":
			enter_command()
		elif l == "Backspace":
			current_input = current_input.erase(current_input.length()-1, 1)
		elif l == "Space":
			current_input += " "
		elif l == "Ctrl+C":
			current_input = ""

func enter_command():
	if state in [STATE.HELP, STATE.UNKNOWN_COMMAND]:
		change_state(STATE.START)
	if state == STATE.START:
		if current_input.to_lower() == "help":
			change_state(STATE.HELP)
		if current_input.to_lower() == "exit":
			computer_exit_request.emit()
		elif current_input.to_lower() != "":
			change_state(STATE.UNKNOWN_COMMAND)


func change_state(new_state:STATE):
	if state == STATE.IDLE:
		$Content/Everett.hide()
		label.show()
	label.text = ""
	label.visible_characters = 0
	last_command = current_input
	current_input = ""
	state = new_state
	reveal = 0

func _physics_process(delta: float) -> void:
	scanline_effect(delta)
	appendtimer = wrapf(appendtimer+delta, 0.0, 1.0)
	label.visible_characters = reveal
	reveal += 1
	match state:
		STATE.IDLE:
			show_idle()
		STATE.START:
			show_start()
		STATE.HELP:
			show_help()
		STATE.UNKNOWN_COMMAND:
			show_unknown_command()

func show_start():
	label.text = screens["start"] % [user_id, current_input + get_input_char()]

func show_help():
	label.text = screens["help"]

func show_unknown_command():
	label.text = screens["unknown_command"] % [last_command]

func show_idle():
	$Content/Everett.show()
	label.hide()

func get_input_char() -> String:
	return "" if appendtimer > 0.5 else "|"

func scanline_effect(delta:float):
	scanline_1.position.y = wrapf(scanline_1.position.y+delta*10.0, -16.0, 240.0)
	scanline_2.position.y = wrapf(scanline_2.position.y+delta*70.0, -4.0, 240.0)
	scanline_3.position.y = wrapf(scanline_3.position.y+delta*30.0, -50.0, 240.0)
