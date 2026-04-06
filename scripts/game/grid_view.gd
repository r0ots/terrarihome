class_name GridView extends Node2D

signal cell_clicked(grid_pos: Vector2i)
signal cell_hovered(grid_pos: Vector2i)

const GRID_COLOR := Color(0.28, 0.24, 0.18)
const HOVER_COLOR := Color(1.0, 0.9, 0.6, 0.15)
const VALID_COLOR := Color(0.4, 0.75, 0.3, 0.3)
const INVALID_COLOR := Color(0.8, 0.35, 0.25, 0.3)
const BLOCKED_COLOR := Color(0.18, 0.15, 0.12, 0.5)
const TOP_MARGIN := 40.0
const BOTTOM_MARGIN := 160.0
const BORDER_WIDTH := 2.0

const TYPE_COLORS: Dictionary = {
	&"legume": Color("#E67E22"),
	&"plante": Color("#27AE60"),
	&"champi": Color("#8E44AD"),
	&"racine": Color("#D4AC0D"),
}

const PLANT_COLORS: Dictionary = {
	&"carotte": Color("#E67E22"),
	&"herberaude": Color("#2ECC71"),
	&"boutomate": Color("#E74C3C"),
	&"persil_piquant": Color("#1ABC9C"),
	&"cactus_epineux": Color("#27AE60"),
	&"basilic_royal": Color("#9B59B6"),
	&"truffe": Color("#795548"),
	&"champi_mi_gnon": Color("#A1887F"),
	&"morille_doree": Color("#F4D03F"),
	&"pleurote_cascade": Color("#AF7AC5"),
	&"mousse_lunaire": Color("#5DADE2"),
	&"patate_douce": Color("#DC7633"),
	&"radis_rose": Color("#F1948A"),
	&"navet_tournoyant": Color("#F7DC6F"),
	&"gingembre_tourne_vent": Color("#F39C12"),
	&"ail_des_ours": Color("#82E0AA"),
	&"fougere_dor": Color("#229954"),
	&"fraise_sauvage": Color("#CB4335"),
}

var grid_data: GridData
var cell_size: float = 40.0
var preview_plant_id: StringName = &""
var preview_pos: Vector2i = Vector2i(-1, -1)
var hover_pos: Vector2i = Vector2i(-1, -1)
var active_tool: StringName = &""
var _info_popup: PanelContainer = null
var _hovered_plant_id: int = -1


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_tree().root.size_changed.connect(_on_viewport_resized)


func set_grid_data(data: GridData) -> void:
	grid_data = data
	_recalculate_layout()


func _on_viewport_resized() -> void:
	_recalculate_layout()


func _recalculate_layout() -> void:
	if not grid_data:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var available_w: float = vp_size.x * 0.9
	var available_h: float = vp_size.y - TOP_MARGIN - BOTTOM_MARGIN
	var cs_w: float = available_w / grid_data.width
	var cs_h: float = available_h / grid_data.height
	cell_size = floorf(minf(cs_w, cs_h))
	var grid_w: float = grid_data.width * cell_size
	var grid_h: float = grid_data.height * cell_size
	position = Vector2((vp_size.x - grid_w) / 2.0, TOP_MARGIN + (available_h - grid_h) / 2.0)
	queue_redraw()


func set_preview(plant_id: StringName, grid_pos: Vector2i) -> void:
	preview_plant_id = plant_id
	preview_pos = grid_pos
	queue_redraw()


func clear_preview() -> void:
	preview_plant_id = &""
	preview_pos = Vector2i(-1, -1)
	active_tool = &""
	queue_redraw()


func set_tool_hover(tool_id: StringName, grid_pos: Vector2i) -> void:
	active_tool = tool_id
	preview_plant_id = &""
	hover_pos = grid_pos
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var local: Vector2 = to_local(screen_pos)
	if local.x < 0 or local.y < 0:
		return Vector2i(-1, -1)
	var gx: int = int(local.x / cell_size)
	var gy: int = int(local.y / cell_size)
	return Vector2i(gx, gy)


