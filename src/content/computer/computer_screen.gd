extends Node2D

signal computer_exit_request
signal beep

@onready var scanline_1: Sprite2D = $Content/Scanline1
@onready var scanline_2: Sprite2D = $Content/Scanline2
@onready var scanline_3: Sprite2D = $Content/Scanline3

enum STATE {IDLE, START, HELP, SCAN, STATUS, SCANNING, SCAN_RESULT_1, SCAN_RESULT_2, MANUAL, MANUAL_PIONEER, MANUAL_SUPERVISOR, STATUS_DETAILS_ONLINE, STATUS_DETAILS_OFFLINE, STATUS_DETAILS_REBOOT, REBOOTING_STATION, WRONG_CODE, LOG, LOG_DETAIL, UNKNOWN_COMMAND}

var state := STATE.IDLE
const VALID := [
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","1","2","3","4","5","6","7","8","9","0"
]
var screens := {
	"start" : "### Welcome User %s!
			%s
			
			Enter Command:
			> %s",
	"help" : "### Commands:
			[help]
			[network]
			[logs]
			[exit]
			[scan]
			[manual]
			
			Enter Command:
			> %s",
	"unknown_command" : "Unknown command:
			[%s]
			
			[Any key] to return",
	"status" : "### Network: %s
			[1] Station 1: %s
			[2] Station 2: %s
			[3] Station 3: %s
			[4] Station 4: %s
			
			[exit] Return to menu
			> %s",
	"log" : "### Log
			%s
			
			> %s",
	"log_entry" : "### Log: %s
			%s
			
			[Any key] to return",
	"status_details_offline" : "### Station %s
			Status: ERROR
			
			[reboot] Reboot Station
			[exit] Return to Status
			> %s",
	"status_details_online" : "Station %s
			Status: OK
			
			[exit] Return to Status
			> %s",
	"status_details_reboot" : "### Reboot Station %s
			
			Enter Station Code:
			> %s",
	"rebooting" : "### Establishing Connection
			
			%s",
	"scan" : "### Scan for signals
			Stations: %s of %s
			Signals: %s
			
			%s
			[exit] Return to menu
			> %s",
	"scanning" : "### Select Signal
			%s
			
			[exit] Return to menu
			> %s",
	"manual" : "### Manuals
			[1] Pioneer
			[2] Supervisor
			[exit] Return to menu
			> %s",
	"manual_supervisor" : "### Supervisor
			Your job is it to help the Pioneer to orientate in the wilderness.
			Use the map and talk with the Pioneer if they can spot any unique landscape features that you can spot on the map.
			Reconnect the stations using this Computer.
			Scan for additional signals once the stations are reconnected.
			  [Any key] to return",
	"manual_pioneer" : "### Pioneer
			You are the strong arm! Use your compass (Press [C]) to orientate and communicate landscape features to your supervisor for orientation.
			Open the panels are reactivate the stations so your supervisor can input the code in the Computer.
			Your job is to find and collect Black Boxes. Your supervisor can scan for them.
			  [Any key] to return",
}
var user_id := "723"
var appendtimer := 0.0
var reveal := 0
var rebooting := 0.0
var just_changed_screen := 0.0
var current_input := ""
var last_state_before_unknown_command := STATE.START
var last_command := ""
var selected_station := 1
var selected_log := 1
var new_scans_available := false
@onready var label: Label = $Content/Label

func start_computer():
	change_state(STATE.START)

func exit_computer():
	$Content/ScanResult1.hide()
	$Content/ScanResult2.hide()
	change_state(STATE.IDLE)

