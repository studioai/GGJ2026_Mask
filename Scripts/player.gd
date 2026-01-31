extends CharacterBody2D

@export var speed = 300.0
@export var brake = 0.2

var current_mask_row: int = 0
var current_dir_index: int = 0

@onready var body_sprite = $BodySprite
@onready var mask_sprite = $BodySprite/MaskSprite
# [추가] 방금 만든 접촉 감지 영역
@onready var interaction_zone = $InteractionZone

func _ready():
	if has_node("Camera2D"):
		$Camera2D.enabled = true
		$Camera2D.make_current()
	update_mask_visual()

func _input(event):
	if event.is_action_pressed("interact"):
		try_interact()

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

# --- [변경된 로직] 거리 계산 대신 '접촉(Overlap)'을 확인 ---

func try_interact():
	# 내 'InteractionZone'과 겹쳐있는 모든 물체를 가져옵니다.
	var overlapping_bodies = interaction_zone.get_overlapping_bodies()
	
	for body in overlapping_bodies:
		# 그 물체가 'npc' 그룹인지 확인
		if body.is_in_group("npc"):
			
			# 1. 쳐다보게 하기
			if body.has_method("look_at_target"):
				body.look_at_target(global_position)
			
			# 2. 가면 교환
			swap_mask_with(body)
			
			# 한 명하고만 상호작용하고 끝냄 (여러 명 겹쳤을 때 방지)
			return

func swap_mask_with(npc):
	var temp_row = current_mask_row
	current_mask_row = npc.mask_row
	npc.mask_row = temp_row
	
	update_mask_visual()
	print("접촉 상호작용 성공! 내 가면: ", current_mask_row)

func update_mask_visual():
	if mask_sprite:
		mask_sprite.frame = (current_mask_row * 4) + current_dir_index

func play_walk_animation(dir):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			$AnimationPlayer.play("walk_right")
			current_dir_index = 3
		else:
			$AnimationPlayer.play("walk_left")
			current_dir_index = 2
	else:
		if dir.y > 0:
			$AnimationPlayer.play("walk_down")
			current_dir_index = 0
		else:
			$AnimationPlayer.play("walk_up")
			current_dir_index = 1
	update_mask_visual()
