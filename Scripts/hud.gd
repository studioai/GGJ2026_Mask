extends CanvasLayer

# 위에서 만든 마커 씬 경로 (반드시 확인하세요!)
var marker_scene = preload("res://scenes/off_screen_marker.tscn")

# [설정] 인스펙터에서 각각의 아이콘을 넣으세요
@export var detective_icon: Texture2D
@export var goal_icon: Texture2D

func _ready():
	# 노드들이 준비될 때까지 한 프레임 대기
	await get_tree().process_frame
	_create_markers()

func _create_markers():
	# 1. 형사 마커 생성 (그룹명: enemy)
	var enemy = get_tree().get_first_node_in_group("enemy")
	if enemy:
		var marker = marker_scene.instantiate()
		add_child(marker)
		# 형사 아이콘 적용
		marker.setup(enemy, detective_icon)
	
	# 2. 골 마커 생성 (그룹명: goal)
	var goal = get_tree().get_first_node_in_group("goal")
	if goal:
		var marker = marker_scene.instantiate()
		add_child(marker)
		# 골 아이콘 적용
		marker.setup(goal, goal_icon)
