extends Node2D

@onready var mask_npc = $Content/MaskNPC
@onready var arrow = $Content/Arrow
@onready var mask_player = $Content/MaskPlayer
@onready var emote_icon = $Content/EmoteIcon

func _ready():
	visible = false
	scale = Vector2.ZERO

# --- [수사 모드] 형사와의 대화 ---

func show_detective_chat(type: String, data = null):
	_reset_all()
	match type:
		"emote": # !, ?, X
			emote_icon.visible = true
			emote_icon.frame = data
		"mask": # 제보 (가면 하나만 노출)
			mask_npc.visible = true
			mask_npc.frame = data * 4
			mask_npc.position = Vector2.ZERO
		"inquiry": # 심문 (가면 + ?)
			mask_npc.visible = true
			mask_npc.frame = data * 4
			mask_npc.position.x = -12
			emote_icon.visible = true
			emote_icon.frame = 0 # ? 아이콘
			emote_icon.position.x = 12
	_pop_up(1.5)

# --- [교환 모드] 플레이어와의 상호작용 ---

func show_trade_ui(npc_mask: int, player_mask: int, is_receptionist: bool):
	_reset_all()
	visible = true
	scale = Vector2.ONE # 교환 UI는 지속되어야 하므로 애니메이션 없이 즉시 표시
	
	if is_receptionist: # 접수원은 주는 가면만 표시
		mask_npc.visible = true
		mask_npc.frame = npc_mask * 4
		mask_npc.position = Vector2.ZERO
	else: # 일반 NPC는 [내 가면 -> 네 가면] 표시
		mask_npc.visible = true
		mask_npc.frame = npc_mask * 4
		mask_npc.position.x = -15
		
		arrow.visible = true
		
		mask_player.visible = true
		mask_player.frame = player_mask * 4
		mask_player.position.x = 15

func hide_bubble():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
	await tween.finished
	visible = false

# --- 공통 내부 로직 ---

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
