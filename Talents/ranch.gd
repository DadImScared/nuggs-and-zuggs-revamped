class_name RanchTalents
extends BaseTalentTree

func _init() -> void:
	sauce_name = "Ranch"

func create_basic_slow():
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "slow"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
