class_name PackDatabase

static var _packs: Dictionary = {}
static var _initialized := false


static func _ensure_init() -> void:
	if _initialized: return
	_initialized = true
	_register_all()


static func get_pack(id: StringName) -> PackData:
	_ensure_init()
	return _packs.get(id)


static func get_all() -> Dictionary:
	_ensure_init()
	return _packs


static func get_pack_price(id: StringName, price_modifier: int) -> int:
	var p := get_pack(id)
	return p.base_cost + price_modifier if p else 0


static func get_available_packs(unlocked: Array[StringName]) -> Array[StringName]:
	_ensure_init()
	var result: Array[StringName] = []
	for id: StringName in _packs:
		var p: PackData = _packs[id]
		if p.required_upgrade == &"" or p.required_upgrade in unlocked:
			result.append(id)
	return result


static func _register_all() -> void:
	_add(&"legumes_frais", "Legumes Frais", &"eco", 3, 3, 1, {"carotte": 50, "boutomate": 30, "radis_rose": 20}, &"")
	_add(&"herbes_du_jardin", "Herbes du Jardin", &"eco", 3, 3, 1, {"herberaude": 50, "persil_piquant": 30, "cactus_epineux": 20}, &"")
	_add(&"potager_mixte", "Potager Mixte", &"standard", 4, 3, 2, {"carotte": 25, "herberaude": 25, "boutomate": 25, "basilic_royal": 25}, &"")
	_add(&"champignons_delicieux", "Champignons Delicieux", &"standard", 4, 3, 2, {"champi_mi_gnon": 40, "truffe": 35, "morille_doree": 25}, &"spores_champignon")
	_add(&"racines_profondes", "Racines Profondes", &"standard", 5, 3, 2, {"patate_douce": 30, "navet_tournoyant": 25, "radis_rose": 25, "ail_des_ours": 20}, &"decouverte_racines")
	_add(&"sous_bois_mystique", "Sous-Bois Mystique", &"premium", 6, 4, 3, {"mousse_lunaire": 25, "pleurote_cascade": 25, "fougere_dor": 25, "morille_doree": 25}, &"packs_avances")
	_add(&"festin_du_chef", "Festin du Chef", &"premium", 7, 4, 3, {"basilic_royal": 25, "ail_des_ours": 25, "persil_piquant": 25, "fraise_sauvage": 25}, &"packs_avances")
	_add(&"recolte_legendaire", "Recolte Legendaire", &"legendary", 10, 5, 5, {"gingembre_tourne_vent": 20, "fraise_sauvage": 20, "pleurote_cascade": 20, "ail_des_ours": 20, "fougere_dor": 20}, &"recolte_legendaire")


static func _add(id: StringName, name_fr: String, tier: StringName, base_cost: int, card_count: int, inflation: int, contents: Dictionary, required_upgrade: StringName) -> void:
	var p := PackData.new()
	p.id = id
	p.name_fr = name_fr
	p.tier = tier
	p.base_cost = base_cost
	p.card_count = card_count
	p.inflation = inflation
	p.contents = contents
	p.required_upgrade = required_upgrade
	_packs[id] = p
