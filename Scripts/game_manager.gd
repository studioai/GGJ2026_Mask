extends Node

# 현재 스테이지 번호
var current_stage_index: int = 1

# 경로 설정
const STAGE_PATH_TEMPLATE = "res://scenes/stages/stage_%d.tscn"
const ENDING_SCENE_PATH = "res://scenes/ending_scene.tscn"
const GAME_OVER_SCENE_PATH = "res://scenes/game_over.tscn"
const TITLE_SCENE_PATH = "res://scenes/title_scene.tscn"

var canvas_layer: CanvasLayer
var color_rect: ColorRect

func _ready():
	_setup_fade_layer()
	fade_in()

func _setup_fade_layer():
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 
	add_child(canvas_layer)
	
	color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.color.a = 0.0 
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	canvas_layer.add_child(color_rect)

# --- [기존] 다음 스테이지 ---
func go_to_next_stage():
	get_tree().paused = true
	await fade_out()
	
	current_stage_index += 1
	var next_stage_path = STAGE_PATH_TEMPLATE % current_stage_index
	
	if FileAccess.file_exists(next_stage_path):
		get_tree().change_scene_to_file(next_stage_path)
	else:
		if FileAccess.file_exists(ENDING_SCENE_PATH):
			get_tree().change_scene_to_file(ENDING_SCENE_PATH)
	
	get_tree().paused = false
	fade_in()

# --- [신규] 게임 오버 처리 ---

# 1. 게임 오버 화면으로 이동
func trigger_game_over():
	print("게임 오버!")
	get_tree().paused = true # 게임 정지
	await fade_out(0.5)      # 빠르게 암전
	
	get_tree().change_scene_to_file(GAME_OVER_SCENE_PATH)
	
	get_tree().paused = false # UI 조작을 위해 정지 해제
	fade_in(0.5)

# 2. 현재 스테이지 재도전
func retry_stage():
	# 현재 저장된 current_stage_index를 그대로 다시 로드
	var stage_path = STAGE_PATH_TEMPLATE % current_stage_index
	
	await fade_out(0.5)
	if FileAccess.file_exists(stage_path):
		get_tree().change_scene_to_file(stage_path)
	else:
		print("오류: 스테이지 파일을 찾을 수 없습니다.")
	fade_in(0.5)

# 3. 타이틀 화면으로 이동
func go_to_title():
	await fade_out(0.5)
	if FileAccess.file_exists(TITLE_SCENE_PATH):
		get_tree().change_scene_to_file(TITLE_SCENE_PATH)
	fade_in(0.5)

func start_game():
	print("새 게임 시작!")
	
	# 1. 스테이지 번호 초기화 (가장 중요!)
	current_stage_index = 1
	
	# 2. 1스테이지 경로 계산
	var first_stage_path = STAGE_PATH_TEMPLATE % current_stage_index
	
	# 3. 페이드 아웃 후 씬 전환
	await fade_out(0.5)
	
	if FileAccess.file_exists(first_stage_path):
		get_tree().change_scene_to_file(first_stage_path)
	else:
		print("오류: 1스테이지 파일이 없습니다! (%s)" % first_stage_path)
		
	fade_in(0.5)

# --- 페이드 효과 ---
func fade_out(duration: float = 1.0):
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP 
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished

func fade_in(duration: float = 1.0):
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	await tween.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
