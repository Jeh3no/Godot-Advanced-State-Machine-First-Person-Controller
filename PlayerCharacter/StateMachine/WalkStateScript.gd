extends State

class_name WalkState

var stateName : String = "Walk"

var cR : CharacterBody3D

func enter(charRef : CharacterBody3D):
	cR = charRef
	
	verifications()
	
func verifications():
	cR.moveSpeed = cR.walkSpeed
	cR.moveAccel = cR.walkAccel
	cR.moveDeccel = cR.walkDeccel
	
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
	if !cR.is_on_floor() and !cR.is_on_wall():
		if cR.velocity.y < 0.0:
			transitioned.emit(self, "InairState")
	if cR.is_on_floor():
		#check if can auto bunny hop
		if cR.autoBunnyHop and cR.hitGroundCooldown > 0.0 and cR.inputDirection != Vector2.ZERO:
			transitioned.emit(self, "JumpState")
		if cR.jumpBuffOn:
			#apply jump buffering
			cR.bufferedJump = true
			cR.jumpBuffOn = false
			transitioned.emit(self, "JumpState")
			
func applies(delta : float):
	if cR.hitGroundCooldown > 0.0: cR.hitGroundCooldown -= delta
	
	cR.hitbox.shape.height = lerp(cR.hitbox.shape.height, cR.baseHitboxHeight, cR.heightChangeSpeed * delta)
	cR.model.scale.y = lerp(cR.model.scale.y, cR.baseModelHeight, cR.heightChangeSpeed * delta)
	
func inputManagement():
	if Input.is_action_just_pressed(cR.jumpAction):
		transitioned.emit(self, "JumpState")
		
	if Input.is_action_just_pressed(cR.crouchAction):
		transitioned.emit(self, "CrouchState")
		
	if Input.is_action_just_pressed(cR.runAction):
		cR.walkOrRun = "RunState"
		transitioned.emit(self, "RunState")
		
func move(delta : float):
	cR.inputDirection = Input.get_vector(cR.moveLeftAction, cR.moveRightAction, cR.moveForwardAction, cR.moveBackwardAction)
	cR.moveDirection = (cR.camHolder.global_basis * Vector3(cR.inputDirection.x, 0.0, cR.inputDirection.y)).normalized()
	
	if cR.moveDirection and cR.is_on_floor():
		#apply smooth move
		cR.velocity.x = lerp(cR.velocity.x, cR.moveDirection.x * cR.moveSpeed, cR.moveAccel * delta)
		cR.velocity.z = lerp(cR.velocity.z, cR.moveDirection.z * cR.moveSpeed, cR.moveAccel * delta)
		
		if cR.hitGroundCooldown <= 0: cR.desiredMoveSpeed = cR.velocity.length()
		
	else:
		transitioned.emit(self, "IdleState")
		
	if cR.desiredMoveSpeed >= cR.maxSpeed: cR.desiredMoveSpeed = cR.maxSpeed
