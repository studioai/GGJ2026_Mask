extends CharacterBody2D
class_name Detective

enum State { INVESTIGATE, CHASE }
var current_state = State.INVESTIGATE

@export var speed = 20.0
var target_mask_id: int = -1
var current_target: Node2D = null
var is_busy: bool = false 

# 이미 확인한 NPC 목록
var ignored_npcs: Array = [] 

# [상태] 활동 시작 여부
var is_active: bool = false

@onready var nav_agent = $NavigationAgent2D
@onready var body_sprite = $BodySprite
@onready var catch_area = $CatchArea
@onready var recalculate_timer = $RecalculateTimer
@onready var animation_player = $AnimationPlayer
@onready var icon_bubble = $IconBubble

func _ready():
	recalculate_timer.timeout.connect(_on_recalculate_timer_timeout)
	catch_area.body_entered.connect(_on_catch_area_body_entered)
	
	await get_tree().physics_frame
	
	# [초기 상태: 완전 은신 모드]
	# 1. 시각적 숨김
	visible = false
	# 2. 논리적 정지 (코드 실행 중단)
	set_physics_process(false)
	# 3. 물리적 충돌 제거 (투명벽 방지)
	collision_layer = 0
	collision_mask = 0
	# 4. 감지 영역 비활성화 (유령 체포 방지)
	catch_area.monitoring = false
	
	# 타이머 연결 (10초 후 등장)
	get_tree().create_timer(10.0).timeout.connect(start_detective_action)
	
	# 접수원 신호 연결 (가면 받으면 등장)
	var npcs = get_tree().get_nodes_in_group("npc")
	for npc in npcs:
		if npc.get("is_receptionist") == true:
			if not npc.receptionist_handed_mask.is_connected(start_detective_action):
				npc.receptionist_handed_mask.connect(start_detective_action)
			break

# [활동 개시 함수]
func start_detective_action():
	if is_active: return # 중복 실행 방지
	is_active = true
	
	# 모든 기능 활성화
	visible = true
	set_physics_process(true)
	collision_layer = 1 # 프로젝트 설정에 맞게 조정 (보통 1)
	collision_mask = 1
	catch_area.monitoring = true
	
	print("형사: 활동 개시! (타이머 또는 접수원 호출)")
	
	# 초기 타겟 설정
	var player = get_tree().get_first_node_in_group("player")
	
	# 플레이어가 이미 가면이 없으면(맨얼굴) 바로 추격
	if player and player.current_mask_row == -1:
		current_state = State.CHASE
		target_mask_id = -1 
		current_target = player
	else:
		# 아니면 접수원에게 탐문 시작
		current_state = State.INVESTIGATE
		find_receptionist()
	
	_on_recalculate_timer_timeout()
	recalculate_timer.start()

func _physics_process(_delta):
	if is_busy or current_target == null:
		animation_player.stop()
		return

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		animation_player.stop()
		
		if is_instance_valid(current_target):
			if global_position.distance_to(current_target.global_position) < 50:
				_arrive_at_target(current_target)
		return

	var next_path_position = nav_agent.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_position) * speed
	
	velocity = new_velocity
	move_and_slide()
	
	if velocity.length() > 10:
		_update_animation(new_velocity)
	else:
		animation_player.stop()

func _update_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0: animation_player.play("walk_right")
		else: animation_player.play("walk_left")
	else:
		if dir.y > 0: animation_player.play("walk_down")
		else: animation_player.play("walk_up")

# --- AI 로직 ---

