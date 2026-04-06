class_name Encyclopedia extends Control

signal closed

const COL_BG := Color(0.06, 0.05, 0.03, 0.94)
const COL_PANEL := Color(0.14, 0.11, 0.08)
const COL_BORDER := Color(0.45, 0.40, 0.28)
const COL_CREAM := Color(0.96, 0.93, 0.85)
const COL_TAN := Color(0.72, 0.65, 0.52)


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var vroot := VBoxContainer.new()
	vroot.set_anchors_preset(PRESET_FULL_RECT)
	vroot.add_theme_constant_override("separation", 12)
	add_child(vroot)

	# Header
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 24)
	vroot.add_child(header)

	var title := Label.new()
	title.text = "Encyclopedie"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", COL_CREAM)
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Retour"
	close_btn.pressed.connect(func() -> void: closed.emit())
	header.add_child(close_btn)

	# Scroll
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vroot.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for id: StringName in PlantDatabase.get_all():
		list.add_child(_make_entry(id))


func _make_entry(id: StringName) -> PanelContainer:
	var data: PlantData = PlantDatabase.get_plant(id)
	var panel := PanelContainer.new()

	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.border_color = COL_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	# Icon
	var icon_tex: ImageTexture = PlantIcons.get_icon(id)
	if icon_tex:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(48, 48)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hbox.add_child(icon)

	# Info
	var info := Label.new()
	info.text = HandView._build_description(data)
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", COL_CREAM)
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(info)

	# Shape preview
	var shape := HandView.ShapePreview.new()
	shape.plant_id = id
	shape.custom_minimum_size = Vector2(80, 60)
	hbox.add_child(shape)

	return panel
