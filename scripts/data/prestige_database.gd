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

static var _nodes: Dictionary = {}
static var _initialized := false


static func _ensure_init() -> void:
	if _initialized: return
	_initialized = true
	_register_all()


static func get_node(id: StringName) -> PrestigeNode:
	_ensure_init()
	return _nodes.get(id)


static func get_all_nodes() -> Dictionary:
	_ensure_init()
	return _nodes


static func get_branch(branch: String) -> Array[PrestigeNode]:
	_ensure_init()
	var result: Array[PrestigeNode] = []
	for node: PrestigeNode in _nodes.values():
		if node.branch == branch:
			result.append(node)
	return result


static func can_unlock(id: StringName, unlocked: Array) -> bool:
	var node := get_node(id)
	if not node or id in unlocked:
		return false
	for prereq: StringName in node.prerequisites:
		if prereq == &"ALL_OTHER_BRANCHES":
			if not are_all_branches_complete(unlocked):
				return false
		elif prereq not in unlocked:
			return false
	return true


static func is_branch_complete(branch: String, unlocked: Array) -> bool:
	for node: PrestigeNode in get_branch(branch):
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


static func _register_all() -> void:
	# Grille & Biomes
	_add(&"parcelle_herbeuse", "Parcelle Herbeuse", 1, [], &"grille_biomes", [&"grid_patch_standard"])
	_add(&"terrain_rocheux", "Terrain Rocheux", 1, [&"parcelle_herbeuse"], &"grille_biomes", [&"grid_patch_rocky"])
	_add(&"riviere", "Riviere", 2, [&"parcelle_herbeuse"], &"grille_biomes", [&"grid_patch_river"])
	# Plantes & Packs
	_add(&"spores_champignon", "Spores de Champignon", 1, [], &"plantes_packs", [&"unlock_mushrooms", &"unlock_pack_champignons"])
	_add(&"decouverte_racines", "Decouverte des Racines", 1, [], &"plantes_packs", [&"unlock_roots", &"unlock_pack_racines"])
	_add(&"packs_avances", "Packs Avances", 1, [&"spores_champignon"], &"plantes_packs", [&"unlock_pack_sous_bois", &"unlock_pack_festin"])
	_add(&"recolte_legendaire", "Recolte Legendaire", 1, [&"packs_avances", &"decouverte_racines"], &"plantes_packs", [&"unlock_pack_legendaire"])
	# Main & Cartes
	_add(&"poubelle", "Poubelle", 1, [], &"main_cartes", [&"unlock_discard"])
	_add(&"composteur", "Composteur", 1, [&"poubelle"], &"main_cartes", [&"unlock_compost"])
	_add(&"main_plus1", "Main +1", 1, [], &"main_cartes", [&"hand_size_plus1"])
	_add(&"starter_bonus", "Starter Bonus", 1, [&"main_plus1"], &"main_cartes", [&"starter_extra_card"])
	# Outils & Inventaire
	_add(&"ceinture_outils", "Ceinture d'Outils", 1, [], &"outils_inventaire", [&"unlock_tool_belt"])
	_add(&"pelle", "Pelle", 1, [&"ceinture_outils"], &"outils_inventaire", [&"unlock_shovel"])
	_add(&"engrais", "Engrais", 1, [&"ceinture_outils"], &"outils_inventaire", [&"unlock_fertilizer"])
	_add(&"arrosoir", "Arrosoir", 1, [&"pelle", &"engrais"], &"outils_inventaire", [&"unlock_watering_can"])
	# Savoir
	_add(&"encyclopedie", "Encyclopedie", 1, [], &"savoir", [&"unlock_encyclopedia"])
	_add(&"loupe", "Loupe", 1, [&"encyclopedie"], &"savoir", [&"unlock_magnifier"])
	_add(&"rayons_x", "Rayons X", 1, [&"loupe"], &"savoir", [&"unlock_xray"])
	# Principale
	_add(&"jardinier_expert", "Jardinier Expert", 1, [&"ALL_OTHER_BRANCHES"], &"principale", [&"cosmetic_expert", &"global_scoring_bonus"])
	_add(&"terrarium_parfait", "Terrarium Parfait", 1, [&"jardinier_expert"], &"principale", [&"game_complete"])


static func _add(id: StringName, name_fr: String, cost: int, prerequisites: Array[StringName], branch: StringName, effects: Array[StringName]) -> void:
	var n := PrestigeNode.new()
	n.id = id
	n.name_fr = name_fr
	n.cost = cost
	n.prerequisites = prerequisites
	n.branch = branch
	n.effects = effects
	_nodes[id] = n
