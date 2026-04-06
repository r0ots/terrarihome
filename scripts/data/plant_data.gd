class_name PlantData
extends Resource

@export var id: StringName
@export var name_fr: String
@export var name_en: String
@export var shape: Array[Vector2i]
@export var types: Array[StringName]
@export var combo_type: StringName
@export var combo_targets: Array[StringName]
@export var scoring_mode: StringName = &"bidirectional"
@export var flat_value: int = 0
@export var compost_value: int = 1
@export var is_base: bool = false
