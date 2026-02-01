extends Area2D

# 클리어 신호를 보낼 사용자 정의 시그널
signal stage_cleared

func _ready():
	# 플레이어가 들어오면 감지하도록 시그널 연결
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	# 감지된 물체가 '플레이어'인지 확인
	if body.is_in_group("player"):
		print("탈출 성공! 스테이지 클리어!")
		
		# 방법 A: 여기서 바로 씬 전환
		# get_tree().change_scene_to_file("res://scenes/ending_scene.tscn")
		
		# 방법 B: 게임 매니저에게 알리기 (추천)
		# GameManager.game_clear() 
		
		# 임시 연출: 게임 멈추기
		get_tree().paused = true
