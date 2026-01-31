extends CharacterBody2D

@export var speed = 300.0
@export var brake = 0.2

# 현재 착용 중인 가면의 '행(Row)' 번호
var current_mask_row: int = 0

@onready var body_sprite = $BodySprite
@onready var mask_sprite = $BodySprite/MaskSprite

func _ready():
	if has_node("Camera2D"):
		$Camera2D.enabled = true
		$Camera2D.make_current()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		interact_with_npc()

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

func interact_with_npc():
	var npc_list = get_tree().get_nodes_in_group("npc")
	for npc in npc_list:
		var dist = global_position.distance_to(npc.global_position)
		if dist < 80:
			if npc.has_method("look_at_target"):
				npc.look_at_target(global_position)

func play_walk_animation(dir):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			$AnimationPlayer.play("walk_right")
			update_mask_frame(3) # 우
		else:
			$AnimationPlayer.play("walk_left")
			update_mask_frame(2) # 좌
	else:
		if dir.y > 0:
			$AnimationPlayer.play("walk_down")
			update_mask_frame(0) # 하
		else:
			$AnimationPlayer.play("walk_up")
			update_mask_frame(1) # 상

func update_mask_frame(direction_index: int):
	if mask_sprite:
		# 공식: (가면 줄 번호 * 가로 개수) + 방향 인덱스
		mask_sprite.frame = (current_mask_row * 4) + direction_index
