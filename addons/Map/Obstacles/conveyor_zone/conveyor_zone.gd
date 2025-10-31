extends Area3D

@export var belt_direction: Vector3 = Vector3(1, 0, 0)
@export var belt_speed: float = 1.0
@export var override_horizontal: bool = false

@export_group("Texture Scrolling")
@export var scroll_texture: bool = false
@export var mesh_instance_path: NodePath
@export var scroll_speed: float = 2.0

var bodies_inside: Array = []
var mesh_instance: MeshInstance3D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if scroll_texture and mesh_instance_path:
		mesh_instance = get_node(mesh_instance_path)

func _physics_process(delta):
	for body in bodies_inside:
		var movement = belt_direction.normalized() * belt_speed
		
		if override_horizontal:
			body.velocity.x = movement.x
			body.velocity.z = movement.z
		else:
			body.velocity += movement
	
	# Scroll texture
	if scroll_texture and mesh_instance and mesh_instance.mesh:
		var material = mesh_instance.get_active_material(0)
		if material and material is StandardMaterial3D:
			var scroll_offset = Vector3(
				belt_direction.x * scroll_speed * delta,
				belt_direction.z * scroll_speed * delta,
				0.0
			)
			material.uv1_offset -= scroll_offset

func _on_body_entered(body):
	if body not in bodies_inside:
		bodies_inside.append(body)

func _on_body_exited(body):
	bodies_inside.erase(body)
