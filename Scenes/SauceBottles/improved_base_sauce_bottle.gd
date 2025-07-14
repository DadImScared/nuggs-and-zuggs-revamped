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
var trigger_effects: Array[TriggerEffectResource] = []
var transformation_effects: Array[String] = []

# Runtime effect variables
var shot_counter: int = 0
var crit_chance: float = 0.0
var crit_multiplier: float = 1.0
var last_trigger_times: Dictionary = {}
var perfect_shots_remaining: int = 0

func _ready() -> void:
	var sauce_name = sauce_data.sauce_name if sauce_data else "UnknownSauce"
	bottle_id = "%s_%d" % [sauce_name, get_instance_id()]
	print("🍼 Created improved bottle with ID: %s" % bottle_id)

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
		var current_range = sauce_data.get_current_range(current_level)
		detection_area.shape.radius = current_range

func setup_shoot_timer():
	if not shoot_timer:
		shoot_timer = Timer.new()
		add_child(shoot_timer)

	# Use leveled fire rate
	var current_fire_rate = sauce_data.get_current_fire_rate(current_level)
	shoot_timer.wait_time = 1.0 / current_fire_rate
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func _on_shoot_timer_timeout():
	if current_target and is_instance_valid(current_target):
		shoot()
	else:
		current_target = null

func update_fire_rate():
	if shoot_timer and sauce_data:
		var current_fire_rate = sauce_data.get_current_fire_rate(current_level)
		shoot_timer.wait_time = 1.0 / current_fire_rate

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
	if enemies_in_range.is_empty():
		current_target = null
		return

	var closest_enemy = null
	var closest_distance = INF

	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy

	current_target = closest_enemy

# ===================================================================
# ENHANCED SHOOTING WITH TALENT EFFECTS
# ===================================================================

func shoot():
	shot_counter += 1

	# Check all trigger effects
	_check_trigger_effects()

	if not current_target:
		return

	# Determine shot type based on special effects
	var projectile_modifiers = _get_projectile_modifiers()

	if "triple_shot" in projectile_modifiers:
		_fire_enhanced_shot(3, 15.0)
	else:
		_fire_enhanced_shot(1, 0.0)

func _get_projectile_modifiers() -> Array[String]:
	"""Get list of active projectile modifiers"""
	var modifiers: Array[String] = []
	for effect in special_effects:
		if effect.effect_type == SpecialEffectResource.EffectType.PROJECTILE_MODIFIER:
			modifiers.append(effect.effect_name)
	return modifiers

func _check_trigger_effects():
	"""Check all trigger conditions and fire effects"""
	for trigger in trigger_effects:
		if _should_trigger(trigger):
			_execute_trigger_effect(trigger)

func _should_trigger(trigger: TriggerEffectResource) -> bool:
	"""Check if a trigger condition is met"""
	match trigger.trigger_type:
		TriggerEffectResource.TriggerType.ON_SHOT_COUNT:
			var interval = trigger.trigger_condition.get("interval", 5)
			return shot_counter % interval == 0
		TriggerEffectResource.TriggerType.ON_TIMER:
			var cooldown = trigger.trigger_condition.get("cooldown", 20.0)
			var last_time = last_trigger_times.get(trigger.trigger_name, 0.0)
			var current_time = Time.get_unix_time_from_system()
			return current_time - last_time >= cooldown
		TriggerEffectResource.TriggerType.ON_RANDOM_CHANCE:
			var chance = trigger.trigger_condition.get("chance", 0.1)
			return randf() < chance
		TriggerEffectResource.TriggerType.ON_CRITICAL_HIT:
			# This would be called from projectile hit detection
			return false  # Not checked here
	return false

