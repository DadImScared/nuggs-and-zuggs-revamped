class_name ViralFrenzyTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "viral_frenzy"
	trigger_description = "25% chance per infection tick: gain +100% fire rate for 8 seconds"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	"""Execute Viral Frenzy using the new buff system"""

	# Get parameters
	var fire_rate_boost = trigger_data.effect_parameters.get("fire_rate_boost", 1.0)  # 100% boost = 1.0
	var duration = trigger_data.effect_parameters.get("duration", 8.0)  # 8 seconds
	var source = "Viral Frenzy"

	#print("🔥 Viral Frenzy: Triggered! Gaining fire rate boost for %.1f seconds" % duration)

	# Use the NEW buff system to add fire rate buff
	var success = PlayerStats.add_fire_rate_buff(fire_rate_boost, duration, source)

	#if success:
		##print("🔥 Viral Frenzy: Applied +%.0f%% fire rate boost for %.1fs" % (fire_rate_boost * 100, duration))
	#else:
		##print("🔥 Viral Frenzy: Buff system failed (shouldn't happen)")

	# Create visual effect
	_create_frenzy_visual(source_bottle)

	log_trigger_executed(source_bottle, trigger_data)

func _create_frenzy_visual(bottle: ImprovedBaseSauceBottle):
	"""Create visual effect when frenzy activates"""
	if not is_instance_valid(bottle):
		return

	# Add a subtle red tint flash to the bottle
	if bottle.bottle_sprites:
		var original_modulate = bottle.bottle_sprites.modulate
		var frenzy_tint = Color(1.2, 0.9, 0.9, 1.0)  # Subtle red tint

		# Quick flash to frenzy color and back
		var tween = bottle.bottle_sprites.create_tween()
		tween.tween_property(bottle.bottle_sprites, "modulate", frenzy_tint, 0.1)
		tween.tween_property(bottle.bottle_sprites, "modulate", original_modulate, 0.3)
