extends Area2D

# [수정된 GoalArea.gd]

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		print("탈출 성공!")
		
		# 충돌을 끄지 않으면 페이드아웃 중에 여러 번 호출될 수 있음
		$CollisionShape2D.set_deferred("disabled", true)
		
		# 게임 매니저에게 "다음 스테이지로 가자"		GameManager.go_to_next_stage()
