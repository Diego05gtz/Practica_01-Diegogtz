extends Area2D

func _ready() -> void:
	add_to_group("pickups")                 # para poder limpiarlo en new_game
	area_entered.connect(_on_area_entered)  # Player también es Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		area.call("grant_shield", 3.0)     # 3 segundos de escudo
		queue_free()
