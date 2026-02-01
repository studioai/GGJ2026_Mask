@tool
extends Node2D

@onready var mask_npc = $Content/MaskNPC
@onready var arrow = $Content/Arrow
@onready var mask_player = $Content/MaskPlayer
@onready var emote_icon = $Content/EmoteIcon
@onready var key_label = $Content/KeyLabel 

func _ready():
	if not Engine.is_editor_hint():
		visible = false
		scale = Vector2.ZERO
	
	# UI가 항상 캐릭터나 배경보다 위에 보이도록 설정
	z_index = 10 
	
	# 입력 장치 변경 감지 (키보드/패드)
	if get_node_or_null("/root/GlobalInput"):
		GlobalInput.input_scheme_changed.connect(_on_input_scheme_changed)

# --- 수사/대기 모드 ---
# duration: 0이면 사라지지 않고 계속 떠 있음 (NPC 상태 표시용)
func show_detective_chat(type: String, data = null, duration: float = 1.5):
	_reset_all()
	
	match type:
		"emote": 
			# data: 0(!), 1(?), 2(X)
			emote_icon.visible = true
			emote_icon.frame = data 
			emote_icon.position = Vector2.ZERO
			
		"mask":
			# data: 가면 ID
			mask_npc.visible = true
			mask_npc.frame = data * 4
			mask_npc.position = Vector2.ZERO
			
		"inquiry":
			# 형사가 "이 가면(Mask) 봤어?(?)" 라고 물어볼 때
			mask_npc.visible = true
			mask_npc.frame = data * 4
			mask_npc.position.x = -12
			
			emote_icon.visible = true
			emote_icon.frame = 1 # 물음표(?)
			emote_icon.position.x = 12
	
	if Engine.is_editor_hint():
		visible = true
		scale = Vector2.ONE
		return

	# [수정됨] duration이 0이면 영구 표시, 아니면 시간 지나면 사라짐
	if duration > 0:
		_pop_up(duration)
	else:
		visible = true
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

# --- 교환 모드 UI ---
# 레이아웃: [플레이어 가면] -> [화살표] -> [NPC 가면]
func show_trade_ui(npc_mask: int, player_mask: int, is_receptionist: bool):
	_reset_all()
	visible = true
	
	# 팝업 애니메이션
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	
	_update_key_label()
	
	if is_receptionist: 
		# 접수원은 줄 가면만 가운데 표시 (플레이어 가면 요구 안함)
		mask_npc.visible = true
		mask_npc.frame = npc_mask * 4
		mask_npc.position = Vector2.ZERO
	else: 
		# [수정됨] 직관적인 좌->우 배치
		
		# 1. 화살표 (가운데)
		arrow.visible = true
		arrow.position = Vector2.ZERO

		# 2. 플레이어 가면 (왼쪽: 내 걸 주고)
		mask_player.visible = true
		mask_player.frame = player_mask * 4
		mask_player.position.x = -20 
		
		# 3. NPC 가면 (오른쪽: 이걸 받는다)
		mask_npc.visible = true
		mask_npc.frame = npc_mask * 4
		mask_npc.position.x = 20 

func hide_bubble():
	if Engine.is_editor_hint():
		visible = false
		return

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
	await tween.finished
	visible = false

# --- 입력 장치 대응 ---
func _on_input_scheme_changed(_is_gamepad):
	_update_key_label()

func _update_key_label():
	if not key_label: return
	
	key_label.visible = true
	var interact_key = "[E]"
	if get_node_or_null("/root/GlobalInput") and GlobalInput.is_using_gamepad:
		interact_key = "[A]" # 엑박 패드 기준
	key_label.text = interact_key

# --- 내부 헬퍼 함수 ---
func _reset_all():
	for child in $Content.get_children():
		child.visible = false
		# 위치 초기화 (필요시 각 모드에서 재설정)
		if "position" in child: 
			child.position = Vector2.ZERO

func _pop_up(duration):
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	
	await get_tree().create_timer(duration).timeout
	hide_bubble()
