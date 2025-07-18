# SauceActions/Infection/Triggers/viral_frenzy.gd - Fixed timer signal binding

class_name ViralFrenzyTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "viral_frenzy"
	trigger_description = "25% chance per infection tick: gain +100% fire rate for 8 seconds"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource) -> void:
	# Get parameters
	var fire_rate_boost = trigger_data.effect_parameters.get("fire_rate_boost", 1.0)  # 100% boost = 1.0
	var duration = trigger_data.effect_parameters.get("duration", 8.0)  # 8 seconds

	print("🔥 Viral Frenzy: Triggered! Gaining fire rate boost for %.1f seconds" % duration)

	# Apply the fire rate boost to the bottle
	_apply_fire_rate_boost(source_bottle, fire_rate_boost, duration)

	# Create visual effect
	_create_frenzy_visual(source_bottle)

	log_trigger_executed(source_bottle, trigger_data)

func _apply_fire_rate_boost(bottle: ImprovedBaseSauceBottle, boost_amount: float, duration: float):
	"""Apply temporary fire rate boost to the bottle"""

	# Create a temporary stat modifier
	var temp_modifier = StatModifier.new()
	temp_modifier.stat_name = "fire_rate"
	temp_modifier.mode = StatModifier.ModifierMode.MULTIPLY
	temp_modifier.multiply = boost_amount  # 1.0 = +100%

	# Apply the modifier
	bottle.modify_stat(temp_modifier)

	print("🔥 Viral Frenzy: Applied +%.0f%% fire rate boost" % (boost_amount * 100))

	# Start timer to remove the boost
	_start_frenzy_timer(bottle, temp_modifier, duration)

func _start_frenzy_timer(bottle: ImprovedBaseSauceBottle, modifier: StatModifier, duration: float):
	"""Start timer to remove frenzy effect after duration - SAFE implementation"""
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true

	# Store data in timer metadata to avoid signal binding issues
	timer.set_meta("target_bottle", bottle)
	timer.set_meta("stat_modifier", modifier)

	# Simple signal connection without parameters
	timer.timeout.connect(_on_frenzy_timer_timeout.bind(timer))

	# Add timer to the bottle so it moves with it
	bottle.add_child(timer)
	timer.start()

func _on_frenzy_timer_timeout(timer: Timer):
	"""Handle frenzy timer timeout safely"""
	if not is_instance_valid(timer):
		return

	# Get stored data
	var bottle = timer.get_meta("target_bottle", null)
	var modifier = timer.get_meta("stat_modifier", null)

	# Execute removal
	_remove_frenzy_effect(bottle, modifier)

	# Clean up timer
	timer.queue_free()

func _remove_frenzy_effect(bottle: ImprovedBaseSauceBottle, modifier: StatModifier):
	"""Remove the viral frenzy effect from the bottle"""
	if not is_instance_valid(bottle):
		return

	# Remove the stat modifier
	if modifier:
		bottle.remove_stat_modifier(modifier)

	# Make sure visual is reset (in case it's still tinted)
	if bottle.bottle_sprites:
		bottle.bottle_sprites.modulate = bottle.sauce_data.sauce_color

	print("🔥 Viral Frenzy: Effect expired")

func _create_frenzy_visual(bottle: ImprovedBaseSauceBottle):
	"""Create very subtle visual effect when frenzy activates"""
	if not is_instance_valid(bottle):
		return

	# Just add a very slight red tint to the bottle
	if bottle.bottle_sprites:
		var original_modulate = bottle.bottle_sprites.modulate
		var subtle_tint = Color(1.1, 0.95, 0.95, 1.0)  # Barely noticeable red tint
		bottle.bottle_sprites.modulate = subtle_tint

		# Quick flash back to normal
		var tween = bottle.bottle_sprites.create_tween()
		tween.tween_property(bottle.bottle_sprites, "modulate", original_modulate, 0.15)
