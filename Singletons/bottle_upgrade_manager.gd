extends Node

signal bottle_needs_upgrade(bottle_id: String, sauce_name: String, level: int)

func _ready():
	print("Bottle Upgrade Manager initialized")

func _on_bottle_leveled_up(bottle_id: String, level: int, sauce_name: String):
	print("Bottle Upgrade Manager: %s leveled up to %d" % [sauce_name, level])
	# Emit signal for UI Manager to show upgrade choices
	bottle_needs_upgrade.emit(bottle_id, sauce_name, level)

func apply_upgrade_choice(bottle_id: String, choice_number: int):
	print("Applying upgrade choice %d to bottle %s" % [choice_number, bottle_id])

	# Forward to sauce_holder to apply the upgrade
	var sauce_holder = get_tree().get_first_node_in_group("sauce_holder")
	if sauce_holder and sauce_holder.has_method("apply_upgrade_to_bottle"):
		sauce_holder.apply_upgrade_to_bottle(bottle_id, choice_number)
	else:
		print("Warning: Could not find sauce_holder to apply upgrade!")
