extends Node2D

@onready var icon = $Icon

var target_node: Node2D = null
var padding: float = 40.0 # 화면 가장자리 여백

func setup(target: Node2D, texture: Texture2D, color: Color):
	target_node = target
	if texture:
		icon.texture = texture
	icon.modulate = color

func _process(_delta):
	# 1. 타겟이 없거나, 게임에서 사라졌거나(queue_free), 숨겨진 상태라면 마커도 숨김
	if not is_instance_valid(target_node) or (target_node is CanvasItem and not target_node.visible):
		visible = false
		return

	# 2. 화면 크기와 타겟의 화면상 위치 계산
	var viewport_rect = get_viewport_rect()
	var screen_pos = target_node.get_global_transform_with_canvas().origin
	
	# 3. 화면 안에 있는지 확인 (여백 포함)
	if viewport_rect.grow(-padding).has_point(screen_pos):
		# 화면 안: 숨김
		visible = false
	else:
		# 화면 밖: 표시 및 위치 계산
		visible = true
		
		# 화면 중심점
		var center = viewport_rect.size / 2.0
		
		# 중심에서 타겟까지의 방향 벡터
		var direction = (screen_pos - center).normalized()
		
		# 화면 비율에 맞춰 가장자리 좌표 계산 (비례식)
		# x, y축 중 어느 벽에 먼저 닿는지 계산
		var abs_dir = direction.abs()
		var scale_x = (center.x - padding) / abs_dir.x if abs_dir.x > 0 else 0
		var scale_y = (center.y - padding) / abs_dir.y if abs_dir.y > 0 else 0
		
		# 더 짧은 쪽이 벽에 닿는 거리임
		var distance_to_edge = min(scale_x, scale_y)
		
		# 최종 위치 설정
		position = center + direction * distance_to_edge
		
		# (선택) 아이콘 회전: 타겟 방향 바라보기
		rotation = direction.angle() + PI/2 # 이미지가 위쪽(12시)을 향한다고 가정
