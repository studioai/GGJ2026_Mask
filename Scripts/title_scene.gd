extends Control

func _ready():
	# 버튼 연결
	$StartButton.pressed.connect(_on_start_pressed)
	
	# [필수] 시작하자마자 버튼에 포커스 (키보드/패드 조작용)
	$StartButton.grab_focus()

func _on_start_pressed():
	# 게임 매니저에게 '새 게임 시작' 요청
	GameManager.start_game()
