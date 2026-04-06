class_name ShopView extends HBoxContainer

signal pack_purchased(slot_index: int)

var shop_slots: Array[String] = []


func _ready() -> void:
	roll_shop()


func roll_shop() -> void:
	var available := PackDatabase.get_available_packs(GameManager.unlocked_upgrades)
	shop_slots.clear()
	for i in 3:
		shop_slots.append(available[randi() % available.size()])


func get_pack_cost(slot_index: int) -> int:
	if slot_index >= shop_slots.size():
		return 999
	return PackDatabase.get_pack_price(shop_slots[slot_index], GameManager.pack_price_modifier)


func draw_cards_from_pack(slot_index: int) -> Array:
	if slot_index >= shop_slots.size():
		return []
	var pack := PackDatabase.get_pack(shop_slots[slot_index])
	var pool: Dictionary = pack.get("contents", {})
	var cards: Array = []
	for _i in pack.get("card_count", 3):
		cards.append(_weighted_pick(pool))
	return cards


func _weighted_pick(pool: Dictionary) -> String:
	var total := 0
	for w: int in pool.values():
		total += w
	var roll := randi() % total
	var acc := 0
	for key: String in pool:
		acc += pool[key]
		if roll < acc:
			return key
	return pool.keys()[0]


func refresh(current_points: int, hand_size: int, hand_max: int) -> void:
	for c in get_children():
		c.queue_free()
	for i in shop_slots.size():
		var pack := PackDatabase.get_pack(shop_slots[i])
		var cost := get_pack_cost(i)
		var room := hand_max - hand_size
		var can_buy := current_points >= cost and room >= pack.get("card_count", 3)
		add_child(_create_pack_slot(i, pack, cost, can_buy))


func _create_pack_slot(index: int, pack: Dictionary, cost: int, can_buy: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 100)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var name_lbl := Label.new()
	name_lbl.text = pack.get("name_fr", "Pack")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(name_lbl)

	var info_lbl := Label.new()
	info_lbl.text = "%d pts  |  %d cartes" % [cost, pack.get("card_count", 3)]
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.add_theme_font_size_override("font_size", 11)
	info_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info_lbl)

	var btn := Button.new()
	btn.text = "Acheter"
	btn.disabled = not can_buy
	btn.pressed.connect(func() -> void: pack_purchased.emit(index))
	vbox.add_child(btn)

	panel.add_child(vbox)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.18)
	sb.border_color = Color(0.4, 0.4, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)

	return panel
