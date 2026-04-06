extends Node

signal points_changed(new_total: int)
signal prestige_done(pp_earned: int)
signal upgrade_unlocked(id: String)

var points: int = 0
var prestige_points: int = 0
var pack_price_modifier: int = 0
var hand: Array = []
var hand_size_max: int = 5
var unlocked_upgrades: Array[String] = []
var starting_cards: Array = ["carotte", "carotte", "herberaude", "herberaude", "boutomate"]


func _ready() -> void:
	new_game()


func new_game() -> void:
	points = 0
	pack_price_modifier = 0
	hand.clear()
	for card_id in starting_cards:
		hand.append(card_id)
	points_changed.emit(points)


func add_points(amount: int) -> void:
	points += amount
	points_changed.emit(points)


func spend_points(amount: int) -> bool:
	if points < amount:
		return false
	points -= amount
	points_changed.emit(points)
	return true


func can_prestige() -> bool:
	return points >= 50


func get_prestige_value() -> int:
	return points / 50


func do_prestige() -> void:
	var pp := get_prestige_value()
	prestige_points += pp
	prestige_done.emit(pp)
	new_game()


func is_upgrade_unlocked(id: String) -> bool:
	return id in unlocked_upgrades


func unlock_upgrade(id: String) -> void:
	if id not in unlocked_upgrades:
		unlocked_upgrades.append(id)
		upgrade_unlocked.emit(id)
