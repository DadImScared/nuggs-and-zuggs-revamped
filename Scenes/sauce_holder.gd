# Scenes/sauce_holder.gd - Simplified to just register with InventoryManager
extends Node2D

func _ready():
	# Register with InventoryManager so it can manage bottles in this scene
	InventoryManager.register_scene_node(self)

	# Connect to player's enemy death signal for XP distribution
	var player = get_parent()
	if player.has_signal("enemy_died_with_sources"):
		player.enemy_died_with_sources.connect(InventoryManager.distribute_xp_by_damage)

	# Create bottle instances for initially equipped resources
	for sauce in InventoryManager.old_equipped:
		if sauce:
			InventoryManager.select_sauce(sauce)
