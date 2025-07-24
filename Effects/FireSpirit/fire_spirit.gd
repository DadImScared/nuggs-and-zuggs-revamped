# Effects/FireSpirit/fire_spirit.gd
extends Area2D

# Spirit properties
var target_enemy: Node2D
var source_bottle: Node
var move_speed: float = 200.0
var burn_stacks_to_apply: int = 2
var spirit_damage: float = 7.0
var lifetime: float = 5.0

# NEW: Trail properties
var leaves_trail: bool = false
var trail_width: float = 60.0
var trail_duration: float = 5.0
var trail_tick_damage: float = 8.0
var trail_tick_interval: float = 0.3
var trail_color: Color = Color.ORANGE
var last_trail_position: Vector2
var trail_spacing: float = 20.0  # Create trail segment every 20 pixels

# Components
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer

# Internal state
var velocity: Vector2
var has_hit_target: bool = false

func _ready():
	#print("🔥 Fire Spirit _ready() called")

	# Setup collision
	collision_layer = 0
	collision_mask = 0

	# Setup lifetime timer
	if lifetime_timer:
		lifetime_timer.wait_time = lifetime
		lifetime_timer.one_shot = true
		lifetime_timer.timeout.connect(_self_destruct)
		lifetime_timer.start()

	# Setup animation
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("burn_loop"):
			animated_sprite.play("burn_loop")
		else:
			_create_fallback_visual()
		animated_sprite.scale = Vector2(0.8, 0.8)
		animated_sprite.modulate = Color.ORANGE
	else:
		_create_fallback_visual()

func _create_fallback_visual():
	"""Create simple visual if animation fails"""
	var fallback = ColorRect.new()
	fallback.size = Vector2(32, 32)
	fallback.position = Vector2(-16, -16)
	fallback.color = Color.RED
	fallback.name = "FallbackVisual"
	add_child(fallback)

	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(fallback, "modulate:a", 0.5, 0.3)
	tween.tween_property(fallback, "modulate:a", 1.0, 0.3)

func setup_spirit(target: Node2D, bottle: Node, speed: float, burn_stacks: int, damage: float = 7.0):
	"""Initialize the fire spirit"""
	target_enemy = target
	source_bottle = bottle
	move_speed = speed
	burn_stacks_to_apply = burn_stacks
	spirit_damage = damage
	last_trail_position = global_position  # Initialize trail tracking

	if target_enemy and is_instance_valid(target_enemy):
		var direction = (target_enemy.global_position - global_position).normalized()
		velocity = direction * move_speed

func setup_trail_behavior(width: float, duration: float, tick_damage: float, tick_interval: float, color: Color):
	"""Setup trail leaving behavior"""
	leaves_trail = true
	trail_width = width
	trail_duration = duration
	trail_tick_damage = tick_damage
	trail_tick_interval = tick_interval
	trail_color = color
	#print("🔥 Fire Spirit: Trail behavior enabled (%.0fpx wide, %.1fs duration)" % [width, duration])

func _physics_process(delta):
	if has_hit_target:
		return

	# Home in on target
	if target_enemy and is_instance_valid(target_enemy):
		var direction = (target_enemy.global_position - global_position).normalized()
		velocity = direction * move_speed

		if animated_sprite:
			animated_sprite.rotation = velocity.angle()
			animated_sprite.flip_v = velocity.x < 0
	else:
		_find_new_target_or_die()
		return

	# Move toward target
	position += velocity * delta

	# NEW: Create trail segments as we move
	if leaves_trail and global_position.distance_to(last_trail_position) >= trail_spacing:
		_create_trail_segment(global_position)
		last_trail_position = global_position

	# Check collision
	if target_enemy and is_instance_valid(target_enemy):
		var distance_to_target = global_position.distance_to(target_enemy.global_position)
		if distance_to_target < 8.0:
			_hit_target()

func _hit_target():
	"""Apply effects to target"""
	if has_hit_target or not target_enemy or not is_instance_valid(target_enemy):
		return

	has_hit_target = true
	#print("🔥 Fire Spirit hit target!")

	# Create hit effect
	_create_hit_effect()

	# Apply burn stacks using METHOD REFERENCES instead of lambdas
	_apply_burn_stacks_to_target()

	# Apply immediate damage
	if target_enemy.has_method("take_damage_from_source") and source_bottle:
		var bottle_id = source_bottle.bottle_id if source_bottle.has_method("bottle_id") else "fire_spirit"
		target_enemy.take_damage_from_source(spirit_damage, bottle_id)

	# Attach to enemy
	_attach_to_enemy()

