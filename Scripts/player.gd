extends CharacterBody2D


@export var speed = 300.0
@export var brake = 0.2

func _ready():
	print("--- 플레이어 스크립트 시작 ---")
	if has_node("Camera2D"):
		print("카메라 노드 발견!")
		$Camera2D.enabled = true
		$Camera2D.make_current()
		print("카메라 좌표: ", $Camera2D.global_position)
	else:
		print("경고: 카메라 노드를 찾을 수 없음!")

func _physics_process(delta: float) -> void:
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		play_walk_animation(direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * brake)
		
		if velocity.length() < 10:
			$AnimationPlayer.stop()
		
	move_and_slide()

func play_walk_animation(dir):
	if (abs(dir.x) > abs(dir.y)):
		if dir.x > 0:
			$AnimationPlayer.play("walk_right")
		else:
			$AnimationPlayer.play("walk_left")
	else:
		if dir.y > 0:
			$AnimationPlayer.play("walk_down")
		else:
			$AnimationPlayer.play("walk_up")
