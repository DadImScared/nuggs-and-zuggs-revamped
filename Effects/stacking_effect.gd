# Effects/StackingEffect.gd
class_name StackingEffect
extends Resource

# BASE PARAMETERS - Edit these in .tres files for tuning
@export var effect_name: String = "generic_effect"
@export var base_duration: float = 3.0
@export var base_tick_interval: float = 0.5
@export var base_tick_damage: float = 5.0
@export var base_max_stacks: int = 8
@export var base_stack_value: float = 1.0
@export var base_color: Color = Color.WHITE

# TALENT MULTIPLIERS - Modified by talents globally
var duration_multiplier: float = 1.0
var tick_interval_multiplier: float = 1.0
var tick_damage_multiplier: float = 1.0
var max_stacks_bonus: int = 0
var damage_multiplier: float = 1.0

# TALENT APPLICATION METHODS
func apply_duration_buff(multiplier: float, talent_name: String = ""):
	duration_multiplier *= multiplier
	DebugControl.debug_status("✨ %s: %s duration now ×%.1f" % [talent_name, effect_name, duration_multiplier])

func apply_damage_buff(multiplier: float, talent_name: String = ""):
	damage_multiplier *= multiplier
	DebugControl.debug_status("✨ %s: %s damage now ×%.1f" % [talent_name, effect_name, damage_multiplier])

func apply_stacks_buff(bonus: int, talent_name: String = ""):
	max_stacks_bonus += bonus
	DebugControl.debug_status("✨ %s: %s max stacks now %d" % [talent_name, effect_name, get_max_stacks()])

func apply_slow_burn():
	duration_multiplier *= 1.5
	tick_interval_multiplier *= 1.3
	DebugControl.debug_status("🔥 Slow Burn: %s lasts 50% longer" % effect_name)

# GET FINAL VALUES - After all talent buffs
func get_duration() -> float:
	return base_duration * duration_multiplier

func get_tick_interval() -> float:
	return base_tick_interval * tick_interval_multiplier

func get_tick_damage() -> float:
	return base_tick_damage * tick_damage_multiplier * damage_multiplier

func get_max_stacks() -> int:
	return base_max_stacks + max_stacks_bonus

func get_stack_value() -> float:
	return base_stack_value

func get_color() -> Color:
	return base_color

# UNIVERSAL APPLICATION METHOD
func apply_to_enemy(enemy: Node2D, source_bottle: Node, stacks: int = 1):
	if not enemy or not is_instance_valid(enemy):
		return

	var bottle_id = source_bottle.bottle_id if source_bottle else "unknown"

	# Apply all stacks at once
	enemy.apply_stacking_effect(
		effect_name,
		get_stack_value() * stacks,
		get_max_stacks(),
		bottle_id,
		get_duration(),
		{
			"immediate_effect": _create_immediate_effect(enemy),
			"tick_effect": _create_tick_effect(enemy, source_bottle),
			"visual_cleanup": _create_visual_cleanup(enemy),
			"tick_interval": get_tick_interval()
		}
	)

	DebugControl.debug_status("✨ Applied %d %s stacks (%.1fs, %.1f dmg)" % [stacks, effect_name, get_duration(), get_tick_damage()])

# EFFECT CALLBACKS
func _create_immediate_effect(enemy: Node2D) -> Callable:
	return func():
		if not is_instance_valid(enemy):
			return
		_create_or_update_visual(enemy)

func _create_tick_effect(enemy: Node2D, source_bottle: Node) -> Callable:
	return func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count(effect_name)
		var damage = get_tick_damage() * total_stacks
		var bottle_id = source_bottle.bottle_id if source_bottle else effect_name

		enemy.take_damage_from_source(damage, bottle_id)
		_create_particle(enemy.global_position)
		DebugControl.debug_combat("✨ %s: %.1f damage (%d stacks)" % [effect_name.capitalize(), damage, total_stacks])

func _create_visual_cleanup(enemy: Node2D) -> Callable:
	return func():
		var overlay = enemy.get_node_or_null(effect_name.capitalize() + "Overlay")
		if overlay:
			overlay.queue_free()

# VISUAL EFFECTS
func _create_or_update_visual(enemy: Node2D):
	var overlay_name = effect_name.capitalize() + "Overlay"
	var overlay = enemy.get_node_or_null(overlay_name)

	if not overlay:
		overlay = ColorRect.new()
		overlay.name = overlay_name
		overlay.size = Vector2(28, 28)
		overlay.position = Vector2(-14, -14)
		overlay.color = get_color()
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		enemy.add_child(overlay)

		var tween = overlay.create_tween()
		tween.set_loops()
		tween.tween_property(overlay, "modulate:a", 0.4, 0.3)
		tween.tween_property(overlay, "modulate:a", 0.8, 0.3)

	# Update based on stacks
	var stacks = enemy.get_total_stack_count(effect_name)
	var intensity = min(1.0, 0.4 + (stacks * 0.1))
	var scale = 1.0 + (stacks * 0.05)
	overlay.modulate = Color(get_color().r, get_color().g, get_color().b, intensity)
	overlay.scale = Vector2(scale, scale)

func _create_particle(position: Vector2):
	var particle = ColorRect.new()
	particle.size = Vector2(6, 6)
	particle.color = get_color()
	particle.position = position + Vector2(randf_range(-8, 8), randf_range(-8, 8))

	var scene = Engine.get_main_loop().current_scene
	scene.add_child(particle)

	var tween = particle.create_tween()
	tween.parallel().tween_property(particle, "position", particle.position + Vector2(0, -30), 0.8)
	tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
	tween.tween_callback(particle.queue_free)
