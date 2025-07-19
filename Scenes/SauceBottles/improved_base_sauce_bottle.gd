# Scenes/SauceBottles/improved_base_sauce_bottle.gd
class_name ImprovedBaseSauceBottle
extends Area2D

signal leveled_up(bottle_id: String, new_level: int, sauce_name: String)

@export var sauce_data: BaseSauceResource
@onready var shoot_timer = $ShootingTimer
@onready var detection_area = $CollisionShape2D
@onready var bottle_sprites = $BottleSprites
@onready var bottle_base = $BottleSprites/BottleBase
@onready var the_tip = $BottleSprites/TheTip
@onready var shooting_point = $BottleSprites/TheTip/ShootingPoint
@onready var animation_player = $AnimationPlayer

var enemies_in_range = []
var current_target = null
var update_timer = 0.0
var update_interval = 0.1
const SAUCE = preload("res://Scenes/sauce_projectile.tscn")

# Animation timing variables
var is_shooting = false
var squeeze_duration = 0.1
var recovery_duration = 0.06

# Leveling system
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 25
var max_level: int = 10

var bottle_id: String = ""
var chosen_upgrades: Array[String] = []

# Talent system variables
var active_talents: Array[Talent] = []
var stat_modifier_history: Array[StatModifier] = []
var special_effects: Array[SpecialEffectResource] = []
var trigger_effects: Array[TriggerEffectResource] = [
	#PrehistoricPestoTalents.new().create_basic_infection()
]
var transformation_effects: Dictionary = {}

# Runtime effect variables
var shot_counter: int = 0
var crit_chance: float = 0.0
var crit_multiplier: float = 1.0
var last_trigger_times: Dictionary = {}
var perfect_shots_remaining: int = 0

var effective_damage: float = 0.0
var effective_fire_rate: float = 0.0
var effective_range: float = 0.0
var effective_projectile_count: int = 1
var effective_effect_chance: float = 0
var effective_effect_intensity: float = 0
var effective_radius: float = 120.0


func _ready() -> void:
	var sauce_name = sauce_data.sauce_name if sauce_data else "UnknownSauce"
	bottle_id = "%s_%d" % [sauce_name, get_instance_id()]
	print("🍼 Created improved bottle with ID: %s" % bottle_id)
	recalculate_all_effective_stats()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	setup_shoot_timer()
	if sauce_data:
		setup_bottle()

func setup_bottle():
	# Apply sauce color to both base and tip
	if bottle_base and bottle_sprites:
		bottle_sprites.modulate = sauce_data.sauce_color
	update_detection_range()

func update_detection_range():
	if detection_area and detection_area.shape and sauce_data:
		var base_range = sauce_data.get_current_range(current_level)
		var modified_range = effective_range
		detection_area.shape.radius = modified_range

func setup_shoot_timer():
	if not shoot_timer:
		shoot_timer = Timer.new()
		add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	update_fire_rate()

func update_fire_rate():
	if shoot_timer and sauce_data:
		var base_fire_rate = sauce_data.get_current_fire_rate(current_level)
		var modified_fire_rate = effective_fire_rate
		shoot_timer.wait_time = 1.0 / modified_fire_rate

func _on_shoot_timer_timeout():
	if current_target and is_instance_valid(current_target):
		shoot()
	else:
		current_target = null

func _physics_process(delta: float) -> void:
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		if enemies_in_range.size() > 1:
			update_closest_target()

	# Rotate the whole bottle sprites group to face target
	if current_target and is_instance_valid(current_target):
		if bottle_sprites:
			# Calculate direction from bottle to target
			var direction = current_target.global_position - global_position
			# Set rotation to point toward target
			bottle_sprites.rotation = direction.angle()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)
		if current_target == null:
			current_target = body
			if not shoot_timer.is_stopped():
				shoot_timer.start()

func _on_body_exited(body):
	if body.is_in_group("enemies"):
		enemies_in_range.erase(body)
		if body == current_target:
			current_target = null
			update_closest_target()

func update_closest_target():
	# Clean up invalid enemies first
	var valid_enemies = []
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			valid_enemies.append(enemy)
	enemies_in_range = valid_enemies

	if enemies_in_range.size() == 0:
		current_target = null
		return

	var closest = enemies_in_range[0]
	var closest_dist = global_position.distance_to(closest.global_position)

	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	current_target = closest

# ===================================================================
# SHOOTING SYSTEM
# ===================================================================

func get_modified_duration(base_duration: float) -> float:
	"""Calculate infection duration with talent modifications"""
	var final_duration = base_duration

	# Check bottle's special effects for duration boost
	for effect in special_effects:
		if effect.effect_name == "infection_duration_boost":
			var multiplier = effect.get_parameter("duration_multiplier", 1.5)
			final_duration *= multiplier
			print("🦠 Persistent Strain: Extending infection from %.1fs to %.1fs" % [base_duration, final_duration])

	return final_duration

