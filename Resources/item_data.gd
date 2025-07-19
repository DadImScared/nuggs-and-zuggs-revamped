# Resources/item_data.gd
class_name ItemData
extends Resource

@export var sauce_resource: BaseSauceResource
@export var bottle_scene_path: String = "res://Scenes/SauceBottles/improved_base_sauce_bottle.tscn"

func create_bottle(p_resource: BaseSauceResource):
	var scene = load(bottle_scene_path)
	var bottle = scene.instantiate()
	bottle.sauce_data = p_resource.duplicate()

	# Add sauce-specific base triggers
	_add_base_triggers(bottle, p_resource)

	return bottle

func _add_base_triggers(bottle: ImprovedBaseSauceBottle, sauce_resource: BaseSauceResource):
	"""Add sauce-specific base triggers based on sauce name"""
	print("🔧 Adding base triggers for: %s" % sauce_resource.sauce_name)

	match sauce_resource.sauce_name:
		"Prehistoric Pesto":
			var pesto_talents = PrehistoricPestoTalents.new()
			bottle.trigger_effects.append(pesto_talents.create_basic_infection())
			print("✅ Added base infection trigger to Prehistoric Pesto")
		"Archaean Apple Butter":
			var apple_butter_talents = ArchaeanAppleButterTalents.new()
			bottle.trigger_effects.append(apple_butter_talents.create_basic_fossilization())
			print("✅ Added base fossilization trigger to Archaean Apple Butter")
		_:
			print("ℹ️ No base triggers defined for: %s" % sauce_resource.sauce_name)
			print("   This sauce will have basic projectile behavior only")
