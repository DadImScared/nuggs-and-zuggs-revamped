extends Node

signal bottle_needs_upgrade(bottle_id: String, sauce_name: String, level: int)

# Store references to all bottles for applying upgrades
var bottle_registry: Dictionary = {}

func _ready():
	print("Upgrade Manager initialized")

func register_bottle(bottle: BaseSauceBottle):
	bottle_registry[bottle.bottle_id] = bottle
	# Connect to the bottle's level up signal
	bottle.leveled_up.connect(_on_bottle_leveled_up)
	print("Registered bottle: %s" % bottle.bottle_id)

func clear_registry():
	# Called when starting a new run
	bottle_registry.clear()
	print("Cleared bottle registry for new run")

func _on_bottle_leveled_up(bottle_id: String, level: int, sauce_name: String):
	print("Upgrade Manager: %s leveled up to %d" % [sauce_name, level])
	# Emit signal for UI Manager to show upgrade choices
	bottle_needs_upgrade.emit(bottle_id, sauce_name, level)

func apply_upgrade_choice(bottle_id: String, choice_number: int):
	if not bottle_registry.has(bottle_id):
		print("Warning: Bottle %s not found in registry!" % bottle_id)
		return

	var bottle = bottle_registry[bottle_id]
	var sauce_name = bottle.sauce_data.sauce_name

	print("Applying upgrade choice %d to %s" % [choice_number, sauce_name])

	# Apply the upgrade based on sauce type and choice
	match sauce_name:
		"Ketchup":
			_apply_ketchup_upgrade(bottle, choice_number)
		"Prehistoric Pesto":
			_apply_pesto_upgrade(bottle, choice_number)
		_:
			_apply_generic_upgrade(bottle, choice_number)

func _apply_ketchup_upgrade(bottle: BaseSauceBottle, choice: int):
	match choice:
		1: # Thick & Chunky
			bottle.sauce_data.damage += 5.0
			bottle.chosen_upgrades.append("ketchup_thick")
			print("Applied Thick & Chunky: +5 damage")
		2: # Double Squirt
			bottle.sauce_data.projectile_count += 1
			bottle.chosen_upgrades.append("ketchup_double")
			print("Applied Double Squirt: +1 projectile")
		3: # Fast Food
			bottle.sauce_data.fire_rate += 0.3
			bottle.chosen_upgrades.append("ketchup_fast")
			bottle.update_fire_rate() # Update the timer
			print("Applied Fast Food: +0.3 fire rate")

func _apply_pesto_upgrade(bottle: BaseSauceBottle, choice: int):
	match choice:
		1: # Viral Load
			bottle.sauce_data.effect_chance += 0.3
			bottle.chosen_upgrades.append("pesto_viral")
			print("Applied Viral Load: +30% effect chance")
		2: # Rapid Mutation
			bottle.sauce_data.fire_rate += 0.5
			bottle.chosen_upgrades.append("pesto_rapid")
			bottle.update_fire_rate()
			print("Applied Rapid Mutation: +0.5 fire rate")
		3: # Toxic Herbs
			bottle.sauce_data.damage += 3.0
			bottle.sauce_data.effect_intensity += 1.5
			bottle.chosen_upgrades.append("pesto_toxic")
			print("Applied Toxic Herbs: +3 damage, +1.5 effect intensity")

func _apply_generic_upgrade(bottle: BaseSauceBottle, choice: int):
	match choice:
		1: # More Damage
			bottle.sauce_data.damage += 3.0
			bottle.chosen_upgrades.append("generic_damage")
			print("Applied More Damage: +3 damage")
		2: # Faster Shooting
			bottle.sauce_data.fire_rate += 0.2
			bottle.chosen_upgrades.append("generic_speed")
			bottle.update_fire_rate()
			print("Applied Faster Shooting: +0.2 fire rate")
		3: # Longer Range
			bottle.sauce_data.range += 20.0
			bottle.chosen_upgrades.append("generic_range")
			bottle.update_detection_range()
			print("Applied Longer Range: +20 range")
