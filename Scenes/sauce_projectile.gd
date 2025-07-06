extends Area2D

var velocity = Vector2(0, 0)
var sauce_damage
var lifetime
var max_range = 1200
var start_position: Vector2

var sauce_resource: BaseSauceResource
var has_pierced = []
var bounce_count: int = 0
var max_bounces: int = 3
var chain_targets: Array[Node] = []
var growth_multiplier: float = 1.0

@onready var sprite = $Sprite2D

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	
	if start_position.distance_to(global_position) > max_range:
		queue_free()

func launch(start_pos, direction, sauce: BaseSauceResource):
	global_position = start_pos
	start_position = start_pos
	velocity = direction.normalized() * sauce.projectile_speed
	rotation = direction.angle()
	sauce_damage = sauce.damage
	modulate = sauce.sauce_color
	sauce_resource = sauce
	#direction = Vector2.RIGHT.rotated(rotation).normalized()

func handle_enemy_hit(enemy: Node2D):
	# Check for pierce effect
	if sauce_resource and sauce_resource.special_effect_type == BaseSauceResource.SpecialEffectType.PIERCE:
		if enemy in has_pierced:
			return # Already hit this enemy
		has_pierced.append(enemy)
		
		# Don't destroy projectile, let it continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(get_scaled_damage())
		apply_special_effects(enemy)
		return
	
	# Normal behavior - destroy projectile and deal damage
	if enemy.has_method("take_damage"):
		enemy.take_damage(get_scaled_damage())
	
	# Apply special effects before destroying
	apply_special_effects(enemy)
	
	# Check if we should destroy the projectile
	if not sauce_resource or sauce_resource.special_effect_type != BaseSauceResource.SpecialEffectType.PIERCE:
		queue_free()

func apply_special_effects(enemy: Node2D):
	if not sauce_resource or sauce_resource.special_effect_type == BaseSauceResource.SpecialEffectType.NONE:
		return
	
	match sauce_resource.special_effect_type:
		BaseSauceResource.SpecialEffectType.BURN:
			apply_burn_effect(enemy)
		BaseSauceResource.SpecialEffectType.SLOW:
			apply_slow_effect(enemy)
		BaseSauceResource.SpecialEffectType.STICKY:
			apply_sticky_effect(enemy)
		BaseSauceResource.SpecialEffectType.CHAIN:
			apply_chain_effect(enemy)
		BaseSauceResource.SpecialEffectType.EXPLODE:
			apply_explosion_effect(enemy)
		BaseSauceResource.SpecialEffectType.POISON:
			apply_poison_effect(enemy)
		BaseSauceResource.SpecialEffectType.FREEZE:
			apply_freeze_effect(enemy)
		BaseSauceResource.SpecialEffectType.HEAL:
			apply_heal_effect()
		BaseSauceResource.SpecialEffectType.MULTIPLY:
			apply_multiply_effect(enemy)
		BaseSauceResource.SpecialEffectType.MAGNETIZE:
			apply_magnetize_effect(enemy)
		BaseSauceResource.SpecialEffectType.SHIELD_BREAK:
			apply_shield_break_effect(enemy)
		BaseSauceResource.SpecialEffectType.LEECH:
			apply_leech_effect(enemy)
		BaseSauceResource.SpecialEffectType.LIGHTNING:
			apply_lightning_effect(enemy)
		BaseSauceResource.SpecialEffectType.CHAOS:
			apply_chaos_effect(enemy)
		BaseSauceResource.SpecialEffectType.MARK:
			apply_mark_effect(enemy)

