class_name StandardBehavior
extends ProjectileBehavior

func handle_hit(projectile: Area2D, enemy: Node2D) -> bool:
	if enemy.has_method("take_damage"):
		enemy.take_damage(projectile.get_scaled_damage())
	return true  # Destroy projectile after hit
