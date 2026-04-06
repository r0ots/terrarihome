extends Control

signal closed
signal node_unlocked(id: StringName)

const COL_LOCKED := Color(0.25, 0.20, 0.15)
const COL_AFFORDABLE := Color(0.90, 0.75, 0.25)
const COL_UNLOCKED := Color(0.35, 0.72, 0.30)
const COL_BG := Color(0.06, 0.05, 0.03, 0.94)

var node_panels: Dictionary = {}
var lines_container: Node2D

@onready var gm := GameManager


func _ready() -> void:
	_build_ui()
	refresh()


func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var vroot: VBoxContainer = VBoxContainer.new()
	vroot.set_anchors_preset(PRESET_FULL_RECT)
	vroot.add_theme_constant_override("separation", 12)
	add_child(vroot)

	var header: HBoxContainer = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 24)
	vroot.add_child(header)

	var title: Label = Label.new()
	title.text = "Arbre de Prestige"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85))
	header.add_child(title)

	var pp_label: Label = Label.new()
	pp_label.name = "PPLabel"
	pp_label.add_theme_font_size_override("font_size", 22)
	pp_label.add_theme_color_override("font_color", Color(0.92, 0.75, 0.25))
	header.add_child(pp_label)

	var close_btn: Button = Button.new()
	close_btn.text = "X"
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	lines_container = Node2D.new()
	lines_container.z_index = -1
	add_child(lines_container)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vroot.add_child(scroll)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(hbox)

	for branch: String in PrestigeDatabase.BRANCHES:
		var col: VBoxContainer = VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 8)
		hbox.add_child(col)

		var branch_label: Label = Label.new()
		branch_label.text = PrestigeDatabase.BRANCH_NAMES.get(branch, branch)
		branch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		branch_label.add_theme_font_size_override("font_size", 18)
		col.add_child(branch_label)

		for node_data: PrestigeNode in PrestigeDatabase.get_branch(branch):
			var panel: PanelContainer = _make_node_panel(node_data)
			col.add_child(panel)
			node_panels[node_data.id] = panel


func _make_node_panel(data: PrestigeNode) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 60)
	panel.name = data.id

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	var name_label: Label = Label.new()
	name_label.text = data.name_fr
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	vb.add_child(name_label)

	var cost_label: Label = Label.new()
	cost_label.text = "Cout: %d PP" % data.cost
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.name = "CostLabel"
	vb.add_child(cost_label)

	panel.gui_input.connect(_on_node_input.bind(data.id))
	return panel


func _on_node_input(event: InputEvent, id: StringName) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_unlock(id)


func _try_unlock(id: StringName) -> void:
	var data: PrestigeNode = PrestigeDatabase.get_node(id)
	if not data:
		return
	if not PrestigeDatabase.can_unlock(id, gm.unlocked_upgrades):
		return
	if gm.prestige_points < data.cost:
		return
	gm.prestige_points -= data.cost
	gm.unlock_upgrade(id)
	_apply_effects(data.effects)
	node_unlocked.emit(id)
	refresh()


func _apply_effects(effects: Array[StringName]) -> void:
	for effect: StringName in effects:
		match effect:
			&"hand_size_plus1":
				gm.hand_size_max += 1
			&"starter_extra_card":
				var all_plants: Array = PlantDatabase.get_all().keys()
				gm.starting_cards.append(all_plants[randi() % all_plants.size()])
			_:
				pass


func refresh() -> void:
	var pp_label: Label = find_child("PPLabel", true, false)
	if pp_label:
		pp_label.text = "PP: %d" % gm.prestige_points

	for id: StringName in node_panels:
		var panel: PanelContainer = node_panels[id]
		var data: PrestigeNode = PrestigeDatabase.get_node(id)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.set_corner_radius_all(6)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 4
		style.content_margin_bottom = 4

		if id in gm.unlocked_upgrades:
			style.bg_color = COL_UNLOCKED
		elif PrestigeDatabase.can_unlock(id, gm.unlocked_upgrades) and gm.prestige_points >= data.cost:
			style.bg_color = Color(0.12, 0.09, 0.06)
			style.border_color = COL_AFFORDABLE
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
		else:
			style.bg_color = COL_LOCKED

		panel.add_theme_stylebox_override("panel", style)

	_draw_lines()


func _draw_lines() -> void:
	for child: Node in lines_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	for id: StringName in node_panels:
		var data: PrestigeNode = PrestigeDatabase.get_node(id)
		for prereq: StringName in data.prerequisites:
			if prereq == &"ALL_OTHER_BRANCHES":
				continue
			if prereq not in node_panels:
				continue
			var from_panel: PanelContainer = node_panels[prereq]
			var to_panel: PanelContainer = node_panels[id]
			var from_pos: Vector2 = from_panel.global_position + from_panel.size / 2
			var to_pos: Vector2 = to_panel.global_position + to_panel.size / 2

			var line: Line2D = Line2D.new()
			line.points = [from_pos - global_position, to_pos - global_position]
			line.width = 2.0

			if id in gm.unlocked_upgrades and prereq in gm.unlocked_upgrades:
				line.default_color = COL_UNLOCKED
			else:
				line.default_color = Color(0.5, 0.5, 0.5, 0.5)

			lines_container.add_child(line)


func _on_close() -> void:
	closed.emit()
	hide()
