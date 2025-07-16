# Effects/MoltenPool/molten_pool.gd
extends Area2D

var damage_per_second: float = 5.0
var pool_radius: float = 45.0
var duration: float = 4.0
var source_bottle_id: String = "unknown"
var tick_rate: float = 0.5  # Damage every 0.5 seconds

var elapsed_time: float = 0.0
var enemies_in_pool: Array[Node2D] = []
var damage_timer: Timer

@onready var pool_visual: Node2D = $PoolVisual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Set up collision layer/mask for enemies
	collision_layer = 0  # Don't collide with anything
	collision_mask = 2   # Detect enemies (assuming enemies are on layer 3, mask = 2^2 = 4)

	# Connect area signals
	body_entered.connect(_on_enemy_entered)
	body_exited.connect(_on_enemy_exited)
	area_entered.connect(_on_enemy_entered)
	area_exited.connect(_on_enemy_exited)

	# Setup damage timer
	damage_timer = Timer.new()
	damage_timer.wait_time = tick_rate
	damage_timer.timeout.connect(_damage_enemies_in_pool)
	damage_timer.autostart = true
	add_child(damage_timer)

	# Create visual circles
	if pool_visual:
		_create_pool_visuals()

	print("🔥 Molten pool ready with %.1f DPS, %.0f radius, %.1f duration" % [damage_per_second, pool_radius, duration])

func _create_pool_visuals():
	"""Create circular visuals using code-generated Polygon2D"""
	# Clear any existing visuals
	if not pool_visual:
		return
	if pool_visual:
		for child in pool_visual.get_children():
			child.queue_free()

	# Create outer glow (largest circle)
	var outer_circle = _create_circle_polygon(pool_radius, 32)
	outer_circle.color = Color(1.0, 0.2, 0.0, 0.6)  # Dark red, semi-transparent
	pool_visual.add_child(outer_circle)

	# Create middle pool
	var middle_circle = _create_circle_polygon(pool_radius * 0.7, 24)
	middle_circle.color = Color(1.0, 0.5, 0.0, 0.8)  # Orange, more opaque
	pool_visual.add_child(middle_circle)

	# Create core glow (smallest, brightest)
	var core_circle = _create_circle_polygon(pool_radius * 0.4, 16)
	core_circle.color = Color(1.0, 1.0, 0.0, 1.0)  # Bright yellow, fully opaque
	pool_visual.add_child(core_circle)

func _create_circle_polygon(radius: float, points: int) -> Polygon2D:
	"""Generate a circular polygon with specified radius and point count"""
	var polygon = Polygon2D.new()
	var polygon_points: PackedVector2Array = []

	# Generate circle points using trigonometry
	for i in range(points):
		var angle = (i * TAU) / points  # TAU = 2 * PI
		var point = Vector2(cos(angle), sin(angle)) * radius
		polygon_points.append(point)

	polygon.polygon = polygon_points
	return polygon

func setup_pool(dps: float, radius: float, pool_duration: float, bottle_id: String):
	"""Initialize the molten pool with specified parameters"""
	damage_per_second = dps
	pool_radius = radius
	duration = pool_duration
	source_bottle_id = bottle_id

	# Update collision shape size
	if collision_shape and collision_shape.shape:
		collision_shape.shape.radius = pool_radius

	# Recreate visuals with new size
	_create_pool_visuals()

func _process(delta):
	elapsed_time += delta

	# Fade out as duration expires
	var alpha = 1.0 - (elapsed_time / duration)
	modulate.a = max(alpha, 0.2)  # Keep at least 20% visible

	# Add subtle pulsing effect for visual appeal
	var pulse = 1.0 + sin(elapsed_time * 4.0) * 0.1
	pool_visual.scale = Vector2(pulse, pulse)

	# Destroy when duration expires
	if elapsed_time >= duration:
		queue_free()

func _on_enemy_entered(enemy: Node2D):
	"""Enemy entered the molten pool"""
	if enemy.is_in_group("enemies") and enemy not in enemies_in_pool:
		enemies_in_pool.append(enemy)
		print("🔥 Enemy entered molten pool: %s" % enemy.name)

func _on_enemy_exited(enemy: Node2D):
	"""Enemy left the molten pool"""
	if enemy in enemies_in_pool:
		enemies_in_pool.erase(enemy)
		print("🔥 Enemy left molten pool: %s" % enemy.name)

func _damage_enemies_in_pool():
	"""Deal damage to all enemies currently in the pool"""
	var tick_damage = damage_per_second * tick_rate

	for enemy in enemies_in_pool:
		if is_instance_valid(enemy):
			if enemy.has_method("take_damage_from_source"):
				enemy.take_damage_from_source(tick_damage, source_bottle_id)
			elif enemy.has_method("take_damage"):
				enemy.take_damage(tick_damage)
		else:
			enemies_in_pool.erase(enemy)

	if enemies_in_pool.size() > 0:
		print("🔥 Molten pool damaged %d enemies for %.1f each" % [enemies_in_pool.size(), tick_damage])
