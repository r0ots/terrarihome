class_name ScoringEngine extends RefCounted

var grid: GridData


func _init(g: GridData) -> void:
	grid = g


func score_placement(plant_id: String, instance_id: int) -> Dictionary:
	var result := {total = 0, breakdown = []}

	# PHASE 1: Modifiers first
	_apply_modifiers_from_plant(plant_id, instance_id)
	_apply_modifiers_to_plant(instance_id)

	# PHASE 2: Score
	var plant = grid.plants[instance_id]
	_score_plant_cells(plant_id, instance_id, plant.cells, result)
	_score_existing_neighbors(instance_id, result)

	return result


func score_retrigger(instance_ids: Array[int]) -> Dictionary:
	var result := {total = 0, breakdown = []}
	for inst_id in instance_ids:
		var plant = grid.plants.get(inst_id)
		if not plant:
			continue
		_score_plant_cells(plant.plant_id, inst_id, plant.cells, result)
	return result


# --- Phase 1: Modifiers ---

func _apply_modifiers_from_plant(plant_id: String, instance_id: int) -> void:
	var data = PlantDatabase.get_plant(plant_id)
	if not data or not data.get("combo_type", "").begins_with("modifier_"):
		return
	var plant = grid.plants[instance_id]
	var mod_type := "x2" if data.combo_type == "modifier_x2" else "plus1"
	var targets: Array = data.get("combo_targets", [])

	for pos in plant.cells:
		for n in grid.get_neighbors(pos):
			var nid := grid.get_plant_at(n)
			if nid == -1 or nid == instance_id:
				continue
			if _plant_has_any_type(nid, targets):
				grid.add_modifier(n, {type = mod_type, source = instance_id})


func _apply_modifiers_to_plant(instance_id: int) -> void:
	var plant = grid.plants[instance_id]
	var plant_data = PlantDatabase.get_plant(plant.plant_id)
	var plant_types: Array = plant_data.get("types", [])

	for pos in plant.cells:
		for n in grid.get_neighbors(pos):
			var nid := grid.get_plant_at(n)
			if nid == -1 or nid == instance_id:
				continue
			var neighbor_plant = grid.plants[nid]
			var neighbor_data = PlantDatabase.get_plant(neighbor_plant.plant_id)
			if not neighbor_data.get("combo_type", "").begins_with("modifier_"):
				continue
			var targets: Array = neighbor_data.get("combo_targets", [])
			if _types_match(plant_types, targets):
				var mod_type := "x2" if neighbor_data.combo_type == "modifier_x2" else "plus1"
				grid.add_modifier(pos, {type = mod_type, source = nid})


# --- Phase 2: Scoring ---

func _score_plant_cells(plant_id: String, instance_id: int, plant_cells: Array, result: Dictionary) -> void:
	var data = PlantDatabase.get_plant(plant_id)
	var combo_type: String = data.get("combo_type", "")

	if combo_type.begins_with("modifier_"):
		return

	if combo_type == "flat":
		var base: int = data.get("flat_value", 0)
		# Flat scores once total, applied to first cell for breakdown tracking
		var pts := _calculate_points_for_cell(plant_cells[0], base)
		if pts > 0:
			result.breakdown.append({cell = plant_cells[0], points = pts, source = plant_id})
			result.total += pts
		return

	for cell in plant_cells:
		var neighbors := grid.get_neighbors(cell)
		for n in neighbors:
			var base := _get_base_points_for_neighbor(combo_type, data, n, instance_id)
			if base <= 0:
				continue
			var pts := _calculate_points_for_cell(cell, base)
			if pts > 0:
				result.breakdown.append({cell = cell, points = pts, source = plant_id})
				result.total += pts


func _score_existing_neighbors(instance_id: int, result: Dictionary) -> void:
	var adjacent_ids := grid.get_adjacent_plant_instances(instance_id)
	var new_plant = grid.plants[instance_id]
	var new_cells_set: Dictionary = {}
	for c in new_plant.cells:
		new_cells_set[c] = true

	for adj_id in adjacent_ids:
		var adj_plant = grid.plants[adj_id]
		var adj_data = PlantDatabase.get_plant(adj_plant.plant_id)

		if adj_data.get("scoring_mode", "bidirectional") == "on_place_only":
			continue
		if adj_data.get("combo_type", "").begins_with("modifier_"):
			continue
		if adj_data.combo_type == "flat":
			continue

		for cell in adj_plant.cells:
			for n in grid.get_neighbors(cell):
				if not new_cells_set.has(n):
					continue
				var base := _get_base_points_for_neighbor(adj_data.combo_type, adj_data, n, adj_id)
				if base <= 0:
					continue
				var pts := _calculate_points_for_cell(cell, base)
				if pts > 0:
					result.breakdown.append({cell = cell, points = pts, source = adj_plant.plant_id})
					result.total += pts


# --- Point calculation ---

func _get_base_points_for_neighbor(combo_type: String, data: Dictionary, neighbor_pos: Vector2i, self_id: int) -> int:
	match combo_type:
		"per_adjacent_type":
			var nid := grid.get_plant_at(neighbor_pos)
			if nid == -1 or nid == self_id:
				return 0
			var targets: Array = data.get("combo_targets", [])
			if _plant_has_any_type(nid, targets):
				return 1
		"per_adjacent_any":
			if grid.get_cell_state(neighbor_pos) == GridData.OCCUPIED:
				var nid := grid.get_plant_at(neighbor_pos)
				if nid != self_id:
					return 1
		"per_adjacent_empty":
			if grid.is_cell_empty(neighbor_pos):
				return 1
	return 0


func _calculate_points_for_cell(cell: Vector2i, base_points: int) -> int:
	var pts := base_points
	var mods := grid.get_modifiers(cell)
	var x2_count := 0
	var plus_count := 0
	for m in mods:
		match m.type:
			"x2":
				x2_count += 1
			"plus1", "fertilizer", "river":
				plus_count += 1

	# River adjacency bonus
	for n in grid.get_neighbors(cell):
		if grid.get_cell_state(n) == GridData.BLOCKED_RIVER:
			plus_count += 1
			break

	# x2 is additive: 1 gingembre = x2, 2 = x3, etc.
	if x2_count > 0:
		pts *= (1 + x2_count)

	pts += plus_count
	return pts


# --- Helpers ---

func _plant_has_any_type(instance_id: int, targets: Array) -> bool:
	var plant = grid.plants.get(instance_id)
	if not plant:
		return false
	var data = PlantDatabase.get_plant(plant.plant_id)
	return _types_match(data.get("types", []), targets)


func _types_match(plant_types: Array, targets: Array) -> bool:
	for t in plant_types:
		if targets.has(t):
			return true
	return false
