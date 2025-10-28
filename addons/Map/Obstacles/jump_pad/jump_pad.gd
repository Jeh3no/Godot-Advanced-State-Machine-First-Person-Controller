extends Area3D

@export var bounce_force: Vector3 = Vector3(0, 20, 0)
@export var override_velocity: bool = true
@export var reset_air_jumps: bool = true

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if "PlayerCharacter" in body.get_groups():
		if override_velocity:
			body.velocity = bounce_force
		else:
			body.velocity += bounce_force
		
		if reset_air_jumps:
			body.nb_jumps_in_air_allowed = body.nb_jumps_in_air_allowed_ref
