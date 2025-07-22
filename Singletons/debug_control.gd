extends Node

# Global debug control - change these to enable/disable debug categories
const ENABLE_COMBAT_DEBUG = true     # Damage, hits, crits
const ENABLE_TALENT_DEBUG = true     # Talent application/removal
const ENABLE_STATUS_DEBUG = true     # Status effects, stacks
const ENABLE_UI_DEBUG = true         # UI interactions, menus
const ENABLE_PROJECTILE_DEBUG = true # Projectile behavior
const ENABLE_ENEMY_DEBUG = true      # Enemy behavior, death
const ENABLE_SYSTEM_DEBUG = true     # Core system operations

# Master debug switch - if false, disables ALL debug output
const MASTER_DEBUG_ENABLED = true    # Set to false for production builds

# Quick debug functions for common patterns
static func debug_print(category: String, message: String):
	"""#print debug message if category is enabled"""
	if not MASTER_DEBUG_ENABLED:
		return

	var should_print = false
	match category:
		"combat":
			should_print = ENABLE_COMBAT_DEBUG
		"talent":
			should_print = ENABLE_TALENT_DEBUG
		"status":
			should_print = ENABLE_STATUS_DEBUG
		"ui":
			should_print = ENABLE_UI_DEBUG
		"projectile":
			should_print = ENABLE_PROJECTILE_DEBUG
		"enemy":
			should_print = ENABLE_ENEMY_DEBUG
		"system":
			should_print = ENABLE_SYSTEM_DEBUG
		_:
			should_print = true  # Unknown categories #print if master is enabled

	if should_print:
		print("[%s] %s" % [category.to_upper(), message])

static func is_debug_enabled(category: String = "") -> bool:
	"""Check if debug is enabled for a category"""
	if not MASTER_DEBUG_ENABLED:
		return false

	match category:
		"combat": return ENABLE_COMBAT_DEBUG
		"talent": return ENABLE_TALENT_DEBUG
		"status": return ENABLE_STATUS_DEBUG
		"ui": return ENABLE_UI_DEBUG
		"projectile": return ENABLE_PROJECTILE_DEBUG
		"enemy": return ENABLE_ENEMY_DEBUG
		"system": return ENABLE_SYSTEM_DEBUG
		"": return true  # No category specified, return master state
		_: return true  # Unknown category, default to enabled if master is on

# Convenience functions for common debug patterns
static func debug_combat(message: String):
	debug_print("combat", message)

static func debug_talent(message: String):
	debug_print("talent", message)

static func debug_status(message: String):
	debug_print("status", message)

static func debug_ui(message: String):
	debug_print("ui", message)

static func debug_projectile(message: String):
	debug_print("projectile", message)

static func debug_enemy(message: String):
	debug_print("enemy", message)

static func debug_system(message: String):
	debug_print("system", message)