func _on_recalculate_timer_timeout():
	if is_busy: return 

	match current_state:
		State.INVESTIGATE:
			if is_instance_valid(current_target):
				nav_agent.target_position = current_target.global_position
			else:
				find_receptionist()
				
		State.CHASE:
			find_closest_suspect()
			
			if is_instance_valid(current_target):
				nav_agent.target_position = current_target.global_position
			else:
				print("형사: 타겟 소실! 접수원에게 재확인")
				current_state = State.INVESTIGATE
				ignored_npcs.clear()
				
				find_receptionist()
				if current_target:
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
	
	if player:
		# 현재 쫓는 가면을 썼거나, 맨얼굴(-1)인 경우
		if player.current_mask_row == target_mask_id or player.current_mask_row == -1:
			potential_targets.append(player)
	
	for node in get_tree().get_nodes_in_group("npc"):
		# 접수원은 추격 대상 아님
		if node.get("is_receptionist") == true: continue
		if node in ignored_npcs: continue
		
		if "mask_row" in node:
			if node.mask_row == target_mask_id:
				potential_targets.append(node)
	
	var nearest_dist = INF
	var nearest_node = null
	for t in potential_targets:
		var dist = global_position.distance_to(t.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_node = t
	current_target = nearest_node

# --- [이벤트] 도착 및 시퀀스 처리 ---

func _on_catch_area_body_entered(body):
	_arrive_at_target(body)

func _arrive_at_target(body):
	if is_busy or body != current_target: return
	
	is_busy = true 
	nav_agent.target_position = global_position
	velocity = Vector2.ZERO
	animation_player.stop()

	# [상황 A] 접수원 탐문 (초기 단서)
	if current_state == State.INVESTIGATE and body.get("is_receptionist"):
		# 1. 형사: 주인공 얼굴(0번 인덱스) + 물음표(?)
		icon_bubble.show_detective_chat("inquiry", 0) 
		await get_tree().create_timer(1.5).timeout
		
		# 2. 접수원: 넘겨준 가면 정보 제시
		if body.has_method("get_handed_mask_info"):
			var new_target = body.get_handed_mask_info()
			
			if target_mask_id != new_target:
				ignored_npcs.clear()
				target_mask_id = new_target
			
			if body.has_node("IconBubble"):
				body.get_node("IconBubble").show_detective_chat("mask", target_mask_id)
			await get_tree().create_timer(1.5).timeout
			
			# 3. 형사: 느낌표(!)
			icon_bubble.show_detective_chat("emote", 0) 
			await get_tree().create_timer(1.0).timeout
			
			# 4. 추격 시작
			current_state = State.CHASE
			current_target = null
			_on_recalculate_timer_timeout()

	# [상황 B] 용의자 체포/심문 (추격 모드)
	elif current_state == State.CHASE:
		if body.get("is_receptionist") == true:
			is_busy = false
			return

		# 1. 공통: 발견(!)
		icon_bubble.show_detective_chat("emote", 0) 
		await get_tree().create_timer(1.0).timeout
		
		# [플레이어 검거]
		if body.is_in_group("player"):
			print("검거 완료! -> 게임 오버")
ssssssssssssssssssss			GameManager.trigger_game_over()
			return
			
		# [NPC 심문]
		elif body.is_in_group("npc"):
			# 2. 공통: 억울함(X)
			if body.has_node("IconBubble"):
				body.get_node("IconBubble").show_detective_chat("emote", 2) 
			await get_tree().create_timer(1.5).timeout
			
			# NPC 정보 확인
			var new_info = -1
			if body.has_method("snitch_on_player"):
				new_info = body.snitch_on_player()
			
			# [분기점] 플레이어와 거래한 적이 있고, 내가 쫓는 타겟과 다른 정보일 때
			if new_info != -1 and new_info != target_mask_id:
				# >> [풀 시퀀스] 정보 획득
				
				# 3. 형사: "이 가면(현재 타겟) 봤어?"
				icon_bubble.show_detective_chat("inquiry", target_mask_id)
				await get_tree().create_timer(1.5).timeout
				
				# 4. NPC: "아니, 이거(새 가면) 쓰고 갔어."
				if body.has_node("IconBubble"):
					body.get_node("IconBubble").show_detective_chat("mask", new_info)
				await get_tree().create_timer(2.0).timeout
				
				# 5. 형사: "알았다!" (!)
				icon_bubble.show_detective_chat("emote", 0) 
				
				target_mask_id = new_info
				ignored_npcs.clear()
				print("새로운 정보 획득! 타겟 변경: ", target_mask_id)
				
			else:
				# >> [간략화 시퀀스] 꽝
				ignored_npcs.append(body)
			
			current_target = null
			recalculate_timer.start(0.5)
	
	is_busy = false
