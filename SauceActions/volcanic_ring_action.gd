# Resources/SauceActions/VolcanicRingAction.gd
class_name VolcanicRingAction
extends BaseSauceAction

func _init():
	action_name = "volcanic_ring"
	action_description = "Creates expanding volcanic rings that damage enemies"

func apply_action(projectile: Area2D, enemy: Node2D, source_bottle: ImprovedBaseSauceBottle) -> void:
	# Get base parameters from bottle (everything we need is in source_bottle!)
	var ring_damage = source_bottle.effective_damage * 0.6
	var ring_position = enemy.global_position
	var ring_duration = source_bottle.sauce_data.effect_duration
	var max_radius = 120.0 + (source_bottle.effective_effect_intensity * 30.0)

	# Get talent modifications
	var talent_mods = get_talent_modifications(source_bottle)

	# Create ONE ring and modify it based on talents
	var ring = preload("res://Effects/MiniVolcanoRing/volcanic_ring.tscn").instantiate()
	ring.global_position = ring_position
	ring.setup_ring(ring_damage, max_radius, ring_duration, source_bottle.bottle_id)
	Engine.get_main_loop().current_scene.add_child(ring)

	# Apply talent modifications to the SAME ring
	for mod in talent_mods:
		_apply_talent_modification_to_ring(ring, mod, ring_damage, max_radius, ring_duration, source_bottle)

	log_action_applied(enemy, talent_mods)

func _apply_talent_modification_to_ring(ring: Node2D, talent: SpecialEffectResource, damage: float, radius: float, duration: float, source_bottle: ImprovedBaseSauceBottle):
	"""Apply talent modifications to an existing ring"""
	match talent.effect_name:
		"volcanic_ring_collapsing":
			_make_ring_collapse(ring, talent)

		"volcanic_ring_amplified":
			_make_ring_amplified(ring, talent)

		"volcanic_ring_rapid":
			_make_ring_rapid(ring, talent)

		"volcanic_ring_storm":
			_create_additional_storm_rings(ring, talent, damage, radius, duration)

		"volcanic_ring_molten_pools":
			_make_ring_create_molten_pools(ring, talent, source_bottle)

func _make_ring_create_molten_pools(ring: Node2D, talent: SpecialEffectResource, source_bottle: ImprovedBaseSauceBottle):
	"""Make the ring create molten pools when it finishes"""
	# Connect to the ring's completion signal or use timer
	_schedule_molten_pool_creation(ring, talent, source_bottle)

func _schedule_molten_pool_creation(ring: Node2D, talent: SpecialEffectResource, source_bottle: ImprovedBaseSauceBottle):
	"""Schedule molten pool creation when ring starts expanding"""
	# Create pool immediately (0 delay) or after ring reaches max size
	var pool_delay = 0.1  # Very small delay to let ring initialize

	# Create timer to spawn molten pool
	var timer = Timer.new()
	timer.wait_time = pool_delay
	timer.one_shot = true
	timer.timeout.connect(_create_molten_pool_at_ring.bind(ring, talent, source_bottle))
	ring.add_child(timer)
	timer.start()

	#print("🔥 Molten pool scheduled for %.1f seconds at ring position" % pool_delay)

func _create_molten_pool_at_ring(ring: Node2D, talent: SpecialEffectResource, source_bottle: ImprovedBaseSauceBottle):
	"""Create the actual molten pool at the ring's position"""
	if not is_instance_valid(ring):
		return

	var pool_damage = source_bottle.effective_damage * talent.get_parameter("damage_multiplier", 0.3)
	var pool_radius = talent.get_parameter("pool_radius", 45.0)
	var pool_duration = talent.get_parameter("pool_duration", 4.0)

	# Create molten pool scene
	var pool = preload("res://Effects/MoltenPool/molten_pool.tscn").instantiate()
	pool.global_position = ring.global_position
	pool.setup_pool(pool_damage, pool_radius, pool_duration, source_bottle.bottle_id)

	# Add to scene
	Engine.get_main_loop().current_scene.add_child(pool)

	#print("🔥 Molten pool created at %s with %.1f DPS for %.1f seconds" % [pool.global_position, pool_damage, pool_duration])

