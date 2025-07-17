# SauceActions/Infection/Triggers/viral_relay.gd
class_name ViralRelayTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "viral_relay"
	trigger_description = "Every 3 seconds, infections jump to closest uninfected targets"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource) -> void:
	# Get parameters
	var jump_range = trigger_data.effect_parameters.get("jump_range", 150.0)
	var infection_strength = trigger_data.effect_parameters.get("infection_strength", 0.8)  # 80% of original

	# Find all infected enemies from this bottle
	var infected_enemies = _find_infected_enemies_from_bottle(source_bottle.bottle_id)

	if infected_enemies.size() == 0:
		print("🔗 Viral Relay: No infected enemies found")
		return

	print("🔗 Viral Relay: Processing %d infected enemies" % infected_enemies.size())

	var successful_jumps = 0

	# Process each infected enemy
	for infected_enemy in infected_enemies:
		var jump_target = _find_closest_uninfected_target(infected_enemy, jump_range)
		if jump_target:
			_execute_viral_jump(infected_enemy, jump_target, source_bottle, infection_strength)
			successful_jumps += 1

	print("🔗 Viral Relay: %d infections jumped to new targets" % successful_jumps)
	log_trigger_executed(source_bottle, trigger_data)

func _find_infected_enemies_from_bottle(bottle_id: String) -> Array[Node2D]:
	"""Find enemies infected by this specific bottle"""
	var infected_enemies: Array[Node2D] = []
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy) and _is_enemy_infected_by_bottle(enemy, bottle_id):
			infected_enemies.append(enemy)

	return infected_enemies

func _is_enemy_infected_by_bottle(enemy: Node2D, bottle_id: String) -> bool:
	"""Check if enemy is infected by this specific bottle"""
	if not is_instance_valid(enemy):
		return false

	# Check if enemy has infection
	if enemy.has_method("has_status_effect"):
		if not enemy.has_status_effect("infect"):
			return false
	elif "active_effects" in enemy:
		if not "infect" in enemy.active_effects:
			return false
	else:
		return false

	# Check if this bottle caused the infection
	if "active_effects" in enemy and "infect" in enemy.active_effects:
		var infection_data = enemy.active_effects["infect"]
		return infection_data.get("source_bottle_id", "") == bottle_id

	return false

func _find_closest_uninfected_target(source_enemy: Node2D, max_range: float) -> Node2D:
	"""Find the closest uninfected enemy within range"""
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")
	var closest_target = null
	var closest_distance = max_range + 1.0  # Start beyond max range

	for enemy in all_enemies:
		if enemy == source_enemy or not is_instance_valid(enemy):
			continue

		# Skip if already infected
		if _is_enemy_infected(enemy):
			continue

		# Check distance
		var distance = source_enemy.global_position.distance_to(enemy.global_position)
		if distance <= max_range and distance < closest_distance:
			closest_target = enemy
			closest_distance = distance

	return closest_target

func _is_enemy_infected(enemy: Node2D) -> bool:
	"""Check if enemy has any infection"""
	if not is_instance_valid(enemy):
		return false

	if enemy.has_method("has_status_effect"):
		return enemy.has_status_effect("infect")
	elif "active_effects" in enemy:
		return "infect" in enemy.active_effects

	return false

func _execute_viral_jump(from_enemy: Node2D, to_enemy: Node2D, source_bottle: ImprovedBaseSauceBottle, strength: float):
	"""Execute the viral jump from one enemy to another"""
	if not is_instance_valid(from_enemy) or not is_instance_valid(to_enemy):
		return

	# Apply infection to target
	var intensity = source_bottle.effective_effect_intensity * strength
	var duration = source_bottle.sauce_data.effect_duration

	if to_enemy.has_method("apply_status_effect"):
		to_enemy.apply_status_effect("infect", duration, intensity, source_bottle.bottle_id)

		# Set infection color
		if "active_effects" in to_enemy and "infect" in to_enemy.active_effects:
			to_enemy.active_effects["infect"]["color"] = source_bottle.sauce_data.sauce_color

	# Create visual relay effect
	_create_relay_visual(from_enemy.global_position, to_enemy.global_position, source_bottle.sauce_data.sauce_color)

func _create_relay_visual(from_pos: Vector2, to_pos: Vector2, color: Color):
	"""Create visual line showing the viral relay - simplified and safe"""
	var line = Line2D.new()
	line.width = 4.0
	line.default_color = Color(color.r, color.g, color.b, 0.9)

	# Create complete line immediately
	line.add_point(from_pos)
	line.add_point(to_pos)

	Engine.get_main_loop().current_scene.add_child(line)

	# Simple fade animation - no complex tween_method calls
	var tween = line.create_tween()

	# Brief bright flash, then fade out
	tween.tween_property(line, "modulate", Color.WHITE, 0.1)
	tween.tween_property(line, "modulate:a", 0.0, 0.5)
	tween.tween_callback(line.queue_free)

	print("🔗 Viral relay visual created from %s to %s" % [from_pos, to_pos])
