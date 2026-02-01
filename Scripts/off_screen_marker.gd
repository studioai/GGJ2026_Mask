extends Node2D

@onready var icon_sprite = $Icon

var target_node: Node2D = null
var padding: float = 50.0 # 화면 가장자리 여백

# [수정] 인자 2개 (target, texture)만 받음
func setup(target: Node2D, texture: Texture2D):
	target_node = target
	if texture:
		icon_sprite.texture = texture

func _process(_delta):
	# 1. 타겟 체크
	if not is_instance_valid(target_node):
		visible = false
		return
		
	if "visible" in target_node and not target_node.visible:
		visible = false
		return

	# 2. 위치 계산
	var screen_pos = target_node.get_global_transform_with_canvas().origin
	var viewport_rect = get_viewport_rect()
	
	# 3. 화면 안/밖 체크
	if viewport_rect.grow(-padding).has_point(screen_pos):
		visible = false
	else:
		visible = true
		
		var center = viewport_rect.size / 2.0
		var direction = (screen_pos - center).normalized()
		var abs_dir = direction.abs()
		
		var scale_factor = 1.0
		if abs_dir.x * center.y > abs_dir.y * center.x:
			scale_factor = (center.x - padding) / abs_dir.x
		else:
			scale_factor = (center.y - padding) / abs_dir.y
			
		position = center + direction * scale_factor
		rotation = direction.angle() + PI/2
