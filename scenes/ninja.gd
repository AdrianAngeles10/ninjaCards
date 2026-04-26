extends CharacterBody2D

# --- MOVEMENT SETTINGS ---
@export var speed: float = 300.0 
@export var jump_velocity: float = -650.0 

# --- ATTACK SETTINGS ---
const ATTACK_DURATION = 0.5 

# --- INTERNAL VARIABLES ---
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_attacking: bool = false
var can_air_attack: bool = true 
# 📢 ESSENTIAL FIX: Flag to prevent immediate re-triggering within the same cycle
var attack_input_buffered: bool = false 

# --- NODE REFERENCES ---
@onready var animated_sprite_2d = $AnimatedSprite2D 
@onready var attack_timer = $AttackTimer 
@onready var attack_hitbox = $AttackHitbox # (Optional: For hitting coins/enemies)

func _ready():
	attack_timer.timeout.connect(_on_attack_animation_finished)

# 📢 FIX: Input is handled instantly and locks itself for the frame
func _input(event):
	# Check specifically for the UI_FOCUS key press event type
	if event.is_action_pressed("ui_focus"):
		
		# 1. Block if input was just processed this cycle (Crucial for stability)
		if attack_input_buffered:
			return 
			
		# 2. Check if the character is allowed to attack 
		if not is_attacking:
			
			# Attack only if grounded OR if the air attack hasn't been used yet
			if is_on_floor() or can_air_attack:
				
				# Start the attack
				start_attack()
				
				# Lock air attack immediately after using it once
				if not is_on_floor():
					can_air_attack = false
					
				# Set the buffer flag immediately
				attack_input_buffered = true
				
				# Prevent this event from being read again
				get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	
	# 1. --- HORIZONTAL MOVEMENT & FLIPPING ---
	var direction_x: float = Input.get_axis("ui_left", "ui_right")
	
	if direction_x:
		velocity.x = direction_x * speed
		
		# Flipping Logic
		var scale = animated_sprite_2d.scale
		var hitbox_scale = attack_hitbox.scale # 💡 NEW: Reference the hitbox scale
		
		if direction_x > 0:
			scale.x = abs(scale.x)
			hitbox_scale.x = abs(hitbox_scale.x) # 💡 NEW: Flip the hitbox to face right
		elif direction_x < 0:
			scale.x = -abs(scale.x)
			hitbox_scale.x = -abs(hitbox_scale.x) # 💡 NEW: Flip the hitbox to face left
			
		animated_sprite_2d.scale = scale
		attack_hitbox.scale = hitbox_scale # 💡 NEW: Apply the hitbox scale
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 0.1)

	# 2. --- JUMP & GRAVITY ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Reset lock and velocity upon touching the floor
		if velocity.y > 0:
			velocity.y = 0
		can_air_attack = true 

	# Jump logic
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_attacking:
		velocity.y = jump_velocity

	# 3. --- ANIMATION STATE HANDLING ---
	if is_attacking:
		# Check if the animation needs to be restarted if it finished early or was interrupted (optional but safer)
		if animated_sprite_2d.get_animation() != "attack":
			animated_sprite_2d.play("attack")
	elif not is_on_floor():
		animated_sprite_2d.play("jump") 
	elif direction_x != 0:
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")

	# 4. --- APPLY MOVEMENT ---
	move_and_slide()
	
	# 📢 FIX: Clear the buffer at the end of the physics frame
	if attack_input_buffered:
		attack_input_buffered = false 

# --- ATTACK FUNCTIONS ---

func start_attack():
	is_attacking = true
	
	# 📢 NEW: Enable the hitbox when the attack starts
	# This assumes attack_hitbox is an Area2D and you want it active immediately
	attack_hitbox.monitoring = true 
	
	animated_sprite_2d.play("attack")
	attack_timer.start(ATTACK_DURATION)

func _on_attack_animation_finished():
	# 1. Reset the attack state
	is_attacking = false
	
	# 📢 NEW: Disable the hitbox when the attack ends
	attack_hitbox.monitoring = false 
	
	# 3. The physics_process loop will automatically set the correct idle/run/jump animation
	attack_timer.stop()
	
func _on_attack_hitbox_area_entered(area: Area2D):
	# The 'area' parameter is the node that entered the hitbox (which should be the coin's root Area2D)
	
	# Check if the overlapped area is a coin (using the group we set up)
	if area.is_in_group("collectible"):
		
		# Ensure the attack hitbox is only processed when the player is actively attacking
		# This check prevents coins from being destroyed just by walking over them
		if is_attacking:
			
			# OPTIONAL: Add score, sound effects, particles here.
			
			# 1. Destroy the coin
			area.collect_and_vanish() 
			
			# 2. Optional: If you only want one hit per attack animation, you can disable the hitbox here:
			# attack_hitbox.monitoring = false
			
			pass # End of coin destruction logic
