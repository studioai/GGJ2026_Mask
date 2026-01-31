@tool
extends CharacterBody2D

# --- [설정 변수] ---
@export var is_receptionist: bool = false # 접수원 여부

@export var mask_row: int = 0: # 현재 쓰고 있는 가면
	set(value):
		mask_row = value
		_update_visual()
		# 게임 실행 중일 때만 UI 갱신 (에러 방지)
		if is_node_ready():
			update_bubble_ui()

@export var desired_mask_row: int = 1: # 원하는 가면 (일반 NPC용)
	set(value):
		desired_mask_row = value
		if is_node_ready():
			update_bubble_ui()

# --- [기억 데이터] (형사 수사 대응용) ---
var has_witnessed_player: bool = false
var witnessed_criminal_mask: int = -1 # 범인이 가져간 가면 번호

# --- [상태 변수] ---
var nearby_player = null
var reception_finished: bool = false 

# --- [노드 참조] ---
@onready var body_sprite = $BodySprite
@onready var mask_sprite = $BodySprite/MaskSprite

# 통합된 픽토그램/교환 말풍선 (필수)
@onready var icon_bubble = $IconBubble 

func _ready():
	_update_visual()
	
	if not has_node("IconBubble"):
		printerr(name + ": IconBubble 노드가 없습니다! 추가해주세요.")
	
	# 초기 상태 UI 갱신
	update_bubble_ui()

# =================================================
# 🔍 [1] 형사 수사 대응 로직
# =================================================

# 접수원용: 최초 단서 제공 (형사가 질문할 때 호출)
func get_handed_mask_info() -> int:
	# 만약 플레이어와 교환한 기억이 있다면 그 정보를, 없다면 기본 가면 정보를 줌
	if has_witnessed_player:
		return witnessed_criminal_mask
	return mask_row 

# 일반 NPC용: 범인 제보 (형사가 심문할 때 호출)
func snitch_on_player() -> int:
	if has_witnessed_player:
		return witnessed_criminal_mask
	return -1 

# =================================================
# 🎭 [2] 플레이어 상호작용 로직
# =================================================

# 플레이어가 근처에 왔을 때 (player.gd에서 호출)
func on_player_entered(player):
	nearby_player = player
	update_bubble_ui()

# 플레이어가 멀어졌을 때 (player.gd에서 호출)
func on_player_exited():
	nearby_player = null
	update_bubble_ui()

# 플레이어와 가면을 바꿀 때 호출됨 (기억 심기)
func remember_criminal_mask(new_mask_on_player: int):
	has_witnessed_player = true
	witnessed_criminal_mask = new_mask_on_player

# 플레이어가 접수를 마쳤을 때 호출됨 (접수원 전용)
func complete_reception():
	reception_finished = true
	update_bubble_ui()

# 플레이어가 말을 걸었을 때 쳐다보기 (선택 사항)
func look_at_target(target_pos: Vector2):
	var dir = global_position.direction_to(target_pos)
	if abs(dir.x) > abs(dir.y):
		# 좌우 반전 대신 프레임 변경 방식을 쓴다면 아래 로직 사용
		body_sprite.frame = 3 if dir.x > 0 else 2
		
		# 단순히 flip_h를 쓴다면:
		# body_sprite.flip_h = (dir.x < 0)

# =================================================
# 💬 [3] 말풍선 UI 관리 (통합된 IconBubble 사용)
# =================================================

func update_bubble_ui():
	# 노드가 준비되지 않았거나 말풍선이 없으면 중단
	if not is_node_ready() or not icon_bubble: return
	
	# 1. 이미 완료된 상태면 말풍선 끄기
	if reception_finished or (not is_receptionist and mask_row == desired_mask_row):
		icon_bubble.hide_bubble()
		return
	
	# 2. 플레이어가 가까이 있을 때 -> 교환 UI 표시
	if nearby_player:
		icon_bubble.show_trade_ui(mask_row, nearby_player.current_mask_row, is_receptionist)
	
	# 3. 평상시 상태 -> 원하는 가면(혹은 줄 가면) 아이콘 표시
	else:
		var show_mask = desired_mask_row
		if is_receptionist:
			show_mask = mask_row # 접수원은 자기가 가진 걸 보여줌
			
		# 형사 대화 모드 중 'mask' 타입만 빌려서 보여줌
		icon_bubble.show_detective_chat("mask", show_mask)

# =================================================
# 🎨 [4] 비주얼 업데이트
# =================================================

func _update_visual():
	if mask_sprite:
		# 몸체 방향(frame)에 맞춰 가면 방향도 동기화 (스프라이트 시트 구조에 따라 조정)
		var current_dir = 0
		if body_sprite: 
			# body_sprite가 AnimatedSprite가 아니라 일반 Sprite2D(Sheet)라고 가정 시:
			current_dir = body_sprite.frame % 4 
			
		mask_sprite.frame = (mask_row * 4) + current_dir
