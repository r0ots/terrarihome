extends Node

const SAVE_PATH := "user://save.json"

var grid_save_data: Dictionary = {}
var shop_slots_save: Array = []
var shop_bonus_save: Array = []


func save_game() -> void:
	var data: Dictionary = {
		"points": GameManager.points,
		"prestige_points": GameManager.prestige_points,
		"hand": GameManager.hand,
		"hand_size_max": GameManager.hand_size_max,
		"unlocked_upgrades": GameManager.unlocked_upgrades,
		"starting_cards": GameManager.starting_cards,
		"tool_inventory": GameManager.tool_inventory,
		"grid": grid_save_data,
		"shop_slots": shop_slots_save,
		"shop_bonus": shop_bonus_save,
	}
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not has_save():
		return false
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	if data == null:
		return false
	GameManager.points = data.get("points", 0)
	GameManager.prestige_points = data.get("prestige_points", 0)
	GameManager.hand.clear()
	for card: String in data.get("hand", []):
		GameManager.hand.append(StringName(card))
	GameManager.hand_size_max = data.get("hand_size_max", 5)
	GameManager.unlocked_upgrades.clear()
	for u: String in data.get("unlocked_upgrades", []):
		GameManager.unlocked_upgrades.append(StringName(u))
	GameManager.starting_cards.clear()
	for c: String in data.get("starting_cards", []):
		GameManager.starting_cards.append(StringName(c))
	GameManager.tool_inventory.clear()
	for t: String in data.get("tool_inventory", []):
		GameManager.tool_inventory.append(StringName(t))
	grid_save_data = data.get("grid", {})
	shop_slots_save = data.get("shop_slots", [])
	shop_bonus_save = data.get("shop_bonus", [])
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func serialize_grid(grid: GridData) -> Dictionary:
	var plants_data: Dictionary = {}
	for id: int in grid.plants:
		var p: Dictionary = grid.plants[id]
		var cells_arr: Array = []
		for c: Vector2i in p.cells:
			cells_arr.append([c.x, c.y])
		plants_data[str(id)] = {"plant_id": p.plant_id, "cells": cells_arr}
	var mods: Dictionary = {}
	for pos: Vector2i in grid.cell_modifiers:
		mods["%d,%d" % [pos.x, pos.y]] = grid.cell_modifiers[pos]
	var blocked: Dictionary = {}
	for x: int in grid.width:
		for y: int in grid.height:
			var s: int = grid.cells[x][y]
			if s >= GridData.BLOCKED_ROCK and s <= GridData.BLOCKED_HOLE:
				blocked["%d,%d" % [x, y]] = s
	return {"width": grid.width, "height": grid.height, "plants": plants_data, "modifiers": mods, "next_id": grid.next_plant_id, "blocked": blocked}


func deserialize_grid(data: Dictionary) -> GridData:
	var g: GridData = GridData.new(data.get("width", 18), data.get("height", 8))
	g.next_plant_id = data.get("next_id", 0)
	var plants_data: Dictionary = data.get("plants", {})
	for id_str: String in plants_data:
		var id: int = int(id_str)
		var pd: Dictionary = plants_data[id_str]
		var cells: Array[Vector2i] = []
		for c: Array in pd.get("cells", []):
			var pos: Vector2i = Vector2i(int(c[0]), int(c[1]))
			cells.append(pos)
			g.cells[pos.x][pos.y] = GridData.OCCUPIED
			g.cell_plant[pos] = id
		g.plants[id] = {plant_id = pd.plant_id, cells = cells, placed_order = id}
	var mods: Dictionary = data.get("modifiers", {})
	for key: String in mods:
		var parts: PackedStringArray = key.split(",")
		var pos: Vector2i = Vector2i(int(parts[0]), int(parts[1]))
		g.cell_modifiers[pos] = mods[key]
	var blocked: Dictionary = data.get("blocked", {})
	for key: String in blocked:
		var parts: PackedStringArray = key.split(",")
		var pos: Vector2i = Vector2i(int(parts[0]), int(parts[1]))
		g.cells[pos.x][pos.y] = int(blocked[key])
	return g
