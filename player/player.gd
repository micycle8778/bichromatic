extends CharacterBody2D

const AIR_FRICTION := 0.05
const MAX_SPEED := 900.
const JUMP_POWER := 950.
const GRAVITY := 2700.

const MOVE_ACCEL := 0.15
var acceleration := MOVE_ACCEL
var tween: Tween

@onready var left_jump_detector: Area2D = %LeftJumpDetector
@onready var right_jump_detector: Area2D = %RightJumpDetector

enum State {
	DEFAULT,
	SLAM
}

var state := State.DEFAULT:
	set(v):
		state = v
		match state:
			State.SLAM:
				slam_force = 0
			_:
				pass

func wall_jump(dir: float) -> void:
	velocity.x += 1000. * dir

	if tween != null: tween.stop()
	acceleration = 0.
	tween = create_tween()
	tween.tween_property(self, "acceleration", MOVE_ACCEL, 0.15)

var visibility := true
var slam_force := 0.
func _process_slam(delta: float) -> void:
	velocity.x = 0
	# print("[player::slam] velocity = ", velocity)
	velocity.y = max(1000, velocity.y)
	velocity.y += 20000 * delta

	move_and_slide()
	slam_force = max(slam_force, velocity.y)

	if is_on_floor():
		# print("[player::slam] slam_force = ", slam_force)
		state = State.DEFAULT

		velocity.y = -1500

		if slam_force > 1500:
			visibility = not visibility
			for n in get_tree().get_nodes_in_group("other_worldly"):
				n.visible = visibility
			for n in get_tree().get_nodes_in_group("alt_worldly"):
				n.visible = not visibility

			MainCam.instance.shake(0.1, Vector2.UP * 1.5)

func _process_default(delta: float) -> void:
	# var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input := Input.get_axis("move_left", "move_right")
	
	if input == 0. and not is_on_floor():
		velocity.x = lerpf(velocity.x, MAX_SPEED * signf(input), min(AIR_FRICTION, acceleration))
	else:
		velocity.x = lerpf(velocity.x, MAX_SPEED * signf(input), acceleration)

	if Input.is_action_just_pressed("jump"):
		var wall_jumped := false

		if left_jump_detector.has_overlapping_bodies():
			# print("[player::default] wall jumping left")
			wall_jump(1)
			wall_jumped = true

		if right_jump_detector.has_overlapping_bodies():
			# print("[player::default] wall jumping right")
			wall_jump(-1)
			wall_jumped = true

		if wall_jumped or is_on_floor():
			velocity += Vector2.UP * JUMP_POWER
	else:
		velocity += Vector2.DOWN * GRAVITY * delta

	move_and_slide()

	if Input.is_action_just_pressed("slam"):
		state = State.SLAM

func _physics_process(delta: float) -> void:
	match state:
		State.DEFAULT:
			_process_default(delta)
		State.SLAM:
			_process_slam(delta)
		_:
			assert(false, "unreachable")
