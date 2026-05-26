extends Node3D

#class name
class_name CameraObject 

#camera variables
@export_group("Camera variables")
@export_range(0.0, 0.5, 0.001) var x_axis_sensibility : float = 0.05
@export_range(0.0, 0.5, 0.001) var y_axis_sensibility : float = 0.05
@export_range(-360.0, 0.0, 0.01) var max_up_angle_view : float = -90.0 #in degrees
@export_range(0.0, 360.0, 0.01) var max_down_angle_view : float = 90.0 #in degrees
@export_range(5.0, 175.0, 0.01) var fov : float = 90.0

@export_group("fov variables")
@export_range(0.0, 180.0, 0.01) var min_fov_val : float = 10.0
@export_range(0.0, 180.0, 0.01) var max_fov_val : float = 170.0
@export var cam_fov_per_state : Dictionary[String, Vector2] = {
	#fov value, durationz
	"Default" : Vector2(90.0, 0.2),
	"Idle" : Vector2(90.0, 0.2),
	"Crouch" : Vector2(90.0, 0.2),
	"Walk" : Vector2(90.0, 0.2),
	"Run" : Vector2(100.0, 0.2),
	"Slide" : Vector2(100.0, 0.2),
	"Dash" : Vector2(110.0, 0.05),
	"Fly" : Vector2(100.0, 0.2)
}

@export_group("Zoom variables")
var zoom_on : bool = false
var zoom_has_occured : bool = false
@export_range(-180.0, 180.0, 1.0) var zoom_val : float = 40.0
@export_range(0.0, 3.0, 0.01) var zoom_duration : float = 0.2

@export_group("Tilt variables")
@export var enable_forward_tilt : bool = true
@export var enable_side_tilt : bool = true
@export_range(0.0, 400.0, 0.1) var forward_move_tilt_divider : float = 260.0 #divider to add to the move speed calculated tilt value
@export_range(0.0, 7.0, 0.01) var forward_move_tilt_duration : float = 0.19
@export_range(0.0, 2.0, 0.001) var forward_move_max_tilt_val : float = 2.0
@export_range(0.0, 6.0, 0.1) var side_move_tilt_divider : float = 2.8
@export_range(0.0, 24.0, 0.01) var side_move_tilt_speed : float = 10.0
@export_range(0.0, 12.0, 0.001) var side_move_max_tilt_val : float = 7.0
var tilt_tween : Tween
var last_input_y : float
@export var tilt_props_per_state : Dictionary[String, Vector2] = {
	#lean value (in radians), lerp speed
	"Default" : Vector2(0.0, 7.5),
	"Slide" : Vector2(10.0, 7.5),
	"Wallrun" : Vector2(16.0, 4.0)
}

#no need to apply different variables for each state for this one
@export_group("Bob variables")
@export var enable_headbob : bool = true
@export_range(0.0, 0.15, 0.001) var bob_pitch : float = 0.05 #in degrees
@export_range(0.0, 0.15, 0.001) var bob_roll : float = 0.025 #in degrees
@export_range(0.0, 1000.0, 1.0) var bob_height_divider : float = 550.0
@export_range(2.0, 10.0, 0.1) var bob_frequency : float = 7.0
@export_range(0.0, 1.0, 0.001) var cam_max_v_offset : float = 0.3
@export_range(0.0, 15.0, 0.1) var cam_v_offset_to_0_speed : float = 1.0
var step_timer : float = 0.0

@export_group("Mouse variables")
var mouse_free : bool = false

@export_group("Keybind variables")
@export var zoom_action : StringName = "play_char_zoom_action"
@export var mouse_mode_action : StringName = "play_char_mouse_mode_action"
@onready var input_actions_list : Array[StringName] = [zoom_action, mouse_mode_action]
@export var check_on_ready_if_inputs_registered : bool = true
var default_input_actions : Dictionary

var state : String

#references variables
@onready var camera : Camera3D = $Camera
@onready var play_char : PlayerCharacter = $".."
@onready var hud : CanvasLayer = $"../HUD"

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) #set mouse mode as captured
	
	camera.fov = fov
	
	build_default_keybinding()
	input_actions_check()

func build_default_keybinding() -> void:
	#build it in runtime to ensure that export variables have been set
	default_input_actions = {
		zoom_action : [Key.KEY_Z],
		mouse_mode_action : [Key.KEY_ESCAPE]
	}

