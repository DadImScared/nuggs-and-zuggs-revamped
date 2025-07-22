# Singletons/PlayerStats.gd - Adding buff system to your existing PlayerStats

extends Node

# ===================================================================
# EXISTING PLAYER STATS (exactly as you have them)
# ===================================================================

signal leveled_up(new_level: int)
signal xp_changed(xp: int, xp_to_next: int)

var xp = 0
var level = 1
var xp_to_next = 100
var speed = 50  # Your existing speed variable
var damage = 3
var base_projectile_count = 1
var extra_projectile_chance = 15
var projectile_count: int = 1
var crit_chance: float = 0.0
var dot_damage: float = 0.0
var dot_duration: float = 3.0
var projectile_speed: float = 500.0
var piercing_count: int = 0
var lifesteal_percent: float = 0.0
var total_infections_this_run = 0

# ===================================================================
# NEW BUFF SYSTEM VARIABLES
# ===================================================================

# Base values for buff calculations
var base_speed: float = 50.0  # Store original speed
var base_damage: float = 1.0  # Store original damage

# Buff storage
var active_buffs: Array[Dictionary] = []
var active_shields: Array[Dictionary] = []

# Buff types
enum BuffType {
	MOVEMENT_SPEED, DAMAGE, FIRE_RATE, RANGE, CRIT_CHANCE,
	EFFECT_CHANCE, PROJECTILES, PIERCE, XP_MULTIPLIER,
	HEALTH_REGEN, SHIELD, DAMAGE_REDUCTION
}

enum StackingMode {
	ADDITIVE, MULTIPLICATIVE, HIGHEST, SEPARATE
}

# New signals for buff system
signal buffs_changed
signal shield_changed

# ===================================================================
# EXISTING METHODS (unchanged except gain_xp enhancement)
# ===================================================================

func gain_xp(amount: int):
	# Apply XP multiplier from buffs
	var multiplier = get_total_buff_value(BuffType.XP_MULTIPLIER)
	var final_amount = int(amount * multiplier)

	xp += final_amount
	emit_signal("xp_changed", xp, xp_to_next)

	if multiplier > 1.0:
		print("💎 XP bonus: %d → %d (%.1fx)" % [amount, final_amount, multiplier])

	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		emit_signal("leveled_up", level)
		_xp_curve()
		emit_signal("xp_changed", xp, xp_to_next)

func _xp_curve():
	xp_to_next = int(xp_to_next * 1.25)

# ===================================================================
# NEW BUFF SYSTEM
# ===================================================================

func _ready():
	# Store base values
	base_speed = speed
	base_damage = damage

func _process(delta: float):
	if active_buffs.size() > 0:
		_update_buffs(delta)

func _update_buffs(delta: float):
	var buffs_changed_flag = false

	# Update and remove expired buffs
	for i in range(active_buffs.size() - 1, -1, -1):
		var buff = active_buffs[i]
		buff.remaining_time -= delta

		if buff.remaining_time <= 0:
			print("⏰ Buff expired: %s from %s" % [_get_buff_type_name(buff.type), buff.source])
			active_buffs.remove_at(i)
			buffs_changed_flag = true

	# Update and remove depleted shields
	for i in range(active_shields.size() - 1, -1, -1):
		var shield = active_shields[i]
		if shield.amount <= 0:
			print("🛡️ Shield depleted: %s" % shield.source)
			active_shields.remove_at(i)
			buffs_changed_flag = true

	# Update PlayerStats variables if buffs changed
	if buffs_changed_flag:
		_update_player_stats()
		buffs_changed.emit()

