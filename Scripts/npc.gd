@tool
extends CharacterBody2D

signal receptionist_handed_mask # 형사 호출용 신호

# [설정] 1~20 사이의 값만 허용
@export_range(1, 20) var mask_row: int = 1:
	set(value):
		var new_val = 1
		if value > 0: new_val = value
		
		if mask_row != new_val:
			mask_row = new_val
			if is_node_ready():
				update_texture()
				update_bubble_ui()

@export_range(1, 20) var desired_mask_row: int = 2:
	set(value):
		var new_val = 1
		if value > 0: new_val = value
		
		if desired_mask_row != new_val:
			desired_mask_row = new_val
			if is_node_ready():
				update_bubble_ui()

@export var is_receptionist: bool = false:
	set(value):
		is_receptionist = value
		if is_node_ready():
			update_texture()
			update_bubble_ui()

# [중요] 노드 이름은 MaskSprite
@onready var sprite = $BodySprite/MaskSprite
@onready var icon_bubble = $IconBubble

var nearby_player = null
var reception_finished = false
var traded_player_mask_history: int = -1 

func _ready():
	if mask_row <= 0: mask_row = 1
	if desired_mask_row <= 0: desired_mask_row = 1
	
	update_texture()
	# 시작 시 UI 상태 업데이트
	update_bubble_ui()

# --- [수정 1] 외형 업데이트: 접수원은 가면 숨기기 ---
func update_texture():
	if not sprite: return
	
	if is_receptionist:
		# 접수원은 가면을 쓰지 않음 (숨김 처리)
		sprite.visible = false
	else:
		# 일반 NPC는 가면을 씀
		sprite.visible = true
		sprite.frame = mask_row * 4 

# --- UI 업데이트 로직 ---
func update_bubble_ui():
	if not icon_bubble: return 
	
	# 표시할 가면 ID 결정
	var display_mask_id = 0
	if is_receptionist:
		display_mask_id = mask_row
	else:
		display_mask_id = desired_mask_row
	
	# 1. 에디터 모드
	if Engine.is_editor_hint():
		icon_bubble.show_detective_chat("mask", display_mask_id, 0) 
		return

	# 2. 거래 완료시 숨김 (영구적)
	if reception_finished or (not is_receptionist and mask_row == desired_mask_row):
		icon_bubble.hide_bubble()
		return
	
	# 3. 플레이어와의 상호작용 상태에 따른 표시
	if nearby_player:
		# 교환 조건 체크
		var can_trade = false
		if is_receptionist:
			can_trade = true
		elif nearby_player.current_mask_row == desired_mask_row:
			can_trade = true
			
		if can_trade:
			# 교환 가능 UI 표시
			icon_bubble.show_trade_ui(mask_row, nearby_player.current_mask_row, is_receptionist)
		else:
			# 조건 불충족 시: 원래 상태(원하는 가면) 유지
			icon_bubble.show_detective_chat("mask", display_mask_id, 0)
	else:
		# [핵심] 플레이어가 멀어졌을 때: 숨기지 않고 원래 상태(원하는 가면) 표시
		icon_bubble.show_detective_chat("mask", display_mask_id, 0)

# --- 플레이어 이벤트 함수들 ---

func on_player_entered(player_node):
	nearby_player = player_node
	update_bubble_ui()

# --- [수정 2] 플레이어가 나갔을 때: 말풍선 숨기지 말고 갱신 ---
func on_player_exited():
	nearby_player = null
	# 버그 원인: icon_bubble.hide_bubble() 삭제함
	# 해결: update_bubble_ui()를 호출하여 'else' 블록(원래 상태 표시)으로 가게 함
	update_bubble_ui()

func complete_reception():
	if is_receptionist and not reception_finished:
		print("접수원: 가면 지급 완료")
		reception_finished = true
		receptionist_handed_mask.emit()
		update_bubble_ui()

func remember_criminal_mask(mask_id: int):
	traded_player_mask_history = mask_id
	update_texture() 
	update_bubble_ui()

func interact(player):
	pass

# --- 형사 상호작용 ---

func snitch_on_player() -> int:
	return traded_player_mask_history

func get_handed_mask_info() -> int:
	return mask_row