func _apply_burn_stacks_to_target():
	"""Apply burn stacks using METHOD REFERENCES instead of lambdas"""
	if not target_enemy or not is_instance_valid(target_enemy):
		return

	var bottle_id = source_bottle.bottle_id if source_bottle and source_bottle.has_method("bottle_id") else "fire_spirit"

	for i in range(burn_stacks_to_apply):
		if target_enemy.has_method("apply_stacking_effect"):

			# Store METHOD REFERENCES to instance methods
			target_enemy.apply_stacking_effect(
				"burn",
				1.0,
				8,
				bottle_id,
				3.0,
				{
					# INSTANCE METHOD REFERENCES - these match the expected signature
					"immediate_effect": fire_spirit_immediate_effect,     # Reference to instance method
					"tick_effect": fire_spirit_tick_effect,               # Reference to instance method
					"visual_cleanup": fire_spirit_visual_cleanup,         # Reference to instance method
					"tick_interval": 0.5
				}
			)

	#print("🔥 Fire Spirit applied %d burn stacks using method references!" % burn_stacks_to_apply)

# INSTANCE METHODS that can be called via method references
func fire_spirit_immediate_effect():
	"""Immediate effect when fire spirit burn is applied"""
	if is_instance_valid(target_enemy):
		var current_stacks = target_enemy.get_total_stack_count("burn")
		#print("🔥 Fire Spirit burn: %d total stacks on enemy" % current_stacks)

func fire_spirit_tick_effect():
	"""Tick effect for fire spirit burns - called every 0.5 seconds"""
	if not is_instance_valid(target_enemy):
		return

	var total_stacks = target_enemy.get_total_stack_count("burn")
	if total_stacks <= 0:
		return

	# Fire spirit enhanced damage
	var damage = 7.0 * total_stacks
	var bottle_id = source_bottle.bottle_id if source_bottle and source_bottle.has_method("bottle_id") else "fire_spirit"
	target_enemy.take_damage_from_source(damage, bottle_id)

	# Create enhanced visuals
	_create_fire_spirit_tick_visual(target_enemy.global_position)

func fire_spirit_visual_cleanup():
	"""Clean up fire spirit burn visuals"""
	if is_instance_valid(target_enemy):
		var burn_overlay = target_enemy.get_node_or_null("BurnOverlay")
		if burn_overlay:
			burn_overlay.queue_free()
		print("🔥 Fire spirit burn visual effects removed")

func _create_fire_spirit_tick_visual(position: Vector2):
	"""Create fire spirit specific burn visuals"""
	# Enhanced visuals for fire spirit burns
	for i in range(3):  # More particles than normal burns
		var particle = ColorRect.new()
		particle.size = Vector2(10, 10)  # Bigger particles
		particle.color = Color(1.0, 0.4, 0.1, 0.8)  # Orange
		particle.position = position + Vector2(randf_range(-15, 15), randf_range(-15, 15))

		var scene = Engine.get_main_loop().current_scene
		scene.add_child(particle)

		var tween = particle.create_tween()
		tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-25, 25), -35), 1.0)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.tween_callback(particle.queue_free)

func _create_trail_segment(position: Vector2):
	"""Create a burning trail segment using reusable FireTrail scene"""
	#print("🔥 Creating trail segment at %s" % position)

	# Create reusable fire trail scene
	var fire_trail_scene = preload("res://Effects/FireTrail/fire_trail.tscn")
	var fire_trail = fire_trail_scene.instantiate()

	# Setup the trail segment
	fire_trail.global_position = position
	fire_trail.setup_trail(source_bottle, trail_width, trail_duration, trail_tick_damage, trail_tick_interval, trail_color)

	# Add to scene
	var scene = Engine.get_main_loop().current_scene
	scene.add_child(fire_trail)

func _create_hit_effect():
	"""Create explosion when spirit hits"""
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = Color.ORANGE
		particle.position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))

		var scene = Engine.get_main_loop().current_scene
		scene.add_child(particle)

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

	#print("🔥 Fire Spirit attaching to enemy!")

	# Fire spirit can die immediately - method references will still work
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_callback(_self_destruct)

func _find_new_target_or_die():
	"""Find new target or self-destruct"""
	var all_nodes = Engine.get_main_loop().current_scene.get_children()
	var enemies = []
	_find_enemies_recursive(all_nodes, enemies)

	var closest_enemy: Node2D = null
	var closest_distance: float = 200.0

	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_enemy = enemy
				closest_distance = distance

	if closest_enemy:
		target_enemy = closest_enemy
		var direction = (target_enemy.global_position - global_position).normalized()
		velocity = direction * move_speed
	else:
		_self_destruct()

func _find_enemies_recursive(nodes: Array, enemies: Array):
	"""Recursively find enemy nodes"""
	for node in nodes:
		if node.is_in_group("enemies"):
			enemies.append(node)
		if node.get_child_count() > 0:
			_find_enemies_recursive(node.get_children(), enemies)

func _self_destruct():
	"""Destroy the fire spirit"""
	#print("🔥 Fire Spirit self-destructing (method references will still work!)")
	queue_free()
