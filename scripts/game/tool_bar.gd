class_name ToolBar extends HBoxContainer

signal tool_selected(tool_id: StringName)
signal tool_deselected

const TOOL_NAMES := {
	&"shovel": "Pelle",
	&"fertilizer": "Engrais",
	&"watering_can": "Arrosoir",
}

var selected_tool: StringName = &""


func refresh() -> void:
	for c: Node in get_children():
		c.queue_free()
	selected_tool = &""
	visible = GameManager.is_upgrade_unlocked(&"unlock_tool_belt")
	if not visible:
		return
	for i: int in GameManager.tool_inventory.size():
		var tid: StringName = GameManager.tool_inventory[i]
		add_child(_create_tool_button(i, tid))
	if GameManager.tool_inventory.is_empty():
		var lbl := Label.new()
		lbl.text = "Pas d'outils"
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35))
		add_child(lbl)


func deselect() -> void:
	if selected_tool != &"":
		selected_tool = &""
		_update_highlights()
		tool_deselected.emit()


func _create_tool_button(index: int, tool_id: StringName) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 50)

	var lbl := Label.new()
	lbl.text = TOOL_NAMES.get(tool_id, str(tool_id))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85))
	panel.add_child(lbl)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if selected_tool == tool_id:
				deselect()
			else:
				selected_tool = tool_id
				_update_highlights()
				tool_selected.emit(tool_id)
	)

	_apply_style(panel, false)
	return panel


func _update_highlights() -> void:
	var idx: int = 0
	for child: Node in get_children():
		if child is PanelContainer:
			var is_sel: bool = idx < GameManager.tool_inventory.size() and GameManager.tool_inventory[idx] == selected_tool
			_apply_style(child as PanelContainer, is_sel)
			idx += 1


func _apply_style(panel: PanelContainer, selected: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.18, 0.12) if selected else Color(0.14, 0.11, 0.08)
	sb.border_color = Color(0.4, 0.8, 0.3) if selected else Color(0.45, 0.40, 0.28)
	sb.set_border_width_all(3 if selected else 1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", sb)
