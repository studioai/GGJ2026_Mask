@tool
extends CharacterBody2D

# 에디터에서도 보이고, 플레이어가 접근할 수도 있는 변수
@export var mask_row: int = 0:
	set(value):
		mask_row = value
		_update_mask()

@onready var body_sprite = $BodySprite
@onready var mask_sprite = $BodySprite/MaskSprite

func _ready():
	_update_mask()

# 현재 보고 있는 방향은 유지한 채, 가면 종류만 바꿈
func _update_mask():
	if mask_sprite:
		var current_dir = mask_sprite.frame % 4 # 현재 방향(0~3) 계산
		mask_sprite.frame = (mask_row * 4) + current_dir

# 플레이어가 말을 걸면 실행되는 함수
func look_at_target(target_position: Vector2):
	var direction = global_position.direction_to(target_position)
	var dir_index = 0
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0: dir_index = 3 # 우
		else: dir_index = 2 # 좌
	else:
		if direction.y > 0: dir_index = 0 # 하
		else: dir_index = 1 # 상
	
	if body_sprite:
		body_sprite.frame = dir_index
		
	if mask_sprite:
		# 바뀐 방향에 맞춰 프레임 갱신
		mask_sprite.frame = (mask_row * 4) + dir_index
