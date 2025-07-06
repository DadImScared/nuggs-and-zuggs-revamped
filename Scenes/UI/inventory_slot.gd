class_name InventorySlot
extends AspectRatioContainer

var slot_type = "inventory"
var slot_index = 0
var sauce_bottle = null


var is_dragging = false
var drag_preview = null

@onready var slot_frame = $SlotFrame
@onready var sauce_icon = $SlotFrame/ColorRect
const DRAG_PREVIEW_SCENE = preload("res://Scenes/UI/drag_preview.tscn")

func _ready():
	sauce_icon.set_drag_forwarding(get_drag_data, can_drop_data, drop_data)
	if slot_type == "equipped":
		sauce_bottle = InventoryManager.equipped.get(slot_index)
	else:
		sauce_bottle = InventoryManager.storage.get(slot_index)
	
	update_visual()

func get_drag_data(at_position):
	if sauce_bottle == null:
		return null
	
	set_drag_preview(create_drag_preview())
	return SlotData.new(self, sauce_bottle, slot_type, slot_index)

func can_drop_data(at_position, data):
#	only allow movement from equipped to inventory and back
	if slot_type == "equipped":
		return data["slot_type"] == "inventory"
	
	if slot_type == "inventory":
		return data["slot_type"] == "equipped"
	return data is SlotData and slot_type == "inventory"

func drop_data(at_position, data):
	InventoryManager.move_sauce(data, SlotData.new(self, sauce_bottle, slot_type, slot_index))
	data["slot"].sauce_bottle = sauce_bottle
	sauce_bottle = data["sauce_bottle"]
	data["slot"].update_visual()
	update_visual()
	
	

func create_drag_preview():
	var _drag_preview = DRAG_PREVIEW_SCENE.instantiate()
	_drag_preview.modulate = sauce_bottle.sauce_color
	return _drag_preview

func update_visual():
	if sauce_bottle:
		sauce_icon.modulate = sauce_bottle.sauce_color
	else:
		sauce_icon.modulate = Color(0.5, 0.5, 0.5, 0.3)
