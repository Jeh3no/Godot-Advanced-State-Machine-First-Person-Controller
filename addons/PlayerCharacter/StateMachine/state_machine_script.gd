extends Node

@export var initial_state : State

var curr_state : State
var curr_state_name  : String
var states : Dictionary = {}

@onready var play_char : CharacterBody3D = $".."

signal change_fov

func _ready() -> void:
	#get all the state childrens
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(on_state_child_transition)
			
	#if initial state, transition to it
	if initial_state:
		initial_state.enter(play_char)
		curr_state = initial_state
		curr_state_name = curr_state.state_name
		
func _process(delta : float) -> void:
	if curr_state: curr_state.update(delta)
	
func _physics_process(delta: float) -> void:
	if curr_state: curr_state.physics_update(delta)
	
func on_state_child_transition(state : State, new_state_name : String) -> void:
	#manage the transition from one state to another
	
	if state != curr_state: return
	
	var new_state = states.get(new_state_name.to_lower())
	if !new_state: return
	
	#exit the current state
	if curr_state: curr_state.exit()
	
	#enter the new state
	new_state.enter(play_char)
	
	curr_state = new_state
	curr_state_name = curr_state.state_name
	
	emit_signal("change_fov")
