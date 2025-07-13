class_name InventorySlot
extends AspectRatioContainer

signal slot_selected(slot: InventorySlot)
signal slot_drag_started(slot: InventorySlot)

var slot_type = "inventory"
var slot_index = 0
var sauce_bottle = null
var is_selected = false

@onready var slot_frame = $SlotFrame
@onready var background = $SlotFrame/Background
@onready var selection_border = $SlotFrame/SelectionBorder
@onready var sauce_icon = $SlotFrame/SauceIcon
@onready var level_label = $SlotFrame/LevelLabel

const DRAG_PREVIEW_SCENE = preload("res://Scenes/UI/drag_preview.tscn")
const BOTTLE_TEXTURE = preload("res://Assets/Sprites/Bottles/basebottle.png")

func _ready():
	# First test - let's see if SlotFrame receives ANY mouse events
	slot_frame.gui_input.connect(_on_slot_frame_input)

	# Try setting up drag forwarding
	slot_frame.set_drag_forwarding(get_drag_data, can_drop_data, drop_data)

	# Initialize bottle data
	if slot_type == "equipped":
		sauce_bottle = InventoryManager.equipped.get(slot_index)
	else:
		sauce_bottle = InventoryManager.storage.get(slot_index)

	print("InventorySlot _ready - slot_type: %s, index: %d, bottle: %s" % [slot_type, slot_index, sauce_bottle])
	update_visual()

func _on_slot_frame_input(event: InputEvent):
	print("SlotFrame received input: ", event)  # This should print for ANY mouse input
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and sauce_bottle != null:
			print("Emitting slot_selected")
			slot_selected.emit(self)
		if event.pressed:
			print("Mouse pressed on SlotFrame - sauce_bottle: ", sauce_bottle)

# Drag and drop methods - all handled by SlotFrame
func get_drag_data(at_position):
	if sauce_bottle == null:
		return null

	# Emit signal that drag started - this will clear selection
	slot_drag_started.emit(self)

	var preview = create_drag_preview()
	set_drag_preview(preview)
	return SlotData.new(self, sauce_bottle, slot_type, slot_index)

func can_drop_data(at_position, data):
	print("Can drop data on SlotFrame")
	print("data: ", data)
	print("data is SlotData: ", data is SlotData)

	if not data is SlotData:
		print("not SlotData")
		return false

	print("source slot_type: ", data["slot_type"])
	print("target slot_type: ", slot_type)

	if slot_type == "equipped":
		var result = data["slot_type"] == "inventory"
		print("equipped target, result: ", result)
		return result
	elif slot_type == "inventory":
		var result = data["slot_type"] == "equipped"
		print("inventory target, result: ", result)
		return result

	return false

func drop_data(at_position, data):
	print("drop_data called on SlotFrame")
	InventoryManager.move_sauce(data, SlotData.new(self, sauce_bottle, slot_type, slot_index))
	data["slot"].sauce_bottle = sauce_bottle
	sauce_bottle = data["sauce_bottle"]
	data["slot"].update_visual()
	update_visual()

func set_selected(selected: bool):
	is_selected = selected
	update_selection_visual()

func update_selection_visual():
	if selection_border:
		if is_selected:
			selection_border.color = Color.html("#FFFF00CC")  # Yellow border with transparency
		else:
			selection_border.color = Color.html("#FFFF0000")  # Transparent

func create_drag_preview():
	var preview = TextureRect.new()
	preview.texture = BOTTLE_TEXTURE
	preview.custom_minimum_size = Vector2(40, 40)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED

	if sauce_bottle and sauce_bottle.sauce_data:
		preview.modulate = sauce_bottle.sauce_data.sauce_color

	return preview

func update_visual():
	print("update_visual - sauce_bottle: ", sauce_bottle)
	if sauce_bottle:
		print("sauce_data: ", sauce_bottle.sauce_data)
		if sauce_bottle.sauce_data:
			print("sauce_name: ", sauce_bottle.sauce_data.sauce_name)

	# Check if all UI elements exist
	if not sauce_icon or not level_label or not background or not selection_border:
		print("ERROR: Missing UI elements!")
		return

	if sauce_bottle and sauce_bottle.sauce_data:
		# Show the bottle sprite with sauce color
		sauce_icon.texture = BOTTLE_TEXTURE
		sauce_icon.modulate = sauce_bottle.sauce_data.sauce_color
		sauce_icon.visible = true

		# Show level if bottle is leveled up
		if sauce_bottle.current_level > 1:
			level_label.text = str(sauce_bottle.current_level)
			level_label.visible = true
		else:
			level_label.visible = false

		# Update background to show slot is occupied
		background.color = Color.html("#4D4D4DCC")  # Lighter gray for occupied slots
	else:
		# Empty slot - keep TextureRect visible but transparent
		sauce_icon.texture = BOTTLE_TEXTURE
		sauce_icon.modulate = Color.TRANSPARENT  # Transparent instead of hiding
		sauce_icon.visible = true  # Keep visible so it doesn't interfere with input
		level_label.visible = false
		background.color = Color.html("#333333CC")  # Dark gray for empty slots

	# Update selection visual
	update_selection_visual()
