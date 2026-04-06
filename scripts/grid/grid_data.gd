class_name GridData extends RefCounted

const EMPTY := 0
const OCCUPIED := 1
const BLOCKED_ROCK := 2
const BLOCKED_RIVER := 3
const BLOCKED_HOLE := 4

var width: int
var height: int
var cells: Array[Array]
var cell_plant: Dictionary  # Dictionary[Vector2i, int]
var cell_modifiers: Dictionary  # Dictionary[Vector2i, Array]
var plants: Dictionary  # Dictionary[int, Dictionary]
var next_plant_id: int = 0


func _init(w: int = 18, h: int = 8) -> void:
	width = w
	height = h
	cells = []
	for x: int in w:
		var col: Array[int] = []
		col.resize(h)
		col.fill(EMPTY)
		cells.append(col)


func is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


func get_cell_state(pos: Vector2i) -> int:
	if not is_valid_pos(pos):
		return -1
	return cells[pos.x][pos.y]


func is_cell_empty(pos: Vector2i) -> bool:
	return is_valid_pos(pos) and cells[pos.x][pos.y] == EMPTY


func can_place_plant(plant_id: StringName, origin: Vector2i) -> bool:
	var data: PlantData = PlantDatabase.get_plant(plant_id)
	if not data:
		return false
	for offset: Vector2i in data.shape:
		if not is_cell_empty(origin + offset):
			return false
	return true


func place_plant(plant_id: StringName, origin: Vector2i) -> int:
	var data: PlantData = PlantDatabase.get_plant(plant_id)
	if not data:
		return -1
	var id: int = next_plant_id
	next_plant_id += 1
	var occupied_cells: Array[Vector2i] = []
	for offset: Vector2i in data.shape:
		var pos: Vector2i = origin + offset
		cells[pos.x][pos.y] = OCCUPIED
		cell_plant[pos] = id
		occupied_cells.append(pos)
	plants[id] = {plant_id = plant_id, cells = occupied_cells, placed_order = id}
	return id


func remove_plant(instance_id: int) -> StringName:
	var plant: Dictionary = plants.get(instance_id, {})
	if plant.is_empty():
		return &""
	for pos: Vector2i in plant.cells:
		cells[pos.x][pos.y] = EMPTY
		cell_plant.erase(pos)
		cell_modifiers.erase(pos)
	var pid: StringName = plant.plant_id
	plants.erase(instance_id)
	return pid


func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var n: Vector2i = pos + dir
		if is_valid_pos(n):
			result.append(n)
	return result


func get_plant_at(pos: Vector2i) -> int:
	return cell_plant.get(pos, -1)


func get_adjacent_plant_instances(instance_id: int) -> Array[int]:
	var plant: Dictionary = plants.get(instance_id, {})
	if plant.is_empty():
		return []
	var seen: Dictionary = {}
	var result: Array[int] = []
	for pos: Vector2i in plant.cells:
		for n: Vector2i in get_neighbors(pos):
			var nid: int = get_plant_at(n)
			if nid != -1 and nid != instance_id and not seen.has(nid):
				seen[nid] = true
				result.append(nid)
	return result


func add_modifier(pos: Vector2i, modifier: Dictionary) -> void:
	if not cell_modifiers.has(pos):
		cell_modifiers[pos] = []
	cell_modifiers[pos].append(modifier)


func get_modifiers(pos: Vector2i) -> Array:
	return cell_modifiers.get(pos, [])


func get_all_occupied_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for n: Vector2i in get_neighbors(pos):
		if get_cell_state(n) == OCCUPIED:
			result.append(n)
	return result


func is_grid_full() -> bool:
	for x: int in width:
		for y: int in height:
			if cells[x][y] == EMPTY:
				return false
	return true
