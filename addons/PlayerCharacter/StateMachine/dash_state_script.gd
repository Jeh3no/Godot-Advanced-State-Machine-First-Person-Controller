extends State

class_name DashState

var state_name : String = "Dash"

var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D):
	play_char = play_char_ref
	
	verifications()
	
func verifications():
	play_char.velocity_pre_dash = play_char.velocity #get velocity before start dashing, to apply it later, after dash finished, to keep a smooth transitio between dash state and next state
	play_char.dash_direction = play_char.move_direction.normalized() #get move direction before actually start dashing, and stick to that direction
	play_char.hud.display_speed_lines(true)
	
	play_char.nb_dashs_allowed -= 1
	
	play_char.tween_hitbox_height(play_char.base_hitbox_height)
	play_char.tween_model_height(play_char.base_model_height)
	
func physics_update(delta : float):
	applies(delta)
	
	move()
	
func applies(delta : float):
	if play_char.dash_time > 0.0: 
		play_char.dash_time -= delta
	else:
		play_char.time_bef_can_dash_again = play_char.time_bef_can_dash_again_ref
		#reset velocity on x and z axis
		play_char.velocity = Vector3(play_char.velocity_pre_dash.x, 0.0, play_char.velocity_pre_dash.z)
		play_char.has_dashed = true
		play_char.hud.display_speed_lines(false)
		
		if play_char.is_on_floor():
			transitioned.emit(self, play_char.walk_or_run)
		else:
			transitioned.emit(self, "InairState")
			
func move():
	#can't change direction while dashing
	if play_char.dash_direction != Vector3.ZERO:
		play_char.desired_move_speed = clamp(play_char.desired_move_speed, 0.0, play_char.max_desired_move_speed)
		
		play_char.velocity.x = play_char.dash_direction.x * play_char.dash_speed
		play_char.velocity.z = play_char.dash_direction.z * play_char.dash_speed
