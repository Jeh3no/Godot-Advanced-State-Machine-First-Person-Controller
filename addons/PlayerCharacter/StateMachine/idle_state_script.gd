extends State

class_name IdleState

var state_name : String = "Idle"

var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D):
	#pass play char reference
	play_char = play_char_ref
	
	verifications()
	
func verifications():
	#manage the appliements that need to be set at the start of the state
	play_char.floor_snap_length = 1.0
	if play_char.nb_jumps_in_air_allowed < play_char.nb_jumps_in_air_allowed_ref: play_char.nb_jumps_in_air_allowed = play_char.nb_jumps_in_air_allowed_ref
	if play_char.coyote_jump_cooldown < play_char.coyote_jump_cooldown_ref: play_char.coyote_jump_cooldown = play_char.coyote_jump_cooldown_ref
	if play_char.has_dashed: play_char.has_dashed = false
	if play_char.last_wallrunned_wall_out_of_time != 0: play_char.last_wallrunned_wall_out_of_time = 0
	
	play_char.tween_hitbox_height(play_char.base_hitbox_height)
	play_char.tween_model_height(play_char.base_model_height)
	
func physics_update(delta : float):
	applies(delta)
	
	play_char.gravity_apply(delta)
	
	input_management()
	
	move(delta)
	
func applies(delta : float):
	#manage the appliements of things that needs to be set/checked/performed every frame
	if play_char.hit_ground_cooldown > 0.0: play_char.hit_ground_cooldown -= delta
	
	#i don't know why, but if i put this line in verifications, it broke the jump cooldown, because he constantly stay at -1.0
	if play_char.jump_cooldown > 0.0: play_char.jump_cooldown = -1.0
	
	#manage the appliements and state transitions that needs to be sets/checked/performed
	#every time the play char pass through one of the following : floor-inair-onwall
	if !play_char.is_on_floor() and !play_char.is_on_wall():
		transitioned.emit(self, "InairState")
		
	if play_char.is_on_floor():
		if play_char.jump_buff_on and play_char.jump_cooldown < 0.0: 
			play_char.buffered_jump = true
			play_char.jump_buff_on = false
			transitioned.emit(self, "JumpState")
	
func input_management():
	#manage the state transitions depending on the actions inputs
	if Input.is_action_just_pressed(play_char.jump_action):
		if play_char.jump_cooldown < 0.0:
			transitioned.emit(self, "JumpState")
		
	if Input.is_action_just_pressed(play_char.crouch_action):
		transitioned.emit(self, "CrouchState")
		
	if Input.is_action_just_pressed(play_char.run_action):
		if play_char.walk_or_run == "WalkState": play_char.walk_or_run = "RunState"
		elif play_char.walk_or_run == "RunState": play_char.walk_or_run = "WalkState"
		
	if Input.is_action_just_pressed(play_char.fly_action):
		transitioned.emit(self, "FlyState")
		
func move(delta : float):
	#manage the character movement
	
	#direction input
	play_char.input_direction = Input.get_vector(play_char.move_left_action, play_char.move_right_action, play_char.move_forward_action, play_char.move_backward_action)
	#get the move direction depending on the input
	play_char.move_direction = (play_char.cam_holder.global_basis * Vector3(play_char.input_direction.x, 0.0, play_char.input_direction.y)).normalized()
	
	#set to ensure the character don't exceed the max speed authorized
	play_char.desired_move_speed = clamp(play_char.desired_move_speed, 0.0, play_char.max_desired_move_speed)
	
	if play_char.move_direction and play_char.is_on_floor():
		#transition to corresponding state
		transitioned.emit(self, play_char.walk_or_run)
	else:
		#apply smooth stop 
		play_char.velocity.x = lerp(play_char.velocity.x, 0.0, play_char.move_deccel * delta)
		play_char.velocity.z = lerp(play_char.velocity.z, 0.0, play_char.move_deccel * delta)
		
		#cancel desired move speed accumulation if the timer has elapsed (is up)
		if play_char.hit_ground_cooldown <= 0: play_char.desired_move_speed = play_char.velocity.length()
