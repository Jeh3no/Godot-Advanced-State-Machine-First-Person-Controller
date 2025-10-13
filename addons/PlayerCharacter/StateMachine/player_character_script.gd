extends CharacterBody3D

class_name PlayerCharacter

@export_group("Movement variables")
var move_speed: float
var move_accel: float
var move_deccel: float
var input_direction: Vector2
var move_direction: Vector3
var desired_move_speed: float
@export var desired_move_speed_curve: Curve
@export var max_desired_move_speed: float = 30.0
@export var in_air_move_speed_curve: Curve
@export var hit_ground_cooldown: float = 0.1 #amount of time the character keep his accumulated speed before losing it (while being on ground)
var hit_ground_cooldown_ref: float
@export var bunny_hop_dms_incre: float = 3.0 #bunny hopping desired move speed incrementer
@export var auto_bunny_hop: bool = false
var last_frame_position: Vector3
var last_frame_velocity: Vector3
var was_on_floor: bool
var walk_or_run: String = "WalkState" #keep in memory if play char was walking or running before being in the air
#for states that require visible changes of the model
@export var base_hitbox_height: float = 2.0
@export var base_model_height: float = 1.0
@export var height_change_duration: float = 0.15

@export_group("Crouch variables")
@export var crouch_speed: float = 6.0
@export var crouch_accel: float = 12.0
@export var crouch_deccel: float = 11.0
@export var continious_crouch: bool = false #if true, doesn't need to keep crouch button on to crouch
@export var crouch_hitbox_height: float = 1.2
@export var crouch_model_height: float = 0.6

@export_group("Walk variables")
@export var walk_speed: float = 9.0
@export var walk_accel: float = 11.0
@export var walk_deccel: float = 10.0

@export_group("Run variables")
@export var run_speed: float = 12.0
@export var run_accel: float = 10.0
@export var run_deccel: float = 9.0
@export var continious_run: bool = false #if true, doesn't need to keep run button on to run

@export_group("Jump variables")
@export var jump_height: float = 2.0
@export var jump_time_to_peak: float = 0.4
@export var jump_time_to_fall: float = 0.35
@onready var jump_velocity: float = (2.0 * jump_height) / jump_time_to_peak
@export var jump_cooldown: float = 0.25
var jump_cooldown_ref: float
@export var nb_jumps_in_air_allowed: int = 1
var nb_jumps_in_air_allowed_ref: int
var jump_buff_on: bool = false
var buffered_jump: bool = false
@export var coyote_jump_cooldown: float = 0.3
var coyote_jump_cooldown_ref: float
var coyote_jump_on: bool = false
@export_range(0.1, 1.0, 0.05) var in_air_input_multiplier: float = 1.0

@export_group("Slide variables")
var slide_direction: Vector3 = Vector3.ZERO
@export var use_desired_move_speed: bool = false
@export var slide_speed: float = 12.0
@export var slide_accel: float = 23.0
@export var slide_time: float = 1.2
var slide_time_ref: float
@export var time_bef_can_slide_again: float = 1.5
var time_bef_can_slide_again_ref: float
@export_range(0.0, 90.0, 0.1) var max_slope_angle: float = 75.0 #max slope angle where the slide time operate
@export_range(0.0, 0.1, 0.001) var uphill_tolerance : float = 0.05 #vertical tolerance, to avoid fake uphills
@export var amount_velocity_lost_per_sec: float = 4.0
@export var slope_sliding_dms_incre: float = 2.0 #slope sliding desired move speed incrementer
@export var slope_sliding_ms_incre: float = 2.0 #slope sliding slide speed incrementer
@export var priority_over_crouch: bool = true #if enabled, give priority over crouch state (because crouch and slide actions are assigned at the same input action)
@export var continious_slide: bool = true
var slide_buff_on: bool = false
@export var slide_hitbox_height: float = 1.0
@export var slide_model_height: float = 0.5

@export_group("Dash variables")
var dash_direction: Vector3 = Vector3.ZERO
@export var dash_speed: float = 120.0
@export var dash_time: float = 0.11
var dash_time_ref: float
@export var nb_dashs_allowed: int = 3
var nb_dashs_allowed_ref: int
@export var time_bef_can_dash_again: float = 0.8
var time_bef_can_dash_again_ref: float
@export var time_bef_reload_dash: float = 3.0
var time_bef_reload_dash_ref: float
var velocity_pre_dash : Vector3
var has_dashed : bool = false

@export_group("Fly variables")
@export var fly_speed: float = 20.0
@export var fly_accel: float = 15.0
@export var fly_deccel: float = 15.0
@export var fly_boost_multiplier: float = 3.0
var fly_boost_on: bool = false

