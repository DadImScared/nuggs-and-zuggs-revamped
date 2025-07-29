# SauceActions/Cold/Triggers/frozone.gd
class_name FrostZoneTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "frozone"
	trigger_description = "Cold enemies drop frost zones on death that deal damage over time"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	"""Execute frost zone creation when cold enemy dies"""

	# Get death event data - it's passed directly in the trigger_data for event triggers
	var killed_enemy = trigger_data.effect_parameters.get("killed_enemy")
	var enemy_position = trigger_data.effect_parameters.get("enemy_position", Vector2.ZERO)


	if not killed_enemy:
		return

	# Check if enemy had cold effect
	if not _had_cold_effect(killed_enemy):
		return

	# Get frost zone parameters from the original trigger resource
	var tick_damage = trigger_data.effect_parameters.get("tick_damage", 25)
	var radius = trigger_data.effect_parameters.get("radius", 80)
	var duration = trigger_data.effect_parameters.get("duration", 8)
	var tick_interval = trigger_data.effect_parameters.get("tick_interval", 0.5)

	# Create frost zone at enemy's death position
	_create_frost_zone(enemy_position, tick_damage, radius, duration, tick_interval, source_bottle)

	log_trigger_executed(source_bottle, trigger_data)

func _had_cold_effect(enemy: Node2D) -> bool:
	"""Check if enemy had cold effect when it died"""
	if not is_instance_valid(enemy):
		return false

	# Check stacking effects first (most likely location for cold effects)
	if "stacking_effects" in enemy:
		var stacking_effects = enemy.stacking_effects
		if "cold" in stacking_effects or "freeze" in stacking_effects or "slow" in stacking_effects:
			return true

	# Check basic active effects
	if "active_effects" in enemy:
		var effects = enemy.active_effects
		if "cold" in effects or "freeze" in effects or "slow" in effects:
			return true

	# Fallback: check if enemy has status effect methods
	if enemy.has_method("has_status_effect"):
		return enemy.has_status_effect("cold") or enemy.has_status_effect("freeze") or enemy.has_status_effect("slow")

	# Also check for stacking effect methods
	if enemy.has_method("get_total_stack_count"):
		return enemy.get_total_stack_count("cold") > 0 or enemy.get_total_stack_count("freeze") > 0 or enemy.get_total_stack_count("slow") > 0

	return false

func _create_frost_zone(position: Vector2, tick_damage: float, radius: float, duration: float, tick_interval: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create a frost zone area effect at the specified position"""

	# Get the main scene to add the frost zone to
	var main_scene = Engine.get_main_loop().current_scene
	if not main_scene:
		return

	# Defer the entire frost zone creation to avoid physics conflicts
	call_deferred("_create_frost_zone_deferred", main_scene, position, tick_damage, radius, duration, tick_interval, source_bottle.bottle_id)

func _create_frost_zone_deferred(main_scene: Node, position: Vector2, tick_damage: float, radius: float, duration: float, tick_interval: float, bottle_id: String):
	"""Create frost zone in a deferred call to avoid physics conflicts"""

	# Create frost zone from scene
	var frost_zone = preload("res://Effects/FrostZone/frost_zone.tscn").instantiate()

	# Add to scene first
	main_scene.add_child(frost_zone)

	# Set up frost zone properties
	frost_zone.setup_frost_zone(
		position,
		tick_damage,
		radius,
		duration,
		tick_interval,
		bottle_id
	)

	# Optional: Add spawn visual effect
	#_create_frost_zone_visual(position, radius)

func _create_frost_zone_visual(position: Vector2, radius: float):
	"""Create initial visual effect for frost zone creation"""
	var visual_data = {
		"position": position,
		"radius": radius,
		"color": Color(0.7, 0.9, 1.0, 0.6),  # Light blue
		"effect_type": "frost_zone_spawn"
	}

	# Use VisualEffectManager if available
	if VisualEffectManager:
		VisualEffectManager.create_area_effect(visual_data)
