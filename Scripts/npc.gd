@tool
extends CharacterBody2D

# --- [설정 변수] ---
@export var is_receptionist: bool = false:
	set(v):
		is_receptionist = v
		_update_visual() # 접수원 여부에 따라 가면 숨김/표시
		if Engine.is_editor_hint() or is_node_ready():
			update_bubble_ui()

@export var mask_row: int = 0:
	set(v):
		mask_row = v
		_update_visual()
		if Engine.is_editor_hint() or is_node_ready():
			update_bubble_ui()

@export var desired_mask_row: int = 1:
	set(v):
		desired_mask_row = v
		if Engine.is_editor_hint() or is_node_ready():
			update_bubble_ui()

# --- [기억 데이터] ---
var has_witnessed_player: bool = false
var witnessed_criminal_mask: int = -1 

# --- [상태 변수] ---
var nearby_player = null
var reception_finished: bool = false 

# --- [노드 참조] ---
@onready var body_sprite = $BodySprite
@onready var mask_sprite = $BodySprite/MaskSprite
@onready var icon_bubble = $IconBubble 

func _ready():
	_update_visual()
	if not has_node("IconBubble"):
		printerr(name + ": IconBubble 노드가 없습니다!")
	
	update_bubble_ui()

# --- 형사 수사 대응 ---
func get_handed_mask_info() -> int:
	return witnessed_criminal_mask if has_witnessed_player else mask_row

func snitch_on_player() -> int:
	return witnessed_criminal_mask if has_witnessed_player else -1

# --- 플레이어 상호작용 ---
func on_player_entered(player):
	nearby_player = player
	update_bubble_ui()

func on_player_exited():
	nearby_player = null
	update_bubble_ui()

func remember_criminal_mask(m):
	has_witnessed_player = true
	witnessed_criminal_mask = m

func complete_reception():
	reception_finished = true
	update_bubble_ui()

# --- UI 및 비주얼 관리 ---
func update_bubble_ui():
	if not icon_bubble: return 
	
	# [에디터 모드]
	if Engine.is_editor_hint():
		var show_mask = desired_mask_row if not is_receptionist else mask_row
		icon_bubble.show_detective_chat("mask", show_mask)
		return

	# [게임 런타임]
	if reception_finished or (not is_receptionist and mask_row == desired_mask_row):
		icon_bubble.hide_bubble()
		return
	
	if nearby_player:
		# [핵심] 교환 조건 검사
		var can_trade = false
		
		if is_receptionist:
			can_trade = true
		# 일반 NPC는 내가 원하는 가면을 플레이어가 썼을 때만 거래 가능
		elif nearby_player.current_mask_row == desired_mask_row:
			can_trade = true
			
		if can_trade:
			icon_bubble.show_trade_ui(mask_row, nearby_player.current_mask_row, is_receptionist)
		else:
			# 조건이 안 맞으면 그냥 "난 이걸 원해" 아이콘만 띄움
			icon_bubble.show_detective_chat("mask", desired_mask_row)
	else:
		var show_mask = desired_mask_row if not is_receptionist else mask_row
		icon_bubble.show_detective_chat("mask", show_mask)

func _update_visual():
	if not mask_sprite: return
	
	# 접수원이거나 가면이 없으면(-1) 스프라이트 숨김
	if is_receptionist or mask_row == -1:
		mask_sprite.visible = false
	else:
		mask_sprite.visible = true
		var current_dir = 0
		if body_sprite: 
			current_dir = body_sprite.frame % 4 
		mask_sprite.frame = (mask_row * 4) + current_dir