func input(event: InputEvent) -> void:
	if state == STATE.IDLE or just_changed_screen > 0.0:
		return
	if event is InputEventKey and event.is_pressed():
		if state == STATE.UNKNOWN_COMMAND:
			$key.play()
			enter_command()
			return
		if state == STATE.REBOOTING_STATION and rebooting > 3.0:
			_G.station_state[selected_station] = true
			change_state(STATE.STATUS)
			$key.play()
			return
		if state == STATE.WRONG_CODE and rebooting > 2.0:
			change_state(STATE.STATUS_DETAILS_OFFLINE)
			$key.play()
			return
		if state == STATE.LOG_DETAIL:
			change_state(STATE.LOG)
			$key.play()
			return
		var l := OS.get_keycode_string(event.get_key_label_with_modifiers())
		if "Shift" in l and l.count("+") == 1:
			l = l.remove_chars("+").remove_chars("Shift")
			if l.length() == 1:
				current_input += l
				$key.play()
		elif VALID.has(l):
			current_input += l.to_lower()
			$key.play()
		elif l == "Enter":
			enter_command()
			$key.play()
		elif l == "Backspace":
			if current_input.length() > 0:
				current_input = current_input.erase(current_input.length()-1, 1)
				$key.play()
		elif l == "Space":
			current_input += " "
			$key.play()
		elif l == "Ctrl+C":
			current_input = ""
			$key.play()


func enter_command():
	var inp: String = current_input.to_lower().strip_edges().remove_chars("\n")
	if state == STATE.UNKNOWN_COMMAND:
		if last_state_before_unknown_command == STATE.UNKNOWN_COMMAND:
			last_state_before_unknown_command = STATE.START
		change_state(last_state_before_unknown_command)
	
	elif state in [STATE.START, STATE.HELP]:
		if inp == "help":
			change_state(STATE.HELP)
		elif inp == "network":
			change_state(STATE.STATUS)
		elif inp == "logs":
			change_state(STATE.LOG)
		elif inp == "scan":
			change_state(STATE.SCAN)
		elif inp == "manual":
			change_state(STATE.MANUAL)
		elif inp == "exit":
			computer_exit_request.emit()
		elif inp != "":
			change_state(STATE.UNKNOWN_COMMAND)
	elif state == STATE.LOG:
		if inp.is_valid_int() and int(inp) in _G.log_entries:
			selected_log = int(inp)
			change_state(STATE.LOG_DETAIL)
		elif inp == "exit":
			change_state(STATE.START)
		elif inp != "":
			change_state(STATE.UNKNOWN_COMMAND)
	elif state == STATE.STATUS:
		if inp in ["1", "2", "3", "4"]:
			selected_station = int(inp)
			var is_station_online: bool = _G.station_state[selected_station]
			if is_station_online:
				change_state(STATE.STATUS_DETAILS_ONLINE)
			else:
				change_state(STATE.STATUS_DETAILS_OFFLINE)
		elif inp == "exit":
			change_state(STATE.START)
		elif inp != "":
			change_state(STATE.UNKNOWN_COMMAND)
	
	elif state == STATE.SCAN:
		if inp == "exit":
			change_state(STATE.START)
		elif inp == "start" and _G.get_online_station_count() >= 2:
			change_state(STATE.SCANNING)
		elif inp != "":
			change_state(STATE.UNKNOWN_COMMAND)
			
	elif state == STATE.SCANNING:
		if inp == "exit":
			change_state(STATE.START)
		elif inp == "2" and _G.get_online_station_count() == 4:
			done_scans[1] = true
			new_scans_available = false
			$BeepTimer.stop()
			$Content/ScanResult1.hide()
			$Content/ScanResult2.hide()
			change_state(STATE.SCAN_RESULT_2)
		elif inp == "1" and _G.get_online_station_count() >= 2:
			done_scans[0] = true
			new_scans_available = false
			$BeepTimer.stop()
			$Content/ScanResult1.hide()
			$Content/ScanResult2.hide()
			change_state(STATE.SCAN_RESULT_1)
		elif inp != "":
			change_state(STATE.UNKNOWN_COMMAND)
	
	elif state == STATE.MANUAL:
		if inp == "exit":
			change_state(STATE.START)
		elif inp == "2":
			change_state(STATE.MANUAL_SUPERVISOR)
		elif inp == "1":
			change_state(STATE.MANUAL_PIONEER)
		elif inp != "":
			change_state(STATE.UNKNOWN_COMMAND)
		
	elif state == STATE.MANUAL_SUPERVISOR:
		change_state(STATE.MANUAL)
		
	elif state == STATE.MANUAL_PIONEER:
		change_state(STATE.MANUAL)
		
	elif state == STATE.SCAN_RESULT_1:
		$Content/ScanResult1.hide()
		$Content/ScanResult2.hide()
		change_state(STATE.START)
		
	elif state == STATE.SCAN_RESULT_2:
		$Content/ScanResult1.hide()
		$Content/ScanResult2.hide()
		change_state(STATE.START)
	
	elif state == STATE.STATUS_DETAILS_ONLINE:
		if inp == "exit":
			change_state(STATE.STATUS)
		elif inp != "":
			change_state(STATE.UNKNOWN_COMMAND)
	
	elif state == STATE.STATUS_DETAILS_OFFLINE:
		if inp == "exit":
			change_state(STATE.STATUS)
		elif inp == "reboot":
			change_state(STATE.STATUS_DETAILS_REBOOT)
		elif inp != "":
			change_state(STATE.UNKNOWN_COMMAND)
	
	elif state == STATE.STATUS_DETAILS_REBOOT:
		var is_input_six_numbers := true
		if inp.length() == 6:
			for x in inp:
				if not x.is_valid_int():
					is_input_six_numbers = false
					break
		else:
			is_input_six_numbers = false
		if is_input_six_numbers and int(inp) == _G.STATION_CODES[selected_station]:
			change_state(STATE.REBOOTING_STATION)
		else:
			change_state(STATE.WRONG_CODE)
	
	elif state == STATE.REBOOTING_STATION:
		if inp != "" and rebooting >= 3.0:
			change_state(STATE.STATUS_DETAILS_ONLINE)


