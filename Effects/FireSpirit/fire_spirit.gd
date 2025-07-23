# Effects/FireSpirit/fire_spirit.gd
extends Area2D

# Spirit properties
var target_enemy: Node2D
var source_bottle: Node
var move_speed: float = 200.0
var burn_stacks_to_apply: int = 2
var spirit_damage: float = 7.0  # NEW: Store the damage amount
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

func setup_spirit(target: Node2D, bottle: Node, speed: float, burn_stacks: int, damage: float = 7.0):
	"""Initialize the fire spirit with its target and properties"""
	print("🔥 Fire Spirit setup_spirit() called")
	print("  Target: %s" % target)
	print("  Bottle: %s" % bottle)
	print("  Speed: %s" % speed)
	print("  Burn stacks: %s" % burn_stacks)
	print("  Damage: %s" % damage)  # NEW: Log damage parameter

	target_enemy = target
	source_bottle = bottle
	move_speed = speed
	burn_stacks_to_apply = burn_stacks
	spirit_damage = damage  # NEW: Store damage amount

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

	# Apply immediate damage using the parameter instead of hardcoded value
	if target_enemy.has_method("take_damage_from_source") and source_bottle:
		var bottle_id = source_bottle.bottle_id if source_bottle.has_method("bottle_id") else "fire_spirit"
		target_enemy.take_damage_from_source(spirit_damage, bottle_id)  # NEW: Use spirit_damage parameter
		print("🔥 Fire Spirit dealt %.1f immediate damage to enemy" % spirit_damage)
	elif target_enemy.has_method("take_damage"):
		target_enemy.take_damage(spirit_damage)  # NEW: Use spirit_damage parameter
		print("🔥 Fire Spirit dealt %.1f immediate damage to enemy (fallback)" % spirit_damage)

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

			# Create burn callbacks for stacking system - make them more robust
			var immediate_effect = func():
				if is_instance_valid(target_enemy):
					var current_stacks = target_enemy.get_total_stack_count("burn")
					print("🔥 Fire Spirit burn: %d total stacks on enemy" % current_stacks)

			# Make tick effect more robust by not relying on external references
			var tick_effect = func():
				# Check if target is still valid before doing anything
				if not is_instance_valid(target_enemy):
					return

				var total_stacks = target_enemy.get_total_stack_count("burn")
				if total_stacks <= 0:
					return

				var damage = 5.0 * total_stacks  # 5 damage per stack per tick

				# Apply damage using the most basic method possible
				if target_enemy.has_method("take_damage_from_source"):
					target_enemy.take_damage_from_source(damage, bottle_id)
				elif target_enemy.has_method("take_damage"):
					target_enemy.take_damage(damage)

			# Apply burn stack with simple, robust callbacks
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

	# Position on enemy and fade out
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_callback(_self_destruct)

func _find_new_target_or_die():
	"""Try to find a new target if the current one died"""
	print("🔥 Fire Spirit target died, looking for new target...")

	# Use a simple approach that works - get all enemy nodes directly
	var all_nodes = Engine.get_main_loop().current_scene.get_children()
	var enemies = []

	# Recursively find all enemy nodes
	_find_enemies_recursive(all_nodes, enemies)

	var closest_enemy: Node2D = null
	var closest_distance: float = 200.0  # Reduced range for retargeting

	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_enemy = enemy
				closest_distance = distance

	if closest_enemy:
		print("🔥 Fire Spirit found new target!")
		target_enemy = closest_enemy
		var direction = (target_enemy.global_position - global_position).normalized()
		velocity = direction * move_speed
	else:
		print("🔥 Fire Spirit no targets found, self-destructing")
		_self_destruct()

func _find_enemies_recursive(nodes: Array, enemies: Array):
	"""Recursively find all enemy nodes"""
	for node in nodes:
		if node.is_in_group("enemies"):
			enemies.append(node)
		if node.get_child_count() > 0:
			_find_enemies_recursive(node.get_children(), enemies)

func _self_destruct():
	"""Destroy the fire spirit"""
	print("🔥 Fire Spirit self-destructing")
	queue_free()
