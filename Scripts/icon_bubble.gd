@tool
extends Node2D

@onready var mask_npc = $Content/MaskNPC
@onready var arrow = $Content/Arrow
@onready var mask_player = $Content/MaskPlayer
@onready var emote_icon = $Content/EmoteIcon

# [수정] Label 대신 Sprite2D 참조
@onready var input_icon = $Content/InputIcon 

func _ready():
	if not Engine.is_editor_hint():
		visible = false
		scale = Vector2.ZERO
	
	z_index = 10 
	
	if get_node_or_null("/root/GlobalInput"):
		GlobalInput.input_scheme_changed.connect(_on_input_scheme_changed)

# --- 수사/대기 모드 ---
func show_detective_chat(type: String, data = null, duration: float = 1.5):
	_reset_all()
	
	match type:
		"emote": 
			emote_icon.visible = true
			emote_icon.frame = data 
			emote_icon.position = Vector2.ZERO
			
		"mask":
			mask_npc.visible = true
			mask_npc.frame = data * 4
			mask_npc.position = Vector2.ZERO
			
		"inquiry":
			# 0번(주인공 얼굴)이면 가면만, 아니면 가면+물음표
			if data == 0:
				mask_npc.visible = true
				mask_npc.frame = 0 # 주인공 얼굴
				mask_npc.position = Vector2.ZERO
			else:
				mask_npc.visible = true
				mask_npc.frame = data * 4
				mask_npc.position.x = -12
				
				emote_icon.visible = true
				emote_icon.frame = 1 # ?
				emote_icon.position.x = 12
	
	if Engine.is_editor_hint():
		visible = true
		scale = Vector2.ONE
		return

	if duration > 0:
		_pop_up(duration)
	else:
		visible = true
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

# --- 교환 모드 UI ---
func show_trade_ui(npc_mask: int, player_mask: int, is_receptionist: bool):
	_reset_all()
	visible = true
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	
	# [수정] 텍스트 대신 아이콘 업데이트 함수 호출
	_update_input_icon()
	
	if is_receptionist: 
		mask_npc.visible = true
		mask_npc.frame = npc_mask * 4
		mask_npc.position = Vector2.ZERO
	else: 
		arrow.visible = true
		arrow.position = Vector2.ZERO

		mask_player.visible = true
		mask_player.frame = player_mask * 4
		mask_player.position.x = -20 
		
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

func _on_input_scheme_changed(_is_gamepad):
	_update_input_icon()

# [신규] 입력 장치에 따라 아이콘 프레임 변경
func _update_input_icon():
	if not input_icon: return
	
	input_icon.visible = true
	
	# 기본값: 키보드 (1번)
	var frame_idx = 1 
	
	# 게임패드 사용 중이면: 컨트롤러 (0번)
	if get_node_or_null("/root/GlobalInput") and GlobalInput.is_using_gamepad:
		frame_idx = 0 
	
	input_icon.frame = frame_idx

func _reset_all():
	for child in $Content.get_children():
		child.visible = false
		if "position" in child: child.position = Vector2.ZERO

func _pop_up(duration):
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(duration).timeout
	hide_bubble()
