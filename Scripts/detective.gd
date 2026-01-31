extends CharacterBody2D
class_name Detective

# AI 상태 관리
enum State { INVESTIGATE, CHASE }
var current_state = State.INVESTIGATE

@export var speed = 190.0
var target_mask_id: int = -1
var current_target: Node2D = null

# 노드 참조
@onready var nav_agent = $NavigationAgent2D
@onready var body_sprite = $BodySprite
@onready var catch_area = $CatchArea
@onready var recalculate_timer = $RecalculateTimer
@onready var animation_player = $AnimationPlayer

# 통합된 말풍선 UI
@onready var icon_bubble = $IconBubble

func _ready():
	# 1. 사건 현장(접수원)으로 출발
	find_receptionist()
	
	# 타이머 및 영역 시그널 연결
	recalculate_timer.timeout.connect(_on_recalculate_timer_timeout)
	catch_area.body_entered.connect(_on_catch_area_body_entered)

func _physics_process(_delta):
	# 도착했거나 대화 중(velocity가 0)일 때 애니메이션 정지
	if nav_agent.is_navigation_finished() or velocity.length() < 10:
		animation_player.stop()
		return

	var next_path_position = nav_agent.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_position) * speed
	
	velocity = new_velocity
	move_and_slide()
	_update_animation(new_velocity)

func _update_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0: animation_player.play("walk_right")
		else: animation_player.play("walk_left")
	else:
		if dir.y > 0: animation_player.play("walk_down")
		else: animation_player.play("walk_up")

# --- AI 탐색 및 추적 ---

func _on_recalculate_timer_timeout():
	match current_state:
		State.INVESTIGATE:
			if is_instance_valid(current_target):
				nav_agent.target_position = current_target.global_position
		State.CHASE:
			find_closest_suspect()
			if is_instance_valid(current_target):
				nav_agent.target_position = current_target.global_position

func find_receptionist():
	var npcs = get_tree().get_nodes_in_group("npc")
	for npc in npcs:
		if npc.get("is_receptionist") == true:
			current_target = npc
			return

func find_closest_suspect():
	var potential_targets = []
	var player = get_tree().get_first_node_in_group("player")
	
	# 타겟 가면을 쓴 플레이어/NPC 수집
	if player and player.current_mask_row == target_mask_id:
		potential_targets.append(player)
	
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.mask_row == target_mask_id:
			potential_targets.append(npc)
	
	# 가장 가까운 대상 선정
	var nearest_dist = INF
	var nearest_node = null
	for t in potential_targets:
		var dist = global_position.distance_to(t.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_node = t
	current_target = nearest_node

# --- 🔍 수사 및 심문 연출 (통합 UI 사용) ---

func _on_catch_area_body_entered(body):
	if body == current_target:
		# 즉시 정지
		nav_agent.target_position = global_position
		velocity = Vector2.ZERO
		animation_player.stop()

		# ==========================================
		# [상황 A] 접수원 탐문 (공손하게 시작)
		# ==========================================
		if current_state == State.INVESTIGATE and body.get("is_receptionist"):
			# 형사: [?] (정보 요청)
			icon_bubble.show_detective_chat("emote", 0) 
			await get_tree().create_timer(1.5).timeout
			
			if body.has_method("get_handed_mask_info"):
				target_mask_id = body.get_handed_mask_info()
				
				# 접수원: [가면 아이콘] (이걸 줬어요)
				if body.has_node("IconBubble"):
					body.get_node("IconBubble").show_detective_chat("mask", target_mask_id)
				await get_tree().create_timer(1.5).timeout
				
				# 형사: [!] (확인 완료)
				icon_bubble.show_detective_chat("emote", 1)
				await get_tree().create_timer(1.0).timeout
				
				current_state = State.CHASE
				current_target = null

		# ==========================================
		# [상황 B] 용의자 추격 및 심문
		# ==========================================
		elif current_state == State.CHASE:
			# 1. 형사: [!] (잡았다!)
			icon_bubble.show_detective_chat("emote", 1)
			await get_tree().create_timer(1.0).timeout
			
			# 진짜 범인(플레이어)일 경우
			if body.is_in_group("player"):
				get_tree().paused = true # 게임 오버 처리
				return
				
			# 억울한 NPC일 경우 (정보 갱신)
			elif body.is_in_group("npc"):
				# 2. NPC: [X] (저 아니에요!)
				if body.has_node("IconBubble"):
					body.get_node("IconBubble").show_detective_chat("emote", 2) 
				await get_tree().create_timer(1.5).timeout
				
				# 3. 형사: [가면] + [?] (그럼 범인은 지금 무슨 가면이지?)
				icon_bubble.show_detective_chat("inquiry", target_mask_id)
				await get_tree().create_timer(1.5).timeout
				
				# 4. NPC의 새로운 제보
				if body.has_method("snitch_on_player"):
					target_mask_id = body.snitch_on_player()
					
					# NPC: [새로운 가면] (범인은 이걸 썼어요!)
					if body.has_node("IconBubble"):
						body.get_node("IconBubble").show_detective_chat("mask", target_mask_id)
					await get_tree().create_timer(2.0).timeout
					
					# 5. 형사: [!] (알았다! 재추격!)
					icon_bubble.show_detective_chat("emote", 1)
				
				# 재추격 시작
				current_target = null
				recalculate_timer.start(0.5)