func add_buff(type: BuffType, value: float, duration: float, source: String = "", is_percentage: bool = true, stacking_mode: StackingMode = StackingMode.ADDITIVE, max_stacks: int = -1) -> bool:
	"""Add a buff - returns true if successful"""

	# Check stack limits
	if max_stacks > 0:
		var current_stacks = get_buff_count_from_source(type, source)
		if current_stacks >= max_stacks:
			print("🚫 %s at max stacks (%d)" % [source, max_stacks])
			return false

	# Create buff dictionary
	var new_buff = {
		"type": type,
		"value": value,
		"remaining_time": duration,
		"source": source,
		"is_percentage": is_percentage,
		"stacking_mode": stacking_mode,
		"id": "%s_%d" % [source, Time.get_ticks_msec()]
	}

	active_buffs.append(new_buff)
	print("⚡ Added buff: %s +%s for %.1fs from %s" % [
		_get_buff_type_name(type),
		_format_value(value, is_percentage),
		duration,
		source
	])

	_update_player_stats()
	buffs_changed.emit()
	return true

func add_shield(amount: float, source: String = "", shield_type: String = "default") -> void:
	"""Add a shield that absorbs damage"""
	var new_shield = {
		"amount": amount,
		"max_amount": amount,
		"source": source,
		"type": shield_type,
		"id": "%s_%d" % [source, Time.get_ticks_msec()]
	}

	active_shields.append(new_shield)
	print("🛡️ Added shield: %.0f %s from %s" % [amount, shield_type, source])
	shield_changed.emit()

# ===================================================================
# CONVENIENCE METHODS
# ===================================================================

func add_movement_speed_buff(amount: float, duration: float, source: String = "", max_stacks: int = -1) -> bool:
	return add_buff(BuffType.MOVEMENT_SPEED, amount, duration, source, true, StackingMode.ADDITIVE, max_stacks)

func add_damage_buff(amount: float, duration: float, source: String = "") -> bool:
	return add_buff(BuffType.DAMAGE, amount, duration, source, true, StackingMode.MULTIPLICATIVE)

func add_fire_rate_buff(amount: float, duration: float, source: String = "") -> bool:
	return add_buff(BuffType.FIRE_RATE, amount, duration, source, true, StackingMode.MULTIPLICATIVE)

func add_crit_chance_buff(amount: float, duration: float, source: String = "") -> bool:
	return add_buff(BuffType.CRIT_CHANCE, amount, duration, source, false, StackingMode.ADDITIVE)

func add_xp_multiplier(amount: float, duration: float, source: String = "") -> bool:
	return add_buff(BuffType.XP_MULTIPLIER, amount, duration, source, true, StackingMode.MULTIPLICATIVE)

func add_projectile_buff(count: int, duration: float, source: String = "") -> bool:
	return add_buff(BuffType.PROJECTILES, float(count), duration, source, false, StackingMode.SEPARATE)

# ===================================================================
# DYNAMIC CALCULATION
# ===================================================================

func get_total_buff_value(type: BuffType) -> float:
	"""Dynamically calculate total value for a buff type"""

	# Find all buffs of this type
	var relevant_buffs = []
	for buff in active_buffs:
		if buff.type == type:
			relevant_buffs.append(buff)

	# No buffs = return base value
	if relevant_buffs.is_empty():
		return 0.0 if _is_additive_base_type(type) else 1.0

	# Use stacking mode from first buff
	var stacking_mode = relevant_buffs[0].stacking_mode

	# Calculate based on stacking mode
	match stacking_mode:
		StackingMode.ADDITIVE:
			var total = 0.0
			for buff in relevant_buffs:
				total += buff.value
			return total

		StackingMode.MULTIPLICATIVE:
			var total = 1.0
			for buff in relevant_buffs:
				if buff.is_percentage:
					total *= (1.0 + buff.value)
				else:
					total *= (1.0 + buff.value / 100.0)
			return total

		StackingMode.HIGHEST:
			var highest = relevant_buffs[0].value
			for buff in relevant_buffs:
				if buff.value > highest:
					highest = buff.value
			return highest

		StackingMode.SEPARATE:
			return float(relevant_buffs.size())

	return 0.0

# ===================================================================
# PLAYER STAT UPDATES
# ===================================================================

