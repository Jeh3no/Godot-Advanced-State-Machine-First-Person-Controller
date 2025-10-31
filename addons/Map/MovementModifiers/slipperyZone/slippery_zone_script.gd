extends Area3D

@export_range(0.0, 0.3, 0.01) var friction_multiplier : float = 0.1
@export_range(0.0, 1.0, 0.01) var acceleration_multiplier : float = 0.3

var original_values : Dictionary = {
	"accel" : 0.0,
	"deccel" : 0.0
}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body) -> void:
	#stock original values
	original_values["accel"] = body.move_accel
	original_values["deccel"] = body.move_deccel
	
	#apply acceleration and friction multiplier to acceleration values
	body.move_accel *= acceleration_multiplier
	body.move_deccel *= friction_multiplier
	
func _on_body_exited(body) -> void:
	#return to original acceleration values
	body.move_accel = original_values["accel"]
	body.move_deccel = original_values["deccel"]