func change_state(new_state:STATE):
	if state == STATE.UNKNOWN_COMMAND:
		last_state_before_unknown_command = state
	if state == STATE.IDLE:
		$Content/ScanResult1.hide()
		$Content/ScanResult2.hide()
		$Content/Everett.hide()
		label.show()
	label.text = ""
	just_changed_screen = 0.2
	label.visible_characters = 0
	rebooting = 0.0
	last_command = current_input
	current_input = ""
	state = new_state
	reveal = 0

var available_scans := [false, false]
var done_scans := [false, false]
func check_scans():
	var s := _G.get_online_station_count()
	if s == 4 and not available_scans[1]:
		new_scans_available = true
		beep.emit()
		$BeepTimer.start()
		available_scans[1] = true
	elif s >= 2 and not available_scans[0]:
		new_scans_available = true
		beep.emit()
		$BeepTimer.start()
		available_scans[0] = true

func _physics_process(delta: float) -> void:
	check_scans()
	scanline_effect(delta)
	appendtimer = wrapf(appendtimer+delta, 0.0, 1.0)
	just_changed_screen = max(0.0, just_changed_screen-delta)
	label.visible_characters = reveal
	reveal += (randi()%3)+1
	match state:
		STATE.IDLE:
			show_idle()
		STATE.START:
			show_start()
		STATE.HELP:
			show_help()
		STATE.STATUS:
			show_status()
		STATE.SCAN:
			show_scan()
		STATE.SCANNING:
			show_scanning()
		STATE.MANUAL:
			show_manual()
		STATE.MANUAL_PIONEER:
			show_manual_pioneer()
		STATE.MANUAL_SUPERVISOR:
			show_manual_supervisor()
		STATE.SCAN_RESULT_1:
			show_scan_result(1)
		STATE.SCAN_RESULT_2:
			show_scan_result(2)
		STATE.STATUS_DETAILS_ONLINE:
			show_status_details(true)
		STATE.STATUS_DETAILS_OFFLINE:
			show_status_details(false)
		STATE.STATUS_DETAILS_REBOOT:
			show_status_details_reboot()
		STATE.REBOOTING_STATION:
			show_rebooting(delta)
		STATE.WRONG_CODE:
			show_wrong_code(delta)
		STATE.LOG:
			show_log()
		STATE.LOG_DETAIL:
			show_log_detail()
		STATE.UNKNOWN_COMMAND:
			show_unknown_command()

func show_start():
	var scan_text = "NEW SIGNAL FOR SCANNING!" if new_scans_available else ""
	if appendtimer > 0.5:
		scan_text = ""
	label.text = screens["start"] % [user_id, scan_text, current_input + get_input_char()]

func show_manual():
	label.text = screens["manual"] % [current_input + get_input_char()]

