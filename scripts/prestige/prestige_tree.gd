extends Control

signal closed
signal node_unlocked(id: StringName)

const COL_LOCKED := Color(0.25, 0.20, 0.15)
const COL_AFFORDABLE := Color(0.90, 0.75, 0.25)
const COL_UNLOCKED := Color(0.35, 0.72, 0.30)
const COL_BG := Color(0.06, 0.05, 0.03, 0.94)
const COL_LINE_DONE := Color(0.35, 0.72, 0.30, 0.8)
const COL_LINE_PENDING := Color(0.5, 0.4, 0.2, 0.6)
const COL_CREAM := Color(0.96, 0.93, 0.85)
const COL_TAN := Color(0.72, 0.65, 0.52)

var node_panels: Dictionary = {}
var lines_container: Control

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
	vroot.add_theme_constant_override("separation", 8)
	add_child(vroot)

	# Header
	var header: HBoxContainer = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 24)
	vroot.add_child(header)

	var title: Label = Label.new()
	title.text = "Arbre de Prestige"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", COL_CREAM)
	header.add_child(title)

	var pp_label: Label = Label.new()
	pp_label.name = "PPLabel"
	pp_label.add_theme_font_size_override("font_size", 20)
	pp_label.add_theme_color_override("font_color", COL_AFFORDABLE)
	header.add_child(pp_label)

	var close_btn: Button = Button.new()
	close_btn.text = "Retour"
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	# Scroll with branches
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vroot.add_child(scroll)

	# Lines drawn on a Control overlay
	lines_container = Control.new()
	lines_container.set_anchors_preset(PRESET_FULL_RECT)
	lines_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 32)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(hbox)

	for branch: String in PrestigeDatabase.BRANCHES:
		var col: VBoxContainer = VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 20)
		hbox.add_child(col)

		# Branch title
		var branch_label: Label = Label.new()
		branch_label.text = PrestigeDatabase.BRANCH_NAMES.get(branch, branch)
		branch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		branch_label.add_theme_font_size_override("font_size", 16)
		branch_label.add_theme_color_override("font_color", COL_AFFORDABLE)
		col.add_child(branch_label)

		# Separator
		var sep: HSeparator = HSeparator.new()
		col.add_child(sep)

		for node_data: PrestigeNode in PrestigeDatabase.get_branch(branch):
			var panel: PanelContainer = _make_node_panel(node_data)
			col.add_child(panel)
			node_panels[node_data.id] = panel

	# Add lines container on top of everything
	add_child(lines_container)


func _make_node_panel(data: PrestigeNode) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 80)
	panel.name = data.id

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	# Name
	var name_label: Label = Label.new()
	name_label.text = data.name_fr
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", COL_CREAM)
	vb.add_child(name_label)

	# Cost
	var cost_label: Label = Label.new()
	cost_label.text = "%d PP" % data.cost
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", COL_AFFORDABLE)
	cost_label.name = "CostLabel"
	vb.add_child(cost_label)

	# Prerequisites
	if data.prerequisites.size() > 0:
		var req_label: Label = Label.new()
		var reqs: PackedStringArray = []
		for p: StringName in data.prerequisites:
			if p == &"ALL_OTHER_BRANCHES":
				reqs.append("Toutes les branches")
			else:
				var req_data: PrestigeNode = PrestigeDatabase.get_node(p)
				reqs.append(req_data.name_fr if req_data else str(p))
		req_label.text = "Requiert: %s" % ", ".join(reqs)
		req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_label.add_theme_font_size_override("font_size", 10)
		req_label.add_theme_color_override("font_color", COL_TAN)
		req_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(req_label)

	# Status indicator
	var status_label: Label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 11)
	vb.add_child(status_label)

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
			&"free_first_pack":
				gm.free_first_pack = true
			&"pack_cards_plus1":
				gm.pack_card_bonus += 1
			&"overflow_compost":
				gm.overflow_compost = true
			&"mastery_base_1":
				gm.mastery_bonus[&"base"] = gm.mastery_bonus.get(&"base", 0) + 1
			&"mastery_standard_1":
				gm.mastery_bonus[&"standard"] = gm.mastery_bonus.get(&"standard", 0) + 1
			&"mastery_standard_2":
				gm.mastery_bonus[&"standard"] = gm.mastery_bonus.get(&"standard", 0) + 1
			&"mastery_premium_1":
				gm.mastery_bonus[&"premium"] = gm.mastery_bonus.get(&"premium", 0) + 1
			&"mastery_premium_3":
				gm.mastery_bonus[&"premium"] = gm.mastery_bonus.get(&"premium", 0) + 2
			_:
				pass


