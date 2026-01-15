extends State

class_name JumpState

var state_name : String = "Jump"

var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	
	verifications()
	
	if !play_char.can_wallrun: #meaning that the character was wallrunning before jumping
		walljump()
	else:
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
	
	move(delta)
	
	wall_check()
	
func applies(delta : float) -> void:
	if !play_char.is_on_floor(): 
		if play_char.jump_cooldown > 0.0: play_char.jump_cooldown -= delta
		if play_char.coyote_jump_cooldown > 0.0: play_char.coyote_jump_cooldown -= delta
		if play_char.walljump_lock_in_air_movement_time > 0.0: play_char.walljump_lock_in_air_movement_time -= delta
		if play_char.velocity.y < 0.0: transitioned.emit(self, "InairState")
		
	if play_char.is_on_floor():
		if play_char.move_direction: transitioned.emit(self, play_char.walk_or_run)
		else: transitioned.emit(self, "IdleState")
		
func input_management() -> void:
	if Input.is_action_just_pressed(play_char.jump_action):
		if play_char.jump_cooldown < 0.0:
			jump()
		
	if Input.is_action_just_pressed(play_char.dash_action):
		if play_char.time_bef_can_dash_again <= 0.0 and play_char.nb_dashs_allowed > 0:
			transitioned.emit(self, "DashState")
		
	if Input.is_action_just_pressed(play_char.fly_action):
		transitioned.emit(self, "FlyState")
		
func wall_check() -> void:
	#check if play char collide with a left or right wall, and if all the conditions are correct, start wallrunning (by transitioning to the wallrun state)
	if play_char.can_wallrun and (!play_char.is_on_floor() or play_char.is_on_wall()) and !play_char.wallrun_floor_check.is_colliding():
		if play_char.left_wall_check.is_colliding() and !play_char.right_wall_check.is_colliding() and \
		play_char.last_wallrunned_wall_out_of_time != -1: #if play char has wallrunned on this side 'till the end of his wallrun time, he can't just rewallrun directly to this side, he has to either change side, or change wallrun direction
			play_char.side_check_raycast_collided = -1
			play_char.last_wallrunned_wall_out_of_time = 0
			transitioned.emit(self, "WallrunState")
		elif !play_char.left_wall_check.is_colliding() and play_char.right_wall_check.is_colliding() and \
		play_char.last_wallrunned_wall_out_of_time != 1:
			play_char.side_check_raycast_collided = 1
			play_char.last_wallrunned_wall_out_of_time = 0
			transitioned.emit(self, "WallrunState")
		else:
			return
			
func move(delta : float) -> void:
	play_char.input_direction = Input.get_vector(play_char.move_left_action, play_char.move_right_action, play_char.move_forward_action, play_char.move_backward_action)
	play_char.move_direction = (play_char.cam_holder.global_basis * Vector3(play_char.input_direction.x, 0.0, play_char.input_direction.y)).normalized()
	
	play_char.desired_move_speed = clamp(play_char.desired_move_speed, 0.0, play_char.max_desired_move_speed)
	
	if !play_char.is_on_floor():
		if play_char.move_direction:
			if play_char.desired_move_speed < play_char.max_desired_move_speed: play_char.desired_move_speed += play_char.bunny_hop_dms_incre * delta
			
			#use of curves here to have a better in air movement
			var contrd_des_move_speed : float = play_char.desired_move_speed_curve.sample(play_char.desired_move_speed)
			var contrd_inair_move_speed : float = play_char.in_air_move_speed_curve.sample(play_char.desired_move_speed) * 1.0
			
			if play_char.walljump_lock_in_air_movement_time <= 0.0: #lock the in air movement for a bit when walljumping, to not having the in air velocity decided by input crush the velocity of the walljump
				play_char.velocity.x = lerp(play_char.velocity.x, play_char.move_direction.x * contrd_des_move_speed, contrd_inair_move_speed * delta)
				play_char.velocity.z = lerp(play_char.velocity.z, play_char.move_direction.z * contrd_des_move_speed, contrd_inair_move_speed * delta)

			var horizontal_velocity = Vector3(play_char.velocity.x, 0.0, play_char.velocity.z)
			if horizontal_velocity.length() > play_char.max_desired_move_speed:
				horizontal_velocity = horizontal_velocity.normalized() * play_char.max_desired_move_speed
				play_char.velocity.x = horizontal_velocity.x
				play_char.velocity.z = horizontal_velocity.z
		else:
			#accumulate desired speed for bunny hopping
			play_char.desired_move_speed = play_char.velocity.length()
			
func jump() -> void: 
	#manage the jump behaviour, depending of the different variables and states the character is
	
	var can_jump : bool = false #jump condition
	
	var jump_force_additions : float = 0.0 #accumulation of different buff values to apply to the y velocity once the play char jump
	
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
		play_char.jump_cooldown = play_char.jump_cooldown_ref
		jump_force_additions += 0.0
		
	#apply jump
	if can_jump:
		play_char.velocity.y = play_char.jump_velocity + jump_force_additions
		can_jump = false
		
func walljump() -> void:
	var wall_normal = play_char.wall_normal
	
	var horizontal_velocity := Vector3(play_char.velocity.x,0.0,play_char.velocity.z)
	
	#remove the speed directed toward the wall
	var into_wall_velocity := horizontal_velocity.dot(wall_normal)
	if into_wall_velocity < 0.0: horizontal_velocity -= wall_normal * into_wall_velocity
	
	#add an impulse to exit the wall
	horizontal_velocity += wall_normal * play_char.walljump_push_force
	
	#applies the calculated wall jump speed
	play_char.velocity.x = horizontal_velocity.x
	play_char.velocity.z = horizontal_velocity.z
	play_char.velocity.y = play_char.walljump_y_velocity

	play_char.walljump_lock_in_air_movement_time = play_char.walljump_lock_in_air_movement_time_ref
