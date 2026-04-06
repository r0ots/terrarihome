class_name HandView extends HBoxContainer

signal card_selected(index: int)
signal card_deselected

var selected_index: int = -1


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
		sb.bg_color = Color(0.15, 0.18, 0.15)
		sb.border_color = Color.GOLD if i == selected_index else Color(0.3, 0.3, 0.3)
		sb.set_border_width_all(3 if i == selected_index else 1)
		sb.set_corner_radius_all(6)
		sb.set_content_margin_all(6)
		panel.add_theme_stylebox_override("panel", sb)


func _create_card(index: int, plant_id: StringName) -> PanelContainer:
	var data: PlantData = PlantDatabase.get_plant(plant_id)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(100, 130)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var name_label: Label = Label.new()
	name_label.text = data.name_fr if data else plant_id
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)

	var shape_preview: ShapePreview = ShapePreview.new()
	shape_preview.plant_id = plant_id
	shape_preview.custom_minimum_size = Vector2(80, 60)
	vbox.add_child(shape_preview)

	var types_label: Label = Label.new()
	var type_strs: PackedStringArray = []
	if data:
		for t: StringName in data.types:
			type_strs.append(str(t))
	types_label.text = " ".join(type_strs)
	types_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	types_label.add_theme_font_size_override("font_size", 10)
	types_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(types_label)

	panel.add_child(vbox)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if selected_index == index:
				deselect()
			else:
				select_card(index)
	)

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.18, 0.15)
	sb.border_color = Color(0.3, 0.3, 0.3)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", sb)

	return panel


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
