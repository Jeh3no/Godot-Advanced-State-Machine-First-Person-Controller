extends State

class_name WallrunState

var state_name : String = "Wallrun"

var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	
	verifications()
	
func verifications() -> void:
	wallrun_forward_direction_calculus()
	
	play_char.velocity.y = 0.0
	
	play_char.move_speed = play_char.wallrun_speed
	play_char.move_accel = play_char.wallrun_accel
	play_char.move_deccel = play_char.wallrun_deccel
	
	if play_char.floor_snap_length != 1.0: play_char.floor_snap_length = 1.0
	if play_char.jump_cooldown > 0.0: play_char.jump_cooldown = -1.0
	if play_char.nb_jumps_in_air_allowed < play_char.nb_jumps_in_air_allowed_ref: play_char.nb_jumps_in_air_allowed = play_char.nb_jumps_in_air_allowed_ref
	if play_char.coyote_jump_cooldown < play_char.coyote_jump_cooldown_ref: play_char.coyote_jump_cooldown = play_char.coyote_jump_cooldown_ref
	if play_char.time_bef_can_wallrun_again < play_char.time_bef_can_wallrun_again_ref: play_char.time_bef_can_wallrun_again = play_char.time_bef_can_wallrun_again_ref
	if play_char.has_dashed: play_char.has_dashed = false
	
	play_char.tween_hitbox_height(play_char.base_hitbox_height)
	play_char.tween_model_height(play_char.base_model_height)
	
func physics_update(delta : float) -> void:
	applies(delta)
	
	gravity_apply(delta)
	
	input_management()
	
	move(delta)
	
func applies(delta : float) -> void:
	wallrun_forward_direction_calculus()
	
	if !play_char.infinite_wallrun_time:
		if play_char.wallrun_time > 0.0: play_char.wallrun_time -= delta
		else:
			play_char.can_wallrun = false
			play_char.last_wallrunned_wall_out_of_time = play_char.side_check_raycast_collided #get last wall side where play char wallrunned
			transitioned.emit(self, "InairState")
			
	if (!play_char.is_on_floor() and !play_char.is_on_wall() and \
	!play_char.left_wall_check.is_colliding() and !play_char.right_wall_check.is_colliding()) or \
	play_char.wallrun_floor_check.is_colliding():
		play_char.can_wallrun = false
		transitioned.emit(self, "InairState")
	
func gravity_apply(delta: float) -> void:
	#y axis velocity if obligatory 0 or below 0, so we only manage fall gravity
	play_char.velocity.y += play_char.fall_gravity * play_char.wallrun_fall_gravity_multiplier * delta
	
func input_management() -> void:
	if Input.is_action_just_pressed(play_char.jump_action):
		if play_char.jump_cooldown < 0.0:
			play_char.can_wallrun = false
			play_char.about_to_jump_vel = play_char.velocity
			transitioned.emit(self, "JumpState")
	
func move(delta : float) -> void:
	play_char.desired_move_speed = clamp(play_char.desired_move_speed, 0.0, play_char.max_desired_move_speed)
	
	if Input.is_action_pressed(play_char.move_forward_action):
		if play_char.use_desired_move_speed_wallrun:
			play_char.velocity.x = lerp(play_char.velocity.x, play_char.wall_forward_dir.x * play_char.desired_move_speed, play_char.move_accel * delta)
			play_char.velocity.z = lerp(play_char.velocity.z, play_char.wall_forward_dir.z * play_char.desired_move_speed, play_char.move_accel * delta)
			
			play_char.desired_move_speed += play_char.wallrunning_dms_incre * delta
		else:
			play_char.velocity.x = lerp(play_char.velocity.x, play_char.wall_forward_dir.x * play_char.move_speed, play_char.move_accel * delta)
			play_char.velocity.z = lerp(play_char.velocity.z, play_char.wall_forward_dir.z * play_char.move_speed, play_char.move_accel * delta)
			
			play_char.desired_move_speed = play_char.velocity.length()
	else:
		play_char.can_wallrun = false
		transitioned.emit(self, "InairState")
		
func wallrun_forward_direction_calculus():
	#get wall normal
	if play_char.side_check_raycast_collided == -1:
		play_char.wall_normal = play_char.left_wall_check.get_collision_normal()
	if play_char.side_check_raycast_collided == 1:
		play_char.wall_normal = play_char.right_wall_check.get_collision_normal()
		
	#calculate the forward direction of the wall the player character will move to
	play_char.wall_forward_dir = (play_char.velocity.normalized() - play_char.wall_normal * \
	play_char.velocity.normalized().dot(play_char.wall_normal)).normalized()
