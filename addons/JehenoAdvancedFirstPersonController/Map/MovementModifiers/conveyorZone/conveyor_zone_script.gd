extends Area3D

@export var belt_direction : Vector3 = Vector3(-1, 0, 0)
@export_range(0.0, 8.0, 0.1) var belt_speed : float = 1.0

@export_group("Texture Scrolling")
@export var texture_scroll_enabled : bool = false
@export var mesh_instance_path : NodePath
@export_range(0.0, 16.0, 0.1) var scroll_speed : float = 2.0

var bodies_inside_area : Array = []
var mesh_instance : MeshInstance3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	#get texture mesh to apply scrolling effect to
	if texture_scroll_enabled and mesh_instance_path:
		mesh_instance = get_node(mesh_instance_path)

func _physics_process(delta : float) -> void:
	movement_force()
	
	texture_scroll_effect(delta)
	
func movement_force() -> void:
	for body in bodies_inside_area:
		#add movement force to play char, act like a push
		var movement : Vector3 = belt_direction.normalized() * belt_speed
		body.velocity += movement
		
func texture_scroll_effect(delta : float) -> void:
	#texture scrolling effect
	if texture_scroll_enabled and mesh_instance and mesh_instance.mesh:
		var material = mesh_instance.get_active_material(0)
		if material and material is StandardMaterial3D:
			var scroll_offset = Vector3(
				belt_direction.x * scroll_speed * delta,
				belt_direction.z * scroll_speed * delta,
				0.0
			)
			material.uv1_offset -= scroll_offset
			
func _on_body_entered(body) -> void:
	if body not in bodies_inside_area:
		bodies_inside_area.append(body)

func _on_body_exited(body) -> void:
	bodies_inside_area.erase(body)
