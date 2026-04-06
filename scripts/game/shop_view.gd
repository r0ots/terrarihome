class_name ShopView extends HBoxContainer

signal pack_purchased(slot_index: int)

var shop_slots: Array[StringName] = []
var slot_bonus: Array[int] = [0, 0, 0]
var _pre_drawn_cards: Array[Array] = [[], [], []]
var _info_popup: PanelContainer = null


func _ready() -> void:
	roll_shop()


func roll_shop() -> void:
	var available: Array[StringName] = PackDatabase.get_available_packs(GameManager.unlocked_upgrades)
	shop_slots.clear()
	slot_bonus = [0, 0, 0]
	_pre_drawn_cards = [[], [], []]
	for i: int in 3:
		shop_slots.append(available[randi() % available.size()])
	_pre_roll_all()


func _pre_roll_all() -> void:
	for i: int in shop_slots.size():
		_pre_drawn_cards[i] = _roll_cards_for_slot(i)


func _roll_cards_for_slot(slot_index: int) -> Array[String]:
	var pack: PackData = PackDatabase.get_pack(shop_slots[slot_index])
	if not pack:
		return []
	var cards: Array[String] = []
	for _i: int in pack.card_count + GameManager.pack_card_bonus:
		cards.append(_weighted_pick(pack.contents))
	return cards


func get_pack_cost(slot_index: int) -> int:
	if GameManager.free_first_pack and not GameManager.free_pack_used:
		return 0
	if slot_index >= shop_slots.size():
		return 999
	var pack: PackData = PackDatabase.get_pack(shop_slots[slot_index])
	return pack.base_cost + slot_bonus[slot_index] if pack else 999


func draw_cards_from_pack(slot_index: int) -> Array[String]:
	if slot_index >= shop_slots.size():
		return []
	var cards: Array[String] = []
	if GameManager.is_upgrade_unlocked(&"rayons_x") and _pre_drawn_cards[slot_index].size() > 0:
		cards.assign(_pre_drawn_cards[slot_index])
		_pre_drawn_cards[slot_index] = []
	else:
		var pack: PackData = PackDatabase.get_pack(shop_slots[slot_index])
		for _i: int in pack.card_count + GameManager.pack_card_bonus:
			cards.append(_weighted_pick(pack.contents))
	_try_tool_bonus()
	return cards


func _try_tool_bonus() -> void:
	if not GameManager.is_upgrade_unlocked(&"unlock_tool_belt"):
		return
	if GameManager.tool_inventory.size() >= GameManager.tool_inventory_max:
		return
	if randf() >= 0.15:
		return
	var tid: StringName = _roll_tool_bonus()
	if tid != &"":
		GameManager.tool_inventory.append(tid)


func _roll_tool_bonus() -> StringName:
	var pool: Dictionary = {}
	if GameManager.is_upgrade_unlocked(&"unlock_shovel"):
		pool[&"shovel"] = 40
	if GameManager.is_upgrade_unlocked(&"unlock_fertilizer"):
		pool[&"fertilizer"] = 40
	if GameManager.is_upgrade_unlocked(&"unlock_watering_can"):
		pool[&"watering_can"] = 20
	if pool.is_empty():
		return &""
	var total: int = 0
	for w: int in pool.values():
		total += w
	var roll: int = randi() % total
	var acc: int = 0
	for key: StringName in pool:
		acc += pool[key]
		if roll < acc:
			return key
	return pool.keys()[0]


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
		var has_room: bool = GameManager.overflow_compost or room >= pack.card_count + GameManager.pack_card_bonus
		var can_buy: bool = current_points >= cost and has_room
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
	info_lbl.text = "%d pts  |  %d cartes" % [cost, pack.card_count + GameManager.pack_card_bonus]
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

	# Hover info for loupe / rayons_x
	if GameManager.is_upgrade_unlocked(&"loupe"):
		panel.mouse_entered.connect(_show_pack_info.bind(index, panel))
		panel.mouse_exited.connect(_hide_pack_info)

	return panel


func _show_pack_info(slot_index: int, anchor: PanelContainer) -> void:
	_hide_pack_info()
	var pack: PackData = PackDatabase.get_pack(shop_slots[slot_index])
	if not pack:
		return

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
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85))

	if GameManager.is_upgrade_unlocked(&"rayons_x"):
		# Show exact pre-drawn cards
		var lines: PackedStringArray = ["Cartes exactes:"]
		var cards: Array = _pre_drawn_cards[slot_index]
		for card_id: String in cards:
			var data: PlantData = PlantDatabase.get_plant(StringName(card_id))
			lines.append("  - %s" % (data.name_fr if data else card_id))
		label.text = "\n".join(lines)
	else:
		# Loupe: show plant types with odds
		var total: int = 0
		for w: int in pack.contents.values():
			total += w
		var lines: PackedStringArray = ["Contenu possible:"]
		for key: String in pack.contents:
			var data: PlantData = PlantDatabase.get_plant(StringName(key))
			var pct: int = pack.contents[key] * 100 / total
			lines.append("  %s — %d%%" % [data.name_fr if data else key, pct])
		label.text = "\n".join(lines)

	_info_popup.add_child(label)

	var canvas: CanvasLayer = get_parent() as CanvasLayer
	if canvas:
		canvas.add_child(_info_popup)
	else:
		get_tree().root.add_child(_info_popup)

	await get_tree().process_frame
	var rect: Rect2 = anchor.get_global_rect()
	_info_popup.position = Vector2(
		rect.position.x + rect.size.x / 2 - _info_popup.size.x / 2,
		rect.position.y - _info_popup.size.y - 8
	)


func _hide_pack_info() -> void:
	if _info_popup and is_instance_valid(_info_popup):
		_info_popup.queue_free()
		_info_popup = null