func _make_ring_collapse(ring: Node2D, talent: SpecialEffectResource):
	"""Make the ONE ring collapse inward after expanding"""
	# Change color for collapsing
	ring.modulate = Color(1.0, 0.7, 0.3, 0.8)

	# Reduce the max radius so it doesn't expand as far before collapsing
	ring.max_radius = ring.max_radius * 0.7  # Only expand to 70% of normal
	ring.expansion_speed = ring.max_radius / ring.duration  # Recalculate speed

	# Start a monitoring coroutine that checks elapsed time instead of using timers
	_monitor_ring_for_collapse(ring)

func _monitor_ring_for_collapse(ring: Node2D):
	"""Monitor the ring's elapsed time to trigger collapse"""
	var collapse_start_time = ring.duration * 0.5

	# Wait until it's time to collapse (check every frame)
	while is_instance_valid(ring) and ring.elapsed_time < collapse_start_time:
		await Engine.get_main_loop().process_frame

	# Start the collapse
	if is_instance_valid(ring) and ring.ring_visual:
		ring.modulate = Color(1.2, 0.5, 0.2, 1.0)  # More intense color during collapse

		# STOP the ring's normal processing so it doesn't override our animation
		ring.set_process(false)

		var collapse_duration = ring.duration * 0.5  # Use remaining 50% to collapse

		# Create a tween to shrink the visual scale back to near 0
		var collapse_tween = ring.create_tween()
		collapse_tween.tween_property(ring.ring_visual, "scale", Vector2(0.1, 0.1), collapse_duration)
		collapse_tween.parallel().tween_property(ring.ring_visual, "modulate:a", 0.2, collapse_duration)

		# When collapse finishes, destroy the ring
		collapse_tween.tween_callback(func(): ring.queue_free() if is_instance_valid(ring) else null)

func _make_ring_amplified(ring: Node2D, talent: SpecialEffectResource):
	"""Make the ring larger and more damaging"""
	var damage_boost = talent.get_parameter("damage_boost", 1.5)
	var radius_boost = talent.get_parameter("radius_boost", 1.5)

	ring.ring_damage *= damage_boost
	ring.max_radius *= radius_boost
	ring.expansion_speed = ring.max_radius / ring.duration  # Recalculate speed
	ring.modulate = Color(1.2, 0.8, 0.2, 1.0)  # Brighter color
	ring.scale = Vector2(1.2, 1.2)  # Visually larger

func _make_ring_rapid(ring: Node2D, talent: SpecialEffectResource):
	"""Make the ring expand faster"""
	var speed_multiplier = talent.get_parameter("speed_multiplier", 2.0)
	var duration_multiplier = talent.get_parameter("duration_multiplier", 0.6)

	ring.expansion_speed *= speed_multiplier
	ring.duration *= duration_multiplier
	ring.modulate = Color(1.0, 0.9, 0.5, 0.9)  # Faster, more yellow

func _create_additional_storm_rings(ring: Node2D, talent: SpecialEffectResource, damage: float, radius: float, duration: float):
	"""Create additional rings for storm effect (this is the only case where we make more rings)"""
	var ring_count = talent.get_parameter("ring_count", 3)
	var spread_radius = talent.get_parameter("spread_radius", 150.0)
	var damage_multiplier = talent.get_parameter("damage_multiplier", 0.7)

	# Make the original ring different for storm
	ring.modulate = Color(0.8, 0.6, 0.9, 0.7)

	# Create additional storm rings
	for i in range(ring_count - 1):  # -1 because we already have the original
		var angle = randf() * TAU
		var distance = randf() * spread_radius
		var storm_position = ring.global_position + Vector2.from_angle(angle) * distance

		var storm_ring = preload("res://Effects/MiniVolcanoRing/volcanic_ring.tscn").instantiate()
		storm_ring.global_position = storm_position
		storm_ring.setup_ring(damage * damage_multiplier, radius * 0.8, duration, ring.source_bottle_id)
		storm_ring.modulate = Color(0.8, 0.6, 0.9, 0.7)
		storm_ring.scale = Vector2(0.8, 0.8)

		await Engine.get_main_loop().current_scene.get_tree().create_timer(i * 0.1).timeout
		Engine.get_main_loop().current_scene.add_child(storm_ring)
