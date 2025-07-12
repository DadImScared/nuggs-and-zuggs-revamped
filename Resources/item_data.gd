class_name ItemData
extends Resource

@export var sauce_resource: BaseSauceResource
@export var bottle_scene_path: String = "res://Scenes/SauceBottles/improved_base_sauce_bottle.tscn"

func create_bottle(p_resource: BaseSauceResource):
	var scene = load(bottle_scene_path)
	var bottle = scene.instantiate()
	bottle.sauce_data = p_resource
	return bottle