func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return to_global(Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size))


func _input(event: InputEvent) -> void:
	if not grid_data:
		return
	if event is InputEventMouseMotion:
		var gp: Vector2i = screen_to_grid(event.global_position)
		if gp != hover_pos:
			hover_pos = gp
			cell_hovered.emit(gp)
			_update_hover_info(gp)
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var gp: Vector2i = screen_to_grid(event.global_position)
			if grid_data.is_valid_pos(gp):
				cell_clicked.emit(gp)
	elif event is InputEventScreenDrag:
		var gp: Vector2i = screen_to_grid(event.position)
		if gp != hover_pos:
			hover_pos = gp
			cell_hovered.emit(gp)
			_update_hover_info(gp)
			queue_redraw()
	elif event is InputEventScreenTouch:
		var gp: Vector2i = screen_to_grid(event.position)
		if event.pressed and grid_data.is_valid_pos(gp):
			hover_pos = gp
			cell_hovered.emit(gp)
			cell_clicked.emit(gp)


func _update_hover_info(gp: Vector2i) -> void:
	var inst_id: int = grid_data.get_plant_at(gp) if grid_data.is_valid_pos(gp) else -1
	if inst_id == _hovered_plant_id:
		return
	_hovered_plant_id = inst_id
	_hide_info()
	if inst_id == -1:
		return
	var plant: Dictionary = grid_data.plants[inst_id]
	var data: PlantData = PlantDatabase.get_plant(plant.plant_id)
	if not data:
		return
	_show_info(gp, data)


func _show_info(gp: Vector2i, data: PlantData) -> void:
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
	label.text = _build_plant_info(data)
	label.add_theme_font_size_override("font_size", 13)
	_info_popup.add_child(label)

	get_tree().root.add_child(_info_popup)

	await get_tree().process_frame
	var screen_pos: Vector2 = grid_to_screen(gp)
	_info_popup.position = Vector2(
		screen_pos.x + cell_size + 8,
		screen_pos.y
	)
	# Clamp to viewport
	var vp: Vector2 = get_viewport_rect().size
	if _info_popup.position.x + _info_popup.size.x > vp.x:
		_info_popup.position.x = screen_pos.x - _info_popup.size.x - 8
	if _info_popup.position.y + _info_popup.size.y > vp.y:
		_info_popup.position.y = vp.y - _info_popup.size.y - 4


func _hide_info() -> void:
	if _info_popup and is_instance_valid(_info_popup):
		_info_popup.queue_free()
		_info_popup = null


static func _build_plant_info(data: PlantData) -> String:
	var lines: PackedStringArray = [data.name_fr]
	var types_str: String = ", ".join(data.types.map(func(t: StringName) -> String: return str(t).capitalize()))
	lines.append("Types: %s" % types_str)
	lines.append("")
	match data.combo_type:
		&"flat":
			lines.append("+%d pts au placement" % data.flat_value)
		&"per_adjacent_type":
			var targets: String = " ou ".join(data.combo_targets.map(func(t: StringName) -> String: return str(t).capitalize()))
			lines.append("+1 pt / %s adjacent" % targets)
		&"per_adjacent_any":
			lines.append("+1 pt / case occupee adjacente")
		&"per_adjacent_empty":
			lines.append("+1 pt / case vide adjacente")
		&"modifier_x2":
			var targets: String = " ou ".join(data.combo_targets.map(func(t: StringName) -> String: return str(t).capitalize()))
			lines.append("x2 pts futurs des %s adj." % targets)
		&"modifier_plus1":
			var targets: String = " ou ".join(data.combo_targets.map(func(t: StringName) -> String: return str(t).capitalize()))
			lines.append("+1 gains futurs des %s adj." % targets)
	if data.scoring_mode == &"on_place_only":
		lines.append("(placement uniquement)")
	else:
		lines.append("(bidirectionnel)")
	return "\n".join(lines)


