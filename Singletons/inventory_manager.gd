# Singletons/inventory_manager.gd
extends Node

# Direct signals for UI
signal bottle_leveled_up(bottle_id: String, sauce_name: String, level: int)

var max_equipped_size = 6
var max_inventory = 6

# Both arrays now store bottle instances only
var storage: Array = []
var equipped: Array = []

# Legacy resources for initial setup only
var old_equipped: Array = [
	preload("res://Resources/glacier_glaze.tres"),
	#preload("res://Resources/prehistoric_pesto.tres")
	#preload("res://Resources/hot_sauce.tres"),
	#preload("res://Resources/archaean_apple_butter.tres")
	#preload("res://Resources/jurassic_jalapeno.tres")
	#preload("res://Resources/sriracha.tres")
]

var scene_holder_node: Node2D

signal sauce_moved(from_data, to_data)
signal sauce_equipped(bottle_instance: ImprovedBaseSauceBottle)
signal sauce_unequipped(bottle_instance: ImprovedBaseSauceBottle)

# New signals for talent system
signal talent_applied(bottle: ImprovedBaseSauceBottle, talent: Talent)
signal talent_removed(bottle: ImprovedBaseSauceBottle, talent: Talent)
signal bottle_respecced(bottle: ImprovedBaseSauceBottle)

func _ready() -> void:
	storage.resize(max_inventory)
	equipped.resize(max_equipped_size)
	#print("InventoryManager initialized with bottle instance storage only")

func register_scene_node(scene_node: Node2D):
	scene_holder_node = scene_node
	#print("InventoryManager: Scene node registered")

# BOTTLE INSTANCE MANAGEMENT
func create_bottle_for_sauce(sauce_resource: BaseSauceResource) -> ImprovedBaseSauceBottle:
	var item_data = ItemData.new()
	var bottle = item_data.create_bottle(sauce_resource)

	if not bottle:
		#print("❌ Failed to create bottle instance!")
		return null

	# Connect bottle level up signal
	if bottle.has_signal("leveled_up"):
		bottle.leveled_up.connect(_on_bottle_leveled_up)

	#print("✅ Created bottle for: %s" % sauce_resource.sauce_name)
	return bottle

func add_bottle_to_scene(bottle: ImprovedBaseSauceBottle):
	"""Add bottle to scene when equipped"""
	if scene_holder_node and bottle:
		scene_holder_node.add_child(bottle)
		_position_weapons()

func remove_bottle_from_scene(bottle: ImprovedBaseSauceBottle):
	"""Remove bottle from scene when unequipped"""
	if scene_holder_node and bottle and bottle.get_parent() == scene_holder_node:
		scene_holder_node.remove_child(bottle)
		_position_weapons()

func destroy_bottle(bottle: ImprovedBaseSauceBottle):
	"""Completely destroy a bottle instance"""
	if not bottle:
		return

	# Disconnect signal
	if bottle.has_signal("leveled_up"):
		bottle.leveled_up.disconnect(_on_bottle_leveled_up)

	# Remove from scene if present
	remove_bottle_from_scene(bottle)

	# Queue for deletion
	bottle.queue_free()
	#print("🗑️ Destroyed bottle: %s" % bottle.sauce_data.sauce_name)

# SIGNAL HANDLING
func _on_bottle_leveled_up(bottle_id: String, level: int, sauce_name: String):
	#print("InventoryManager: %s leveled up to %d" % [sauce_name, level])
	bottle_leveled_up.emit(bottle_id, sauce_name, level)

# BOTTLE LOOKUP
func get_bottle_by_id(bottle_id: String) -> ImprovedBaseSauceBottle:
	# Search in equipped first
	for bottle in equipped:
		if bottle and bottle.bottle_id == bottle_id:
			return bottle

	# Search in storage
	for bottle in storage:
		if bottle and bottle.bottle_id == bottle_id:
			return bottle

	return null

# POSITIONING
func _position_weapons():
	if not scene_holder_node:
		return

	# Only position bottles that are actually in the scene (equipped)
	var equipped_bottles = []
	for bottle in equipped:
		if is_instance_valid(bottle) and bottle.get_parent() == scene_holder_node:
			equipped_bottles.append(bottle)

	var bottle_count = equipped_bottles.size()
	if bottle_count == 0:
		return

	var angle_step = TAU / bottle_count
	for i in range(bottle_count):
		var bottle = equipped_bottles[i]
		var angle = i * angle_step
		var offset = Vector2(cos(angle), sin(angle)) * 24.0
		bottle.position = offset

