class_name InfectTrigger
extends BaseTriggerAction

func _init() -> void:
	trigger_name = "infect"
	trigger_description = "20% chance to infect on hit"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var enemy = data.effect_parameters.hit_enemy
	var duration = data.effect_parameters.get("duration", bottle.sauce_data.effect_duration)
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect(data.trigger_name, duration, bottle.effective_effect_intensity, bottle.bottle_id)