func _execute_trigger_effect(trigger: TriggerEffectResource):
	"""Execute a triggered effect"""
	match trigger.effect_name:
		"fire_burst":
			var burst_size = trigger.effect_parameters.get("burst_size", 5)
			var spread = trigger.effect_parameters.get("spread_angle", 8.0)
			_fire_enhanced_shot(burst_size, spread)

			# Check for chain burst
			if trigger.trigger_name == "chain_burst":
				if randf() < trigger.trigger_condition.get("chance", 0.5):
					print("Chain burst triggered!")
					_fire_enhanced_shot(burst_size, spread)

		"create_tsunami":
			var damage_mult = trigger.effect_parameters.get("damage_multiplier", 2.0)
			TalentEffectManager.create_tsunami_wave(global_position, sauce_data.damage * damage_mult)
			last_trigger_times[trigger.trigger_name] = Time.get_unix_time_from_system()

		"increase_crit_chance":
			var bonus = trigger.effect_parameters.get("bonus_per_crit", 0.05)
			var max_bonus = trigger.effect_parameters.get("max_bonus", 0.5)
			crit_chance = min(crit_chance + bonus, max_bonus)
			print("Crit chance increased to %.1f%%" % (crit_chance * 100))

		"activate_perfect_mode":
			var shot_count = trigger.effect_parameters.get("shot_count", 10)
			perfect_shots_remaining = shot_count
			print("Perfect Shots activated! %d shots remaining" % shot_count)

func _fire_enhanced_shot(count: int, spread_angle: float):
	"""Fire projectiles with all current enhancements"""
	for i in range(count):
		var angle_offset = 0.0
		if count > 1:
			angle_offset = (i - (count - 1) / 2.0) * spread_angle

		var projectile = SAUCE.instantiate()
		get_tree().current_scene.add_child(projectile)

		var shoot_position = shooting_point.global_position
		var base_direction = shoot_position.direction_to(current_target.global_position)
		var adjusted_direction = base_direction.rotated(deg_to_rad(angle_offset))

		# Check for crit (or perfect shot)
		var is_crit = (perfect_shots_remaining > 0) or (randf() < crit_chance)
		var damage_multiplier = crit_multiplier if is_crit else 1.0

		if perfect_shots_remaining > 0:
			perfect_shots_remaining -= 1
			damage_multiplier = crit_multiplier * 2.0  # Perfect shots are mega crits

		projectile.launch(shoot_position, adjusted_direction, sauce_data, current_level, bottle_id)

		# Apply all current effects to projectile
		_enhance_projectile(projectile, is_crit, damage_multiplier)

		# Check for crit triggers
		if is_crit:
			_handle_crit_triggers()

func _handle_crit_triggers():
	"""Handle effects that trigger on critical hits"""
	for trigger in trigger_effects:
		if trigger.trigger_type == TriggerEffectResource.TriggerType.ON_CRITICAL_HIT:
			_execute_trigger_effect(trigger)

func _enhance_projectile(projectile, is_crit: bool, damage_multiplier: float):
	"""Apply all bottle effects to a projectile"""
	if is_crit:
		projectile.damage_multiplier = damage_multiplier
		projectile.is_critical_hit = true

	# Apply special effects
	for effect in special_effects:
		_apply_effect_to_projectile(projectile, effect)

