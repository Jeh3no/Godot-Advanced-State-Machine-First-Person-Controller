extends State

class_name CrouchState

var state_name : String = "Crouch"

var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	
	verifications()
	
func verifications() -> void:
	play_char.move_speed = play_char.crouch_speed
	play_char.move_deccel = play_char.crouch_accel
	play_char.move_deccel = play_char.crouch_deccel
	
	play_char.floor_snap_length = 1.0
	if play_char.jump_cooldown > 0.0: play_char.jump_cooldown = -1.0
	if play_char.nb_jumps_in_air_allowed < play_char.nb_jumps_in_air_allowed_ref: play_char.nb_jumps_in_air_allowed = play_char.nb_jumps_in_air_allowed_ref
	if play_char.coyote_jump_cooldown < play_char.coyote_jump_cooldown_ref: play_char.coyote_jump_cooldown = play_char.coyote_jump_cooldown_ref
	if play_char.has_dashed: play_char.has_dashed = false
	if play_char.last_wallrunned_wall_out_of_time != 0: play_char.last_wallrunned_wall_out_of_time = 0
	
	play_char.tween_hitbox_height(play_char.crouch_hitbox_height)
	play_char.tween_model_height(play_char.crouch_model_height)
	
func physics_update(delta : float) -> void:
	applies(delta)
	
	play_char.gravity_apply(delta)
	
	input_management()
	
	move(delta)
	
func applies(delta : float) -> void:
	if play_char.hit_ground_cooldown > 0.0: play_char.hit_ground_cooldown -= delta
	
	if !play_char.is_on_floor() and !play_char.is_on_wall():
		if play_char.velocity.y < 0.0:
			transitioned.emit(self, "InairState")
			
	if play_char.is_on_floor():
		if play_char.jump_buff_on and play_char.jump_cooldown < 0.0:
			play_char.buffered_jump = true
			play_char.jump_buff_on = false
			transitioned.emit(self, "JumpState")
	
func input_management() -> void:
	if Input.is_action_just_pressed(play_char.jump_action):
		if play_char.jump_cooldown < 0.0 and !raycast_verification(): #if nothing block the player character when it will leaves the play_charouch state
			transitioned.emit(self, "JumpState")
			
	if play_char.continious_crouch: 
		#has to press run button once to run
		if Input.is_action_just_pressed(play_char.crouch_action):
			if !raycast_verification():
				play_char.walk_or_run = "WalkState"
				transitioned.emit(self, "WalkState")
	else:
		#has to continuously press play_charouch button to play_charouch
		if !Input.is_action_pressed(play_char.crouch_action):
			if !raycast_verification():
				play_char.walk_or_run = "WalkState"
				transitioned.emit(self, "WalkState")
			
func raycast_verification() -> bool:
	#check if the raycast used to check ceilings is colliding or not
	return play_char.ceiling_check.is_colliding()
			
func move(delta : float) -> void:
	play_char.input_direction = Input.get_vector(play_char.move_left_action, play_char.move_right_action, play_char.move_forward_action, play_char.move_backward_action)
	play_char.move_direction = (play_char.cam_holder.global_basis * Vector3(play_char.input_direction.x, 0.0, play_char.input_direction.y)).normalized()
	
	play_char.desired_move_speed = clamp(play_char.desired_move_speed, 0.0, play_char.max_desired_move_speed)
	
	if play_char.move_direction and play_char.is_on_floor():
		play_char.velocity.x = lerp(play_char.velocity.x, play_char.move_direction.x * play_char.move_speed, play_char.move_deccel * delta)
		play_char.velocity.z = lerp(play_char.velocity.z, play_char.move_direction.z * play_char.move_speed, play_char.move_deccel * delta)
	else:
		play_char.velocity.x = lerp(play_char.velocity.x, 0.0, play_char.move_deccel * delta)
		play_char.velocity.z = lerp(play_char.velocity.z, 0.0, play_char.move_deccel * delta)
		
	if play_char.hit_ground_cooldown <= 0: play_char.desired_move_speed = play_char.velocity.length()
