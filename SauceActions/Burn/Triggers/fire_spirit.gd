# SauceActions/Burn/Triggers/fire_spirit.gd
class_name FireSpiritTrigger
extends BaseTriggerAction

# Track recently targeted enemies to encourage spread
var recently_targeted: Array[Node2D] = []

func _init() -> void:
	trigger_name = "fire_spirit"
	trigger_description = "15% chance to spawn a seeking fire spirit that travels to nearest enemy"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var hit_enemy = data.effect_parameters.get("hit_enemy")
	var projectile = data.effect_parameters.get("hit_projectile")

	# Always spawn from bottle position for cooler effect
	var spawn_pos: Vector2
	if bottle and is_instance_valid(bottle):
		spawn_pos = bottle.global_position
		DebugControl.debug_status("🔥 Fire Spirit: Spawning from bottle at %s" % spawn_pos)
	else:
		DebugControl.debug_status("⚠️ Fire Spirit: No valid bottle position")
		return

	# Read ALL parameters from effect_parameters (consistent location)
	var spirit_count = data.effect_parameters.get("spirit_count", 1)
	var seek_range = data.effect_parameters.get("seek_range", 300.0)
	var spirit_speed = data.effect_parameters.get("spirit_speed", 200.0)
	var burn_stacks = data.effect_parameters.get("burn_stacks", 2)
	var spirit_damage = data.effect_parameters.get("spirit_damage", 7.0)

	# NEW: Trail parameters from Blazing Trails talent
	var leaves_trail = data.effect_parameters.get("leaves_trail", false)
	var trail_width = data.effect_parameters.get("trail_width", 60.0)
	var trail_duration = data.effect_parameters.get("trail_duration", 5.0)
	var trail_tick_damage = data.effect_parameters.get("trail_tick_damage", 8.0)
	var trail_tick_interval = data.effect_parameters.get("trail_tick_interval", 0.3)
	var trail_color = data.effect_parameters.get("trail_color", Color(1.0, 0.3, 0.0, 0.6))

	# Spawn fire spirits from the bottle
	for i in range(spirit_count):
		_spawn_fire_spirit(spawn_pos, seek_range, spirit_speed, burn_stacks,
			spirit_damage, bottle, leaves_trail, trail_width, trail_duration,
			trail_tick_damage, trail_tick_interval, trail_color, data.effect_parameters)

func _spawn_fire_spirit(spawn_pos: Vector2, seek_range: float, spirit_speed: float,
	burn_stacks: int, spirit_damage: float, source_bottle: ImprovedBaseSauceBottle,
	leaves_trail: bool = false, trail_width: float = 60.0, trail_duration: float = 5.0,
	trail_tick_damage: float = 8.0, trail_tick_interval: float = 0.3,
	trail_color: Color = Color(1.0, 0.3, 0.0, 0.6), enhanced_params: Dictionary = {}):
	"""Spawn a single fire spirit with smart targeting"""

	# Find smart target
	var target_enemy = _find_smart_target(spawn_pos, seek_range)
	if not target_enemy:
		# Try clearing recently targeted and search again
		_clear_recently_targeted_if_needed()
		target_enemy = _find_smart_target(spawn_pos, seek_range)

	if not target_enemy:
		DebugControl.debug_status("🔥 Fire Spirit: No valid targets found")
		return

	# Add to recently targeted list
	_manage_recently_targeted_list(target_enemy)

	# Load fire spirit scene
	var fire_spirit_scene = preload("res://Effects/FireSpirit/fire_spirit.tscn")
	var fire_spirit = fire_spirit_scene.instantiate()

	# Set position
	fire_spirit.global_position = spawn_pos

	# Setup fire spirit with correct method and parameters
	fire_spirit.setup_spirit(target_enemy, source_bottle, spirit_speed, burn_stacks, spirit_damage)

	# NEW: Pass enhanced burn parameters from the trigger system
	if source_bottle and TriggerActionManager.trigger_actions.has("burn"):
		var burn_action = TriggerActionManager.trigger_actions["burn"]
		var burn_trigger = _find_burn_trigger(source_bottle)
		if burn_trigger:
			var enhanced_burn_data = burn_action.apply_enhancements(source_bottle, burn_trigger)
			fire_spirit.setup_enhanced_burn_params(enhanced_burn_data.effect_parameters)

	# Enable trail behavior if Blazing Trails talent is active
	if leaves_trail:
		fire_spirit.setup_trail_behavior(trail_width, trail_duration, trail_tick_damage, trail_tick_interval, trail_color)

	# Add to scene (deferred to avoid physics collision issues)
	var main_scene = Engine.get_main_loop().current_scene
	main_scene.call_deferred("add_child", fire_spirit)

	DebugControl.debug_status("🔥 Fire Spirit spawned with speed: %.0f, targeting: %s" % [spirit_speed, str(target_enemy)])

