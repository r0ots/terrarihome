class_name PrestigeDatabase

const BRANCHES := [
	"grille_biomes", "plantes_packs", "main_cartes", "outils_inventaire", "savoir", "principale"
]

const BRANCH_NAMES := {
	"grille_biomes": "Grille & Biomes",
	"plantes_packs": "Plantes & Packs",
	"main_cartes": "Main & Cartes",
	"outils_inventaire": "Outils & Inventaire",
	"savoir": "Savoir",
	"principale": "Principale",
}

const NODES := {
	# Grille & Biomes (4 pts)
	"parcelle_herbeuse": {
		"id": "parcelle_herbeuse", "name_fr": "Parcelle Herbeuse", "cost": 1,
		"prerequisites": [], "branch": "grille_biomes",
		"effects": ["grid_patch_standard"],
	},
	"terrain_rocheux": {
		"id": "terrain_rocheux", "name_fr": "Terrain Rocheux", "cost": 1,
		"prerequisites": ["parcelle_herbeuse"], "branch": "grille_biomes",
		"effects": ["grid_patch_rocky"],
	},
	"riviere": {
		"id": "riviere", "name_fr": "Riviere", "cost": 2,
		"prerequisites": ["parcelle_herbeuse"], "branch": "grille_biomes",
		"effects": ["grid_patch_river"],
	},
	# Plantes & Packs (4 pts)
	"spores_champignon": {
		"id": "spores_champignon", "name_fr": "Spores de Champignon", "cost": 1,
		"prerequisites": [], "branch": "plantes_packs",
		"effects": ["unlock_mushrooms", "unlock_pack_champignons"],
	},
	"decouverte_racines": {
		"id": "decouverte_racines", "name_fr": "Decouverte des Racines", "cost": 1,
		"prerequisites": [], "branch": "plantes_packs",
		"effects": ["unlock_roots", "unlock_pack_racines"],
	},
	"packs_avances": {
		"id": "packs_avances", "name_fr": "Packs Avances", "cost": 1,
		"prerequisites": ["spores_champignon"], "branch": "plantes_packs",
		"effects": ["unlock_pack_sous_bois", "unlock_pack_festin"],
	},
	"recolte_legendaire": {
		"id": "recolte_legendaire", "name_fr": "Recolte Legendaire", "cost": 1,
		"prerequisites": ["packs_avances", "decouverte_racines"], "branch": "plantes_packs",
		"effects": ["unlock_pack_legendaire"],
	},
	# Main & Cartes (4 pts)
	"poubelle": {
		"id": "poubelle", "name_fr": "Poubelle", "cost": 1,
		"prerequisites": [], "branch": "main_cartes",
		"effects": ["unlock_discard"],
	},
	"composteur": {
		"id": "composteur", "name_fr": "Composteur", "cost": 1,
		"prerequisites": ["poubelle"], "branch": "main_cartes",
		"effects": ["unlock_compost"],
	},
	"main_plus1": {
		"id": "main_plus1", "name_fr": "Main +1", "cost": 1,
		"prerequisites": [], "branch": "main_cartes",
		"effects": ["hand_size_plus1"],
	},
	"starter_bonus": {
		"id": "starter_bonus", "name_fr": "Starter Bonus", "cost": 1,
		"prerequisites": ["main_plus1"], "branch": "main_cartes",
		"effects": ["starter_extra_card"],
	},
	# Outils & Inventaire (4 pts)
	"ceinture_outils": {
		"id": "ceinture_outils", "name_fr": "Ceinture d'Outils", "cost": 1,
		"prerequisites": [], "branch": "outils_inventaire",
		"effects": ["unlock_tool_belt"],
	},
	"pelle": {
		"id": "pelle", "name_fr": "Pelle", "cost": 1,
		"prerequisites": ["ceinture_outils"], "branch": "outils_inventaire",
		"effects": ["unlock_shovel"],
	},
	"engrais": {
		"id": "engrais", "name_fr": "Engrais", "cost": 1,
		"prerequisites": ["ceinture_outils"], "branch": "outils_inventaire",
		"effects": ["unlock_fertilizer"],
	},
	"arrosoir": {
		"id": "arrosoir", "name_fr": "Arrosoir", "cost": 1,
		"prerequisites": ["pelle", "engrais"], "branch": "outils_inventaire",
		"effects": ["unlock_watering_can"],
	},
	# Savoir (3 pts)
	"encyclopedie": {
		"id": "encyclopedie", "name_fr": "Encyclopedie", "cost": 1,
		"prerequisites": [], "branch": "savoir",
		"effects": ["unlock_encyclopedia"],
	},
	"loupe": {
		"id": "loupe", "name_fr": "Loupe", "cost": 1,
		"prerequisites": ["encyclopedie"], "branch": "savoir",
		"effects": ["unlock_magnifier"],
	},
	"rayons_x": {
		"id": "rayons_x", "name_fr": "Rayons X", "cost": 1,
		"prerequisites": ["loupe"], "branch": "savoir",
		"effects": ["unlock_xray"],
	},
	# Principale (2 pts)
	"jardinier_expert": {
		"id": "jardinier_expert", "name_fr": "Jardinier Expert", "cost": 1,
		"prerequisites": ["ALL_OTHER_BRANCHES"], "branch": "principale",
		"effects": ["cosmetic_expert", "global_scoring_bonus"],
	},
	"terrarium_parfait": {
		"id": "terrarium_parfait", "name_fr": "Terrarium Parfait", "cost": 1,
		"prerequisites": ["jardinier_expert"], "branch": "principale",
		"effects": ["game_complete"],
	},
}


static func get_node(id: String) -> Dictionary:
	return NODES.get(id, {})


static func get_all_nodes() -> Dictionary:
	return NODES


static func get_branch(branch: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in NODES.values():
		if node.branch == branch:
			result.append(node)
	return result


static func can_unlock(id: String, unlocked: Array) -> bool:
	var node := get_node(id)
	if node.is_empty() or id in unlocked:
		return false
	for prereq in node.prerequisites:
		if prereq == "ALL_OTHER_BRANCHES":
			if not are_all_branches_complete(unlocked):
				return false
		elif prereq not in unlocked:
			return false
	return true


static func is_branch_complete(branch: String, unlocked: Array) -> bool:
	for node in get_branch(branch):
		if node.id not in unlocked:
			return false
	return true


static func are_all_branches_complete(unlocked: Array) -> bool:
	for branch in BRANCHES:
		if branch == "principale":
			continue
		if not is_branch_complete(branch, unlocked):
			return false
	return true
