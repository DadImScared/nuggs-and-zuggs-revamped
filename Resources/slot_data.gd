class_name SlotData
extends Resource

var slot: Node
var sauce_bottle: BaseSauceResource
@export var slot_type: String
@export var slot_index: int

func _init(p_slot = null, p_sauce_bottle = null, p_slot_type = "", p_slot_index = 0):
	slot = p_slot
	sauce_bottle = p_sauce_bottle
	slot_type = p_slot_type
	slot_index = p_slot_index
