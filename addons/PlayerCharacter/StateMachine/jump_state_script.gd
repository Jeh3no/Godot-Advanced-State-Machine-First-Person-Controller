extends State

class_name JumpState

var state_name : String = "Jump"

var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	
	verifications()
	
	jump()
	
func verifications() -> void:
	if play_char.floor_snap_length != 0.0:  play_char.floor_snap_length = 0.0
	if play_char.jump_cooldown < play_char.jump_cooldown_ref: play_char.jump_cooldown = play_char.jump_cooldown_ref
	if play_char.hit_ground_cooldown != play_char.hit_ground_cooldown_ref: play_char.hit_ground_cooldown = play_char.hit_ground_cooldown_ref
	
	play_char.tween_hitbox_height(play_char.base_hitbox_height)
	play_char.tween_model_height(play_char.base_model_height)
	
func physics_update(delta : float) -> void:
	
	applies(delta)
	
	play_char.gravity_apply(delta)
	
	input_management()
	
	check_if_floor()
	
	move(delta)
	
func applies(delta : float) -> void:
	if !play_char.is_on_floor(): 
		if play_char.jump_cooldown > 0.0: play_char.jump_cooldown -= delta
		if play_char.coyote_jump_cooldown > 0.0: play_char.coyote_jump_cooldown -= delta
		
func input_management() -> void:
	if Input.is_action_just_pressed(play_char.jump_action):
		if play_char.jump_cooldown < 0.0:
			jump()
		
	if Input.is_action_just_pressed(play_char.dash_action):
		if play_char.time_bef_can_dash_again <= 0.0 and play_char.nb_dashs_allowed > 0:
			transitioned.emit(self, "DashState")
		
	if Input.is_action_just_pressed(play_char.fly_action):
		transitioned.emit(self, "FlyState")
		
func check_if_floor():
	if !play_char.is_on_floor() and play_char.velocity.y < 0.0:
		transitioned.emit(self, "InairState")
		
	if play_char.is_on_floor():
		if play_char.move_direction: transitioned.emit(self, play_char.walk_or_run)
		else: transitioned.emit(self, "IdleState")
	
	#lose all velocity and accumulated speed if play char hit a wall
	if play_char.is_on_wall():
		play_char.desired_move_speed = 0.0
		play_char.velocity.x = 0.0
		play_char.velocity.z = 0.0
		
func move(delta : float) -> void:
	play_char.input_direction = Input.get_vector(play_char.move_left_action, play_char.move_right_action, play_char.move_forward_action, play_char.move_backward_action)
	play_char.move_direction = (play_char.cam_holder.global_basis * Vector3(play_char.input_direction.x, 0.0, play_char.input_direction.y)).normalized()
	
	play_char.desired_move_speed = clamp(play_char.desired_move_speed, 0.0, play_char.max_desired_move_speed)
	
	if !play_char.is_on_floor():
		if play_char.move_direction:
			if play_char.desired_move_speed < play_char.max_desired_move_speed: play_char.desired_move_speed += play_char.bunny_hop_dms_incre * delta
			
			#use of curves here to have a better in air movement
			var contrd_des_move_speed : float = play_char.desired_move_speed_curve.sample(play_char.desired_move_speed)
			var contrd_inair_move_speed : float = play_char.in_air_move_speed_curve.sample(play_char.desired_move_speed) * play_char.in_air_input_multiplier
			
			play_char.velocity.x = lerp(play_char.velocity.x, play_char.move_direction.x * contrd_des_move_speed, contrd_inair_move_speed * delta)
			play_char.velocity.z = lerp(play_char.velocity.z, play_char.move_direction.z * contrd_des_move_speed, contrd_inair_move_speed * delta)

			if play_char.velocity.length() > play_char.max_desired_move_speed:
				play_char.velocity = play_char.velocity.normalized() * play_char.max_desired_move_speed
		else:
			#accumulate desired speed for bunny hopping
			play_char.desired_move_speed = play_char.velocity.length()
			
func jump() -> void: 
	#manage the jump behaviour, depending of the different variables and states the character is
	
	var can_jump : bool = false #jump condition
	
	#in air jump
	if !play_char.is_on_floor():
		if !play_char.coyote_jump_on and play_char.nb_jumps_in_air_allowed > 0:
			play_char.nb_jumps_in_air_allowed -= 1
			play_char.jump_cooldown = play_char.jump_cooldown_ref
			can_jump = true 
		if play_char.coyote_jump_on:
			play_char.jump_cooldown = play_char.jump_cooldown_ref
			play_char.coyote_jump_cooldown = -1.0 #so that the character cannot immediately make another coyote jump
			play_char.coyote_jump_on = false
			can_jump = true 
			
	#on floor jump
	if play_char.is_on_floor():
		play_char.jump_cooldown = play_char.jump_cooldown_ref
		can_jump = true 
		
	#jump buffering
	if play_char.buffered_jump:
		play_char.buffered_jump = false
		play_char.nb_jumps_in_air_allowed = play_char.nb_jumps_in_air_allowed_ref
		
	#apply jump
	if can_jump:
		play_char.velocity.y = play_char.jump_velocity
		can_jump = false
