# EnhancedTriggerData.gd
class_name EnhancedTriggerData
extends Resource

var trigger_name: String
var trigger_type: TriggerEffectResource.TriggerType
var trigger_condition: Dictionary = {}
var effect_parameters: Dictionary = {}

# Track enhancement sources for each parameter
var enhancement_sources: Dictionary = {}

func _init(base_data: TriggerEffectResource):
	trigger_name = base_data.trigger_name
	trigger_type = base_data.trigger_type
	trigger_condition = base_data.trigger_condition.duplicate()
	effect_parameters = base_data.effect_parameters.duplicate()

	# Initialize source tracking for base values
	for key in trigger_condition.keys():
		enhancement_sources[key] = {
			"base_value": trigger_condition[key],
			"final_value": trigger_condition[key],
			"sources": ["Base " + trigger_name.capitalize()]
		}

	for key in effect_parameters.keys():
		enhancement_sources[key] = {
			"base_value": effect_parameters[key],
			"final_value": effect_parameters[key],
			"sources": ["Base " + trigger_name.capitalize()]
		}

func add_enhancement_source(param_key: String, enhancement_name: String, operation: String, value, final_result):
	"""Track which talent contributed to which parameter"""
	if not enhancement_sources.has(param_key):
		enhancement_sources[param_key] = {
			"base_value": 0,
			"final_value": final_result,
			"sources": []
		}

	enhancement_sources[param_key]["final_value"] = final_result

	var operation_text = ""
	match operation:
		"multiply": operation_text = "×%.2f" % value
		"add": operation_text = "+%.2f" % value
		"set": operation_text = "→%.2f" % value

	enhancement_sources[param_key]["sources"].append("%s (%s)" % [enhancement_name, operation_text])

func get_parameter_info(param_key: String) -> Dictionary:
	"""Get detailed info about a parameter including all sources"""
	return enhancement_sources.get(param_key, {})

func get_tooltip_text() -> String:
	"""Generate tooltip showing all enhancements"""
	var tooltip = "=== %s ENHANCEMENTS ===\n" % trigger_name.to_upper()

	for param_key in enhancement_sources.keys():
		var info = enhancement_sources[param_key]
		tooltip += "\n🔧 %s: %.2f\n" % [param_key.capitalize(), info["final_value"]]

		for source in info["sources"]:
			tooltip += "  • %s\n" % source

	return tooltip
