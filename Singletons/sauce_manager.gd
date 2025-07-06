extends Node

var all_sauces = {
	"ketchup": preload("res://Resources/ketchup.tres"),
	"bbq": preload("res://Resources/bbq_sauce.tres"),
	"hot_sauce": preload("res://Resources/hot_sauce.tres"),
	"ranch": preload("res://Resources/ranch.tres")
}

func get_sauce(name: String):
	return all_sauces.get(name)

func get_random_sauces(num: int = 3) -> Array[BaseSauceResource]:
	var sauce_names = all_sauces.keys()
	sauce_names.shuffle()
	var chosen = sauce_names.slice(0, num)
	var scenes: Array[BaseSauceResource] = []
	for name in chosen:
		scenes.append(all_sauces[name])
	return scenes