func apply_burn_effect(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("burn", sauce_resource.effect_duration, sauce_resource.effect_intensity)
	#create_burn_particles(enemy.global_position)

func apply_slow_effect(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("slow", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func apply_sticky_effect(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("sticky", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func apply_chain_effect(enemy: Node2D):
	var nearby_enemies = get_nearby_enemies(enemy, 200.0)
	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy not in chain_targets:
			chain_targets.append(nearby_enemy)
			if nearby_enemy.has_method("take_damage"):
				nearby_enemy.take_damage(get_scaled_damage() * 0.6) # Reduced chain damage
			#create_chain_visual(enemy.global_position, nearby_enemy.global_position)

func apply_explosion_effect(enemy: Node2D):
	var explosion_radius = 120.0 * sauce_resource.effect_intensity
	var nearby_enemies = get_nearby_enemies(enemy, explosion_radius)
	
	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy.has_method("take_damage"):
			var distance = enemy.global_position.distance_to(nearby_enemy.global_position)
			var damage_multiplier = 1.0 - (distance / explosion_radius)
			nearby_enemy.take_damage(get_scaled_damage() * damage_multiplier * 0.7)
	
	#create_explosion_visual(enemy.global_position, explosion_radius)

func apply_poison_effect(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("poison", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func apply_freeze_effect(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("freeze", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func apply_heal_effect():
	if PlayerStats.has_method("heal"):
		PlayerStats.heal(sauce_damage * 0.2) # Heal for 20% of damage dealt

func apply_multiply_effect(enemy: Node2D):
	var split_count = int(sauce_resource.effect_intensity)
	for i in range(split_count):
		var split_projectile = duplicate()
		get_tree().current_scene.add_child(split_projectile)
		
		var angle_offset = (i - split_count/2.0) * 45.0 # Spread projectiles
		var new_direction = Vector2.RIGHT.rotated(rotation + deg_to_rad(angle_offset))
		
		split_projectile.launch(
			global_position,
			new_direction,
			sauce_damage * 0.5, # Reduced damage for splits
			velocity.length() * 0.8, # Slightly slower
			modulate,
			sauce_resource
		)

func apply_magnetize_effect(enemy: Node2D):
	var nearby_enemies = get_nearby_enemies(enemy, 300.0)
	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy.has_method("apply_pull_force"):
			nearby_enemy.apply_pull_force(enemy.global_position, sauce_resource.effect_intensity * 500.0)

func apply_shield_break_effect(enemy: Node2D):
	if enemy.has_method("break_shield"):
		enemy.break_shield()

func apply_leech_effect(enemy: Node2D):
	if PlayerStats.has_method("heal"):
		PlayerStats.heal(get_scaled_damage() * 0.15) # Heal for 15% of damage dealt

func apply_lightning_effect(enemy: Node2D):
	var chain_distance = 250.0
	var chain_count = int(sauce_resource.effect_intensity)
	var current_target = enemy
	
	for i in range(chain_count):
		var next_enemies = get_nearby_enemies(current_target, chain_distance)
		if next_enemies.is_empty():
			break
			
		var next_target = next_enemies[0]
		if next_target.has_method("take_damage"):
			next_target.take_damage(get_scaled_damage() * 0.5)
		
		#create_lightning_visual(current_target.global_position, next_target.global_position)
		current_target = next_target

func apply_chaos_effect(enemy: Node2D):
	var chaos_effects = [
		BaseSauceResource.SpecialEffectType.BURN,
		BaseSauceResource.SpecialEffectType.SLOW,
		BaseSauceResource.SpecialEffectType.FREEZE,
		BaseSauceResource.SpecialEffectType.EXPLODE,
		BaseSauceResource.SpecialEffectType.CHAIN,
		BaseSauceResource.SpecialEffectType.POISON
	]
	
	var original_effect = sauce_resource.special_effect_type
	sauce_resource.special_effect_type = chaos_effects[randi() % chaos_effects.size()]
	apply_special_effects(enemy)
	sauce_resource.special_effect_type = original_effect

func apply_mark_effect(enemy: Node2D):
	if enemy.has_method("apply_mark"):
		enemy.apply_mark(sauce_resource.effect_duration, sauce_resource.effect_intensity)

# Helper functions
func get_nearby_enemies(center_enemy: Node2D, radius: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var bodies = get_tree().get_nodes_in_group("enemies")
	
	for body in bodies:
		if body != center_enemy and body.global_position.distance_to(center_enemy.global_position) <= radius:
			enemies.append(body)
	
	return enemies

func bounce_off_wall(wall: Node2D):
	# Simple bounce logic - reverse velocity components based on wall normal
	var collision_normal = (global_position - wall.global_position).normalized()
	velocity = velocity.bounce(collision_normal)
	rotation = velocity.angle()

func find_and_target_nearest_enemy():
	var nearest_enemy = null
	var nearest_distance = INF
	
	for body in get_tree().get_nodes_in_group("enemies"):
		var distance = global_position.distance_to(body.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = body
	
	if nearest_enemy:
		var direction = (nearest_enemy.global_position - global_position).normalized()
		velocity = direction * velocity.length()
		rotation = direction.angle()

func get_scaled_damage():
	var base_scale = 1.0 + (PlayerStats.level - 1)
	var damage_scale = base_scale * 0.1
	return sauce_damage + (sauce_damage * damage_scale)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		handle_enemy_hit(body)