# INVENTORY MANAGEMENT - Now handles instances properly
func move_sauce(from_data, to_data):
	var from = get_storage_data(from_data["slot_type"])
	var to = get_storage_data(to_data["slot_type"])

	# Get what's currently in each slot (both are bottle instances now)
	var from_item = from[from_data["slot_index"]]
	var to_item = to[to_data["slot_index"]]

	# Handle scene management when moving between equipped and storage
	if from_data["slot_type"] == "equipped" and from_item != null:
		remove_bottle_from_scene(from_item)
		sauce_unequipped.emit(from_item)

	if to_data["slot_type"] == "equipped" and to_item != null:
		remove_bottle_from_scene(to_item)
		sauce_unequipped.emit(to_item)

	# Swap the bottle instances
	from[from_data["slot_index"]] = to_item
	to[to_data["slot_index"]] = from_item

	# Handle scene addition when moving to equipped
	if to_data["slot_type"] == "equipped" and from_item != null:
		add_bottle_to_scene(from_item)
		sauce_equipped.emit(from_item)

	if from_data["slot_type"] == "equipped" and to_item != null:
		add_bottle_to_scene(to_item)
		sauce_equipped.emit(to_item)

	emit_signal("sauce_moved", from_data, to_data)

func get_storage_data(location):
	if location == "equipped":
		return equipped
	else:
		return storage

func get_equipped_bottles() -> Array:
	var active_bottles = []
	for bottle in equipped:
		if bottle != null:
			active_bottles.append(bottle)
	return active_bottles

# XP DISTRIBUTION - Equal share to all equipped bottles
func distribute_xp_by_damage(total_xp: int, damage_sources: Dictionary):
	var equipped_bottles = get_equipped_bottles()

	print("🎯 XP Distribution Debug:")
	print("  Total XP: %d" % total_xp)
	print("  Damage sources: %s" % str(damage_sources))
	print("  Equipped bottles count: %d" % equipped_bottles.size())
	for i in range(equipped_bottles.size()):
		var bottle = equipped_bottles[i]
		if bottle and bottle.sauce_data:
			print("    %d. %s (ID: %s)" % [i+1, bottle.sauce_data.sauce_name, bottle.bottle_id])

	if equipped_bottles.is_empty():
		print("❌ No equipped bottles to distribute XP to")
		return

	# Split XP equally among all equipped bottles
	var xp_per_bottle = int(total_xp / equipped_bottles.size())
	var remainder = total_xp % equipped_bottles.size()

	print("💎 Distributing %d XP equally: %d per bottle to %d bottles" % [total_xp, xp_per_bottle, equipped_bottles.size()])

	for i in range(equipped_bottles.size()):
		var bottle = equipped_bottles[i]
		if bottle and bottle.has_method("gain_xp"):
			var final_xp = xp_per_bottle
			# Give remainder XP to first few bottles to ensure total adds up
			if i < remainder:
				final_xp += 1

			bottle.gain_xp(final_xp)
			print("  ✅ %s gained %d XP" % [bottle.sauce_data.sauce_name if bottle.sauce_data else "Unknown", final_xp])
		else:
			print("  ❌ Bottle %d has no gain_xp method" % i)

# ===================================================================
# TALENT SYSTEM - REPLACES OLD UPGRADE SYSTEM
# ===================================================================

# TALENT APPLICATION
func apply_upgrade_choice(bottle_id: String, choice_number: int):
	#print("InventoryManager: Applying talent choice %d to bottle %s" % [choice_number, bottle_id])

	var bottle = get_bottle_by_id(bottle_id)
	if not bottle:
		#print("Warning: Bottle %s not found!" % bottle_id)
		return

	var sauce_name = bottle.sauce_data.sauce_name
	var level = bottle.current_level

	# Get talent from talent manager
	var talent = TalentManager.get_talent_by_choice(sauce_name, level, choice_number)
	if not talent:
		#print("No talent found for %s level %d choice %d" % [sauce_name, level, choice_number])
		return

	# Apply the talent
	talent.apply_to_bottle(bottle)
	bottle.active_talents.append(talent)

	# Update chosen upgrades display with level info
	var full_talent = "L%d: %s" % [level, talent.talent_name]
	bottle.chosen_upgrades.append(full_talent)

	#print("✨ Applied talent: %s to bottle %s" % [talent.talent_name, bottle_id])

	# Trigger talent applied signal for UI updates
	talent_applied.emit(bottle, talent)