func _get_plant_color(plant_id: StringName) -> Color:
	if PLANT_COLORS.has(plant_id):
		return PLANT_COLORS[plant_id]
	var data: PlantData = PlantDatabase.get_plant(plant_id)
	if not data:
		return Color.WHITE
	if data.types.size() > 0:
		return TYPE_COLORS.get(data.types[0], Color.WHITE)
	return Color.WHITE


func _draw() -> void:
	if not grid_data:
		return
	var w: int = grid_data.width
	var h: int = grid_data.height
	var cs: float = cell_size

	# Background
	draw_rect(Rect2(0, 0, w * cs, h * cs), Color(0.12, 0.09, 0.06, 0.85))

	# Blocked cells
	for x: int in w:
		for y: int in h:
			var state: int = grid_data.get_cell_state(Vector2i(x, y))
			if state == GridData.BLOCKED_ROCK:
				draw_rect(Rect2(x * cs, y * cs, cs, cs), Color(0.25, 0.20, 0.15))
				draw_rect(Rect2(x * cs + cs * 0.2, y * cs + cs * 0.3, cs * 0.3, cs * 0.25), Color(0.35, 0.30, 0.25))
				draw_rect(Rect2(x * cs + cs * 0.5, y * cs + cs * 0.5, cs * 0.35, cs * 0.3), Color(0.30, 0.25, 0.20))
			elif state == GridData.BLOCKED_RIVER:
				draw_rect(Rect2(x * cs, y * cs, cs, cs), Color(0.15, 0.30, 0.50, 0.7))
				draw_line(Vector2(x * cs + 2, y * cs + cs * 0.4), Vector2(x * cs + cs - 2, y * cs + cs * 0.6), Color(0.3, 0.5, 0.8, 0.5), 2.0)
			elif state == GridData.BLOCKED_HOLE:
				draw_rect(Rect2(x * cs, y * cs, cs, cs), Color(0.08, 0.06, 0.04))
				draw_line(Vector2(x * cs + 4, y * cs + 4), Vector2(x * cs + cs - 4, y * cs + cs - 4), Color(0.3, 0.2, 0.1), 2.0)
				draw_line(Vector2(x * cs + cs - 4, y * cs + 4), Vector2(x * cs + 4, y * cs + cs - 4), Color(0.3, 0.2, 0.1), 2.0)

	# Grid lines (drawn BEFORE plants so plants cover them)
	for x: int in w + 1:
		draw_line(Vector2(x * cs, 0), Vector2(x * cs, h * cs), GRID_COLOR)
	for y: int in h + 1:
		draw_line(Vector2(0, y * cs), Vector2(w * cs, y * cs), GRID_COLOR)

	# Placed plants (on top of grid lines)
	for inst_id: int in grid_data.plants:
		var plant: Dictionary = grid_data.plants[inst_id]
		var col: Color = _get_plant_color(plant.plant_id)
		var data: PlantData = PlantDatabase.get_plant(plant.plant_id)
		var cells_set: Dictionary = {}
		for c: Vector2i in plant.cells:
			cells_set[c] = true

		# Fill all cells (cover grid lines between cells of same plant)
		for cell_pos: Vector2i in plant.cells:
			var r: Rect2 = Rect2(cell_pos.x * cs, cell_pos.y * cs, cs, cs)
			draw_rect(r, Color(col, 0.7))

		# External borders only
		var bw: float = BORDER_WIDTH
		var border_col: Color = col.lightened(0.4)
		for cell_pos: Vector2i in plant.cells:
			var px: float = cell_pos.x * cs
			var py: float = cell_pos.y * cs
			if not cells_set.has(Vector2i(cell_pos.x, cell_pos.y - 1)):
				draw_rect(Rect2(px, py, cs, bw), border_col)
			if not cells_set.has(Vector2i(cell_pos.x, cell_pos.y + 1)):
				draw_rect(Rect2(px, py + cs - bw, cs, bw), border_col)
			if not cells_set.has(Vector2i(cell_pos.x - 1, cell_pos.y)):
				draw_rect(Rect2(px, py, bw, cs), border_col)
			if not cells_set.has(Vector2i(cell_pos.x + 1, cell_pos.y)):
				draw_rect(Rect2(px + cs - bw, py, bw, cs), border_col)

		# Icon then name (icon behind text)
		if data and plant.cells.size() > 0:
			var first: Vector2i = plant.cells[0]
			var icon: ImageTexture = PlantIcons.get_icon(plant.plant_id)
			if icon:
				var icon_scale: int = maxi(1, int(cs / 16.0))
				var icon_size: float = 16.0 * icon_scale
				var icon_pos: Vector2 = Vector2(
					first.x * cs + (cs - icon_size) / 2.0,
					first.y * cs + (cs - icon_size) / 2.0
				)
				draw_texture_rect(icon, Rect2(icon_pos, Vector2(icon_size, icon_size)), false)

	# Highlight hovered plant
	if _hovered_plant_id >= 0 and grid_data.plants.has(_hovered_plant_id):
		var hplant: Dictionary = grid_data.plants[_hovered_plant_id]
		for cell_pos: Vector2i in hplant.cells:
			draw_rect(Rect2(cell_pos.x * cs, cell_pos.y * cs, cs, cs), Color(1, 1, 1, 0.12))

	# Preview overlay
	if preview_plant_id != &"" and grid_data.is_valid_pos(preview_pos):
		var data: PlantData = PlantDatabase.get_plant(preview_plant_id)
		if data:
			var can_place: bool = grid_data.can_place_plant(preview_plant_id, preview_pos)
			var overlay_color: Color = VALID_COLOR if can_place else INVALID_COLOR
			for offset: Vector2i in data.shape:
				var p: Vector2i = preview_pos + offset
				var r: Rect2 = Rect2(p.x * cs, p.y * cs, cs, cs)
				draw_rect(r, overlay_color)

	# Tool hover overlay
	if active_tool != &"" and grid_data.is_valid_pos(hover_pos):
		match active_tool:
			&"shovel":
				var col := Color(0.9, 0.3, 0.2, 0.35)
				draw_rect(Rect2(hover_pos.x * cs, hover_pos.y * cs, cs, cs), col)
			&"fertilizer":
				var area: Array[Vector2i] = grid_data.get_cells_in_area(hover_pos, 1)
				for c: Vector2i in area:
					draw_rect(Rect2(c.x * cs, c.y * cs, cs, cs), Color(0.3, 0.75, 0.25, 0.25))
			&"watering_can":
				var area: Array[Vector2i] = grid_data.get_cells_in_area(hover_pos, 1)
				for c: Vector2i in area:
					draw_rect(Rect2(c.x * cs, c.y * cs, cs, cs), Color(0.3, 0.55, 0.9, 0.25))

	# Hover highlight (when no preview, no tool, and no plant hovered)
	if preview_plant_id == &"" and active_tool == &"" and _hovered_plant_id == -1 and grid_data.is_valid_pos(hover_pos):
		draw_rect(Rect2(hover_pos.x * cs, hover_pos.y * cs, cs, cs), HOVER_COLOR)



func spawn_floating_text(grid_pos: Vector2i, text: String, color: Color = Color(1.0, 0.85, 0.4)) -> void:
	var ft: FloatingText = FloatingText.new()
	ft.text = text
	ft.add_theme_color_override("font_color", color)
	ft.add_theme_font_size_override("font_size", int(cell_size * 0.5))
	var fs: int = int(cell_size * 0.5)
	ft.position = Vector2(grid_pos.x * cell_size + cell_size / 2.0 - fs * 0.4, grid_pos.y * cell_size + cell_size / 2.0 - fs * 0.5)
	add_child(ft)
