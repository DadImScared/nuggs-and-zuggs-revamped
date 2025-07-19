
class_name SauceDatabase
extends RefCounted

# Static sauce registry
static var _all_sauces = {
	"ketchup": preload("res://Resources/ketchup.tres"),
	"bbq": preload("res://Resources/bbq_sauce.tres"),
	"hot_sauce": preload("res://Resources/hot_sauce.tres"),
	"ranch": preload("res://Resources/ranch.tres"),
	"mustard": preload("res://Resources/mustard.tres"),
	"sriracha": preload("res://Resources/sriracha.tres"),
	"worcestershire": preload("res://Resources/worcestershire.tres"),
	"mesozoic_mayo": preload("res://Resources/mesozoic_miracle_whip.tres"),
	"prehistoric_pesto": preload("res://Resources/prehistoric_pesto.tres"),
	"jurasic_jalapeno": preload("res://Resources/jurassic_jalapeno.tres"),
	"archaean_apple_butter": preload("res://Resources/archaean_apple_butter.tres")
}

# Get sauce by name - static method
static func get_sauce(name: String) -> BaseSauceResource:
	return _all_sauces.get(name)

# Get random sauces for level up - static method
static func get_random_sauces(num: int = 3) -> Array[BaseSauceResource]:
	var sauce_names = _all_sauces.keys()
	sauce_names.shuffle()
	var chosen = sauce_names.slice(0, num)
	var sauces: Array[BaseSauceResource] = []
	for name in chosen:
		sauces.append(_all_sauces[name])
	return sauces

# Get all sauce names - static method
static func get_all_sauce_names() -> Array[String]:
	return _all_sauces.keys()

# Get all sauces - static method
static func get_all_sauces() -> Dictionary:
	return _all_sauces.duplicate()

# Check if sauce exists - static method
static func has_sauce(name: String) -> bool:
	return _all_sauces.has(name)

# Register new sauce (for mods/expansion) - static method
static func register_sauce(name: String, sauce_resource: BaseSauceResource):
	_all_sauces[name] = sauce_resource
	print("Registered new sauce: %s" % name)
