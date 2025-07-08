class_name StandardBehavior
extends ProjectileBehavior

func handle_hit(projectile: Area2D, enemy: Node2D) -> bool:
	if enemy.has_method("take_damage_from_source"):
		var damage = projectile.get_scaled_damage()
		var source_id = projectile.source_bottle_id if projectile.source_bottle_id != "" else "unknown"
		enemy.take_damage_from_source(damage, source_id)
	elif enemy.has_method("take_damage"):
		enemy.take_damage(projectile.get_scaled_damage())
	return true  # Destroy projectile after hit
