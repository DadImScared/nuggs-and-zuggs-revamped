# Effects/FireSpirit/fire_spirit.gd
extends Area2D

# Spirit properties
var target_enemy: Node2D
var source_bottle: Node
var move_speed: float = 200.0
var burn_stacks_to_apply: int = 2
var spirit_damage: float = 7.0
var lifetime: float = 5.0

# Enhanced burn parameters from trigger system
var enhanced_burn_params: Dictionary = {}

# Trail properties
var leaves_trail: bool = false
var trail_width: float = 60.0
var trail_duration: float = 5.0
var trail_tick_damage: float = 8.0
var trail_tick_interval: float = 0.3
var trail_color: Color = Color.ORANGE
var last_trail_position: Vector2
var trail_spacing: float = 20.0

# Components
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer

# Internal state
var velocity: Vector2
var has_hit_target: bool = false

func _ready():
	DebugControl.debug_status("🔥 Fire Spirit _ready() called")

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
	last_trail_position = global_position

	if target_enemy and is_instance_valid(target_enemy):
		var direction = (target_enemy.global_position - global_position).normalized()
		velocity = direction * move_speed

func setup_enhanced_burn_params(enhanced_params: Dictionary):
	"""Store enhanced burn parameters from the trigger system"""
	enhanced_burn_params = enhanced_params
	DebugControl.debug_status("🔥 Fire Spirit: Enhanced burn params stored (%.1f damage)" % enhanced_params.get("tick_damage", 5.0))

func setup_trail_behavior(width: float, duration: float, tick_damage: float, tick_interval: float, color: Color):
	"""Setup trail leaving behavior"""
	leaves_trail = true
	trail_width = width
	trail_duration = duration
	trail_tick_damage = tick_damage
	trail_tick_interval = tick_interval
	trail_color = color
	DebugControl.debug_status("🔥 Fire Spirit: Trail behavior enabled (%.0fpx wide, %.1fs duration)" % [width, duration])

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

	# Create trail segments as we move
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
	DebugControl.debug_status("🔥 Fire Spirit hit target!")

	# Create hit effect
	_create_hit_effect()

	# Apply burn with enhanced parameters if available
	Effects.burn.apply_from_talent(target_enemy, source_bottle, burn_stacks_to_apply, enhanced_burn_params)

	# Apply immediate damage
	if target_enemy.has_method("take_damage_from_source") and source_bottle:
		var bottle_id = source_bottle.bottle_id if source_bottle.has_method("bottle_id") else "fire_spirit"
		target_enemy.take_damage_from_source(spirit_damage, bottle_id)

	# Attach to enemy
	_attach_to_enemy()

func _create_hit_effect():
	"""Create visual effect when hitting target"""
	if not is_instance_valid(target_enemy):
		return

	# Create impact explosion
	var explosion = ColorRect.new()
	explosion.size = Vector2(40, 40)
	explosion.position = target_enemy.global_position + Vector2(-20, -20)
	explosion.color = Color(1.0, 0.5, 0.1, 0.8)

	var scene = Engine.get_main_loop().current_scene
	scene.add_child(explosion)

	# Animate explosion
	var tween = explosion.create_tween()
	tween.parallel().tween_property(explosion, "scale", Vector2(2.0, 2.0), 0.3)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)

func _attach_to_enemy():
	"""Attach spirit to enemy after hitting"""
	if not target_enemy or not is_instance_valid(target_enemy):
		return

	# Reparent to enemy for visual effect
	var original_parent = get_parent()
	if original_parent:
		original_parent.remove_child(self)

	target_enemy.add_child(self)
	position = Vector2.ZERO

	# Fade out over time
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	fade_tween.tween_callback(queue_free)

func _find_new_target_or_die():
	"""Find a new target or self-destruct"""
	_self_destruct()

func _self_destruct():
	"""Remove the fire spirit"""
	DebugControl.debug_status("🔥 Fire Spirit self-destructing")
	queue_free()

func _create_trail_segment(position: Vector2):
	"""Create a burning trail segment that also applies burn!"""
	DebugControl.debug_status("🔥 Creating trail segment at %s" % position)

	# Create trail effect with burn application
	var trail_visual = ColorRect.new()
	trail_visual.size = Vector2(trail_width, trail_width)
	trail_visual.position = position - Vector2(trail_width/2, trail_width/2)
	trail_visual.color = trail_color

	var scene = Engine.get_main_loop().current_scene
	scene.add_child(trail_visual)

	# TODO: Apply burn to any enemies in trail area using enhanced parameters
	# For enemies in trail area: Effects.burn.apply_from_talent(enemy, source_bottle, 1, enhanced_burn_params)

	# Fade out trail
	var tween = trail_visual.create_tween()
	tween.tween_property(trail_visual, "modulate:a", 0.0, trail_duration)
	tween.tween_callback(trail_visual.queue_free)
