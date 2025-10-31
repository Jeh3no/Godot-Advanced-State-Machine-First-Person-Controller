extends Area3D

@export_range(0.0, 200.0, 0.1) var bounce_force : float = 25.0
@export var override_velocity : bool = false
@export var overrided_direction : Vector3 = Vector3.ZERO
@export var reset_air_jumps : bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body) -> void:
	#class name have to be converted to stringName
	if "PlayerCharacter" in body.get_groups():
		if override_velocity:
			#apply new vector direction to the velocity
			body.velocity = overrided_direction
		else:
			#act like a normal jump
			body.velocity.y = bounce_force
			
		if reset_air_jumps:
			body.nb_jumps_in_air_allowed = body.nb_jumps_in_air_allowed_ref
