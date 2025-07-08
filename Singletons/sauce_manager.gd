extends Node

var all_sauces = {
	"ketchup": preload("res://Resources/ketchup.tres"),
	"bbq": preload("res://Resources/bbq_sauce.tres"),
	"hot_sauce": preload("res://Resources/hot_sauce.tres"),
	"ranch": preload("res://Resources/ranch.tres"),
	"mustard": preload("res://Resources/mustard.tres"),
	"sriracha": preload("res://Resources/sriracha.tres"),
	"worcestershire": preload("res://Resources/worcestershire.tres"),
	"mesozoic_mayo": preload("res://Resources/mesozoic_miracle_whip.tres"),
	"prehistoric_pesto": preload("res://Resources/prehistoric_pesto.tres")
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
