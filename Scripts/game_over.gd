extends Control

func _ready():
	var retry_btn = $VBoxContainer/HBoxContainer/RetryButton
	var title_btn = $VBoxContainer/HBoxContainer/TitleButton
	
	retry_btn.pressed.connect(_on_retry_pressed)
	title_btn.pressed.connect(_on_title_pressed)
	
	retry_btn.grab_focus()
	
func _on_retry_pressed():
	# 게임 매니저에게 '재도전' 요청
	GameManager.retry_stage()

func _on_title_pressed():
	# 게임 매니저에게 '타이틀 이동' 요청
	GameManager.go_to_title()
