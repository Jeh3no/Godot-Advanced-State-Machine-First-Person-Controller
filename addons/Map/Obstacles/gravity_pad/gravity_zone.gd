extends Area3D

@export var gravity_multiplier: float = 2.0
@export var custom_gravity_direction: Vector3 = Vector3.ZERO

var original_gravity: Dictionary = {}

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Store original gravity values
	original_gravity[body] = {
		"jump_gravity": body.jump_gravity,
		"fall_gravity": body.fall_gravity
	}
	
	# Apply modified gravity
	if custom_gravity_direction == Vector3.ZERO:
		# Just multiply existing gravity
		body.jump_gravity *= gravity_multiplier
		body.fall_gravity *= gravity_multiplier
	else:
		# Custom gravity direction
		body.jump_gravity = custom_gravity_direction.y
		body.fall_gravity = custom_gravity_direction.y

func _on_body_exited(body):
	if body in original_gravity:
		# Restore original gravity
		body.jump_gravity = original_gravity[body]["jump_gravity"]
		body.fall_gravity = original_gravity[body]["fall_gravity"]
		original_gravity.erase(body)
