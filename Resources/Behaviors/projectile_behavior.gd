# Base class for all projectile behaviors

class_name ProjectileBehavior
extends Resource

func handle_hit(projectile: Area2D, enemy: Node2D) -> bool:
	# Return true if projectile should be destroyed, false otherwise
	# Override this in subclasses
	return true