func refresh() -> void:
	var pp_label: Label = find_child("PPLabel", true, false)
	if pp_label:
		pp_label.text = "Points de Prestige: %d" % gm.prestige_points

	for id: StringName in node_panels:
		var panel: PanelContainer = node_panels[id]
		var data: PrestigeNode = PrestigeDatabase.get_node(id)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 6
		style.content_margin_bottom = 6

		var status_label: Label = panel.find_child("StatusLabel", true, false)
		var unlocked: bool = id in gm.unlocked_upgrades
		var can_afford: bool = gm.prestige_points >= data.cost
		var prereqs_met: bool = PrestigeDatabase.can_unlock(id, gm.unlocked_upgrades)

		if unlocked:
			style.bg_color = COL_UNLOCKED.darkened(0.3)
			style.border_color = COL_UNLOCKED
			style.set_border_width_all(2)
			if status_label:
				status_label.text = "Debloque"
				status_label.add_theme_color_override("font_color", COL_UNLOCKED)
		elif prereqs_met and can_afford:
			style.bg_color = Color(0.15, 0.12, 0.06)
			style.border_color = COL_AFFORDABLE
			style.set_border_width_all(3)
			if status_label:
				status_label.text = ">> Cliquer pour debloquer <<"
				status_label.add_theme_color_override("font_color", COL_AFFORDABLE)
		elif prereqs_met and not can_afford:
			style.bg_color = Color(0.15, 0.12, 0.06)
			style.border_color = Color(0.5, 0.4, 0.2, 0.5)
			style.set_border_width_all(1)
			if status_label:
				status_label.text = "PP insuffisants"
				status_label.add_theme_color_override("font_color", COL_TAN)
		else:
			style.bg_color = COL_LOCKED
			style.border_color = Color(0.3, 0.25, 0.18)
			style.set_border_width_all(1)
			if status_label:
				status_label.text = "Verrouille"
				status_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3))

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
			var from_pos: Vector2 = from_panel.global_position + Vector2(from_panel.size.x / 2, from_panel.size.y)
			var to_pos: Vector2 = to_panel.global_position + Vector2(to_panel.size.x / 2, 0)

			var both_done: bool = id in gm.unlocked_upgrades and prereq in gm.unlocked_upgrades
			var line_col: Color = COL_LINE_DONE if both_done else COL_LINE_PENDING

			# Draw arrow line
			var line: Line2D = Line2D.new()
			line.width = 3.0 if both_done else 2.0
			line.default_color = line_col

			# Bezier-ish: go down from source, then across, then down to target
			var mid_y: float = (from_pos.y + to_pos.y) / 2.0
			var pts: Array[Vector2] = [
				from_pos - lines_container.global_position,
				Vector2(from_pos.x, mid_y) - lines_container.global_position,
				Vector2(to_pos.x, mid_y) - lines_container.global_position,
				to_pos - lines_container.global_position,
			]
			line.points = pts
			lines_container.add_child(line)

			# Arrow head
			var arrow_dir: Vector2 = (pts[3] - pts[2]).normalized()
			var arrow_size: float = 8.0
			var arrow_left: Vector2 = pts[3] - arrow_dir * arrow_size + arrow_dir.rotated(PI / 2) * arrow_size * 0.5
			var arrow_right: Vector2 = pts[3] - arrow_dir * arrow_size - arrow_dir.rotated(PI / 2) * arrow_size * 0.5
			var arrow: Line2D = Line2D.new()
			arrow.width = 2.0
			arrow.default_color = line_col
			arrow.points = [arrow_left, pts[3], arrow_right]
			lines_container.add_child(arrow)


func _on_close() -> void:
	closed.emit()
	hide()
