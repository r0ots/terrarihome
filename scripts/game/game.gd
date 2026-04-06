extends Node2D

@onready var grid_view: GridView = $GridView
@onready var hand_bar: HandView = $UI/HandBar
@onready var shop_panel: ShopView = $UI/ShopPanel
@onready var score_label: Label = $UI/TopBar/ScoreLabel
@onready var prestige_btn: Button = $UI/TopBar/PrestigeButton
@onready var tree_btn: Button = $UI/TopBar/TreeButton
@onready var pp_label: Label = $UI/TopBar/PrestigePointsLabel

var grid_data: GridData
var scoring: ScoringEngine
var selected_card_index: int = -1
var prestige_tree_scene: PackedScene = preload("res://scenes/prestige/prestige_tree.tscn")
var prestige_tree_instance: Control = null


func _ready() -> void:
	grid_data = GridData.new()
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

	_refresh_all()


func _refresh_all() -> void:
	_on_points_changed(GameManager.points)
	hand_bar.refresh(GameManager.hand)
	shop_panel.refresh(GameManager.points, GameManager.hand.size(), GameManager.hand_size_max)
	grid_view.refresh()
	pp_label.text = "PP: %d" % GameManager.prestige_points


func _on_points_changed(total: int) -> void:
	score_label.text = "Points: %d" % total
	prestige_btn.disabled = not GameManager.can_prestige()
	prestige_btn.text = "Prestige (%d PP)" % GameManager.get_prestige_value() if GameManager.can_prestige() else "Prestige"
	pp_label.text = "PP: %d" % GameManager.prestige_points
	shop_panel.refresh(GameManager.points, GameManager.hand.size(), GameManager.hand_size_max)


func _on_card_selected(index: int) -> void:
	selected_card_index = index


func _on_card_deselected() -> void:
	selected_card_index = -1
	grid_view.clear_preview()


func _on_cell_hovered(grid_pos: Vector2i) -> void:
	if selected_card_index < 0 or selected_card_index >= GameManager.hand.size():
		grid_view.clear_preview()
		return
	grid_view.set_preview(GameManager.hand[selected_card_index], grid_pos)


func _on_cell_clicked(grid_pos: Vector2i) -> void:
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
		grid_view.spawn_floating_text(grid_pos, "+%d" % result.total, Color.GOLD)

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
	GameManager.pack_price_modifier += pack.inflation

	var available: Array[StringName] = PackDatabase.get_available_packs(GameManager.unlocked_upgrades)
	shop_panel.shop_slots[slot_index] = available[randi() % available.size()]

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


func _auto_save() -> void:
	SaveManager.grid_save_data = SaveManager.serialize_grid(grid_data)
	SaveManager.shop_slots_save = shop_panel.shop_slots.duplicate()
	SaveManager.save_game()
