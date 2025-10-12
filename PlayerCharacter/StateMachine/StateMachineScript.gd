extends Node

@export var initialState : State

var currState : State
var currStateName  : String
var states : Dictionary = {}

@onready var charRef : CharacterBody3D = $".."

func _ready():
	#get all the state childrens
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(onStateChildTransition)
			
	#if initial state, transition to it
	if initialState:
		initialState.enter(charRef)
		currState = initialState
		currStateName = currState.stateName
		
func _process(delta : float):
	if currState: currState.update(delta)
	
func _physics_process(delta: float):
	if currState: currState.physics_update(delta)
	
func onStateChildTransition(state : State, newStateName : String):
	#manage the transition from one state to another
	
	if state != currState: return
	
	var newState = states.get(newStateName.to_lower())
	if !newState: return
	
	#exit the current state
	if currState: currState.exit()
	
	#enter the new state
	newState.enter(charRef)
	
	currState = newState
	currStateName = currState.stateName
