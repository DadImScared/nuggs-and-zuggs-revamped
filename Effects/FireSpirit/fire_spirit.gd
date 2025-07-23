# Effects/FireSpirit/fire_spirit.gd
extends Area2D

# Spirit properties
var target_enemy: Node2D
var source_bottle: Node
var move_speed: float = 200.0
var burn_stacks_to_apply: int = 2
var lifetime: float = 5.0

# Components - make sure these match your scene node names
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer

# Internal state
var velocity: Vector2
var has_hit_target: bool = false

func _ready():
	print("🔥 Fire Spirit _ready() called")

	# Setup collision
	collision_layer = 0
	collision_mask = 0

	# Setup lifetime timer
	if lifetime_timer:
		lifetime_timer.wait_time = lifetime
		lifetime_timer.one_shot = true
		lifetime_timer.timeout.connect(_self_destruct)
		lifetime_timer.start()

	# Debug the animated sprite setup
	print("🔥 Animated sprite check:")
	print("  animated_sprite exists: %s" % (animated_sprite != null))
	if animated_sprite:
		print("  sprite_frames exists: %s" % (animated_sprite.sprite_frames != null))
		print("  sprite_frames animations: %s" % (animated_sprite.sprite_frames.get_animation_names() if animated_sprite.sprite_frames else "none"))

	# Try to start animation
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("burn_loop"):
			animated_sprite.play("burn_loop")
			print("🔥 Playing burn_loop animation")
		else:
			print("⚠️ No burn_loop animation found!")
			_create_fallback_visual()
		animated_sprite.scale = Vector2(0.8, 0.8)  # Bigger for visibility
		animated_sprite.modulate = Color.ORANGE  # Bright orange for testing
	else:
		print("⚠️ No animated sprite or sprite frames - creating fallback")
		_create_fallback_visual()

	print("🔥 Fire Spirit setup complete!")

func _create_fallback_visual():
	"""Create a simple colored square if animation fails"""
	print("🔥 Creating fallback visual")
	var fallback = ColorRect.new()
	fallback.size = Vector2(32, 32)  # Even bigger fallback
	fallback.position = Vector2(-16, -16)
	fallback.color = Color.RED  # Bright red
	fallback.name = "FallbackVisual"
	add_child(fallback)

	# Make it pulse so we know it's working
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(fallback, "modulate:a", 0.5, 0.3)
	tween.tween_property(fallback, "modulate:a", 1.0, 0.3)

func setup_spirit(target: Node2D, bottle: Node, speed: float, burn_stacks: int):
	"""Initialize the fire spirit with its target and properties"""
	print("🔥 Fire Spirit setup_spirit() called")
	print("  Target: %s" % target)
	print("  Bottle: %s" % bottle)
	print("  Speed: %s" % speed)
	print("  Burn stacks: %s" % burn_stacks)

	target_enemy = target
	source_bottle = bottle
	move_speed = speed
	burn_stacks_to_apply = burn_stacks

	# Set initial direction toward target
	if target_enemy and is_instance_valid(target_enemy):
		var direction = (target_enemy.global_position - global_position).normalized()
		velocity = direction * move_speed
		print("🔥 Fire Spirit targeting enemy at %s" % target_enemy.global_position)

func _physics_process(delta):
	if has_hit_target:
		return

	# Debug position every second
	if Engine.get_process_frames() % 60 == 0:
		print("🔥 Fire Spirit position: %s, velocity: %s" % [global_position, velocity])

	# Update targeting - home in on target
	if target_enemy and is_instance_valid(target_enemy):
		var direction = (target_enemy.global_position - global_position).normalized()
		velocity = direction * move_speed

		# Rotate sprite to face movement direction and flip if needed
		if animated_sprite:
			animated_sprite.rotation = velocity.angle()

			# Flip sprite if flying to the left to keep it upright
			if velocity.x < 0:
				animated_sprite.flip_v = true  # Flip vertically when going left
			else:
				animated_sprite.flip_v = false  # Normal orientation when going right
	else:
		# Target died, find new target or self-destruct
		_find_new_target_or_die()
		return

	# Move toward target
	position += velocity * delta

	# Check if close enough to target
	if target_enemy and is_instance_valid(target_enemy):
		var distance_to_target = global_position.distance_to(target_enemy.global_position)
		if distance_to_target < 8.0:  # Much closer collision distance
			_hit_target()

func _hit_target():
	"""Apply effect to target"""
	if has_hit_target or not target_enemy or not is_instance_valid(target_enemy):
		return

	has_hit_target = true

	print("🔥 Fire Spirit hit target at distance: %s" % global_position.distance_to(target_enemy.global_position))

	# Create a visible hit effect
	_create_hit_effect()

	# Apply burn stacks to the target
	_apply_burn_stacks_to_target()

	# For now, also do some immediate damage
	if target_enemy.has_method("take_damage_from_source") and source_bottle:
		var bottle_id = source_bottle.bottle_id if source_bottle.has_method("bottle_id") else "fire_spirit"
		target_enemy.take_damage_from_source(7.0, bottle_id)
		print("🔥 Fire Spirit dealt 15 immediate damage to enemy")
	elif target_enemy.has_method("take_damage"):
		target_enemy.take_damage(15)
		print("🔥 Fire Spirit dealt 15 immediate damage to enemy (fallback)")

	# Attach to enemy briefly
	_attach_to_enemy()

