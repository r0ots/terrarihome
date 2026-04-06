extends Node2D

@onready var grid_view: GridView = $GridView
@onready var hand_bar: HandView = $UI/HandBar
@onready var shop_panel: ShopView = $UI/ShopPanel
@onready var score_label: Label = $UI/TopBar/ScoreLabel
@onready var prestige_btn: Button = $UI/TopBar/PrestigeButton
@onready var tree_btn: Button = $UI/TopBar/TreeButton
@onready var pp_label: Label = $UI/TopBar/PrestigePointsLabel
@onready var reset_btn: Button = $UI/TopBar/ResetButton
@onready var bin_btn: Button = $UI/BinButton
@onready var encyc_btn: Button = $UI/TopBar/EncycButton
@onready var tool_bar: ToolBar = $UI/ToolBar

var grid_data: GridData
var scoring: ScoringEngine
var selected_card_index: int = -1
var prestige_tree_scene: PackedScene = preload("res://scenes/prestige/prestige_tree.tscn")
var prestige_tree_instance: Control = null
var encyclopedia_instance: Control = null


func _ready() -> void:
	grid_data = GridData.new()
	_apply_grid_patches()
	scoring = ScoringEngine.new(grid_data)
	grid_view.set_grid_data(grid_data)

	GameManager.points_changed.connect(_on_points_changed)
	GameManager.prestige_done.connect(_on_prestige_done)
	grid_view.cell_clicked.connect(_on_cell_clicked)
	grid_view.cell_hovered.connect(_on_cell_hovered)
	hand_bar.card_selected.connect(_on_card_selected)
	hand_bar.card_deselected.connect(_on_card_deselected)
	shop_panel.pack_purchased.connect(_on_pack_purchased)
	prestige_btn.pressed.connect(_on_prestige_pressed)
	tree_btn.pressed.connect(_on_tree_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	bin_btn.pressed.connect(_on_bin_pressed)
	encyc_btn.pressed.connect(_on_encyc_pressed)
	tool_bar.tool_selected.connect(_on_tool_selected)
	tool_bar.tool_deselected.connect(_on_tool_deselected)

	if SaveManager.has_save():
		SaveManager.load_game()
		if not SaveManager.grid_save_data.is_empty():
			grid_data = SaveManager.deserialize_grid(SaveManager.grid_save_data)
			scoring = ScoringEngine.new(grid_data)
			grid_view.set_grid_data(grid_data)
		if SaveManager.shop_slots_save.size() > 0:
			shop_panel.shop_slots.clear()
			for s: String in SaveManager.shop_slots_save:
				shop_panel.shop_slots.append(StringName(s))
			if SaveManager.shop_bonus_save.size() > 0:
				shop_panel.slot_bonus.clear()
				for b: int in SaveManager.shop_bonus_save:
					shop_panel.slot_bonus.append(b)

	_refresh_all()


func _refresh_all() -> void:
	_on_points_changed(GameManager.points)
	hand_bar.refresh(GameManager.hand)
	shop_panel.refresh(GameManager.points, GameManager.hand.size(), GameManager.hand_size_max)
	grid_view.refresh()
	pp_label.text = "PP: %d" % GameManager.prestige_points
	# Bin visibility & label
	bin_btn.visible = GameManager.is_upgrade_unlocked(&"poubelle")
	if GameManager.is_upgrade_unlocked(&"composteur"):
		bin_btn.text = "Composteur"
	else:
		bin_btn.text = "Poubelle"
	# Encyclopedia visibility
	encyc_btn.visible = GameManager.is_upgrade_unlocked(&"encyclopedie")
	# Tool bar
	tool_bar.refresh()


func _on_points_changed(total: int) -> void:
	score_label.text = "Points: %d" % total
	prestige_btn.disabled = not GameManager.can_prestige()
	prestige_btn.text = "Prestige (%d PP)" % GameManager.get_prestige_value() if GameManager.can_prestige() else "Prestige"
	pp_label.text = "PP: %d" % GameManager.prestige_points
	shop_panel.refresh(GameManager.points, GameManager.hand.size(), GameManager.hand_size_max)


func _on_card_selected(index: int) -> void:
	selected_card_index = index
	tool_bar.deselect()


func _on_card_deselected() -> void:
	selected_card_index = -1
	grid_view.clear_preview()


func _on_cell_hovered(grid_pos: Vector2i) -> void:
	if tool_bar.selected_tool != &"":
		grid_view.set_tool_hover(tool_bar.selected_tool, grid_pos)
		return
	grid_view.active_tool = &""
	if selected_card_index < 0 or selected_card_index >= GameManager.hand.size():
		grid_view.clear_preview()
		return
	grid_view.set_preview(GameManager.hand[selected_card_index], grid_pos)


func _on_cell_clicked(grid_pos: Vector2i) -> void:
	if tool_bar.selected_tool != &"":
		_use_tool(tool_bar.selected_tool, grid_pos)
		return
	if selected_card_index < 0 or selected_card_index >= GameManager.hand.size():
		return
	var plant_id: StringName = GameManager.hand[selected_card_index]
	if not grid_data.can_place_plant(plant_id, grid_pos):
		return

	var inst_id: int = grid_data.place_plant(plant_id, grid_pos)
	GameManager.hand.remove_at(selected_card_index)
	selected_card_index = -1

	var result: Dictionary = scoring.score_placement(plant_id, inst_id)
	if result.total > 0:
		GameManager.points += result.total
		var per_cell: Dictionary = {}
		for entry: Dictionary in result.breakdown:
			var c: Vector2i = entry.cell
			per_cell[c] = per_cell.get(c, 0) + entry.points
		for c: Vector2i in per_cell:
			grid_view.spawn_floating_text(c, "+%d" % per_cell[c], Color(1.0, 0.85, 0.4))

	hand_bar.refresh(GameManager.hand)
	hand_bar.deselect()
	grid_view.clear_preview()
	grid_view.refresh()
	shop_panel.refresh(GameManager.points, GameManager.hand.size(), GameManager.hand_size_max)
	_auto_save()


func _on_pack_purchased(slot_index: int) -> void:
	var cost: int = shop_panel.get_pack_cost(slot_index)
	if not GameManager.spend_points(cost):
		return
	var cards: Array[String] = shop_panel.draw_cards_from_pack(slot_index)
	for card_id: String in cards:
		GameManager.hand.append(StringName(card_id))

	var pack: PackData = PackDatabase.get_pack(shop_panel.shop_slots[slot_index])
	var inflation: int = pack.inflation

	var available: Array[StringName] = PackDatabase.get_available_packs(GameManager.unlocked_upgrades)
	shop_panel.shop_slots[slot_index] = available[randi() % available.size()]
	shop_panel.slot_bonus[slot_index] += inflation
	shop_panel._pre_drawn_cards[slot_index] = shop_panel._roll_cards_for_slot(slot_index)

	_refresh_all()
	_auto_save()


func _on_prestige_pressed() -> void:
	if not GameManager.can_prestige():
		return
	var pp: int = GameManager.get_prestige_value()
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.dialog_text = "Prestige pour %d PP ?\nLa grille et la main seront reinitalisees." % pp
	dialog.confirmed.connect(func() -> void: GameManager.do_prestige())
	add_child(dialog)
	dialog.popup_centered()


func _on_prestige_done(_pp: int) -> void:
	grid_data = GridData.new()
	_apply_grid_patches()
	scoring = ScoringEngine.new(grid_data)
	grid_view.set_grid_data(grid_data)
	selected_card_index = -1
	shop_panel.roll_shop()
	_refresh_all()
	_auto_save()


func _on_tree_pressed() -> void:
	if prestige_tree_instance and is_instance_valid(prestige_tree_instance):
		prestige_tree_instance.show()
		prestige_tree_instance.refresh()
		return
	prestige_tree_instance = prestige_tree_scene.instantiate()
	prestige_tree_instance.closed.connect(func() -> void:
		_refresh_all()
	)
	$UI.add_child(prestige_tree_instance)


func _on_reset_pressed() -> void:
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.dialog_text = "Tout reinitialiser ?\nProgression, prestige, tout sera perdu."
	dialog.confirmed.connect(func() -> void:
		SaveManager.delete_save()
		GameManager.prestige_points = 0
		GameManager.hand_size_max = 5
		GameManager.unlocked_upgrades.clear()
		GameManager.starting_cards = [&"carotte", &"carotte", &"herberaude", &"herberaude", &"boutomate"]
		GameManager.new_game()
		grid_data = GridData.new()
		scoring = ScoringEngine.new(grid_data)
		grid_view.set_grid_data(grid_data)
		selected_card_index = -1
		shop_panel.roll_shop()
		_refresh_all()
	)
	add_child(dialog)
	dialog.popup_centered()


func _on_bin_pressed() -> void:
	if selected_card_index < 0 or selected_card_index >= GameManager.hand.size():
		return
	var plant_id: StringName = GameManager.hand[selected_card_index]
	if GameManager.is_upgrade_unlocked(&"composteur"):
		var data: PlantData = PlantDatabase.get_plant(plant_id)
		if data:
			GameManager.points += data.compost_value
	GameManager.hand.remove_at(selected_card_index)
	selected_card_index = -1
	hand_bar.deselect()
	_refresh_all()
	_auto_save()


func _on_encyc_pressed() -> void:
	if encyclopedia_instance and is_instance_valid(encyclopedia_instance):
		encyclopedia_instance.show()
		return
	encyclopedia_instance = Encyclopedia.new()
	encyclopedia_instance.closed.connect(func() -> void:
		encyclopedia_instance.hide()
	)
	$UI.add_child(encyclopedia_instance)


func _on_tool_selected(_tool_id: StringName) -> void:
	hand_bar.deselect()
	selected_card_index = -1
	grid_view.clear_preview()


func _on_tool_deselected() -> void:
	grid_view.active_tool = &""
	grid_view.queue_redraw()


func _use_tool(tool_id: StringName, grid_pos: Vector2i) -> void:
	if not grid_data.is_valid_pos(grid_pos):
		return
	var used := false
	match tool_id:
		&"shovel":
			used = _use_shovel(grid_pos)
		&"fertilizer":
			used = _use_fertilizer(grid_pos)
		&"watering_can":
			used = _use_watering_can(grid_pos)
	if not used:
		return
	GameManager.tool_inventory.erase(tool_id)
	tool_bar.deselect()
	grid_view.active_tool = &""
	grid_view.clear_preview()
	_refresh_all()
	_auto_save()


func _use_shovel(pos: Vector2i) -> bool:
	var inst_id: int = grid_data.get_plant_at(pos)
	if inst_id == -1:
		return false
	var plant: Dictionary = grid_data.plants.get(inst_id, {})
	if plant.is_empty():
		return false
	var hole_cells: Array[Vector2i] = []
	for c: Vector2i in plant.cells:
		hole_cells.append(c)
	var plant_id: StringName = grid_data.remove_plant(inst_id)
	for c: Vector2i in hole_cells:
		grid_data.cells[c.x][c.y] = GridData.BLOCKED_HOLE
	if GameManager.hand.size() < GameManager.hand_size_max:
		GameManager.hand.append(plant_id)
	grid_view.spawn_floating_text(pos, "Retire!", Color(0.9, 0.4, 0.3))
	return true


func _use_fertilizer(pos: Vector2i) -> bool:
	var area: Array[Vector2i] = grid_data.get_cells_in_area(pos, 1)
	for c: Vector2i in area:
		grid_data.add_modifier(c, {type = "plus1", source = -1})
	for c: Vector2i in area:
		grid_view.spawn_floating_text(c, "+1", Color(0.4, 0.8, 0.3))
	return true


func _use_watering_can(pos: Vector2i) -> bool:
	var inst_ids: Array[int] = grid_data.get_plant_instances_in_area(pos, 1)
	if inst_ids.is_empty():
		return false
	var result: Dictionary = scoring.score_retrigger(inst_ids)
	if result.total > 0:
		GameManager.points += result.total
		var per_cell: Dictionary = {}
		for entry: Dictionary in result.breakdown:
			var c: Vector2i = entry.cell
			per_cell[c] = per_cell.get(c, 0) + entry.points
		for c: Vector2i in per_cell:
			grid_view.spawn_floating_text(c, "+%d" % per_cell[c], Color(0.4, 0.7, 1.0))
	else:
		grid_view.spawn_floating_text(pos, "0", Color(0.5, 0.5, 0.5))
	return true


func _apply_grid_patches() -> void:
	if GameManager.is_upgrade_unlocked(&"parcelle_herbeuse"):
		grid_data.expand_grid(6, 0, &"standard")
	if GameManager.is_upgrade_unlocked(&"terrain_rocheux"):
		grid_data.expand_grid(6, 0, &"rocky")
	if GameManager.is_upgrade_unlocked(&"riviere"):
		grid_data.expand_grid(6, 0, &"river")


func _auto_save() -> void:
	SaveManager.grid_save_data = SaveManager.serialize_grid(grid_data)
	SaveManager.shop_slots_save = shop_panel.shop_slots.duplicate()
	SaveManager.shop_bonus_save = shop_panel.slot_bonus.duplicate()
	SaveManager.save_game()