@export_group("Gravity variables")
@onready var jump_gravity: float = (-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity: float = (-2.0 * jump_height) / (jump_time_to_fall * jump_time_to_fall)

@export_group("Keybind variables")
@export var move_forward_action: String = ""
@export var move_backward_action: String = ""
@export var move_left_action: String = ""
@export var move_right_action: String = ""
@export var run_action: String = ""
@export var crouch_action: String = ""
@export var jump_action: String = ""
@export var slide_action: String = ""
@export var dash_action: String = ""
@export var fly_action: String = ""

#references variables
@onready var cam_holder: Node3D = $CameraHolder
@onready var cam: Camera3D = %Camera
@onready var model: MeshInstance3D = $Model
@onready var hitbox: CollisionShape3D = $Hitbox
@onready var state_machine: Node = $StateMachine
@onready var hud: CanvasLayer = $HUD
@onready var ceiling_check: RayCast3D = %CeilingCheck
@onready var floor_check: RayCast3D = %FloorCheck
@onready var slide_floor_check: RayCast3D = %SlideFloorCheck

func _ready() -> void:
	#set and value references
	hit_ground_cooldown_ref = hit_ground_cooldown
	jump_cooldown_ref = jump_cooldown
	jump_cooldown = -1.0
	nb_jumps_in_air_allowed_ref = nb_jumps_in_air_allowed
	coyote_jump_cooldown_ref = coyote_jump_cooldown
	slide_time_ref = slide_time
	time_bef_can_slide_again_ref = time_bef_can_slide_again
	time_bef_can_slide_again = -1.0
	time_bef_can_dash_again_ref = time_bef_can_dash_again
	time_bef_can_dash_again = -1.0
	time_bef_reload_dash_ref = time_bef_reload_dash
	time_bef_reload_dash = -1.0
	nb_dashs_allowed_ref = nb_dashs_allowed
	
func _process(delta: float) -> void:
	slide_timers(delta)

	dash_timers(delta)
	
func _physics_process(_delta: float) -> void:
	modify_physics_properties()

	move_and_slide()
	
func slide_timers(delta: float) -> void:
	if time_bef_can_slide_again > 0.0: time_bef_can_slide_again -= delta
	else:
		#can only reset slide time when not sliding
		if state_machine.curr_state_name != "Slide":
			slide_time = slide_time_ref
			
func dash_timers(delta: float) -> void:
	#reloads dash every *timeBefReloadDash* time, to avoid dash spamming
	#if you want to be able to spam dashes, set timeBefReloadDash to 0.0
	if nb_dashs_allowed < nb_dashs_allowed_ref:
		if time_bef_reload_dash > 0.0: time_bef_reload_dash -= delta
		else:
			time_bef_reload_dash = time_bef_reload_dash_ref
			nb_dashs_allowed += 1

	if time_bef_can_dash_again > 0.0: time_bef_can_dash_again -= delta
	else:
		#can only reset slide time when not dashing
		if state_machine.curr_state_name != "Dash":
			dash_time = dash_time_ref
			
func modify_physics_properties() -> void:
	last_frame_position = global_position #get play char global position every frame
	last_frame_velocity = velocity #get play char velocity every frame
	was_on_floor = !is_on_floor() #check if play char was on floor every frame
	
func gravity_apply(delta: float) -> void:
	#if play char goes up, apply jump gravity
	#otherwise, apply fall gravity
	if velocity.y >= 0.0: velocity.y += jump_gravity * delta
	elif velocity.y < 0.0: velocity.y += fall_gravity * delta
	
#use of 2 tweens to change the hitbox and model heights, relative to a specific state
func tween_hitbox_height(state_hitbox_height : float) -> void:
	var hitbox_tween: Tween = create_tween()
	if hitbox != null:
		hitbox_tween.tween_method(func(v): set_hitbox_height(v), hitbox.shape.height, 
		state_hitbox_height, height_change_duration)
	#to avoid "no tweeners" error
	else:
		hitbox_tween.tween_interval(0.1)
	hitbox_tween.finished.connect(Callable(hitbox_tween, "kill"))

func set_hitbox_height(value: float) -> void:
	if hitbox.shape is CapsuleShape3D:
		hitbox.shape.height = value
		
func tween_model_height(state_model_height : float) -> void:
	var model_tween: Tween = create_tween()
	if model != null:
		model_tween.tween_property(model, "scale:y", 
		state_model_height, height_change_duration)
	#to avoid "no tweeners" error
	else:
		model_tween.tween_interval(0.1)
	model_tween.finished.connect(Callable(model_tween, "kill"))
		
