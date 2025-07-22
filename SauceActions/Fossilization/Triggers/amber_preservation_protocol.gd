# SauceActions/Fossilization/Triggers/amber_preservation_protocol.gd
class_name AmberPreservationProtocolTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "amber_preservation_protocol"
	trigger_description = "When fossilized enemies die, shatter into 3-5 amber seekers that fly out and fossilize on hit"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	# Get the dead enemy and spawn seekers from its position
	var dead_enemy = trigger_data.effect_parameters.get("killed_enemy")
	if not dead_enemy or not is_instance_valid(dead_enemy):
		return

	#print("🔶 Amber Preservation: Fossilized enemy died! Spawning seekers...")
	call_deferred("_spawn_amber_seekers", dead_enemy.global_position, trigger_data, source_bottle)
	#_spawn_amber_seekers(dead_enemy.global_position, trigger_data, source_bottle)

func should_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> bool:
	# Check if a fossilized enemy died
	var dead_enemy = trigger_data.effect_parameters.get("killed_enemy")
	if dead_enemy and is_instance_valid(dead_enemy):
		return _was_enemy_fossilized(dead_enemy)
	return false

func _was_enemy_fossilized(enemy: Node2D) -> bool:
	"""Check if the dead enemy was fossilized when it died"""
	if enemy.has_method("get_total_stack_count"):
		return enemy.get_total_stack_count("fossilize") > 0
	return false

func _spawn_amber_seekers(death_position: Vector2, trigger_data: EnhancedTriggerData, source_bottle: ImprovedBaseSauceBottle):
	"""Spawn amber seekers flying out from the death position"""
	var seeker_count = trigger_data.effect_parameters.get("seeker_count", [3, 5])
	var actual_count = randi_range(seeker_count[0], seeker_count[1])

	#print("🔶 Spawning %d amber seekers at %s" % [actual_count, death_position])

	for i in range(actual_count):
		_create_amber_seeker(death_position, trigger_data, i, actual_count, source_bottle)

func _create_amber_seeker(spawn_position: Vector2, trigger_data: EnhancedTriggerData, index: int, total_count: int, source_bottle: ImprovedBaseSauceBottle):
	"""Create amber seeker projectile using existing projectile system"""
	# Load projectile scene
	var seeker_scene = load("res://Scenes/sauce_projectile.tscn")
	var seeker = seeker_scene.instantiate()

	# Get seeker parameters from trigger data
	var seeker_range = trigger_data.effect_parameters.get("seeker_range", 200.0)
	var fossilize_chance = trigger_data.effect_parameters.get("seeker_fossilize_chance", 0.6)

	# Create amber seeker sauce resource
	var seeker_sauce = BaseSauceResource.new()
	seeker_sauce.sauce_name = "Amber Seeker"
	seeker_sauce.damage = 0  # No direct damage
	seeker_sauce.range = seeker_range
	seeker_sauce.effect_chance = fossilize_chance
	seeker_sauce.special_effect_type = BaseSauceResource.SpecialEffectType.FOSSILIZE
	seeker_sauce.sauce_color = Color(1.0, 0.8, 0.3, 0.8)  # Amber color

	# Calculate direction (spread pattern)
	var angle = (TAU / total_count) * index
	var direction = Vector2.RIGHT.rotated(angle)

	# Launch seeker using existing projectile system with source bottle
	seeker.launch(spawn_position, direction, seeker_sauce, 1, source_bottle.bottle_id, source_bottle)
	seeker.scale = Vector2(0.7, 0.7)  # Smaller than normal projectiles

	# Add to scene
	Engine.get_main_loop().current_scene.add_child(seeker)

	#print("🔶 Created amber seeker %d/%d" % [index + 1, total_count])