func _update_player_stats():
	"""Update PlayerStats variables based on active buffs"""

	# Update speed (your existing variable)
	var speed_bonus = get_total_buff_value(BuffType.MOVEMENT_SPEED)
	speed = base_speed * (1.0 + speed_bonus)

	# Update damage (your existing variable)
	var damage_multiplier = get_total_buff_value(BuffType.DAMAGE)
	damage = base_damage * damage_multiplier

	# Update crit chance (your existing variable)
	var crit_bonus = get_total_buff_value(BuffType.CRIT_CHANCE)
	crit_chance = crit_bonus  # Flat bonus to existing crit

	# Update projectile count (your existing variable)
	var extra_projectiles = int(get_total_buff_value(BuffType.PROJECTILES))
	projectile_count = base_projectile_count + extra_projectiles

# ===================================================================
# QUERY METHODS
# ===================================================================

func get_buff_count_from_source(type: BuffType, source: String) -> int:
	"""Get number of buffs of a type from a specific source"""
	var count = 0
	for buff in active_buffs:
		if buff.type == type and buff.source == source:
			count += 1
	return count

func has_buff_type(type: BuffType) -> bool:
	"""Check if any buffs of this type are active"""
	for buff in active_buffs:
		if buff.type == type:
			return true
	return false

func get_total_shield_amount() -> float:
	"""Get total shield protection available"""
	var total = 0.0
	for shield in active_shields:
		total += shield.amount
	return total

# ===================================================================
# DAMAGE ABSORPTION
# ===================================================================

func absorb_damage(incoming_damage: float) -> float:
	"""Process incoming damage through shields and damage reduction"""
	var remaining_damage = incoming_damage

	# Apply damage reduction buffs first
	var damage_reduction = get_total_buff_value(BuffType.DAMAGE_REDUCTION)
	remaining_damage *= (1.0 - damage_reduction)

	# Apply shields in order
	for shield in active_shields:
		if shield.amount > 0 and remaining_damage > 0:
			var absorbed = min(remaining_damage, shield.amount)
			shield.amount -= absorbed
			remaining_damage -= absorbed

			if absorbed > 0:
				print("🛡️ Shield absorbed %.0f damage" % absorbed)

	return remaining_damage

# ===================================================================
# GETTERS FOR OTHER SYSTEMS
# ===================================================================

func get_current_speed() -> float:
	return speed  # Returns your buffed speed

func get_current_damage() -> float:
	return damage  # Returns your buffed damage

func get_movement_speed_multiplier() -> float:
	return speed / base_speed

func get_damage_multiplier() -> float:
	return damage / base_damage

func get_xp_multiplier() -> float:
	return get_total_buff_value(BuffType.XP_MULTIPLIER)

# ===================================================================
# HELPER METHODS
# ===================================================================

func _is_additive_base_type(type: BuffType) -> bool:
	"""Types that start at 0 vs 1.0"""
	return type in [
		BuffType.MOVEMENT_SPEED, BuffType.CRIT_CHANCE,
		BuffType.HEALTH_REGEN, BuffType.DAMAGE_REDUCTION
	]

func _get_buff_type_name(type: BuffType) -> String:
	return BuffType.keys()[type].replace("_", " ").capitalize()

func _format_value(value: float, is_percentage: bool) -> String:
	if is_percentage:
		return "%.1f%%" % (value * 100)
	else:
		return "%.1f" % value

# ===================================================================
# DEBUG METHODS
# ===================================================================

func debug_print_buffs():
	if active_buffs.size() == 0 and active_shields.size() == 0:
		print("No active buffs or shields")
		return

	print("=== ACTIVE BUFFS ===")
	for buff in active_buffs:
		print("  %s: %s for %.1fs from %s" % [
			_get_buff_type_name(buff.type),
			_format_value(buff.value, buff.is_percentage),
			buff.remaining_time,
			buff.source
		])

	print("=== CURRENT STATS ===")
	print("  Speed: %.1f (base: %.1f)" % [speed, base_speed])
	print("  Damage: %.1f (base: %.1f)" % [damage, base_damage])
	print("  Crit: %.1f%%" % (crit_chance * 100))
	print("  Projectiles: %d" % projectile_count)
	print("===================")
