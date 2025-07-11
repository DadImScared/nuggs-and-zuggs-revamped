# Singletons/enemy_pool_manager.gd
extends Node

# Arrays to hold different types of enemies
var basic_enemies: Array[BaseEnemyResource] = []
var elite_enemies: Array[BaseEnemyResource] = []
var boss_enemies: Array[BaseEnemyResource] = []

# This tracks which enemies can currently spawn (based on weights)
var current_spawn_weights: Dictionary = {}

# At what player levels do different enemy tiers unlock?
var spawn_tier_thresholds = {
	"basic": 1,      # Basic enemies available from start
	"elite": 5,      # Elite enemies unlock at level 5
	"boss": 10       # Boss enemies unlock at level 10
}

func _ready():
	print("Enemy Pool Manager starting up...")
	load_enemy_types()
	update_spawn_weights()

func load_enemy_types():
	print("Loading enemy types...")

	# Load basic enemy (your existing red square)
	var basic_enemy = BaseEnemyResource.new()
	basic_enemy.enemy_name = "Red Square"
	basic_enemy.enemy_type = "basic"
	basic_enemy.enemy_color = Color.RED
	basic_enemy.spawn_weight = 100
	basic_enemy.scene_path = "res://Scenes/enemy.tscn"  # Your existing enemy scene
	basic_enemies.append(basic_enemy)
	print("✓ Created basic enemy resource")

	# Load bee enemy from .tres file
	var bee_resource_path = "res://Scenes/Enemies/bee_enemy.tres"
	if ResourceLoader.exists(bee_resource_path):
		var bee_enemy = load(bee_resource_path) as BaseEnemyResource
		if bee_enemy:
			basic_enemies.append(bee_enemy)
			print("✓ Loaded bee enemy from file: %s" % bee_enemy.enemy_name)
			print("  - Health: %.1f, Speed: %.1f, Spawn Weight: %d" % [bee_enemy.base_health, bee_enemy.base_speed, bee_enemy.spawn_weight])
		else:
			print("✗ Failed to load bee enemy resource - file exists but couldn't parse")
	else:
		print("✗ Bee enemy resource file not found at: %s" % bee_resource_path)
		print("  Please create Resources/bee_enemy.tres with BaseEnemyResource type")

	print("Final enemy count: %d enemies loaded" % basic_enemies.size())
	for enemy in basic_enemies:
		print("  - %s (weight: %d)" % [enemy.enemy_name, enemy.spawn_weight])

func update_spawn_weights():
	# Clear previous weights
	current_spawn_weights.clear()

	# Get current player level
	var player_level = PlayerStats.level if PlayerStats else 1

	# Add basic enemies if player level allows
	if player_level >= spawn_tier_thresholds["basic"]:
		for enemy in basic_enemies:
			current_spawn_weights[enemy] = enemy.spawn_weight

	# Add elite enemies if player level allows
	if player_level >= spawn_tier_thresholds["elite"]:
		for enemy in elite_enemies:
			current_spawn_weights[enemy] = enemy.spawn_weight

	# Add boss enemies if player level allows (but make them rare)
	if player_level >= spawn_tier_thresholds["boss"]:
		for enemy in boss_enemies:
			current_spawn_weights[enemy] = enemy.spawn_weight * 0.1  # Much rarer

	print("Updated spawn weights: %d enemy types available" % current_spawn_weights.size())

func get_random_enemy_resource() -> BaseEnemyResource:
	# Update weights in case player leveled up
	update_spawn_weights()

	# If no enemies available, return null
	if current_spawn_weights.is_empty():
		print("Warning: No enemies available to spawn!")
		return null

	# Calculate total weight of all enemies
	var total_weight = 0
	for enemy in current_spawn_weights:
		total_weight += current_spawn_weights[enemy]

	# Pick a random number between 0 and total weight
	var random_value = randf() * total_weight
	var cumulative_weight = 0

	# Find which enemy this random number corresponds to
	for enemy in current_spawn_weights:
		cumulative_weight += current_spawn_weights[enemy]
		if random_value <= cumulative_weight:
			print("Selected enemy: %s" % enemy.enemy_name)
			return enemy

	# Fallback - return first enemy
	return current_spawn_weights.keys()[0]

func add_enemy_type(enemy_resource: BaseEnemyResource, tier: String = "basic"):
	print("Adding enemy type: %s to tier: %s" % [enemy_resource.enemy_name, tier])

	match tier:
		"basic":
			basic_enemies.append(enemy_resource)
		"elite":
			elite_enemies.append(enemy_resource)
		"boss":
			boss_enemies.append(enemy_resource)
		_:
			print("Unknown tier: %s, adding to basic" % tier)
			basic_enemies.append(enemy_resource)

	# Update weights so new enemy can spawn
	update_spawn_weights()
