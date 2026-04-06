class_name ShopView extends HBoxContainer

signal pack_purchased(slot_index: int)

var shop_slots: Array[StringName] = []


func _ready() -> void:
	roll_shop()


func roll_shop() -> void:
	var available: Array[StringName] = PackDatabase.get_available_packs(GameManager.unlocked_upgrades)
	shop_slots.clear()
	for i: int in 3:
		shop_slots.append(available[randi() % available.size()])


func get_pack_cost(slot_index: int) -> int:
	if slot_index >= shop_slots.size():
		return 999
	return PackDatabase.get_pack_price(shop_slots[slot_index], GameManager.pack_price_modifier)


func draw_cards_from_pack(slot_index: int) -> Array[String]:
	if slot_index >= shop_slots.size():
		return []
	var pack: PackData = PackDatabase.get_pack(shop_slots[slot_index])
	var cards: Array[String] = []
	for _i: int in pack.card_count:
		cards.append(_weighted_pick(pack.contents))
	return cards


func _weighted_pick(pool: Dictionary) -> String:
	var total: int = 0
	for w: int in pool.values():
		total += w
	var roll: int = randi() % total
	var acc: int = 0
	for key: String in pool:
		acc += pool[key]
		if roll < acc:
			return key
	return pool.keys()[0]


func refresh(current_points: int, hand_size: int, hand_max: int) -> void:
	for c: Node in get_children():
		c.queue_free()
	for i: int in shop_slots.size():
		var pack: PackData = PackDatabase.get_pack(shop_slots[i])
		var cost: int = get_pack_cost(i)
		var room: int = hand_max - hand_size
		var can_buy: bool = current_points >= cost and room >= pack.card_count
		add_child(_create_pack_slot(i, pack, cost, can_buy))


func _create_pack_slot(index: int, pack: PackData, cost: int, can_buy: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 100)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var name_lbl: Label = Label.new()
	name_lbl.text = pack.name_fr
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85))
	vbox.add_child(name_lbl)

	var info_lbl: Label = Label.new()
	info_lbl.text = "%d pts  |  %d cartes" % [cost, pack.card_count]
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.add_theme_font_size_override("font_size", 11)
	info_lbl.add_theme_color_override("font_color", Color(0.72, 0.65, 0.52))
	vbox.add_child(info_lbl)

	var btn: Button = Button.new()
	btn.text = "Acheter"
	btn.disabled = not can_buy
	btn.pressed.connect(func() -> void: pack_purchased.emit(index))
	vbox.add_child(btn)

	panel.add_child(vbox)

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.11, 0.08)
	sb.border_color = Color(0.45, 0.40, 0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)

	return panel
