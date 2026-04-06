class_name GridView extends Node2D

signal cell_clicked(grid_pos: Vector2i)
signal cell_hovered(grid_pos: Vector2i)

const CELL_SIZE := 40
const GRID_COLOR := Color(0.3, 0.3, 0.3, 0.4)
const HOVER_COLOR := Color(1, 1, 1, 0.15)
const VALID_COLOR := Color(0.3, 0.8, 0.3, 0.35)
const INVALID_COLOR := Color(0.8, 0.3, 0.3, 0.35)
const BLOCKED_COLOR := Color(0.2, 0.2, 0.2, 0.5)

const TYPE_COLORS := {
	&"legume": Color("#4CAF50"),
	&"plante": Color("#8BC34A"),
	&"champi": Color("#795548"),
	&"racine": Color("#FF9800"),
}

var grid_data: GridData
var preview_plant_id: String = ""
var preview_pos := Vector2i(-1, -1)
var hover_pos := Vector2i(-1, -1)


func set_grid_data(data: GridData) -> void:
	grid_data = data
	queue_redraw()


func set_preview(plant_id: String, grid_pos: Vector2i) -> void:
	preview_plant_id = plant_id
	preview_pos = grid_pos
	queue_redraw()


func clear_preview() -> void:
	preview_plant_id = ""
	preview_pos = Vector2i(-1, -1)
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var local := to_local(screen_pos)
	var gx := int(local.x / CELL_SIZE)
	var gy := int(local.y / CELL_SIZE)
	if local.x < 0 or local.y < 0:
		return Vector2i(-1, -1)
	return Vector2i(gx, gy)


func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return to_global(Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE))


func _input(event: InputEvent) -> void:
	if not grid_data:
		return
	if event is InputEventMouseMotion:
		var gp := screen_to_grid(event.global_position)
		if gp != hover_pos:
			hover_pos = gp
			cell_hovered.emit(gp)
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var gp := screen_to_grid(event.global_position)
			if grid_data.is_valid_pos(gp):
				cell_clicked.emit(gp)


func _get_plant_color(plant_id: String) -> Color:
	var data := PlantDatabase.get_plant(plant_id)
	if data.is_empty():
		return Color.WHITE
	var types: Array = data.get("types", [])
	if types.size() > 0:
		return TYPE_COLORS.get(types[0], Color.WHITE)
	return Color.WHITE


func _draw() -> void:
	if not grid_data:
		return
	var w := grid_data.width
	var h := grid_data.height

	# Background
	draw_rect(Rect2(0, 0, w * CELL_SIZE, h * CELL_SIZE), Color(0.1, 0.12, 0.1, 0.8))

	# Blocked cells
	for x in w:
		for y in h:
			var state := grid_data.get_cell_state(Vector2i(x, y))
			if state == GridData.BLOCKED_ROCK or state == GridData.BLOCKED_HOLE:
				draw_rect(Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE), BLOCKED_COLOR)
			elif state == GridData.BLOCKED_RIVER:
				draw_rect(Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE), Color(0.2, 0.4, 0.7, 0.5))

	# Placed plants
	for inst_id in grid_data.plants:
		var plant: Dictionary = grid_data.plants[inst_id]
		var col := _get_plant_color(plant.plant_id)
		for cell_pos: Vector2i in plant.cells:
			var r := Rect2(cell_pos.x * CELL_SIZE + 1, cell_pos.y * CELL_SIZE + 1, CELL_SIZE - 2, CELL_SIZE - 2)
			draw_rect(r, col)

	# Preview overlay
	if preview_plant_id != "" and grid_data.is_valid_pos(preview_pos):
		var data := PlantDatabase.get_plant(preview_plant_id)
		if not data.is_empty():
			var can_place := grid_data.can_place_plant(preview_plant_id, preview_pos)
			var overlay_color := VALID_COLOR if can_place else INVALID_COLOR
			for offset: Vector2i in data.shape:
				var p := preview_pos + offset
				var r := Rect2(p.x * CELL_SIZE, p.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
				draw_rect(r, overlay_color)

	# Hover highlight (single cell when no preview active)
	if preview_plant_id == "" and grid_data.is_valid_pos(hover_pos):
		draw_rect(Rect2(hover_pos.x * CELL_SIZE, hover_pos.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), HOVER_COLOR)

	# Grid lines
	for x in w + 1:
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, h * CELL_SIZE), GRID_COLOR)
	for y in h + 1:
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(w * CELL_SIZE, y * CELL_SIZE), GRID_COLOR)


func spawn_floating_text(grid_pos: Vector2i, text: String, color: Color = Color.WHITE) -> void:
	var ft := FloatingText.new()
	ft.text = text
	ft.add_theme_color_override("font_color", color)
	ft.add_theme_font_size_override("font_size", 18)
	ft.position = Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE) - Vector2(10, 20)
	add_child(ft)
