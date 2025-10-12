extends State

class_name IdleState

var stateName : String = "Idle"

var cR : CharacterBody3D

func enter(charRef : CharacterBody3D):
	#pass play char reference
	cR = charRef
	
	verifications()
	
func verifications():
	#manage the appliements that need to be set at the start of the state
	cR.floor_snap_length = 1.0
	if cR.jumpCooldown > 0.0: cR.jumpCooldown = -1.0
	if cR.nbJumpsInAirAllowed < cR.nbJumpsInAirAllowedRef: cR.nbJumpsInAirAllowed = cR.nbJumpsInAirAllowedRef
	if cR.coyoteJumpCooldown < cR.coyoteJumpCooldownRef: cR.coyoteJumpCooldown = cR.coyoteJumpCooldownRef
	
func physics_update(delta : float):
	checkIfFloor()
	
	applies(delta)
	
	cR.gravityApply(delta)
	
	inputManagement()
	
	move(delta)
	
func checkIfFloor():
	#manage the appliements and state transitions that needs to be sets/checked/performed
	#every time the play char pass through one of the following : floor-inair-onwall
	if !cR.is_on_floor() and !cR.is_on_wall():
		transitioned.emit(self, "InairState")
	if cR.is_on_floor():
		if cR.jumpBuffOn: 
			cR.bufferedJump = true
			cR.jumpBuffOn = false
			transitioned.emit(self, "JumpState")
			
func applies(delta : float):
	#manage the appliements of things that needs to be set/checked/performed every frame
	if cR.hitGroundCooldown > 0.0: cR.hitGroundCooldown -= delta
	
	cR.hitbox.shape.height = lerp(cR.hitbox.shape.height, cR.baseHitboxHeight, cR.heightChangeSpeed * delta)
	cR.model.scale.y = lerp(cR.model.scale.y, cR.baseModelHeight, cR.heightChangeSpeed * delta)
	
func inputManagement():
	#manage the state transitions depending on the actions inputs
	if Input.is_action_just_pressed(cR.jumpAction):
		transitioned.emit(self, "JumpState")
		
	if Input.is_action_just_pressed(cR.crouchAction):
		transitioned.emit(self, "CrouchState")
		
	if Input.is_action_just_pressed(cR.runAction):
		if cR.walkOrRun == "WalkState": cR.walkOrRun = "RunState"
		elif cR.walkOrRun == "RunState": cR.walkOrRun = "WalkState"
		
func move(delta : float):
	#manage the character movement
	
	#direction input
	cR.inputDirection = Input.get_vector(cR.moveLeftAction, cR.moveRightAction, cR.moveForwardAction, cR.moveBackwardAction)
	#get the move direction depending on the input
	cR.moveDirection = (cR.camHolder.global_basis * Vector3(cR.inputDirection.x, 0.0, cR.inputDirection.y)).normalized()
	
	if cR.moveDirection and cR.is_on_floor():
		#transition to corresponding state
		transitioned.emit(self, cR.walkOrRun)
	else:
		#apply smooth stop 
		cR.velocity.x = lerp(cR.velocity.x, 0.0, cR.moveDeccel * delta)
		cR.velocity.z = lerp(cR.velocity.z, 0.0, cR.moveDeccel * delta)
		
		#cancel desired move speed accumulation if the timer has elapsed (is up)
		if cR.hitGroundCooldown <= 0: cR.desiredMoveSpeed = cR.velocity.length()
		
	#set to ensure the character don't exceed the max speed authorized
	if cR.desiredMoveSpeed >= cR.maxSpeed: cR.desiredMoveSpeed = cR.maxSpeed