func show_manual_pioneer():
	label.text = screens["manual_pioneer"]

func show_manual_supervisor():
	label.text = screens["manual_supervisor"]

func show_scan():
	var online_stations := _G.get_online_station_count()
	var signals := 0
	if online_stations == 4:
		signals = 2
	elif online_stations >= 2:
		signals = 1
	var extra_line := "" if signals == 0 else "[start] Start Scan"
	label.text = screens["scan"] % [online_stations, 4, signals, extra_line, current_input + get_input_char()]

func show_scanning():
	var scans := ""
	var online_stations := _G.get_online_station_count()
	if online_stations == 4:
		scans = "[1] Scan Signal 1
			[2] Scan Signal 2"
	elif online_stations >= 2:
		scans = "[1] Scan Signal 1"
	label.text = screens["scanning"] % [scans, current_input + get_input_char()]

func show_scan_result(id:int):
	if id == 1:
		$Content/ScanResult1.show()
	elif id == 2:
		$Content/ScanResult2.show()

func show_help():
	label.text = screens["help"] % [current_input + get_input_char()]

func show_unknown_command():
	label.text = screens["unknown_command"] % [last_command]

func show_log():
	var logs := ""
	for l in _G.log_entries:
		logs += "[%s] %s\n" % [l, _G.log_entries[l].title]
	logs += "\n[exit] Return to menu"
	label.text = screens["log"] % [logs, current_input + get_input_char()]

func show_log_detail():
	var log_entry: Dictionary = _G.log_entries[selected_log]
	label.text = screens["log_entry"] % [log_entry.title, log_entry.entry]

func show_status():
	label.text = screens["status"] % [bool_to_error(_G.stations_online()), 
	bool_to_error(_G.station_state[1]),
	bool_to_error(_G.station_state[2]),
	bool_to_error(_G.station_state[3]),
	bool_to_error(_G.station_state[4]),
	current_input + get_input_char()
	]

func bool_to_error(b:bool) -> String:
	return "OK" if b else "ERROR"

func show_status_details(online:bool):
	var base_text = screens["status_details_online"] if online else screens["status_details_offline"]
	base_text = base_text % [selected_station, current_input + get_input_char()]
	label.text = base_text

func show_status_details_reboot():
	var is_station_online: bool = _G.station_state[selected_station]
	if is_station_online:
		change_state(STATE.STATUS_DETAILS_ONLINE)
		return
	label.text = screens["status_details_reboot"] % [selected_station, current_input + get_input_char()]

func show_rebooting(delta):
	var reboot_state = ""
	if rebooting < 3.0:
		var bla_bla := "Handshake"
		if rebooting > 2.0:
			bla_bla = "Authorizing"
		elif rebooting >= 1.0:
			bla_bla = "Exchanging Keys"
		reboot_state = "%s
		Connecting: %d%%" % [bla_bla, clamp(rebooting / 3.0, 0.0, 1.0)*100.0]
		rebooting += delta
	else:
		reboot_state = "Connected!
		[Any key] to return"
	label.text = screens["rebooting"] % reboot_state

func show_wrong_code(delta):
	var reboot_state = ""
	if rebooting < 2.0:
		var bla_bla := "Handshake"
		if rebooting >= 1.0:
			bla_bla = "Exchanging Keys"
		reboot_state = "%s
		Connecting: %d%%" % [bla_bla, clamp(rebooting / 3.0, 0.0, 1.0)*100.0]
		rebooting += delta
	else:
		reboot_state = "Connection could not be established:
			ERROR: Incorrect Code!
			
			[Any key] to return"
	label.text = screens["rebooting"] % reboot_state

func show_idle():
	$Content/Everett.show()
	label.hide()

func get_input_char() -> String:
	return "" if appendtimer > 0.5 else "|"

func scanline_effect(delta:float):
	scanline_1.position.y = wrapf(scanline_1.position.y+delta*10.0, -16.0, 240.0)
	scanline_2.position.y = wrapf(scanline_2.position.y+delta*70.0, -4.0, 240.0)
	scanline_3.position.y = wrapf(scanline_3.position.y+delta*30.0, -50.0, 240.0)


func _on_beep_timer_timeout() -> void:
	beep.emit()
