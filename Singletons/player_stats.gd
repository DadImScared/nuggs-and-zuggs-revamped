extends Node


signal leveled_up(new_level: int)
signal xp_changed(xp: int, xp_to_next: int)

var xp = 0
var level = 1
var xp_to_next = 50

var damage = 1
var base_projectile_count = 1
var extra_projectile_chance = 15
var projectile_count: int = 1
var crit_chance: float = 0.0
var dot_damage: float = 0.0
var dot_duration: float = 3.0
var projectile_speed: float = 500.0
var piercing_count: int = 0
var lifesteal_percent: float = 0.0

func gain_xp(amount: int):
	xp += amount
	emit_signal("xp_changed", xp, xp_to_next)
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		emit_signal("leveled_up", level)
		_xp_curve()
		emit_signal("xp_changed", xp, xp_to_next)  # emit again after leveling

func _xp_curve():
	xp_to_next = int(xp_to_next * 1.25)
