@tool
extends CharacterBody2D

# 값을 바꿀 때마다 _update_mask() 함수를 실행하도록 설정
@export var mask_row: int = 0:
	set(value):
		mask_row = value
		_update_mask()

@onready var body_sprite = $BodySprite
@onready var mask_sprite = $BodySprite/MaskSprite

func _ready():
	_update_mask()

# 에디터와 게임 양쪽에서 가면을 갱신하는 함수
func _update_mask():
	if mask_sprite:
		# 현재 보고 있는 방향(열)은 유지하면서 가면 종류(행)만 변경
		var current_col = mask_sprite.frame % 4
		mask_sprite.frame = (mask_row * 4) + current_col

# --- 기존 로직 ---

func look_at_target(target_position: Vector2):
	var direction = global_position.direction_to(target_position)
	var dir_index = 0
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			dir_index = 3
		else:
			dir_index = 2
	else:
		if direction.y > 0:
			dir_index = 0
		else:
			dir_index = 1
	
	if body_sprite:
		body_sprite.frame = dir_index
		
	if mask_sprite:
		mask_sprite.frame = (mask_row * 4) + dir_index
