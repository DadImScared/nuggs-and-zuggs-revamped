# Singletons/EffectsManager.gd
extends Node

# EFFECT PRELOADS - Add new effects here when you create them
var burn: StackingEffect = preload("res://Resources/Effects/Burn.tres")
var cold: StackingEffect = preload("res://Resources/Effects/Cold.tres")
# var poison: StackingEffect = preload("res://Resources/Effects/Poison.tres")
# var freeze: StackingEffect = preload("res://Resources/Effects/Freeze.tres")
# var slow: StackingEffect = preload("res://Resources/Effects/Slow.tres")
# var bleed: StackingEffect = preload("res://Resources/Effects/Bleed.tres")

func _ready():
	DebugControl.debug_status("✨ EffectsManager: Effects loaded successfully")
	_validate_effects()

func _validate_effects():
	"""Validate that all effects loaded properly"""
	if burn:
		DebugControl.debug_status("✅ Burn effect loaded")
	else:
		DebugControl.debug_status("❌ Failed to load Burn effect")

# Optional: Debug function to list available effects
func get_available_effects():
	var effects = []
	if burn: effects.append("burn")
	if cold: effects.append("cold")
	# if poison: effects.append("poison")
	# if freeze: effects.append("freeze")
	# etc...
	return effects

func debug_print_effects():
	var effects = get_available_effects()
	DebugControl.debug_status("📋 Available Effects: %s" % str(effects))
