extends Node

@export var mob_scene: PackedScene
@export var shield_scene: PackedScene		# arrastra shield_pickup.tscn
@export var shield_every_points: int = 8	# cada cuántos puntos aparece un escudo

var score: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	# new_game()	# descomenta si quieres arrancar automáticamente
	pass


func _process(_delta: float) -> void:
	pass


func game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$Music.stop()
	$DeathSound.play()


func new_game() -> void:
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")

	# limpia mobs y pickups
	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("pickups", "queue_free")

	# ritmo base del spawner
	$MobTimer.wait_time = 0.5

	$Music.play()


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()


func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)

	# spawnea escudo cada X puntos
	if shield_scene and shield_every_points > 0 and score % shield_every_points == 0:
		_spawn_shield()

	# (opcional) dificultad progresiva
	if score % 10 == 0:
		$MobTimer.wait_time = max(0.3, $MobTimer.wait_time - 0.05)


func _spawn_shield() -> void:
	var s: Node2D = shield_scene.instantiate()
	# tamaño visible del viewport en Godot 4
	var view: Vector2 = get_viewport().get_visible_rect().size
	var margin: Vector2 = Vector2(40.0, 80.0)

	s.position = Vector2(
		_rng.randf_range(margin.x, view.x - margin.x),
		_rng.randf_range(margin.y, view.y - margin.y)
	)

	# por si tu pickup no se añade al grupo en su _ready()
	if not s.is_in_group("pickups"):
		s.add_to_group("pickups")

	add_child(s)


func _on_mob_timer_timeout() -> void:
	# instancia un Mob
	var mob := mob_scene.instantiate()

	# posición aleatoria en el Path2D
	var spawn = $MobPath/MobSpawnLocation
	spawn.progress_ratio = randf()
	mob.position = spawn.position

	# dirección perpendicular al path con ruido
	var direction: float = spawn.rotation + PI / 2.0
	direction += randf_range(-PI / 4.0, PI / 4.0)
	mob.rotation = direction

	# velocidad aleatoria
	var velocity: Vector2 = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	add_child(mob)
