extends Node2D

# --- COIN CONFIGURATION ---
# Load your coin scenes once in the script (Preload is efficient)
const COIN_TYPES = [
	preload("res://Scenes/cards.tscn"),  # Common Coin (e.g., 1 value)
	preload("res://Scenes/card_2.tscn"),  # Rare Coin (e.g., 5 value)
	preload("res://Scenes/card_3.tscn"),  # Legendary Coin (e.g., 10 value)
]

# --- SPAWNING SETTINGS ---
@export var spawn_height_offset: float = -600.0 # Negative value to spawn high above the spawner
@export var spawn_interval_min: float = 1.0  # Fastest time between drops (seconds)
@export var spawn_interval_max: float = 3.0  # Slowest time between drops (seconds)
@export var spawn_x_range: float = 400.0    # Random horizontal distance from spawner center

# --- INTERNAL NODES ---
@onready var spawn_timer = Timer.new()

func _ready():
	# Setup the timer
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# Start the timer with a random interval
	_set_random_timer()

func _set_random_timer():
	var random_time = randf_range(spawn_interval_min, spawn_interval_max)
	spawn_timer.start(random_time)

func _on_spawn_timer_timeout():
	# 1. Choose a random coin type
	var coin_scene = COIN_TYPES[randi_range(0, COIN_TYPES.size() - 1)]
	
	# 2. Instantiate the coin
	var coin_instance = coin_scene.instantiate()
	
# 3. Determine a random spawn position
	var random_x_offset = randf_range(-spawn_x_range, spawn_x_range)
	
	# 📢 THE FIX: Add a large NEGATIVE Y offset (spawn_height_offset)
	var spawn_offset = Vector2(random_x_offset, spawn_height_offset)
	
	coin_instance.global_position = global_position + spawn_offset
	
	# 4. Add the coin to the main scene tree (root node for easy access)
	get_tree().root.add_child(coin_instance)

	# 5. Reset the timer for the next drop
	_set_random_timer()
