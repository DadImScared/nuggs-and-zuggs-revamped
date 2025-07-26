class_name EmberCascadeTrigger extends BaseTriggerAction

func _init(): trigger_name = "ember_cascade"

func execute_trigger(source_bottle, trigger_data):
	var affected_enemy = trigger_data.effect_parameters.get("dot_enemy")
	var burn_stacks = trigger_data.effect_parameters.get("burn_stacks", 1)
	print("ember cascade triggered -----------------------")
	Effects.burn.apply_from_talent(affected_enemy, source_bottle, burn_stacks)
