extends CharacterBody2D

@export var speed = 100.0
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
	if has_node("Camera2D"):
		$Camera2D.enabled = true
		$Camera2D.make_current()
	
	update_mask_visual()
	
	if not interaction_zone.body_entered.is_connected(_on_interaction_zone_body_entered):
		interaction_zone.body_entered.connect(_on_interaction_zone_body_entered)
	if not interaction_zone.body_exited.is_connected(_on_interaction_zone_body_exited):
		interaction_zone.body_exited.connect(_on_interaction_zone_body_exited)

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
			animation_player.stop()
		
	move_and_slide()

# --- 상호작용 로직 ---

func try_interact():
	if not current_interactable_npc: return

	# 1. 접수원: 언제든 가능
	if "is_receptionist" in current_interactable_npc and current_interactable_npc.is_receptionist:
		_interact_with_receptionist(current_interactable_npc)
		return

	# 2. 일반 NPC: 조건 검사
	
	# 가면이 없으면(-1) 일반 NPC와 교환 불가
	if current_mask_row == -1:
		return
		
	# NPC가 원하는 가면이 아니면 교환 불가
	if current_mask_row != current_interactable_npc.desired_mask_row:
		return
	
	# 이미 완료된 NPC 제외
	if current_interactable_npc.mask_row == current_interactable_npc.desired_mask_row:
		return

	if current_interactable_npc.has_method("look_at_target"):
		current_interactable_npc.look_at_target(global_position)
	
	swap_mask_with(current_interactable_npc)

func _interact_with_receptionist(npc):
	if npc.reception_finished: return
	
	current_mask_row = npc.mask_row
	update_mask_visual()
	
	if npc.has_method("complete_reception"):
		npc.complete_reception()

func swap_mask_with(npc):
	var temp_row = current_mask_row
	current_mask_row = npc.mask_row
	npc.mask_row = temp_row
	
	update_mask_visual()
	
	# NPC에게 단서 남기기 (플레이어가 가져간 가면 기억)
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
