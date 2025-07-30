# SauceActions/Cold/Triggers/ice_comet_barrage.gd
class_name IceCometBarrageTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "ice_comet_barrage"
	trigger_description = "60% chance on hit to call down ice comet barrage at enemy position"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	"""Execute ice comet barrage when enemy is hit"""

	# Get hit enemy data from trigger parameters
	var hit_enemy = trigger_data.effect_parameters.get("hit_enemy")
	var enemy_position = Vector2.ZERO

	if hit_enemy and is_instance_valid(hit_enemy):
		enemy_position = hit_enemy.global_position
	else:
		print("⚠️ Ice Comet Barrage: No valid enemy target")
		return

	# Get barrage parameters from trigger data
	var comet_damage = trigger_data.effect_parameters.get("damage", 25)
	var impact_radius = trigger_data.effect_parameters.get("radius", 80)
	var comet_count = trigger_data.effect_parameters.get("comet_count", 4)  # Default 4 comets

	# Call down the barrage at enemy position
	_create_comet_barrage(enemy_position, comet_damage, impact_radius, comet_count, source_bottle)

	print("☄️ Ice Comet Barrage: Called down %d comets at %s" % [comet_count, enemy_position])

	log_trigger_executed(source_bottle, trigger_data)

func _create_comet_barrage(target_position: Vector2, damage: float, radius: float, comet_count: int, source_bottle: ImprovedBaseSauceBottle):
	"""Create a barrage of ice comets at the target position"""

	# Get the main scene to add comets to
	var main_scene = Engine.get_main_loop().current_scene
	if not main_scene:
		print("⚠️ Ice Comet Barrage: No main scene found")
		return

	# Defer the barrage creation to avoid physics conflicts - NOW PASSES BOTTLE
	call_deferred("_create_barrage_deferred", main_scene, target_position, damage, radius, comet_count, source_bottle)

func _create_barrage_deferred(main_scene: Node, target_position: Vector2, damage: float, radius: float, comet_count: int, source_bottle: ImprovedBaseSauceBottle):
	"""Create comet barrage in a deferred call"""

	print("☄️ Creating barrage of %d comets at %s" % [comet_count, target_position])

	for i in range(comet_count):
		# Random positions above the target area
		var start_offset = Vector2(randf_range(-400, 400), randf_range(-600, -400))
		var start_pos = target_position + start_offset

		# Slight random spread around target for more natural barrage
		var target_offset = Vector2(randf_range(-60, 60), randf_range(-60, 60))
		var final_target = target_position + target_offset

		# Stagger the timing so comets don't all arrive at once
		var delay = i * 0.3  # 0.3 second intervals

		# Use the main scene's tree to create timer - NOW PASSES BOTTLE
		var timer = main_scene.get_tree().create_timer(delay)
		timer.timeout.connect(_create_single_comet.bind(main_scene, start_pos, final_target, damage, radius, source_bottle))

func _create_single_comet(main_scene: Node, start_pos: Vector2, target_pos: Vector2, damage: float, radius: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create a single ice comet"""

	# Create ice comet
	var ice_comet = IceComet.new()

	# Set up the comet with bottle reference - NOW PASSES BOTTLE
	ice_comet.setup_ice_comet(start_pos, target_pos, damage, radius, source_bottle.bottle_id, source_bottle)

	# Add to scene
	main_scene.add_child(ice_comet)

	print("☄️ Comet launched from %s to %s" % [start_pos, target_pos])