func input_actions_check() -> void:
	#check if the input actions written in the editor are the same as the ones registered in the Input map, and if they are written correctly
	#if not, add it to runtime Input map with default keybindings
	if check_on_ready_if_inputs_registered:
		var registered_input_actions: Array[StringName] = []
		for input_action in InputMap.get_actions():
			if input_action.begins_with(&"play_char_"):
				registered_input_actions.append(input_action)
				
		for input_action in input_actions_list:
			if input_action == &"":
				assert(false, "There's an undefined input action")
				
			if not registered_input_actions.has(input_action):
				var key_names = default_input_actions[input_action].map(func(key):
					return OS.get_keycode_string(key)
				)
				
				push_warning("'{input}' missing in InputMap, or input action wrongly named in the editor.\nAdding the '{input}' to runtime InputMap temporarily with the key/s: {keys}"
				.format({"input": input_action, "keys": String(", ").join(key_names)}))
				
				InputMap.add_action(input_action)
				for keycode in default_input_actions[input_action]:
					var input_event_key = InputEventKey.new()
					input_event_key.physical_keycode = keycode
					InputMap.action_add_event(input_action, input_event_key)
				
func _unhandled_input(event) -> void:
	#manage camera rotation (360 on x axis, blocked at specified values on y axis, to not having the character do a complete head turn, which will be kinda weird)
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * (x_axis_sensibility / 10))
		camera.rotate_x(-event.relative.y * (y_axis_sensibility / 10))
		#use of deg_to_rad, because we change the x axis rotation with rotation,x, which use radians instead of degrees
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(max_up_angle_view), deg_to_rad(max_down_angle_view))
		
func _process(delta : float) -> void:
	state = play_char.state_machine.curr_state_name
	
	tilt(delta)
	
	bob(delta)
	
	zoom()
	
	mouse_mode()
	