func shoot():
	shot_counter += 1
	_check_trigger_effects()

	if not current_target or not sauce_data:
		return

	# Play animation if available
	if animation_player and animation_player.has_animation("squeeze"):
		animation_player.play("squeeze")

	# Fire projectile with flash effect
	fire_projectile_with_flash()

func fire_projectile_with_flash():
	if not current_target or not sauce_data:
		return

	var new_sauce = SAUCE.instantiate()
	get_tree().current_scene.add_child(new_sauce)
	new_sauce.scale = scale

	var shoot_position = shooting_point.global_position
	var target_direction = shoot_position.direction_to(current_target.global_position)

	# Calculate final damage with talent modifiers
	var base_damage = sauce_data.get_current_damage(current_level)
	var final_damage = get_modified_damage(base_damage)

	# Create modified sauce data for projectile
	var modified_sauce_data = sauce_data.duplicate()
	modified_sauce_data.damage = final_damage

	# Launch projectile
	new_sauce.launch(
		shoot_position,
		target_direction,
		modified_sauce_data,
		current_level,
		bottle_id,
		self
	)
	new_sauce.effect_chance = effective_effect_chance
	new_sauce.effect_intensity = effective_effect_intensity

	# Apply special effects to projectile
	_apply_special_effects_to_projectile(new_sauce)

	# Flash effect
	if the_tip:
		var scale_tween = create_tween()
		var original_scale = the_tip.scale
		scale_tween.tween_property(the_tip, "scale", original_scale * 1.3, 0.05)
		scale_tween.tween_property(the_tip, "scale", original_scale, 0.15)

func _check_trigger_effects():
	"""Check and apply trigger-based effects"""
	TriggerActionManager.process_trigger_effects(self)
	for trigger in trigger_effects:
		match trigger.trigger_name:
			"burst_fire":
				var interval = trigger.get_parameter("shot_interval", 5)
				if shot_counter % interval == 0:
					_trigger_burst_fire(trigger)
			"perfect_shots":
				if perfect_shots_remaining > 0:
					perfect_shots_remaining -= 1
			"mini_volcano":
				var interval = trigger.trigger_condition.interval
				if shot_counter % interval == 0:
					var damage = trigger.effect_parameters.damage
					var radius = trigger.effect_parameters.radius

					TalentEffectManager.create_mini_volcano(current_target.global_position, damage, radius, bottle_id )

func _trigger_burst_fire(trigger: TriggerEffectResource):
	"""Fire a burst of projectiles"""
	var burst_count = trigger.get_parameter("burst_count", 5)
	for i in range(burst_count):
		get_tree().create_timer(i * 0.1).timeout.connect(fire_projectile_with_flash)

func _apply_special_effects_to_projectile(projectile):
	"""Apply bottle's special effects to the projectile"""

	for effect in special_effects:
		match effect.effect_name:
			"critical_hits":
				if randf() < crit_chance:
					projectile.apply_critical_hit(crit_multiplier)
			"slow_enemies":
				var strength = effect.get_parameter("slow_strength", 0.5)
				var duration = effect.get_parameter("duration", 2.0)
				projectile.add_on_hit_effect("slow", {"strength": strength, "duration": duration})

# ===================================================================
# LEVELING SYSTEM
# ===================================================================

func gain_xp(amount: int):
	if current_level >= max_level:
		return

	current_xp += amount
	while current_xp >= xp_to_next_level and current_level < max_level:
		level_up()

func level_up():
	current_level += 1
	current_xp -= xp_to_next_level
	xp_to_next_level = int(xp_to_next_level * 1.3) # 30% more XP needed each level

	# Update stats based on new level
	update_fire_rate() # Update fire rate
	update_detection_range() # Update range
	recalculate_all_effective_stats()

	# Emit signal for UI updates
	leveled_up.emit(bottle_id, current_level, sauce_data.sauce_name)

	# Visual feedback
	create_level_up_effect()

func create_level_up_effect():
	"""Level up effect that flashes both base and tip"""
	var base_tween = create_tween()
	var tip_tween = create_tween()

	if bottle_base:
		var original_base_scale = bottle_base.scale
		base_tween.tween_property(bottle_base, "scale", original_base_scale * 1.3, 0.2)
		base_tween.tween_property(bottle_base, "scale", original_base_scale, 0.2)

	if the_tip:
		var original_tip_modulate = the_tip.modulate
		tip_tween.tween_property(the_tip, "modulate", Color.GOLD, 0.2)
		tip_tween.tween_property(the_tip, "modulate", original_tip_modulate, 0.2)