func _apply_effect_to_projectile(projectile, effect: SpecialEffectResource):
	"""Apply a specific effect to a projectile"""
	match effect.effect_name:
		"apply_slow":
			var strength = effect.get_parameter("slow_strength", 0.4)
			var duration = effect.get_parameter("duration", 3.0)
			projectile.add_on_hit_effect("slow", {"strength": strength, "duration": duration})

		"create_puddles":
			var chance = effect.get_parameter("chance", 0.25)
			var damage_mult = effect.get_parameter("damage_multiplier", 0.5)
			var duration = effect.get_parameter("duration", 5.0)
			if randf() < chance:
				projectile.add_on_hit_effect("create_puddle", {
					"damage": sauce_data.damage * damage_mult,
					"duration": duration
				})

		"enhanced_puddles":
			# Modifies existing puddle behavior
			projectile.add_on_hit_effect("enhanced_puddle", {
				"slow_enemies": effect.get_parameter("puddle_slow", true),
				"duration_multiplier": effect.get_parameter("duration_multiplier", 1.5)
			})

		"ramping_pierce":
			var bonus = effect.get_parameter("damage_bonus_per_hit", 0.25)
			projectile.pierce_damage_bonus = bonus

		"homing_missiles":
			var turn_speed = effect.get_parameter("turn_speed", 0.05)
			projectile.make_homing(turn_speed)

		"infinite_pierce":
			projectile.pierce_count = effect.get_parameter("pierce_count", 999)
			projectile.infinite_pierce = true

		"bouncing_shots":
			var max_bounces = effect.get_parameter("max_bounces", 3)
			var bounce_range = effect.get_parameter("bounce_range", 200.0)
			projectile.setup_bouncing(max_bounces, bounce_range)

		"vulnerability_debuff":
			var bonus = effect.get_parameter("damage_bonus", 0.25)
			var duration = effect.get_parameter("duration", 5.0)
			projectile.add_on_hit_effect("vulnerability", {"bonus": bonus, "duration": duration})

# ===================================================================
# TALENT INTERFACE FUNCTIONS
# ===================================================================

# CLEAN STAT MODIFICATION INTERFACE
func modify_stat(modifier: StatModifier):
	"""Apply a stat modifier and track it for potential removal"""
	if not sauce_data.has_method("get"):
		print("Warning: sauce_data doesn't support get method")
		return

	var current_value = sauce_data.get(modifier.stat_name)
	if current_value == null:
		print("Warning: Unknown stat '%s'" % modifier.stat_name)
		return

	var new_value = modifier.apply_to_value(current_value)
	sauce_data.set(modifier.stat_name, new_value)

	# Track for potential removal
	stat_modifier_history.append(modifier)

	print("  %s: %.1f -> %.1f (%s)" % [
		modifier.stat_name, current_value, new_value, modifier.get_description()
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

# SPECIAL EFFECTS MANAGEMENT
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

# TRIGGER EFFECTS MANAGEMENT
func add_trigger_effect(trigger: TriggerEffectResource):
	"""Add a trigger effect to this bottle"""
	trigger_effects.append(trigger)
	print("  Added trigger effect: %s" % trigger.trigger_name)

func remove_trigger_effect(trigger: TriggerEffectResource):
	"""Remove a trigger effect from this bottle"""
	if trigger in trigger_effects:
		trigger_effects.erase(trigger)
		print("  Removed trigger effect: %s" % trigger.trigger_name)

# TRANSFORMATION MANAGEMENT
func apply_transformation(talent: Talent):
	"""Apply major transformations to this bottle"""
	transformation_effects.append(talent.talent_name)
	print("  Applying transformation: %s" % talent.talent_name)

	match talent.talent_name:
		"Ballistic Ketchup":
			# Make all projectiles homing missiles
			add_special_effect(SpecialEffectResource.create_homing_missiles())
		"Arena Transform":
			TalentEffectManager.transform_arena(self)
		"The Heinz Factor":
			TalentEffectManager.activate_god_mode(self, 30.0)
		"Condiment Synergy":
			# Handled by TalentManager.apply_aura_effect
			pass
		"Eternal Flood":
			TalentEffectManager.create_eternal_flood_mode(self)
		"Crit Ascension":
			crit_chance = 1.0  # Always crit
			crit_multiplier = 5.0
		"Tomato Apocalypse":
			TalentEffectManager.transform_arena_to_ketchup_hell(self)

func remove_transformation(talent: Talent):
	"""Remove transformation effects"""
	if talent.talent_name in transformation_effects:
		transformation_effects.erase(talent.talent_name)
		print("  Removing transformation: %s" % talent.talent_name)

# ===================================================================
# LEVELING SYSTEM
# ===================================================================

# Level system functions
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
