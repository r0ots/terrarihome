class_name PlantDatabase

static var _plants: Dictionary = {}
static var _initialized := false


static func _ensure_init() -> void:
	if _initialized: return
	_initialized = true
	_register_all()


static func get_plant(id: StringName) -> PlantData:
	_ensure_init()
	return _plants.get(id)


static func get_all() -> Dictionary:
	_ensure_init()
	return _plants


static func _register_all() -> void:
	_add(&"carotte", "Carotte", "Carrot", [Vector2i(0,0), Vector2i(0,1)], [&"legume"], &"per_adjacent_type", [&"legume"], &"bidirectional", 0, 1, true)
	_add(&"herberaude", "Herberaude", "Herberaude", [Vector2i(0,0)], [&"plante"], &"flat", [], &"on_place_only", 1, 1, true)
	_add(&"boutomate", "Boutomate", "Boutomate", [Vector2i(0,0), Vector2i(1,0)], [&"legume"], &"per_adjacent_type", [&"legume", &"plante"], &"bidirectional", 0, 2, true)
	_add(&"persil_piquant", "Persil Piquant", "Spicy Parsley", [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)], [&"plante"], &"per_adjacent_type", [&"plante"], &"bidirectional", 0, 2, true)
	_add(&"cactus_epineux", "Cactus Epineux", "Spiny Cactus", [Vector2i(0,0)], [&"plante"], &"per_adjacent_empty", [], &"on_place_only", 0, 1, true)
	_add(&"basilic_royal", "Basilic Royal", "Royal Basil", [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)], [&"plante", &"legume"], &"per_adjacent_type", [&"legume"], &"bidirectional", 0, 2, true)
	_add(&"truffe", "Truffe", "Truffle", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], [&"champi"], &"per_adjacent_type", [&"champi"], &"bidirectional", 0, 2, false)
	_add(&"champi_mi_gnon", "Champi-mi-gnon", "Cute Shroom", [Vector2i(0,0)], [&"champi"], &"per_adjacent_any", [], &"on_place_only", 0, 1, false)
	_add(&"morille_doree", "Morille Doree", "Golden Morel", [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)], [&"champi"], &"per_adjacent_type", [&"champi"], &"bidirectional", 0, 2, false)
	_add(&"pleurote_cascade", "Pleurote Cascade", "Cascade Oyster", [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)], [&"champi"], &"per_adjacent_type", [&"champi", &"plante"], &"bidirectional", 0, 3, false)
	_add(&"mousse_lunaire", "Mousse Lunaire", "Moon Moss", [Vector2i(0,0), Vector2i(1,0)], [&"plante"], &"per_adjacent_type", [&"plante", &"champi"], &"bidirectional", 0, 2, false)
	_add(&"patate_douce", "Patate Douce", "Sweet Potato", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1)], [&"legume", &"racine"], &"per_adjacent_type", [&"racine"], &"bidirectional", 0, 2, false)
	_add(&"radis_rose", "Radis Rose", "Pink Radish", [Vector2i(0,0)], [&"legume", &"racine"], &"flat", [], &"on_place_only", 2, 1, false)
	_add(&"navet_tournoyant", "Navet Tournoyant", "Spinning Turnip", [Vector2i(0,0), Vector2i(0,1)], [&"racine", &"legume"], &"modifier_plus1", [&"racine"], &"bidirectional", 0, 2, false)
	_add(&"gingembre_tourne_vent", "Gingembre Tourne-Vent", "Windmill Ginger", [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(1,2)], [&"legume", &"racine"], &"modifier_x2", [&"legume"], &"bidirectional", 0, 3, false)
	_add(&"ail_des_ours", "Ail des Ours", "Wild Garlic", [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], [&"legume", &"racine"], &"per_adjacent_type", [&"legume", &"racine"], &"bidirectional", 0, 3, false)
	_add(&"fougere_dor", "Fougere d'Or", "Golden Fern", [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)], [&"plante"], &"per_adjacent_type", [&"plante"], &"bidirectional", 0, 3, false)
	_add(&"fraise_sauvage", "Fraise Sauvage", "Wild Strawberry", [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)], [&"legume", &"plante"], &"per_adjacent_type", [&"legume", &"plante"], &"bidirectional", 0, 4, false)


static func _add(id: StringName, name_fr: String, name_en: String, shape: Array[Vector2i], types: Array[StringName], combo_type: StringName, combo_targets: Array[StringName], scoring_mode: StringName, flat_value: int, compost_value: int, is_base: bool) -> void:
	var p := PlantData.new()
	p.id = id
	p.name_fr = name_fr
	p.name_en = name_en
	p.shape = shape
	p.types = types
	p.combo_type = combo_type
	p.combo_targets = combo_targets
	p.scoring_mode = scoring_mode
	p.flat_value = flat_value
	p.compost_value = compost_value
	p.is_base = is_base
	_plants[id] = p
