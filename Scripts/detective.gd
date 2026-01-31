extends CharacterBody2D
class_name Detective

enum State { INVESTIGATE, CHASE }
var current_state = State.INVESTIGATE

@export var speed = 20.0
var target_mask_id: int = -1
var current_target: Node2D = null
var is_busy: bool = false 

# 심문 끝난 NPC 목록
var ignored_npcs: Array = [] 

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
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.current_mask_row == -1:
		current_state = State.CHASE
		target_mask_id = -1 
		current_target = player
	else:
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
				# 타겟 소실 -> 접수원 복귀
				print("형사: 타겟 소실! 접수원에게 이동")
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
		if player.current_mask_row == target_mask_id or player.current_mask_row == -1:
			potential_targets.append(player)
	
	for node in get_tree().get_nodes_in_group("npc"):
		# [수정] 접수원은 용의자 목록에서 제외 (정보원 역할만 함)
		if node.get("is_receptionist") == true:
			continue

		if node in ignored_npcs:
			continue
		
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

# --- [이벤트] 도착 처리 ---

func _on_catch_area_body_entered(body):
	_arrive_at_target(body)

func _arrive_at_target(body):
	if is_busy or body != current_target: return
	
	is_busy = true 
	nav_agent.target_position = global_position
	velocity = Vector2.ZERO
	animation_player.stop()

	# [상황 A] 접수원 (간소화 시퀀스)
	if current_state == State.INVESTIGATE and body.get("is_receptionist"):
		icon_bubble.show_detective_chat("emote", 1) # ?
		await get_tree().create_timer(1.5).timeout
		
		if body.has_method("get_handed_mask_info"):
			var new_target = body.get_handed_mask_info()
			
			if target_mask_id != new_target:
				ignored_npcs.clear()
				target_mask_id = new_target
			
			if body.has_node("IconBubble"):
				body.get_node("IconBubble").show_detective_chat("mask", target_mask_id)
			await get_tree().create_timer(1.5).timeout
			
			current_state = State.CHASE
			current_target = null
			_on_recalculate_timer_timeout()

	# [상황 B] 용의자 체포/심문
	elif current_state == State.CHASE:
		# [수정] 접수원은 추격 대상이 아니므로 무시 (중복 심문 방지)
		if body.get("is_receptionist") == true:
			is_busy = false
			return

		# 1. 공통: 발견(!)
		icon_bubble.show_detective_chat("emote", 0) # !
		await get_tree().create_timer(1.0).timeout
		
		if body.is_in_group("player"):
			print("검거 완료!")
			get_tree().paused = true
			return
			
		elif body.is_in_group("npc"):
			# 2. 공통: 억울함(X)
			if body.has_node("IconBubble"):
				body.get_node("IconBubble").show_detective_chat("emote", 2) # X
			await get_tree().create_timer(1.5).timeout
			
			var new_info = -1
			if body.has_method("snitch_on_player"):
				new_info = body.snitch_on_player()
			
			# ---------------------------------------------------------
			# [분기점] 플레이어와 거래한 적이 있는가?
			# ---------------------------------------------------------
			if new_info != -1 and new_info != target_mask_id:
				# >> [풀 시퀀스]
				icon_bubble.show_detective_chat("inquiry", target_mask_id)
				await get_tree().create_timer(1.5).timeout
				
				if body.has_node("IconBubble"):
					body.get_node("IconBubble").show_detective_chat("mask", new_info)
				await get_tree().create_timer(2.0).timeout
				
				icon_bubble.show_detective_chat("emote", 0) 
				
				target_mask_id = new_info
				ignored_npcs.clear()
				print("새로운 정보 획득! 타겟 변경: ", target_mask_id)
				
			else:
				# >> [간략화 시퀀스]
				ignored_npcs.append(body)
			
			current_target = null
			recalculate_timer.start(0.5)
	
	is_busy = false
