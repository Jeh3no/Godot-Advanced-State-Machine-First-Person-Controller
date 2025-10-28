extends Area3D

@export var friction_multiplier: float = 0.1  # Very slippery
@export var acceleration_multiplier: float = 0.3  # Harder to accelerate

var original_values: Dictionary = {}

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Store original values
	original_values[body] = {
		"walk_accel": body.walk_accel,
		"walk_deccel": body.walk_deccel,
		"run_accel": body.run_accel,
		"run_deccel": body.run_deccel,
		"crouch_accel": body.crouch_accel,
		"crouch_deccel": body.crouch_deccel
	}
	
	body.walk_accel *= acceleration_multiplier
	body.walk_deccel *= friction_multiplier
	body.run_accel *= acceleration_multiplier
	body.run_deccel *= friction_multiplier
	body.crouch_accel *= acceleration_multiplier
	body.crouch_deccel *= friction_multiplier

func _on_body_exited(body):
	if body in original_values:
		# Restore original values
		body.walk_accel = original_values[body]["walk_accel"]
		body.walk_deccel = original_values[body]["walk_deccel"]
		body.run_accel = original_values[body]["run_accel"]
		body.run_deccel = original_values[body]["run_deccel"]
		body.crouch_accel = original_values[body]["crouch_accel"]
		body.crouch_deccel = original_values[body]["crouch_deccel"]
		original_values.erase(body)
