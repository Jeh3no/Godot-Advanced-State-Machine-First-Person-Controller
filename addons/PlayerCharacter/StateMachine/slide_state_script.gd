extends State

class_name SlideState

var state_name : String = "Slide"

var play_char : CharacterBody3D

var slope_angle : float

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	
	verifications()
	
func verifications() -> void:
	play_char.move_speed = play_char.slide_speed
	play_char.move_accel = play_char.slide_accel
	play_char.move_deccel = 0.0
	
	play_char.slide_direction = play_char.move_direction.normalized() #get move direction before actually start sliding, and stick to that direction
	
	if play_char.floor_snap_length != 1.0: play_char.floor_snap_length = 1.0
	if play_char.jump_cooldown > 0.0: play_char.jump_cooldown = -1.0
	if play_char.nb_jumps_in_air_allowed < play_char.nb_jumps_in_air_allowed_ref: play_char.nb_jumps_in_air_allowed = play_char.nb_jumps_in_air_allowed_ref
	if play_char.coyote_jump_cooldown < play_char.coyote_jump_cooldown_ref: play_char.coyote_jump_cooldown = play_char.coyote_jump_cooldown_ref
	if play_char.has_dashed: play_char.has_dashed = false
	if play_char.last_wallrunned_wall_out_of_time != 0: play_char.last_wallrunned_wall_out_of_time = 0
	
	play_char.tween_hitbox_height(play_char.slide_hitbox_height)
	play_char.tween_model_height(play_char.slide_model_height)
	
func physics_update(delta : float) -> void:
	applies(delta)
	
	play_char.gravity_apply(delta)
	
	input_management()
	
	move(delta)
	
func applies(delta : float) -> void:
	if (play_char.global_position.y - play_char.last_frame_position.y) > play_char.uphill_tolerance: #check if play char is uphill
		play_char.slide_time = -1.0
		play_char.slide_direction = Vector3.ZERO
		if !raycast_verification():
			transitioned.emit(self, play_char.walk_or_run)
		else:
			transitioned.emit(self, "CrouchState")
		
	#if play_char.hitGroundCooldown > 0.0: play_char.hitGroundCooldown -= delta
	slope_angle = rad_to_deg(acos(play_char.get_floor_normal().dot(Vector3.UP)))
	
	#if current slope angle superior than max slope angle, play char slides indefinitely while he's on the slope
	if slope_angle < play_char.max_slope_angle:
		if play_char.slide_time > 0.0:
			if play_char.is_on_floor():
				play_char.slide_time -= delta
		else:
			play_char.slide_direction = Vector3.ZERO
			play_char.time_bef_can_slide_again = play_char.time_bef_can_slide_again_ref
			if !raycast_verification():
				transitioned.emit(self, play_char.walk_or_run)
			else:
				transitioned.emit(self, "CrouchState")
				
	if play_char.is_on_floor():
		if play_char.jump_buff_on and play_char.jump_cooldown < 0.0:
			play_char.buffered_jump = true
			play_char.jump_buff_on = false
			transitioned.emit(self, "JumpState")
				
func input_management() -> void:
	if Input.is_action_just_pressed(play_char.jump_action):
		#if nothing block play char when he will leave the slide state
		if (slope_angle > play_char.max_slope_angle or !raycast_verification()) and play_char.jump_cooldown < 0.0:
			#force break slide state
			play_char.slide_time = -1.0
			play_char.slide_direction = Vector3.ZERO
			play_char.time_bef_can_slide_again = play_char.time_bef_can_slide_again_ref
			transitioned.emit(self, "JumpState")
			
	if play_char.continious_slide: 
		#has to press slide button once to run
		if Input.is_action_just_pressed(play_char.slide_action):
			play_char.slide_time = -1.0
			play_char.slide_direction = Vector3.ZERO
			play_char.time_bef_can_slide_again = play_char.time_bef_can_slide_again_ref
			if !raycast_verification():
				transitioned.emit(self, play_char.walk_or_run)
			else:
				transitioned.emit(self, "CrouchState")
	else:
		#has to continuously press slide button to play_charouch
		if !Input.is_action_pressed(play_char.slide_action):
			if !raycast_verification():
				play_char.slide_time = -1.0
				play_char.slide_direction = Vector3.ZERO
				play_char.time_bef_can_slide_again = play_char.time_bef_can_slide_again_ref
				if !raycast_verification():
					transitioned.emit(self, play_char.walk_or_run)
				else:
					transitioned.emit(self, "CrouchState")
			
func raycast_verification() -> bool:
	#check if the raycast used to check ceilings is colliding or not
	return play_char.ceiling_check.is_colliding()
	
func move(delta : float) -> void:
	#can't change direction while sliding
	if play_char.slide_direction and play_char.is_on_floor():
		if play_char.desired_move_speed:
			play_char.desired_move_speed = clamp(play_char.desired_move_speed, 0.0, play_char.max_desired_move_speed)
			
			#(play_char.desired_move_speed - play_char.amount_velocity_lost_per_sec * delta > 0.0) to avoid having negative move speed, and so slide in opposite direction than initial
			if slope_angle < play_char.max_slope_angle and (play_char.desired_move_speed - play_char.amount_velocity_lost_per_sec * delta > 0.0) : play_char.desired_move_speed -= play_char.amount_velocity_lost_per_sec * delta
			else: play_char.desired_move_speed += play_char.slope_sliding_dms_incre * delta
			
			play_char.velocity.x = play_char.move_direction.x * play_char.desired_move_speed
			play_char.velocity.z = play_char.move_direction.z * play_char.desired_move_speed
		else:
			if slope_angle < play_char.max_slope_angle and (play_char.desired_move_speed - play_char.amount_velocity_lost_per_sec * delta > 0.0): play_char.move_speed -= play_char.amount_velocity_lost_per_sec * delta
			else: play_char.move_speed += play_char.slope_sliding_ms_incre	 * delta
			
			play_char.velocity.x = lerp(play_char.velocity.x, play_char.move_direction.x * play_char.move_speed, play_char.move_accel * delta)
			play_char.velocity.z = lerp(play_char.velocity.z, play_char.move_direction.z * play_char.move_speed, play_char.move_accel * delta)