# Updated to get talent names and descriptions for UI
func get_upgrade_name(sauce_name: String, choice_number: int) -> String:
	# Default to level 1 for backwards compatibility
	return get_talent_name_for_level(sauce_name, 1, choice_number)

func get_talent_name_for_level(sauce_name: String, level: int, choice_number: int) -> String:
	var talent = TalentManager.get_talent_by_choice(sauce_name, level, choice_number)
	return talent.talent_name if talent else "Unknown Talent"

func get_upgrade_description(sauce_name: String, choice_number: int) -> String:
	# Default to level 1 for backwards compatibility
	return get_talent_description_for_level(sauce_name, 1, choice_number)

func get_talent_description_for_level(sauce_name: String, level: int, choice_number: int) -> String:
	var talent = TalentManager.get_talent_by_choice(sauce_name, level, choice_number)
	return talent.description if talent else "Unknown Effect"

func get_talent_preview_for_level(sauce_name: String, level: int, choice_number: int) -> String:
	var talent = TalentManager.get_talent_by_choice(sauce_name, level, choice_number)
	return talent.get_preview_text() if talent else ""

# BETTER: Level-aware talent application (used by UI)
func apply_talent_choice_with_level(bottle_id: String, level: int, choice_number: int):
	#print("InventoryManager: Applying level %d talent choice %d to bottle %s" % [level, choice_number, bottle_id])

	var bottle = get_bottle_by_id(bottle_id)
	if not bottle:
		#print("Warning: Bottle %s not found!" % bottle_id)
		return

	var sauce_name = bottle.sauce_data.sauce_name

	# Get talent from talent manager
	var talent = TalentManager.get_talent_by_choice(sauce_name, level, choice_number, bottle)
	if not talent:
		#print("No talent found for %s level %d choice %d" % [sauce_name, level, choice_number])
		return

	# Apply the talent
	talent.apply_to_bottle(bottle)
	bottle.active_talents.append(talent)

	# Update chosen upgrades display with detailed info
	var full_talent = "L%d: %s (%s)" % [level, talent.talent_name, talent.description]
	bottle.chosen_upgrades.append(full_talent)

	#print("✨ Applied talent: %s to bottle %s" % [talent.talent_name, bottle_id])

	# Trigger talent applied signal for UI updates
	talent_applied.emit(bottle, talent)

# Helper functions for talent system
func get_available_talents_for_bottle(bottle: ImprovedBaseSauceBottle) -> Array[Talent]:
	"""Get available talents for a bottle's current level"""
	return TalentManager.get_talents_for_level(bottle.sauce_data.sauce_name, bottle.current_level, bottle)

func can_bottle_level_up(bottle: ImprovedBaseSauceBottle) -> bool:
	"""Check if bottle can still level up and get talents"""
	return bottle.current_level < bottle.max_level

func get_bottle_talent_summary(bottle: ImprovedBaseSauceBottle) -> Dictionary:
	"""Get summary of bottle's talents for UI"""
	var summary = bottle.get_talent_summary()
	summary["available_talents"] = get_available_talents_for_bottle(bottle).size()
	summary["can_level_up"] = can_bottle_level_up(bottle)
	return summary

# Talent removal (for respec functionality)
func remove_talent_from_bottle(bottle: ImprovedBaseSauceBottle, talent: Talent):
	"""Remove a specific talent from a bottle"""
	if talent in bottle.active_talents:
		talent.remove_from_bottle(bottle)
		bottle.active_talents.erase(talent)

		# Update display
		var talent_display = "L%d: %s" % [talent.level_required, talent.talent_name]
		if talent_display in bottle.chosen_upgrades:
			bottle.chosen_upgrades.erase(talent_display)

		#print("Removed talent: %s from bottle %s" % [talent.talent_name, bottle.bottle_id])
		talent_removed.emit(bottle, talent)

