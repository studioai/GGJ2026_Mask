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
	
	if get_node_or_null("/root/GlobalInput"):
		GlobalInput.input_scheme_changed.connect(_on_input_scheme_changed)

# --- 수사/대기 모드 ---
func show_detective_chat(type: String, data = null):
	_reset_all()
	match type:
		"emote": 
			emote_icon.visible = true
			emote_icon.frame = data # 0:!, 1:?, 2:X
		"mask":
			mask_npc.visible = true
			mask_npc.frame = data * 4
			mask_npc.position = Vector2.ZERO
		"inquiry":
			# "이 가면 봤어?" (가면 + 물음표)
			mask_npc.visible = true
			mask_npc.frame = data * 4
			mask_npc.position.x = -12
			
			emote_icon.visible = true
			# [수정됨] 물음표(?) 인덱스가 1번이므로 1로 설정
			emote_icon.frame = 1 
			emote_icon.position.x = 12
	
	if Engine.is_editor_hint():
		visible = true
		scale = Vector2.ONE
		return

	_pop_up(1.5)

# --- 교환 모드 (이하 동일) ---
func show_trade_ui(npc_mask: int, player_mask: int, is_receptionist: bool):
	_reset_all()
	visible = true
	scale = Vector2.ONE 
	
	_update_key_label()
	
	if is_receptionist: 
		mask_npc.visible = true
		mask_npc.frame = npc_mask * 4
		mask_npc.position = Vector2.ZERO
	else: 
		mask_npc.visible = true
		mask_npc.frame = npc_mask * 4
		mask_npc.position.x = -15
		arrow.visible = true
		mask_player.visible = true
		mask_player.frame = player_mask * 4
		mask_player.position.x = 15

func hide_bubble():
	if Engine.is_editor_hint():
		visible = false
		return

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
	await tween.finished
	visible = false

func _on_input_scheme_changed(_is_gamepad):
	_update_key_label()

func _update_key_label():
	if not key_label: return
	key_label.visible = true
	var interact_key = "[E]"
	if get_node_or_null("/root/GlobalInput") and GlobalInput.is_using_gamepad:
		interact_key = "[A]"
	key_label.text = interact_key

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