# ===================================================================
# TALENT SYSTEM METHODS
# ===================================================================

func recalculate_all_effective_stats():
	# Start with base + level scaling
	var base_damage = sauce_data.get_current_damage(current_level)
	var base_fire_rate = sauce_data.get_current_fire_rate(current_level)
	var base_range = sauce_data.get_current_range(current_level)
	var base_effect_chance = sauce_data.get_current_effect_chance(current_level)
	var base_effect_intensity = sauce_data.get_current_effect_intensity(current_level)
	var base_effect_radius = sauce_data.get_current_effect_radius(current_level)

	# Apply all modifiers from stat_modifier_history
	for modifier in stat_modifier_history:
		match modifier.stat_name:
			"damage": base_damage = modifier.apply_to_value(base_damage)
			"fire_rate": base_fire_rate = modifier.apply_to_value(base_fire_rate)
			"range": base_range = modifier.apply_to_value(base_range)
			"effect_chance": base_effect_chance = modifier.apply_to_value(base_effect_chance)
			"effect_intensity": base_effect_intensity = modifier.apply_to_value(base_effect_intensity)
			"base_radius":

				base_effect_radius = modifier.apply_to_value(base_effect_radius)
				print("in radius?", base_effect_radius)

	# Store in effective variables
	effective_damage = base_damage
	effective_fire_rate = base_fire_rate
	effective_range = base_range
	effective_effect_chance = base_effect_chance
	effective_effect_intensity = base_effect_intensity
	effective_radius = base_effect_radius
	print("Final effective stats:")
	print("  Damage: %.1f" % effective_damage)
	print("  Fire Rate: %.1f" % effective_fire_rate)
	print("  Range: %.1f" % effective_range)
	print("  Effect Chance: %.2f" % effective_effect_chance)
	print("  Effect Intensity: %.2f" % effective_effect_intensity)
	print("  Effect radius: %.2f" % effective_radius)
	print("=======================================")


# TALENT MODIFIER CALCULATION METHODS
func get_modified_damage(base_damage: float) -> float:
	"""Apply all talent modifiers to calculate final damage"""
	var final_damage = base_damage

	# Apply stat modifiers from talent system
	for mod in stat_modifier_history:
		if mod.stat_name == "damage":
			final_damage = mod.apply_to_value(final_damage)

	return final_damage

func get_modified_fire_rate(base_fire_rate: float) -> float:
	"""Apply all talent modifiers to calculate final fire rate"""
	var final_fire_rate = base_fire_rate

	# Apply stat modifiers from talent system
	for mod in stat_modifier_history:
		if mod.stat_name == "fire_rate":
			final_fire_rate = mod.apply_to_value(final_fire_rate)

	return final_fire_rate

func get_modified_range(base_range: float) -> float:
	"""Apply all talent modifiers to calculate final range"""
	var final_range = base_range

	# Apply stat modifiers from talent system
	for mod in stat_modifier_history:
		if mod.stat_name == "range":
			final_range = mod.apply_to_value(final_range)

	return final_range

func get_modified_projectile_count() -> int:
	"""Calculate total projectile count from talents"""
	var projectile_count = 1 # Base projectile count

	# Apply projectile count modifiers
	for mod in stat_modifier_history:
		if mod.stat_name == "projectile_count":
			projectile_count = int(mod.apply_to_value(float(projectile_count)))

	return max(1, projectile_count) # At least 1 projectile

# TALENT MANAGEMENT METHODS
func modify_stat(modifier: StatModifier):
	"""Apply a stat modifier from a talent"""
	if not sauce_data.has_method("get"):
		print("Warning: sauce_data doesn't support get method")
		return

	var current_value = sauce_data.get(modifier.stat_name)

	if current_value == null:
		print("Warning: Unknown stat '%s'" % modifier.stat_name)
		return

	#var new_value = modifier.apply_to_value(current_value)
	#sauce_data.set(modifier.stat_name, new_value)
	# Track for potential removal
	stat_modifier_history.append(modifier)
	recalculate_all_effective_stats()

	print(" hi %s: %.1f -> %.1f (%s)" % [
		modifier.stat_name, current_value, effective_damage, modifier.get_description()
	])

	# Update runtime systems if needed
	_update_runtime_stats(modifier.stat_name)

func remove_stat_modifier(modifier: StatModifier):
	"""Remove a previously applied stat modifier"""
	if modifier in stat_modifier_history:
		stat_modifier_history.erase(modifier)
		print("Removed stat modifier: %s" % modifier.get_description())
		# Note: Full removal would require recalculating from base values

