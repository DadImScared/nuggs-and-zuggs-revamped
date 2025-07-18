class_name PlagueBearerTrigger
extends BaseTriggerAction

func _init() -> void:
	trigger_name = "plague_bearer"
	trigger_description = "Enemies within 50 units have 10% chance per second to get infected"

func execute_trigger(bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource):
		var enemies = get_enemies_in_radius(bottle.global_position, 50)
		for enemy in enemies:
			if "infect" not in enemy["active_effects"] and randf() < trigger_data.trigger_condition["chance"]:
				if enemy.has_method("apply_status_effect"):
					enemy.apply_status_effect(
						"infect",
						bottle.get_modified_duration(trigger_data.effect_parameters["duration"]),
						bottle.effective_effect_intensity or 0.2,
						bottle.bottle_id
					)
