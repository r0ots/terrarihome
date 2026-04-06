class_name HandView extends HBoxContainer

signal card_selected(index: int)
signal card_deselected

var selected_index: int = -1
var _info_popup: PanelContainer = null


func refresh(hand: Array[StringName]) -> void:
	for c: Node in get_children():
		c.queue_free()
	selected_index = -1
	for i: int in hand.size():
		add_child(_create_card(i, hand[i]))


func select_card(index: int) -> void:
	selected_index = index
	_update_highlights()
	card_selected.emit(index)


func deselect() -> void:
	selected_index = -1
	_update_highlights()
	card_deselected.emit()


func _update_highlights() -> void:
	for i: int in get_child_count():
		var panel: PanelContainer = get_child(i)
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.14, 0.09)
		sb.border_color = Color(0.92, 0.75, 0.25) if i == selected_index else Color(0.55, 0.42, 0.22)
		sb.set_border_width_all(3 if i == selected_index else 1)
		sb.set_corner_radius_all(6)
		sb.set_content_margin_all(6)
		panel.add_theme_stylebox_override("panel", sb)


func _show_info(panel: PanelContainer, data: PlantData) -> void:
	_hide_info()
	_info_popup = PanelContainer.new()
	_info_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.07, 0.04, 0.95)
	sb.border_color = Color(0.55, 0.42, 0.22)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	_info_popup.add_theme_stylebox_override("panel", sb)

	var label: Label = Label.new()
	label.text = _build_description(data)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85))
	_info_popup.add_child(label)

	# Position above the card
	var canvas: CanvasLayer = get_parent() as CanvasLayer
	if canvas:
		canvas.add_child(_info_popup)
	else:
		get_tree().root.add_child(_info_popup)

	await get_tree().process_frame
	var card_rect: Rect2 = panel.get_global_rect()
	_info_popup.position = Vector2(
		card_rect.position.x + card_rect.size.x / 2 - _info_popup.size.x / 2,
		card_rect.position.y - _info_popup.size.y - 8
	)


func _hide_info() -> void:
	if _info_popup and is_instance_valid(_info_popup):
		_info_popup.queue_free()
		_info_popup = null


func _create_card(index: int, plant_id: StringName) -> PanelContainer:
	var data: PlantData = PlantDatabase.get_plant(plant_id)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 140)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS

	var name_label: Label = Label.new()
	name_label.text = data.name_fr if data else plant_id
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85))
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(name_label)

	var shape_preview: ShapePreview = ShapePreview.new()
	shape_preview.plant_id = plant_id
	shape_preview.custom_minimum_size = Vector2(80, 60)
	shape_preview.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(shape_preview)

	var types_label: Label = Label.new()
	var type_strs: PackedStringArray = []
	if data:
		for t: StringName in data.types:
			type_strs.append(str(t))
	types_label.text = " ".join(type_strs)
	types_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	types_label.add_theme_font_size_override("font_size", 10)
	types_label.add_theme_color_override("font_color", Color(0.72, 0.65, 0.52))
	types_label.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(types_label)

	panel.add_child(vbox)

	panel.mouse_entered.connect(_show_info.bind(panel, data))
	panel.mouse_exited.connect(_hide_info)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if selected_index == index:
				deselect()
			else:
				select_card(index)
	)

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.14, 0.09)
	sb.border_color = Color(0.55, 0.42, 0.22)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", sb)

	return panel


static func _build_description(data: PlantData) -> String:
	var lines: PackedStringArray = [data.name_fr]
	var types_str: String = ", ".join(data.types.map(func(t: StringName) -> String: return str(t).capitalize()))
	lines.append("Types: %s" % types_str)
	lines.append("Taille: %d cases" % data.shape.size())
	lines.append("")
	match data.combo_type:
		&"flat":
			lines.append("+%d pts au placement" % data.flat_value)
		&"per_adjacent_type":
			var targets: String = " ou ".join(data.combo_targets.map(func(t: StringName) -> String: return str(t).capitalize()))
			lines.append("+1 pt par %s adjacent (par case)" % targets)
		&"per_adjacent_any":
			lines.append("+1 pt par case occupee adjacente")
		&"per_adjacent_empty":
			lines.append("+1 pt par case vide adjacente")
		&"modifier_x2":
			var targets: String = " ou ".join(data.combo_targets.map(func(t: StringName) -> String: return str(t).capitalize()))
			lines.append("x2 aux points futurs des %s adjacents" % targets)
		&"modifier_plus1":
			var targets: String = " ou ".join(data.combo_targets.map(func(t: StringName) -> String: return str(t).capitalize()))
			lines.append("+1 aux gains futurs des %s adjacents" % targets)
	lines.append("")
	if data.scoring_mode == &"on_place_only":
		lines.append("Au placement uniquement")
	else:
		lines.append("Bidirectionnel")
	lines.append("Compost: %d" % data.compost_value)
	return "\n".join(lines)


class ShapePreview extends Control:
	var plant_id: StringName = &""
	const MINI_CELL := 10
	const TYPE_COLORS: Dictionary = {
		&"legume": Color("#4CAF50"),
		&"plante": Color("#8BC34A"),
		&"champi": Color("#795548"),
		&"racine": Color("#FF9800"),
	}

	func _draw() -> void:
		var data: PlantData = PlantDatabase.get_plant(plant_id)
		if not data:
			return
		var col: Color = TYPE_COLORS.get(data.types[0], Color.WHITE) if data.types.size() > 0 else Color.WHITE

		var min_x: int = 999
		var min_y: int = 999
		var max_x: int = -999
		var max_y: int = -999
		for s: Vector2i in data.shape:
			min_x = mini(min_x, s.x)
			min_y = mini(min_y, s.y)
			max_x = maxi(max_x, s.x)
			max_y = maxi(max_y, s.y)
		var shape_w: int = (max_x - min_x + 1) * MINI_CELL
		var shape_h: int = (max_y - min_y + 1) * MINI_CELL
		var offset: Vector2 = Vector2((size.x - shape_w) / 2, (size.y - shape_h) / 2)

		for s: Vector2i in data.shape:
			var r: Rect2 = Rect2(offset.x + (s.x - min_x) * MINI_CELL, offset.y + (s.y - min_y) * MINI_CELL, MINI_CELL - 1, MINI_CELL - 1)
			draw_rect(r, col)
