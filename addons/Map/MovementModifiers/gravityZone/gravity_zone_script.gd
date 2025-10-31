extends Area3D

@export_range(0.0, 7.0, 0.1) var gravity_multiplier : float = 1.2

var original_gravity_vals: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body) -> void:
	#store original gravity values
	original_gravity_vals[body] = {
		"jump_gravity": body.jump_gravity,
		"fall_gravity": body.fall_gravity
	}
	
	#apply gravity multiplier to gravity values
	body.jump_gravity *= -gravity_multiplier
	body.fall_gravity *= -gravity_multiplier
	
func _on_body_exited(body) -> void:
	if body in original_gravity_vals:
		#restore original gravity values
		body.jump_gravity = original_gravity_vals[body]["jump_gravity"]
		body.fall_gravity = original_gravity_vals[body]["fall_gravity"]
		original_gravity_vals.erase(body)