func _apply_burn_stacks_to_target():
	"""Apply burn stacks to the target enemy"""
	if not target_enemy or not is_instance_valid(target_enemy):
		return

	print("🔥 Fire Spirit applying %d burn stacks to target" % burn_stacks_to_apply)

	# Apply the burn stacks
	for i in range(burn_stacks_to_apply):
		# Use the stacking burn system
		if target_enemy.has_method("apply_stacking_effect"):
			var bottle_id = source_bottle.bottle_id if source_bottle and source_bottle.has_method("bottle_id") else "fire_spirit"

			# Create burn callbacks for stacking system
			var immediate_effect = func():
				if is_instance_valid(target_enemy):
					var current_stacks = target_enemy.get_total_stack_count("burn")
					print("🔥 Fire Spirit burn: %d total stacks on enemy" % current_stacks)

			var tick_effect = func():
				if is_instance_valid(target_enemy):
					var total_stacks = target_enemy.get_total_stack_count("burn")
					var damage = 5.0 * total_stacks  # 5 damage per stack per tick
					if target_enemy.has_method("take_damage_from_source"):
						target_enemy.take_damage_from_source(damage, bottle_id)

			# Apply burn stack
			target_enemy.apply_stacking_effect(
				"burn",
				1.0,  # stack_value
				8,    # max_stacks
				bottle_id,
				3.0,  # duration
				{
					"immediate_effect": immediate_effect,
					"tick_effect": tick_effect,
					"tick_interval": 0.5
				}
			)
		else:
			print("⚠️ Target enemy doesn't support stacking effects")

	print("🔥 Fire Spirit applied burn stacks - enemy should be burning!")

func _create_hit_effect():
	"""Create visible explosion when spirit hits enemy"""
	print("🔥 Creating hit effect!")

	# Create explosion visual at hit location
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = Color.ORANGE  # Orange fire particles instead of yellow
		particle.position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))

		# Add to scene
		var scene = Engine.get_main_loop().current_scene
		scene.add_child(particle)

		# Animate explosion particles
		var tween = particle.create_tween()
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		tween.parallel().tween_property(particle, "position", particle.position + direction * 30, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)

func _attach_to_enemy():
	"""Attach fire spirit to enemy as visual effect"""
	if not target_enemy or not is_instance_valid(target_enemy):
		_self_destruct()
		return

	print("🔥 Fire Spirit attaching to enemy!")

	# Stop movement
	velocity = Vector2.ZERO

	# Try to reparent to enemy
	var old_global_pos = global_position
	var old_parent = get_parent()

	if old_parent and is_instance_valid(old_parent):
		old_parent.remove_child(self)

		if is_instance_valid(target_enemy):
			target_enemy.add_child(self)
			# Set local position relative to enemy center
			position = Vector2(0, -25)  # Float higher above enemy
			print("🔥 Fire Spirit successfully attached at local position: %s" % position)
		else:
			print("⚠️ Target enemy became invalid during attachment")
			queue_free()
			return
	else:
		print("⚠️ Fire Spirit parent became invalid")
		queue_free()
		return

	# Don't scale down - keep full size when attached
	# Just fade slightly to show it's attached
	if animated_sprite:
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate:a", 0.8, 0.3)

	var fallback = get_node_or_null("FallbackVisual")
	if fallback:
		var tween2 = create_tween()
		tween2.tween_property(fallback, "modulate:a", 0.8, 0.3)

	# Auto-remove after 3 seconds
	var attachment_timer = Timer.new()
	attachment_timer.wait_time = 3.0
	attachment_timer.one_shot = true
	attachment_timer.timeout.connect(queue_free)
	add_child(attachment_timer)
	attachment_timer.start()

	print("🔥 Fire Spirit attached! Will disappear in 3 seconds")

func _find_new_target_or_die():
	"""Try to find new target or self-destruct"""
	print("🔥 Fire Spirit: Target died, looking for new target...")

	# Find nearby enemies within reasonable range
	var nearby_enemies = _get_enemies_in_radius(global_position, 200.0)

	if nearby_enemies.size() > 0:
		# Find closest enemy
		var closest_enemy = null
		var closest_distance = 999999.0

		for enemy in nearby_enemies:
			if is_instance_valid(enemy):
				var distance = global_position.distance_to(enemy.global_position)
				if distance < closest_distance:
					closest_distance = distance
					closest_enemy = enemy

		if closest_enemy:
			target_enemy = closest_enemy
			print("🔥 Fire Spirit: Found new target at %s" % target_enemy.global_position)
			return

	print("🔥 Fire Spirit: No new targets found, self-destructing")
	_self_destruct()

func _get_enemies_in_radius(center: Vector2, radius: float) -> Array[Node2D]:
	"""Get all enemies within radius"""
	var enemies: Array[Node2D] = []
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy) and center.distance_to(enemy.global_position) <= radius:
			enemies.append(enemy)

	return enemies

func _self_destruct():
	"""Remove fire spirit"""
	print("🔥 Fire Spirit self-destructing")
	queue_free()