func _update_runtime_stats(stat_name: String):
	"""Update runtime systems when stats change"""
	match stat_name:
		"fire_rate":
			update_fire_rate()
		"range":
			update_detection_range()

func add_special_effect(effect: SpecialEffectResource):
	"""Add a special effect to this bottle"""
	special_effects.append(effect)

	# Apply immediate effects
	match effect.effect_type:
		SpecialEffectResource.EffectType.PASSIVE_EFFECT:
			_apply_passive_effect(effect)

	print("  Added special effect: %s" % effect.effect_name)

func remove_special_effect(effect: SpecialEffectResource):
	"""Remove a special effect from this bottle"""
	if effect in special_effects:
		special_effects.erase(effect)
		_remove_passive_effect(effect)
		print("  Removed special effect: %s" % effect.effect_name)

func _apply_passive_effect(effect: SpecialEffectResource):
	"""Apply effects that are always active"""
	match effect.effect_name:
		"critical_hits":
			crit_chance = effect.get_parameter("crit_chance", 0.15)
			crit_multiplier = effect.get_parameter("crit_multiplier", 3.0)
		"crit_mode":
			# Set up crit mode trigger
			pass
		"slow_synergy":
			# This would modify damage calculation against slowed enemies
			pass

func _remove_passive_effect(effect: SpecialEffectResource):
	"""Remove passive effects"""
	match effect.effect_name:
		"critical_hits":
			crit_chance = 0.0
			crit_multiplier = 1.0

func add_trigger_effect(trigger: TriggerEffectResource):
	"""Add a trigger effect from a talent"""
	if not trigger in trigger_effects:
		trigger_effects.append(trigger)
		print("Added trigger effect: %s" % trigger.trigger_name)

func remove_trigger_effect(trigger: TriggerEffectResource):
	"""Remove a trigger effect (for respec)"""
	if trigger in trigger_effects:
		trigger_effects.erase(trigger)
		print("Removed trigger effect: %s" % trigger.trigger_name)

func apply_transformation(talent: Talent):
	"""Apply a transformation talent"""
	transformation_effects[talent.talent_name] = talent
	print("Applied transformation: %s" % talent.talent_name)

func remove_transformation(talent: Talent):
	"""Remove a transformation talent"""
	if talent.talent_name in transformation_effects:
		transformation_effects.erase(talent.talent_name)
		print("Removed transformation: %s" % talent.talent_name)

# ===================================================================
# UTILITY FUNCTIONS
# ===================================================================

func get_level_info() -> Dictionary:
	return {
		"level": current_level,
		"xp": current_xp,
		"xp_to_next": xp_to_next_level,
		"upgrades": chosen_upgrades.duplicate()
	}

func get_talent_summary() -> Dictionary:
	"""Get summary of all applied talents for UI"""
	return {
		"active_talents": active_talents.size(),
		"stat_modifiers": stat_modifier_history.size(),
		"special_effects": special_effects.size(),
		"trigger_effects": trigger_effects.size(),
		"transformations": transformation_effects.size(),
		"crit_chance": crit_chance,
		"perfect_shots": perfect_shots_remaining
	}

func get_effective_stats() -> Dictionary:
	"""Get current effective stats after all modifiers"""
	var base_damage = sauce_data.get_current_damage(current_level)
	var base_fire_rate = sauce_data.get_current_fire_rate(current_level)
	var base_range = sauce_data.get_current_range(current_level)

	return {
		"base_damage": base_damage,
		"modified_damage": get_modified_damage(base_damage),
		"base_fire_rate": base_fire_rate,
		"modified_fire_rate": get_modified_fire_rate(base_fire_rate),
		"base_range": base_range,
		"modified_range": get_modified_range(base_range),
		"projectile_count": get_modified_projectile_count()
	}

func debug_print_effective_stats():
	"""Debug function to print all effective stats"""
	var stats = get_effective_stats()
	print("=== Effective Stats for %s ===" % bottle_id)
	print("Damage: %.1f (base: %.1f)" % [stats.modified_damage, stats.base_damage])
	print("Fire Rate: %.2f/sec (base: %.2f/sec)" % [stats.modified_fire_rate, stats.base_fire_rate])
	print("Range: %.0f (base: %.0f)" % [stats.modified_range, stats.base_range])
	print("Projectiles: %d" % stats.projectile_count)
	print("Active Modifiers: %d" % stat_modifier_history.size())
	print("=============================")

# Utility functions for external access
func get_bottle_base() -> Node2D:
	return bottle_base

func get_tip() -> Node2D:
	return the_tip

func set_tip_color(color: Color):
	"""Set tip color independently from base"""
	if the_tip:
		the_tip.modulate = color

func set_base_color(color: Color):
	"""Set base color independently from tip"""
	if bottle_base:
		bottle_base.modulate = color
