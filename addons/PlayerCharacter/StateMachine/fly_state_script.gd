extends State

class_name FlyState

var state_name : String = "Fly"

var play_char : CharacterBody3D

var fly_speed : float = 0.0
var fly_accel : float = 0.0
var fly_deccel : float = 0.0

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	
	verifications()
	
func verifications() -> void:
	fly_speed = play_char.fly_speed
	fly_accel = play_char.fly_accel
	fly_deccel = play_char.fly_deccel
	
	play_char.floor_snap_length = 1.0
	if play_char.jump_cooldown > 0.0: play_char.jump_cooldown = -1.0
	if play_char.nb_jumps_in_air_allowed < play_char.nb_jumps_in_air_allowed_ref: play_char.nb_jumps_in_air_allowed = play_char.nb_jumps_in_air_allowed_ref
	if play_char.coyote_jump_cooldown < play_char.coyote_jump_cooldown_ref: play_char.coyote_jump_cooldown = play_char.coyote_jump_cooldown_ref
	if play_char.has_dashed: play_char.has_dashed = false
	
	play_char.tween_hitbox_height(play_char.base_hitbox_height)
	play_char.tween_model_height(play_char.base_model_height)
	
func physics_update(delta : float) -> void:
	applies(delta)
	
	input_management()
	
	move(delta)
	
func applies(delta : float) -> void:
	if play_char.hit_ground_cooldown > 0.0: play_char.hit_ground_cooldown -= delta
	
func input_management() -> void:
	if Input.is_action_just_pressed(play_char.fly_action):
		transitioned.emit(self, "InairState")
		
	if Input.is_action_just_pressed(play_char.run_action):
		play_char.fly_boost_on = !play_char.fly_boost_on
		fly_speed = play_char.fly_speed * play_char.fly_boost_multiplier if play_char.fly_boost_on else play_char.fly_speed
		fly_accel = play_char.fly_speed * play_char.fly_boost_multiplier if play_char.fly_boost_on else play_char.fly_accel
		fly_deccel = play_char.fly_speed * play_char.fly_boost_multiplier if play_char.fly_boost_on else play_char.fly_deccel
		
func move(delta : float) -> void:
	play_char.input_direction = Input.get_vector(play_char.move_left_action, play_char.move_right_action, play_char.move_forward_action, play_char.move_backward_action)
	#need to get the cam reference directly, and not the cam holder one, because only the cam is rotating
	play_char.move_direction = (play_char.cam.global_transform.basis * Vector3(play_char.input_direction.x, 0.0, play_char.input_direction.y))
	
	play_char.desired_move_speed = clamp(play_char.desired_move_speed, 0.0, play_char.max_desired_move_speed)
	
	if play_char.move_direction:
		play_char.velocity = lerp(play_char.velocity, play_char.move_direction * fly_speed, fly_accel * delta)
	else:
		play_char.velocity = lerp(play_char.velocity, play_char.move_direction * fly_speed, fly_deccel * delta)
