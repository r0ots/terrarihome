class_name ScoringEngine extends RefCounted

var grid: GridData


func _init(g: GridData) -> void:
	grid = g


func score_placement(plant_id: StringName, instance_id: int) -> Dictionary:
	var result: Dictionary = {total = 0, breakdown = []}
	_apply_modifiers_from_plant(plant_id, instance_id)
	_apply_modifiers_to_plant(instance_id)
	var plant: Dictionary = grid.plants[instance_id]
	_score_plant_cells(plant_id, instance_id, plant.cells, result)
	_score_existing_neighbors(instance_id, result)
	return result


func score_retrigger(instance_ids: Array[int]) -> Dictionary:
	var result: Dictionary = {total = 0, breakdown = []}
	for inst_id: int in instance_ids:
		var plant: Dictionary = grid.plants.get(inst_id, {})
		if plant.is_empty():
			continue
		_score_plant_cells(plant.plant_id, inst_id, plant.cells, result)
	return result


func _apply_modifiers_from_plant(plant_id: StringName, instance_id: int) -> void:
	var data: PlantData = PlantDatabase.get_plant(plant_id)
	if not data or not data.combo_type.begins_with("modifier_"):
		return
	var plant: Dictionary = grid.plants[instance_id]
	var mastery: int = _get_mastery_for_data(data)

	for pos: Vector2i in plant.cells:
		for n: Vector2i in grid.get_neighbors(pos):
			var nid: int = grid.get_plant_at(n)
			if nid == -1 or nid == instance_id:
				continue
			if _plant_has_any_type(nid, data.combo_targets):
				if data.combo_type == &"modifier_x2":
					grid.add_modifier(n, {type = "x2", source = instance_id, bonus = mastery})
				else:
					grid.add_modifier(n, {type = "plus1", source = instance_id, value = 1 + mastery})


func _apply_modifiers_to_plant(instance_id: int) -> void:
	var plant: Dictionary = grid.plants[instance_id]
	var plant_data: PlantData = PlantDatabase.get_plant(plant.plant_id)

	for pos: Vector2i in plant.cells:
		for n: Vector2i in grid.get_neighbors(pos):
			var nid: int = grid.get_plant_at(n)
			if nid == -1 or nid == instance_id:
				continue
			var neighbor_plant: Dictionary = grid.plants[nid]
			var neighbor_data: PlantData = PlantDatabase.get_plant(neighbor_plant.plant_id)
			if not neighbor_data.combo_type.begins_with("modifier_"):
				continue
			if _types_match(plant_data.types, neighbor_data.combo_targets):
				var n_mastery: int = _get_mastery_for_data(neighbor_data)
				if neighbor_data.combo_type == &"modifier_x2":
					grid.add_modifier(pos, {type = "x2", source = nid, bonus = n_mastery})
				else:
					grid.add_modifier(pos, {type = "plus1", source = nid, value = 1 + n_mastery})


func _score_plant_cells(plant_id: StringName, instance_id: int, plant_cells: Array, result: Dictionary) -> void:
	var data: PlantData = PlantDatabase.get_plant(plant_id)

	if data.combo_type.begins_with("modifier_"):
		return

	if data.combo_type == &"flat":
		var pts: int = _calculate_points_for_cell(plant_cells[0], data.flat_value + _get_mastery_for_data(data))
		if pts > 0:
			result.breakdown.append({cell = plant_cells[0], points = pts, source = plant_id})
			result.total += pts
		return

	for cell: Vector2i in plant_cells:
		var neighbors: Array[Vector2i] = grid.get_neighbors(cell)
		for n: Vector2i in neighbors:
			var base: int = _get_base_points_for_neighbor(data.combo_type, data, n, instance_id)
			if base <= 0:
				continue
			var pts: int = _calculate_points_for_cell(cell, base)
			if pts > 0:
				result.breakdown.append({cell = cell, points = pts, source = plant_id})
				result.total += pts


func _score_existing_neighbors(instance_id: int, result: Dictionary) -> void:
	var adjacent_ids: Array[int] = grid.get_adjacent_plant_instances(instance_id)
	var new_plant: Dictionary = grid.plants[instance_id]
	var new_cells_set: Dictionary = {}
	for c: Vector2i in new_plant.cells:
		new_cells_set[c] = true

	for adj_id: int in adjacent_ids:
		var adj_plant: Dictionary = grid.plants[adj_id]
		var adj_data: PlantData = PlantDatabase.get_plant(adj_plant.plant_id)

		if adj_data.scoring_mode == &"on_place_only":
			continue
		if adj_data.combo_type.begins_with("modifier_"):
			continue
		if adj_data.combo_type == &"flat":
			continue

		for cell: Vector2i in adj_plant.cells:
			for n: Vector2i in grid.get_neighbors(cell):
				if not new_cells_set.has(n):
					continue
				var base: int = _get_base_points_for_neighbor(adj_data.combo_type, adj_data, n, adj_id)
				if base <= 0:
					continue
				var pts: int = _calculate_points_for_cell(cell, base)
				if pts > 0:
					result.breakdown.append({cell = cell, points = pts, source = adj_plant.plant_id})
					result.total += pts


func _get_base_points_for_neighbor(combo_type: StringName, data: PlantData, neighbor_pos: Vector2i, self_id: int) -> int:
	var mastery: int = _get_mastery(self_id)
	match combo_type:
		&"per_adjacent_type":
			var nid: int = grid.get_plant_at(neighbor_pos)
			if nid == -1 or nid == self_id:
				return 0
			if _plant_has_any_type(nid, data.combo_targets):
				return 1 + mastery
		&"per_adjacent_any":
			if grid.get_cell_state(neighbor_pos) == GridData.OCCUPIED:
				var nid: int = grid.get_plant_at(neighbor_pos)
				if nid != self_id:
					return 1 + mastery
		&"per_adjacent_empty":
			if grid.is_cell_empty(neighbor_pos):
				return 1 + mastery
	return 0


func _calculate_points_for_cell(cell: Vector2i, base_points: int) -> int:
	var pts: int = base_points
	var mods: Array = grid.get_modifiers(cell)
	var x2_count: int = 0
	var x2_bonus: int = 0
	var plus_count: int = 0
	for m: Dictionary in mods:
		match m.type:
			"x2":
				x2_count += 1
				x2_bonus += m.get("bonus", 0)
			"plus1":
				plus_count += m.get("value", 1)
			"fertilizer", "river":
				plus_count += 1

	for n: Vector2i in grid.get_neighbors(cell):
		if grid.get_cell_state(n) == GridData.BLOCKED_RIVER:
			plus_count += 1
			break

	if x2_count > 0:
		pts *= (1 + x2_count)
	pts += plus_count + x2_bonus
	return pts


func _plant_has_any_type(instance_id: int, targets: Array[StringName]) -> bool:
	var plant: Dictionary = grid.plants.get(instance_id, {})
	if plant.is_empty():
		return false
	var data: PlantData = PlantDatabase.get_plant(plant.plant_id)
	return _types_match(data.types, targets)


func _types_match(plant_types: Array[StringName], targets: Array[StringName]) -> bool:
	for t: StringName in plant_types:
		if targets.has(t):
			return true
	return false


func _get_mastery(instance_id: int) -> int:
	var plant: Dictionary = grid.plants.get(instance_id, {})
	if plant.is_empty(): return 0
	return GameManager.get_mastery_for_plant(plant.plant_id)


func _get_mastery_for_data(data: PlantData) -> int:
	return GameManager.get_mastery_for_plant(data.id)