func tilt(delta : float) -> void:
	if state != "Fly" and state != "Slide" and state != "Wallrun":
		if enable_forward_tilt:
			##forward (forward and backward movement) tilt
			#in most first person games, forward and backward tilt is not continious, but only applied at start of the movement
			#using a lerp will be counter productive, so in that case, we use a tween, to apply a one time camera rotation
			
			#use if sign() in the case of analogic sticks used
			var has_started_moving_forward = sign(play_char.input_direction.y) == 1 and sign(last_input_y) != 1
			var has_started_moving_backward = sign(play_char.input_direction.y) == -1 and sign(last_input_y) != -1
			
			#forward or backward input
			if has_started_moving_forward or has_started_moving_backward:
				reset_tween()
				var cam_x_rot_pre_tween : float = rotation.x
				var tilt_offset : float = clamp((-play_char.input_direction.y * play_char.move_speed) / forward_move_tilt_divider, -forward_move_max_tilt_val, forward_move_max_tilt_val)
				var tilt_target : float = clamp(cam_x_rot_pre_tween - tilt_offset, deg_to_rad(max_up_angle_view), deg_to_rad(max_down_angle_view))
				
				tilt_tween.tween_property(self, "rotation:x", tilt_target, forward_move_tilt_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tilt_tween.tween_property(self, "rotation:x", cam_x_rot_pre_tween, forward_move_tilt_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				
				tilt_tween.finished.connect(Callable(tilt_tween, "kill"))
		
			last_input_y = play_char.input_direction.y
			
		if enable_side_tilt:
			##side (left and right movement) tilt
			#in most first person games, lateral/side tilt is continious, so we use a lerp
			rotation_degrees.z = lerp(rotation_degrees.z,
			clamp((-play_char.input_direction.x * play_char.move_speed) / side_move_tilt_divider, -side_move_max_tilt_val, side_move_max_tilt_val), 
			side_move_tilt_speed * delta)
			
	#tilt for specific states, for example when wallrunning
	if state in tilt_props_per_state.keys():
		if state == "Wallrun" and play_char.side_check_raycast_collided != 0: #specific case for wallrun
			rotation_degrees.z = lerp(rotation_degrees.z, tilt_props_per_state[state][0] * -play_char.side_check_raycast_collided, tilt_props_per_state[state][1] * delta)
		else:
			rotation_degrees.z = lerp(rotation_degrees.z, tilt_props_per_state[state][0], tilt_props_per_state[state][1] * delta)
	else:
		#default camera rotation if no specific lean needs to be applied
		rotation_degrees.z = lerp(rotation_degrees.z, tilt_props_per_state["Default"][0], tilt_props_per_state["Default"][1] * delta)
			
func reset_tween():
	if tilt_tween and tilt_tween.is_running():
		tilt_tween.kill()
	tilt_tween = create_tween()
	
#i batantly copy pasted this code from StayAtHomeDev's "Godot FPS Series #2 - Camera effects" video
#for more in depth explanation of what this code does, and why, check his video
func bob(delta : float) -> void:
	var bob_speed : float = Vector2(play_char.velocity.x, play_char.velocity.z).length()
	if bob_speed > 0.1:
		step_timer += delta * (bob_speed / bob_frequency)
		#fmod purpose here is to create a continious cycle for every step
		#by keeping the timer value between 0.0 and 1.0 
		step_timer = fmod(step_timer, 1.0)
	else:
		step_timer = 0.0
	var bob_sinus : float = sin(step_timer * 2.0 * PI) * 0.5
	
	#ceiling check raycast used here to avoid camera clipping through ceiling when for example, play char is crouching
	if enable_headbob and state != "Idle" and state != "Jump" and state != "Slide" and state != "Dash" and state != "Fly" and state != "Wallrun" and !play_char.ceiling_check.is_colliding():
		#the bobbing scale is related to the player character movement speed
		
		#convert bob_pitch and bob_roll from degrees to radians, for a smoother bobbing effect
		
		var pitch_delta : float = bob_sinus * deg_to_rad(bob_pitch) * bob_speed
		var pitch_delta_apply : float = clamp(rotation_degrees.x - pitch_delta, max_up_angle_view, max_down_angle_view)
		rotation_degrees.x = pitch_delta_apply
		
		var roll_delta : float = bob_sinus * deg_to_rad(bob_roll) * bob_speed
		var roll_delta_apply : float = clamp(rotation_degrees.z - roll_delta, max_up_angle_view, max_down_angle_view)
		rotation_degrees.z = roll_delta_apply
		
		var bob_height : float = (bob_sinus * bob_speed) / bob_height_divider
		camera.v_offset += bob_height
		camera.v_offset = clamp(camera.v_offset, 0.0, cam_max_v_offset)
		
	elif enable_headbob and (state == "Idle" or state == "Jump" or state == "Slide" or state == "Dash" or state == "Fly" or state == "Wallrun" or play_char.ceiling_check.is_colliding()):
		#smoothly reset position vertical offset
		#if not applied, the camera can be upper the play char body for listed above states, resulting in wrong view
		if camera.v_offset != 0.0: camera.v_offset = move_toward(camera.v_offset, 0.0, cam_v_offset_to_0_speed * delta)
		
func zoom() -> void:
	if Input.is_action_just_pressed(zoom_action):
		zoom_on = !zoom_on
		if !zoom_on: zoom_has_occured = false
		
		change_fov()
		
func change_fov() -> void:
	#for state related fov change requests
	#if zoom is occuring, pass the rest of the function
	if zoom_has_occured:
		return
	
	#manage the fov changes relative to a specific state
	state = play_char.state_machine.curr_state_name
	
	camera.fov = clamp(camera.fov, min_fov_val, max_fov_val)
	
	var fov_change_tween : Tween = get_tree().create_tween()
	
	if !zoom_on and !zoom_has_occured:
		if state != null and state != "Jump" and state != "Inair" and state != "Wallrun":
			fov_change_tween.tween_property(camera, "fov", cam_fov_per_state[state][0], cam_fov_per_state[state][1])
			fov_change_tween.finished.connect(Callable(fov_change_tween, "kill"))
		else:
			#default value used for case like this one, when you need to force a fov change for a state that doesn't have his own setted fov
			if state != "Jump" and state != "Inair" and state != "Wallrun":
				fov_change_tween.tween_property(camera, "fov", cam_fov_per_state["Default"][0], cam_fov_per_state["Default"][1])
				fov_change_tween.finished.connect(Callable(fov_change_tween, "kill"))
			else:
				#not a great piece of code, but that's the most effective and simple way a found to solve the issue
				#that if you dezoom while being in Jump in Inair state, since these two states doesn't have a fixed fov
				#the fov would go back to the default one, even if play char jump with the Run state fov
				
				var walk_or_run_state : String
				if play_char.walk_or_run == "WalkState":
					walk_or_run_state = "Walk"
				if play_char.walk_or_run == "RunState":
					if (play_char.velocity.x < 1.0 and play_char.velocity.x > -1.0 and play_char.velocity.z < 1.0 and play_char.velocity.z > -1.0): #play char not moving at all on x and z axis
						walk_or_run_state = "Walk"
					else:
						walk_or_run_state = "Run"
						
				fov_change_tween.tween_property(camera, "fov", cam_fov_per_state[walk_or_run_state][0], cam_fov_per_state[walk_or_run_state][1])
				fov_change_tween.finished.connect(Callable(fov_change_tween, "kill"))
				
	#doesn't set zoom boolean to false right now, because we want the zoom to occur whatever the current state of play char is
	if zoom_on and !zoom_has_occured:
		zoom_has_occured = true
		fov_change_tween.tween_property(camera, "fov", camera.fov - zoom_val, zoom_duration)
		fov_change_tween.finished.connect(Callable(fov_change_tween, "kill"))
		
func mouse_mode() -> void:
	#manage the mouse mode (visible = can use mouse on the screen, captured = mouse not visible and locked in at the center of the screen)
	if Input.is_action_just_pressed(mouse_mode_action): mouse_free = !mouse_free
	if !mouse_free: Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
