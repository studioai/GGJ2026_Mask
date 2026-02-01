extends CharacterBody2D

signal receptionist_handed_mask # 형사 호출용 신호

# [설정] 1~20 사이의 값만 허용
@export_range(1, 20) var mask_row: int = 1:
	set(value):
		if value <= 0: mask_row = 1
		else: mask_row = value
		if Engine.is_editor_hint() and has_method("update_texture"):
			call("update_texture")

@export_range(1, 20) var desired_mask_row: int = 2:
	set(value):
		if value <= 0: desired_mask_row = 1
		else: desired_mask_row = value

@export var is_receptionist: bool = false

@onready var sprite = $Sprite2D
@onready var icon_bubble = $IconBubble

# interaction_area 관련 변수 삭제 (플레이어 InteractionZone 사용)

var nearby_player = null
var reception_finished = false
var traded_player_mask_history: int = -1 

func _ready():
	if mask_row <= 0: mask_row = 1
	if desired_mask_row <= 0: desired_mask_row = 1
	update_texture()
	
	# 시작할 때 한 번 호출
	update_bubble_ui()

# [삭제됨] _process 함수는 더 이상 필요 없습니다! (버그의 원인)

func update_texture():
	if sprite:
		sprite.frame = mask_row * 4 

# --- 플레이어(player.gd)가 호출하는 이벤트 함수들 ---

# 플레이어가 영역에 들어왔을 때
func on_player_entered(player_node):
	nearby_player = player_node
	update_bubble_ui() # [추가] 입장 시 1회 갱신

# 플레이어가 영역에서 나갔을 때
func on_player_exited():
	nearby_player = null
	if icon_bubble:
		icon_bubble.hide_bubble()

# 접수원 업무 완료 처리
func complete_reception():
	if is_receptionist and not reception_finished:
		print("접수원: 가면 지급 완료")
		reception_finished = true
		receptionist_handed_mask.emit()
		update_bubble_ui() # [추가] 상태 변경 시 갱신

# 범인의 가면 기억
func remember_criminal_mask(mask_id: int):
	traded_player_mask_history = mask_id
	update_texture()
	update_bubble_ui() # [추가] 가면 교환 후 갱신

# 플레이어가 상호작용 시도 (직접 호출될 경우를 대비)
func interact(player):
	# player.gd가 로직을 처리하고 complete_reception이나 remember_criminal_mask를 부르겠지만,
	# 만약 npc.gd 내부에서 처리해야 할 로직이 있다면 여기서 update_bubble_ui()를 호출해야 함.
	# 현재 구조상 player.gd가 주도하므로, 위 함수들(complete_..., remember_...)에서 UI 갱신하면 충분함.
	pass

# --- UI 로직 ---

func update_bubble_ui():
	if not icon_bubble: return 
	
	# 에디터 모드
	if Engine.is_editor_hint():
		var show_mask = desired_mask_row if not is_receptionist else mask_row
		icon_bubble.show_detective_chat("mask", show_mask, 0) 
		return

	# 거래 완료시 숨김
	if reception_finished or (not is_receptionist and mask_row == desired_mask_row):
		icon_bubble.hide_bubble()
		return
	
	# 플레이어가 근처에 있을 때
	if nearby_player:
		var can_trade = false
		if is_receptionist:
			can_trade = true
		elif nearby_player.current_mask_row == desired_mask_row:
			can_trade = true
			
		if can_trade:
			icon_bubble.show_trade_ui(mask_row, nearby_player.current_mask_row, is_receptionist)
		else:
			icon_bubble.show_detective_chat("mask", desired_mask_row, 0)
	else:
		# 멀리 있을 때: 원하는 가면 표시
		var show_mask = desired_mask_row if not is_receptionist else mask_row
		icon_bubble.show_detective_chat("mask", show_mask, 0)

# --- 형사(Detective)가 호출하는 함수들 ---

func snitch_on_player() -> int:
	return traded_player_mask_history

func get_handed_mask_info() -> int:
	return mask_row
