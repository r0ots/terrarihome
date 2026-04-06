extends Node

signal points_changed(new_total: int)
signal prestige_points_changed(new_total: int)
signal prestige_done(pp_earned: int)
signal upgrade_unlocked(id: StringName)

var points: int = 0:
	set(value):
		points = value
		points_changed.emit(points)

var prestige_points: int = 0:
	set(value):
		prestige_points = value
		prestige_points_changed.emit(prestige_points)

var hand: Array[StringName] = []
var hand_size_max: int = 5
var unlocked_upgrades: Array[StringName] = []
var tool_inventory: Array[StringName] = []
var tool_inventory_max: int = 2
var starting_cards: Array[StringName] = [&"carotte", &"carotte", &"herberaude", &"herberaude", &"boutomate"]

var pack_card_bonus: int = 0
var mastery_bonus: Dictionary = {&"base": 0, &"standard": 0, &"premium": 0}
var free_first_pack: bool = false
var free_pack_used: bool = false
var overflow_compost: bool = false


func _ready() -> void:
	new_game()


func new_game() -> void:
	points = 0
	hand.clear()
	tool_inventory.clear()
	free_pack_used = false
	for card_id: StringName in starting_cards:
		hand.append(card_id)


func spend_points(amount: int) -> bool:
	if points < amount:
		return false
	points -= amount
	return true


func can_prestige() -> bool:
	return points >= 50


func get_prestige_value() -> int:
	return points / 50


func do_prestige() -> void:
	var pp: int = get_prestige_value()
	prestige_points += pp
	prestige_done.emit(pp)
	new_game()


func is_upgrade_unlocked(id: StringName) -> bool:
	return id in unlocked_upgrades


func unlock_upgrade(id: StringName) -> void:
	if id not in unlocked_upgrades:
		unlocked_upgrades.append(id)
		upgrade_unlocked.emit(id)


func get_mastery_for_plant(plant_id: StringName) -> int:
	var data: PlantData = PlantDatabase.get_plant(plant_id)
	if not data: return 0
	var tier_bonus: int = mastery_bonus.get(data.tier, 0)
	return mini(tier_bonus, PlantDatabase.get_max_mastery(data.tier))


func get_inflation_reduction(tier: StringName) -> int:
	match tier:
		&"eco":
			return 1 if is_upgrade_unlocked(&"reduction_eco") else 0
		&"standard":
			return 1 if is_upgrade_unlocked(&"reduction_standard") else 0
		&"premium", &"legendary":
			return 1 if is_upgrade_unlocked(&"reduction_premium") else 0
	return 0
