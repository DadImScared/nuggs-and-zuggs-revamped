
class_name PierceBehavior
extends ProjectileBehavior

func handle_hit(projectile: Area2D, enemy: Node2D) -> bool:
	if enemy in projectile.has_pierced:
		return false  # Already hit this enemy, keep going

	projectile.has_pierced.append(enemy)
	if enemy.has_method("take_damage"):
		enemy.take_damage(projectile.get_scaled_damage())
	return false  # Don't destroy, keep piercing through enemies
