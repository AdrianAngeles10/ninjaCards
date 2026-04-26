extends Area2D

# --- FALLING SETTINGS ---
# Maximum speed the coin can fall, to prevent it from becoming too fast.
@export var fall_speed_max: float = 150.0 
# How fast the coin accelerates downward (acting as local gravity).
@export var gravity_acceleration: float = 600.0 
# Y position where the coin is considered dropped and is removed (despawned).
@export var despawn_y_threshold: float = 2000.0 
@onready var animated_sprite_2d = $AnimatedSprite2D
const DEATH_ANIMATION_DURATION = 0.4 
@onready var death_timer = $death_timer
var is_collected: bool = false # <--- 🚨 THIS LINE MUST BE PRESENT 🚨
# --- INTERNAL VARIABLES ---
# The current speed and direction of the coin (only Y component is used for falling).
var current_velocity: Vector2 = Vector2(0, 0)

# --- NODE REFERENCES ---
# Assumes the AnimatedSprite2D is a direct child of this Area2D
#@onready var animated_sprite = $AnimatedSprite2D 


func _ready():
	# 1. Start the coin's spinning animation
	# 🚨 Ensure you have an animation named "spin" or change this name 🚨
	#animated_sprite.play("spin")
	animated_sprite_2d.play("default")  
	
	# 2. Give the coin a small initial downward push
	current_velocity.y = 50.0 


func _physics_process(delta: float) -> void:
	
	# 1. Apply Acceleration (Gravity)
	# Increase the downward velocity every frame based on the acceleration rate
	current_velocity.y += gravity_acceleration * delta
	
	# 2. Clamp Max Speed 
	# Prevents the coin from accelerating past a reasonable maximum speed
	current_velocity.y = min(current_velocity.y, fall_speed_max)
	
	# 3. Apply Movement
	# Update the coin's position based on its current velocity
	position += current_velocity * delta
	
	# 4. Cleanup (Despawn)
	# Check if the coin has fallen past the bottom of the screen threshold
	if position.y > despawn_y_threshold:
		queue_free() # Safely remove the coin from the scene
		
		
# func _on_body_entered(body):
#     # This function is where you would typically handle collection logic:
#     # if body is a CharacterBody2D (e.g., the player)
#     #     body.add_score(1)
#     #     queue_free()
#     pass
func collect_and_vanish():
	# Only run the collection logic once
	if is_collected:
		return
		
	is_collected = true
	
	# 1. Stop all movement
	current_velocity = Vector2.ZERO 
	
	# 2. Disable collision so it can't be hit again or interact with the player body
	monitoring = false
	
	# 3. Play the death/vanish animation
	# 🚨 Ensure your AnimatedSprite2D has an animation named "vanish" or "destroy"
	animated_sprite_2d.play("vanish") 
	
	# 4. Start the timer to remove the node after the animation finishes
	death_timer.start(DEATH_ANIMATION_DURATION)
