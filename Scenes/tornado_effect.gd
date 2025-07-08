extends Area2D

var pull_force: float = 450.0
var damage_per_tick: float = 5.0
var tick_timer: float = 0.0
var tick_interval: float = 0.2

func setup(duration: float, intensity: float, damage: float):
	pull_force = 200.0 * intensity
	damage_per_tick = damage

	body_entered.connect(_on_enemy_entered)
	body_exited.connect(_on_enemy_exited)

var enemies_in_tornado: Array[Node2D] = []

func _on_enemy_entered(enemy: Node2D):
	if enemy.is_in_group("enemies"):
		enemies_in_tornado.append(enemy)

func _on_enemy_exited(enemy: Node2D):
	enemies_in_tornado.erase(enemy)

func _physics_process(delta: float):
	tick_timer += delta

	for enemy in enemies_in_tornado:
		if not is_instance_valid(enemy):
			enemies_in_tornado.erase(enemy)
			continue

		var direction = (enemy.global_position - global_position).normalized()
		var distance = global_position.distance_to(enemy.global_position)
		var pull_strength = pull_force * delta

		if enemy is CharacterBody2D:
			var pull_velocity = -direction * pull_strength
			if distance < 3.0:  # Too close to center - give them a small push out
				pull_velocity = direction * pull_strength * 0.5  # Push away from center
			else:
				pull_velocity = -direction * pull_strength  # Normal pull toward center
			# Just override the velocity, let the enemy handle move_and_slide() in its own process
			if enemy.has_method("apply_external_velocity"):
				enemy.apply_external_velocity(pull_velocity)

	if tick_timer >= tick_interval:
		tick_timer = 0.0
		for enemy in enemies_in_tornado:
			if is_instance_valid(enemy) and enemy.has_method("take_damage"):
				enemy.take_damage(damage_per_tick)
