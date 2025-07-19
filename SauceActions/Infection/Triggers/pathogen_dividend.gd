class_name PathogenDividendTrigger
extends BaseTriggerAction

func _init() -> void:
	trigger_name = "pathogen_dividend"
	trigger_description = "gain xp on enemy death if infected"

func execute_trigger(bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData):
	var xp_reward = trigger_data.effect_parameters.get("xp_reward", 5)
	var death_data = trigger_data.effect_parameters.get("event_data", {})
	var enemy_position = death_data.get("enemy_position", Vector2.ZERO)
	var damage_sources = death_data.get("damage_sources", {})

	var bottle_contributed = damage_sources.has(bottle.bottle_id)

	if bottle_contributed:
		# Give XP to the bottle
		bottle.gain_xp(xp_reward)
		print("💰 Pathogen Dividend: %s gained %d XP from infected enemy death" % [bottle.sauce_data.sauce_name, xp_reward])

		# Optional: Create visual effect at enemy death position
		_create_dividend_visual(enemy_position)
	else:
		print("💰 Pathogen Dividend: Bottle didn't contribute to this kill, no XP gained")

	log_trigger_executed(bottle, trigger_data)

func _create_dividend_visual(position: Vector2):
	"""Create a visual effect showing XP gain"""
	var xp_label = Label.new()
	xp_label.text = "+5 XP"
	xp_label.add_theme_color_override("font_color", Color.GOLD)
	xp_label.add_theme_font_size_override("font_size", 16)
	xp_label.global_position = position

	# Add to scene
	Engine.get_main_loop().current_scene.add_child(xp_label)

	# Animate floating upward and fade out
	var tween = xp_label.create_tween()
	tween.parallel().tween_property(xp_label, "global_position", position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(xp_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(xp_label.queue_free)
