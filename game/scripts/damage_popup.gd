extends Label
class_name DamagePopup

@export var rise_distance: float = 36.0
@export var life_time: float = 0.45

func setup(text_value: String, color_value: Color) -> void:
    text = text_value
    modulate = color_value

func _ready() -> void:
    z_index = 50
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "position:y", position.y - rise_distance, life_time)
    tween.tween_property(self, "modulate:a", 0.0, life_time)
    tween.finished.connect(queue_free)
