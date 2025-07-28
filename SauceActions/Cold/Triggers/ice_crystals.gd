# SauceActions/IceCrystals/Triggers/ice_crystals.gd
class_name IceCrystalsTrigger
extends BaseTriggerAction

const ICE_CRYSTAL_SCENE = preload("res://Effects/IceCrystal/ice_crystal.tscn")

func _init() -> void:
	trigger_name = "ice_crystals"
	trigger_description = "20% chance to create ice spikes when cold is applied"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var enemy = data.effect_parameters.hit_enemy
	var projectile = data.effect_parameters.get("projectile", null)

	if not enemy or not is_instance_valid(enemy):
		print("⚠️ Ice Crystals: No valid enemy to spawn crystals around")
		return

	# Get parameters from trigger (processor strips _multiplier suffix)
	var spike_count = data.effect_parameters.get("spike_count", 3)
	var damage = data.effect_parameters.get("damage", bottle.effective_damage * 0.6)  # Fixed!
	var spike_range = data.effect_parameters.get("spike_range", 40.0)

	print("🧊 Ice Crystals triggered! Spawning %d ice spikes around enemy" % spike_count)

	# DEFER the spawning to avoid physics timing issues
	call_deferred("_spawn_ice_crystals", enemy.global_position, spike_count, damage, bottle.bottle_id, spike_range)

func _spawn_ice_crystals(center_position: Vector2, count: int, damage: float, bottle_id: String, range_radius: float):
	"""Spawn ice crystals in a pattern around the target position"""

	for i in range(count):
		# Create positions in a rough circle around the enemy
		var angle = (TAU / count) * i + randf_range(-0.3, 0.3)  # Add some randomness
		var distance = randf_range(range_radius * 0.6, range_radius)  # Vary the distance
		var crystal_position = center_position + Vector2.from_angle(angle) * distance

		# Create the ice crystal
		var ice_crystal = ICE_CRYSTAL_SCENE.instantiate()

		# Add to scene
		Engine.get_main_loop().current_scene.add_child(ice_crystal)
		ice_crystal.global_position = crystal_position

		# Setup the crystal
		ice_crystal.setup_crystal(damage, bottle_id, Color.CYAN)

		# Connect shatter signal for potential chain effects
		ice_crystal.crystal_shattered.connect(_on_crystal_shattered.bind(crystal_position))

		print("🧊 Spawned ice crystal at %s with %.1f damage" % [crystal_position, damage])

func _on_crystal_shattered(position: Vector2):
	"""Handle when an ice crystal shatters - could trigger additional effects"""
	# Future enhancement: Could spawn smaller crystals, create freeze area, etc.
	print("💎 Ice crystal shattered at %s" % position)