func _find_burn_trigger(bottle: ImprovedBaseSauceBottle) -> TriggerEffectResource:
	"""Find the burn trigger in the bottle's trigger effects"""
	for trigger_effect in bottle.trigger_effects:
		if trigger_effect.trigger_name == "burn":
			return trigger_effect
	return null

func _find_smart_target(spawn_pos: Vector2, seek_range: float) -> Node2D:
	"""Find the best target using smart targeting logic"""
	var main_scene = Engine.get_main_loop().current_scene
	var all_enemies = main_scene.get_tree().get_nodes_in_group("enemies")
	var valid_targets = []

	for enemy in all_enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = spawn_pos.distance_to(enemy.global_position)
		if distance <= seek_range:
			valid_targets.append({"enemy": enemy, "distance": distance})

	if valid_targets.is_empty():
		return null

	# Sort by distance
	valid_targets.sort_custom(func(a, b): return a.distance < b.distance)

	# Prioritize fresh enemies (not recently targeted)
	for target_data in valid_targets:
		var enemy = target_data.enemy
		if not enemy in recently_targeted:
			# Check if enemy is not burning (prefer fresh targets)
			if not _is_enemy_burning(enemy):
				DebugControl.debug_status("🔥 Fire Spirit: Targeting non-burning fresh enemy")
				return enemy

	# If no fresh non-burning enemies, target fresh burning enemies
	for target_data in valid_targets:
		var enemy = target_data.enemy
		if not enemy in recently_targeted:
			DebugControl.debug_status("🔥 Fire Spirit: Targeting fresh burning enemy")
			return enemy

	# Fallback: target recently targeted enemies if needed
	for target_data in valid_targets:
		var enemy = target_data.enemy
		if not _is_enemy_burning(enemy):
			DebugControl.debug_status("🔥 Fire Spirit: Targeting non-burning enemy (recently targeted)")
			return enemy

	# Last resort: any valid target
	if valid_targets.size() > 0:
		DebugControl.debug_status("🔥 Fire Spirit: Random target fallback")
		return valid_targets[0].enemy

	return null

func _is_enemy_burning(enemy: Node2D) -> bool:
	"""Check if enemy is currently burning"""
	if not is_instance_valid(enemy):
		return false

	# Check for burn effect
	if enemy.has_method("has_status_effect"):
		return enemy.has_status_effect("burn")
	elif enemy.has_method("get_total_stack_count"):
		return enemy.get_total_stack_count("burn") > 0
	elif "active_effects" in enemy:
		return "burn" in enemy.active_effects

	return false

func _manage_recently_targeted_list(enemy: Node2D):
	"""Add enemy to recently targeted list and manage list size"""
	if not enemy in recently_targeted:
		recently_targeted.append(enemy)

	# Keep list manageable size
	if recently_targeted.size() > 6:
		recently_targeted.pop_front()

func _clear_recently_targeted_if_needed():
	"""Clear recently targeted list if it's getting too restrictive"""
	if recently_targeted.size() > 4:
		recently_targeted.clear()
		DebugControl.debug_status("🔥 Fire Spirit: Cleared recently targeted list")
