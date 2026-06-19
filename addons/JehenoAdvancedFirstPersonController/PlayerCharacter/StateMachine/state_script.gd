extends Node

class_name State

signal transitioned #it's normal if this signal isn't used in this script, because it's purpose is to be used in the scripts that extends from the State class

func enter(_char_reference : CharacterBody3D):
	#enter state
	pass
	
func exit():
	#exit state
	pass
	
func update(_delta : float):
	#process update
	pass
	
func physics_update(_delta : float):
	#physics_process update
	pass 
