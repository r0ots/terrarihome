class_name PackDatabase

const PACKS := {
	"legumes_frais": {
		"id": "legumes_frais",
		"name_fr": "Legumes Frais",
		"tier": "eco",
		"base_cost": 3,
		"card_count": 3,
		"inflation": 1,
		"contents": {"carotte": 50, "boutomate": 30, "radis_rose": 20},
		"required_upgrade": "",
	},
	"herbes_du_jardin": {
		"id": "herbes_du_jardin",
		"name_fr": "Herbes du Jardin",
		"tier": "eco",
		"base_cost": 3,
		"card_count": 3,
		"inflation": 1,
		"contents": {"herberaude": 50, "persil_piquant": 30, "cactus_epineux": 20},
		"required_upgrade": "",
	},
	"potager_mixte": {
		"id": "potager_mixte",
		"name_fr": "Potager Mixte",
		"tier": "standard",
		"base_cost": 4,
		"card_count": 3,
		"inflation": 2,
		"contents": {"carotte": 25, "herberaude": 25, "boutomate": 25, "basilic_royal": 25},
		"required_upgrade": "",
	},
	"champignons_delicieux": {
		"id": "champignons_delicieux",
		"name_fr": "Champignons Delicieux",
		"tier": "standard",
		"base_cost": 4,
		"card_count": 3,
		"inflation": 2,
		"contents": {"champi_mi_gnon": 40, "truffe": 35, "morille_doree": 25},
		"required_upgrade": "spores_champignon",
	},
	"racines_profondes": {
		"id": "racines_profondes",
		"name_fr": "Racines Profondes",
		"tier": "standard",
		"base_cost": 5,
		"card_count": 3,
		"inflation": 2,
		"contents": {"patate_douce": 30, "navet_tournoyant": 25, "radis_rose": 25, "ail_des_ours": 20},
		"required_upgrade": "decouverte_racines",
	},
	"sous_bois_mystique": {
		"id": "sous_bois_mystique",
		"name_fr": "Sous-Bois Mystique",
		"tier": "premium",
		"base_cost": 6,
		"card_count": 4,
		"inflation": 3,
		"contents": {"mousse_lunaire": 25, "pleurote_cascade": 25, "fougere_dor": 25, "morille_doree": 25},
		"required_upgrade": "packs_avances",
	},
	"festin_du_chef": {
		"id": "festin_du_chef",
		"name_fr": "Festin du Chef",
		"tier": "premium",
		"base_cost": 7,
		"card_count": 4,
		"inflation": 3,
		"contents": {"basilic_royal": 25, "ail_des_ours": 25, "persil_piquant": 25, "fraise_sauvage": 25},
		"required_upgrade": "packs_avances",
	},
	"recolte_legendaire": {
		"id": "recolte_legendaire",
		"name_fr": "Recolte Legendaire",
		"tier": "legendary",
		"base_cost": 10,
		"card_count": 5,
		"inflation": 5,
		"contents": {"gingembre_tourne_vent": 20, "fraise_sauvage": 20, "pleurote_cascade": 20, "ail_des_ours": 20, "fougere_dor": 20},
		"required_upgrade": "recolte_legendaire",
	},
}


static func get_pack(id: String) -> Dictionary:
	return PACKS.get(id, {})


static func get_pack_price(id: String, price_modifier: int) -> int:
	var pack := get_pack(id)
	return pack.get("base_cost", 0) + price_modifier


static func get_available_packs(unlocked_upgrades: Array[String]) -> Array[String]:
	var available: Array[String] = []
	for id in PACKS:
		var req: String = PACKS[id]["required_upgrade"]
		if req == "" or req in unlocked_upgrades:
			available.append(id)
	return available
