# Scenes/sauce_holder.gd - Now just a simple scene registration
extends Node2D

func _ready():
	# Register with InventoryManager
	InventoryManager.register_scene_node(self)

	# Connect to player's enemy death signal for XP distribution
	var player = get_parent()
	if player.has_signal("enemy_died_with_sources"):
		player.enemy_died_with_sources.connect(InventoryManager.distribute_xp_by_damage)

	# Create bottles for initially equipped sauces
	for sauce in InventoryManager.get_equipped_sauces():
		InventoryManager.create_bottle_for_sauce(sauce)
