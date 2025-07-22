# Scenes/game.gd
extends Node2D

@onready var player = $Player

#func _ready():
	#print("Game scene ready, checking EnemyPoolManager...")
	#if EnemyPoolManager:
		#print("✓ EnemyPoolManager is available!")
	#else:
		#print("✗ EnemyPoolManager not found - did you add it as AutoLoad?")

func spawn_mob():
	#print("Spawning mob...")

	# Get a random enemy from our pool
	var enemy_resource = EnemyPoolManager.get_random_enemy_resource()

	if not enemy_resource:
		#print("No enemy resource available!")
		return

	#print("Selected: %s (weight: %d)" % [enemy_resource.enemy_name, enemy_resource.spawn_weight])

	# Load the correct scene for this enemy type
	var scene_path = enemy_resource.scene_path
	if not ResourceLoader.exists(scene_path):
		#print("Scene not found: %s, using fallback" % scene_path)
		scene_path = "res://Scenes/enemy.tscn"  # Fallback to basic enemy

	var enemy_scene = load(scene_path)
	var new_mob = enemy_scene.instantiate()

	# Set the enemy resource (for bee enemies and future enemy types)
	if new_mob.has_method("set_enemy_resource"):
		new_mob.set_enemy_resource(enemy_resource)
		#print("✓ Applied enemy resource to %s" % enemy_resource.enemy_name)
	else:
		# For basic enemies without the method, just apply color/scale
		if new_mob.has_node("Sprite2D"):
			new_mob.get_node("Sprite2D").modulate = enemy_resource.enemy_color
		#new_mob.scale = Vector2.ONE * enemy_resource.scale_modifier
		#print("✓ Applied basic visual settings to %s" % enemy_resource.enemy_name)

	# Position it randomly around the edge
	%PathFollow2D.progress_ratio = randf()
	new_mob.global_position = %PathFollow2D.global_position

	add_child(new_mob)

	# Connect the death signal
	new_mob.died.connect(Callable(player, "_on_mob_died"))
	if new_mob.has_signal("debuff_xp_earned"):
		new_mob.debuff_xp_earned.connect(Callable(player, "_on_debuff_xp_earned"))

	#print("✓ Spawned %s at %s" % [enemy_resource.enemy_name, new_mob.global_position])

func _on_timer_timeout() -> void:
	spawn_mob()

# Debug function - press Space to manually spawn an enemy
#func _input(event):
	#if event.is_action_pressed("ui_accept"):  # Space key
		##print("Manual spawn requested!")
		#spawn_mob()