func respec_bottle(bottle: ImprovedBaseSauceBottle):
	"""Remove all talents from a bottle (full respec)"""
	var talents_to_remove = bottle.active_talents.duplicate()

	for talent in talents_to_remove:
		remove_talent_from_bottle(bottle, talent)

	#print("Full respec completed for bottle %s" % bottle.bottle_id)
	bottle_respecced.emit(bottle)

# Statistics and debugging
func get_talent_statistics() -> Dictionary:
	"""Get statistics about talent usage across all bottles"""
	var stats = {
		"total_talents_applied": 0,
		"talent_usage": {},
		"transformation_count": 0,
		"bottles_with_talents": 0
	}

	var all_bottles = get_equipped_bottles() + storage.filter(func(x): return x != null)

	for bottle in all_bottles:
		if bottle and bottle.active_talents.size() > 0:
			stats.bottles_with_talents += 1
			stats.total_talents_applied += bottle.active_talents.size()

			for talent in bottle.active_talents:
				if not stats.talent_usage.has(talent.talent_name):
					stats.talent_usage[talent.talent_name] = 0
				stats.talent_usage[talent.talent_name] += 1

				if talent.talent_type == Talent.TalentType.TRANSFORMATION:
					stats.transformation_count += 1

	return stats

func debug_print_bottle_talents(bottle: ImprovedBaseSauceBottle):
	pass
	"""Debug function to #print all talents on a bottle"""
	#print("=== Bottle Talents Debug: %s ===" % bottle.bottle_id)
	#print("Sauce: %s, Level: %d" % [bottle.sauce_data.sauce_name, bottle.current_level])
	#print("Active Talents (%d):" % bottle.active_talents.size())

	for i in range(bottle.active_talents.size()):
		var talent = bottle.active_talents[i]
		#print("  %d. L%d %s (%s)" % [i+1, talent.level_required, talent.talent_name, Talent.TalentType.keys()[talent.talent_type]])

	#print("Special Effects (%d):" % bottle.special_effects.size())
	for effect in bottle.special_effects:
		pass
		#print("  - %s (%s)" % [effect.effect_name, SpecialEffectResource.EffectType.keys()[effect.effect_type]])

	#print("Trigger Effects (%d):" % bottle.trigger_effects.size())
	for trigger in bottle.trigger_effects:
		pass
		#print("  - %s (%s)" % [trigger.trigger_name, TriggerEffectResource.TriggerType.keys()[trigger.trigger_type]])

	#print("Transformations: %s" % str(bottle.transformation_effects))
	#print("========================")

# SAUCE SELECTION
func select_sauce(sauce: BaseSauceResource):
	"""Create new bottle instance and place it"""
	var bottle = create_bottle_for_sauce(sauce)
	if not bottle:
		return

	var first_null_index = equipped.find(null)
	if first_null_index != -1:
		equipped[first_null_index] = bottle
		add_bottle_to_scene(bottle)
		sauce_equipped.emit(bottle)
	else:
		# Put in storage if equipped is full
		var storage_index = storage.find(null)
		if storage_index != -1:
			storage[storage_index] = bottle

# INVENTORY UTILITIES
func is_inventory_full():
	return equipped.find(null) == -1

func can_equip_sauce():
	return equipped.size() < 6

func can_store_sauce():
	return storage.size() < 6

func apply_specific_talent(bottle_id: String, talent: Talent):
	"""Apply a specific talent object to a bottle"""
	#print("InventoryManager: Applying talent %s to bottle %s" % [talent.talent_name, bottle_id])

	var bottle = get_bottle_by_id(bottle_id)
	if not bottle:
		#print("Warning: Bottle %s not found!" % bottle_id)
		return

	# Apply the talent directly
	talent.apply_to_bottle(bottle)
	bottle.active_talents.append(talent)
	bottle.recalculate_all_effective_stats()
	TriggerActionManager.refresh_active_triggers(bottle)

	# Update chosen upgrades display
	var full_talent = "L%d: %s" % [bottle.current_level, talent.talent_name]
	bottle.chosen_upgrades.append(full_talent)

	#print("✨ Applied talent: %s to bottle %s" % [talent.talent_name, bottle_id])

	# Trigger talent applied signal for UI updates
	talent_applied.emit(bottle, talent)
