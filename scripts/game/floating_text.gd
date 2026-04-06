class_name FloatingText extends Label

func _ready() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 50, 0.8)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)
