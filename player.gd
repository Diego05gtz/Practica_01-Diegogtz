extends Area2D
signal hit

@export var speed: float = 400.0
@export var dash_speed: float = 900.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 0.6

# Color para el efecto visual del escudo (azulado)
@export var shield_tint: Color = Color(0.6, 0.9, 1.0, 1.0)

var screen_size: Vector2
var _can_dash := true
var _dashing := false
var _last_input := Vector2.ZERO
var _shield_time := 0.0

func start(pos: Vector2) -> void:
	position = pos
	show()
	# reset de estado al iniciar partida
	_can_dash = true
	_dashing = false
	_shield_time = 0.0
	_update_invuln_state()

func _ready() -> void:
	screen_size = get_viewport_rect().size
	add_to_group("player")

func _process(delta: float) -> void:
	var velocity := Vector2.ZERO
	if Input.is_action_pressed("move_right"): velocity.x += 1.0
	if Input.is_action_pressed("move_left"):  velocity.x -= 1.0
	if Input.is_action_pressed("move_up"):    velocity.y -= 1.0
	if Input.is_action_pressed("move_down"):  velocity.y += 1.0

	if velocity != Vector2.ZERO:
		_last_input = velocity.normalized()

	# ---- DASH ----
	if Input.is_action_just_pressed("dash") and _can_dash:
		var dir := _last_input if _last_input != Vector2.ZERO else Vector2.UP
		_start_dash(dir)

	# Tiempo de escudo
	if _shield_time > 0.0:
		_shield_time = max(0.0, _shield_time - delta)
		# actualizar colisión/visual si terminó
		if _shield_time == 0.0:
			_update_invuln_state()

	# Velocidad (usa dash_speed si está dashing)
	var current_speed := dash_speed if _dashing else speed
	velocity = (velocity.normalized() if velocity != Vector2.ZERO else Vector2.ZERO) * current_speed

	# ---- Animación (walk/up/down o flip) ----
	if velocity.x != 0.0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_h = velocity.x < 0.0
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.play()
	elif velocity.y != 0.0:
		var going_down := velocity.y > 0.0
		var frames: SpriteFrames = $AnimatedSprite2D.sprite_frames
		if going_down and frames and "down" in frames.get_animation_names():
			$AnimatedSprite2D.animation = "down"
			$AnimatedSprite2D.flip_h = false
			$AnimatedSprite2D.flip_v = false
		else:
			$AnimatedSprite2D.animation = "up"
			$AnimatedSprite2D.flip_h = false
			$AnimatedSprite2D.flip_v = going_down
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	# Movimiento y límites
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

func _start_dash(dir: Vector2) -> void:
	_can_dash = false
	_dashing = true
	_update_invuln_state()  # desactiva colisión y pone visual de dash

	# pequeño “empujón” inicial para que se sienta más snappy
	position += dir.normalized() * (dash_speed * 0.03)

	await get_tree().create_timer(dash_time).timeout
	_dashing = false
	_update_invuln_state()  # si no hay escudo, vuelve a colisionar

	await get_tree().create_timer(dash_cooldown).timeout
	_can_dash = true

func grant_shield(seconds: float) -> void:
	# Llamado por el pickup: player.grant_shield(3.0)
	_shield_time = max(_shield_time, seconds)  # refresca o extiende
	_update_invuln_state()

func _update_invuln_state() -> void:
	# Colisión desactivada si está dashing o con escudo
	$CollisionShape2D.disabled = _dashing or (_shield_time > 0.0)

	# Visual:
	if _dashing:
		$AnimatedSprite2D.modulate = Color(1, 1, 1, 0.6)  # semitransparente
	elif _shield_time > 0.0:
		$AnimatedSprite2D.modulate = shield_tint          # tinte azul
	else:
		$AnimatedSprite2D.modulate = Color.WHITE

	# (Opcional) acelerar un poco la anim al dashiAR
	$AnimatedSprite2D.speed_scale = 1.3 if _dashing else 1.0

func _on_body_entered(_body):
	# Si es invulnerable (dash o escudo), ignora golpes
	if _dashing or _shield_time > 0.0:
		return
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)
