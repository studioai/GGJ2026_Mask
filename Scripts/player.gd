extends CharacterBody2D

@export var speed = 300.0
@export var brake = 0.2

# -1: 가면 없음, 0~N: 가면 인덱스
var current_mask_row: int = -1 
var current_dir_index: int = 0
var current_interactable_npc: Node2D = null 

@onready var body_sprite = $BodySprite
@onready var mask_sprite = $BodySprite/MaskSprite
@onready var interaction_zone = $InteractionZone
@onready var animation_player = $AnimationPlayer

func _ready():
	# 카메라 설정 (씬에 있다면)
	if has_node("Camera2D"):
		$Camera2D.enabled = true
		$Camera2D.make_current()
	
	update_mask_visual()
	
	# 상호작용 영역 시그널 연결
	if not interaction_zone.body_entered.is_connected(_on_interaction_zone_body_entered):
		interaction_zone.body_entered.connect(_on_interaction_zone_body_entered)
	if not interaction_zone.body_exited.is_connected(_on_interaction_zone_body_exited):
		interaction_zone.body_exited.connect(_on_interaction_zone_body_exited)

func _input(event):
	if event.is_action_pressed("interact"): # Input Map에 'interact'가 등록되어 있어야 함
		try_interact()

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		play_walk_animation(direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * brake)
		if velocity.length() < 10:
			animation_player.stop()
		
	move_and_slide()

# --- 상호작용 로직 ---

func try_interact():
	if not current_interactable_npc: return

	# 1. 접수원 상호작용
	if "is_receptionist" in current_interactable_npc and current_interactable_npc.is_receptionist:
		_interact_with_receptionist(current_interactable_npc)
		return

	# 2. 일반 NPC 상호작용
	# 가면이 없으면(-1) 교환 불가
	if current_mask_row == -1:
		print("가면이 없어서 교환할 수 없습니다.")
		return
	
	# 이미 원하는 가면을 쓴 NPC라면 무시
	if current_interactable_npc.mask_row == current_interactable_npc.desired_mask_row:
		return

	# NPC가 플레이어를 쳐다봄
	if current_interactable_npc.has_method("look_at_target"):
		current_interactable_npc.look_at_target(global_position)
	
	swap_mask_with(current_interactable_npc)

func _interact_with_receptionist(npc):
	if npc.reception_finished: return
	
	# 가면 받기
	current_mask_row = npc.mask_row
	update_mask_visual()
	
	# 접수 완료 처리
	if npc.has_method("complete_reception"):
		npc.complete_reception()

func swap_mask_with(npc):
	# 서로 가면 교환
	var temp_row = current_mask_row
	current_mask_row = npc.mask_row
	npc.mask_row = temp_row
	
	update_mask_visual()
	if npc.has_method("update_bubble_ui"):
		npc.update_bubble_ui()
		
	# [중요] NPC에게 단서 남기기: "너는 방금 '이 가면'을 쓴 사람이 도망가는 걸 봤어"
	# 플레이어가 방금 획득해서 쓴 가면(current_mask_row)을 기억시킴
	if npc.has_method("remember_criminal_mask"):
		npc.remember_criminal_mask(current_mask_row)

# --- 시각적 처리 ---

func update_mask_visual():
	if mask_sprite:
		if current_mask_row == -1:
			mask_sprite.visible = false
		else:
			mask_sprite.visible = true
			mask_sprite.frame = (current_mask_row * 4) + current_dir_index

func play_walk_animation(dir):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			animation_player.play("walk_right")
			current_dir_index = 3
		else:
			animation_player.play("walk_left")
			current_dir_index = 2
	else:
		if dir.y > 0:
			animation_player.play("walk_down")
			current_dir_index = 0
		else:
			animation_player.play("walk_up")
			current_dir_index = 1
	update_mask_visual()

# --- 영역 감지 ---

func _on_interaction_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("npc"):
		current_interactable_npc = body
		if body.has_method("on_player_entered"):
			body.on_player_entered(self)

func _on_interaction_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("npc"):
		if body == current_interactable_npc:
			current_interactable_npc = null
		if body.has_method("on_player_exited"):
			body.on_player_exited()
