# 繼承 Control 節點，這是 Godot 的 UI 基礎類別
extends Control

# ===== UI 節點引用區域 =====
# @onready 表示這些變數會在節點進入場景樹時才初始化
# $ 符號是節點路徑的簡寫，從當前腳本附加的節點開始查找子節點

@onready var start = $VBoxContainer/Start              # 開始遊戲按鈕
@onready var rules = $VBoxContainer/Rules              # 規則說明按鈕
@onready var rulesContent = $RulesPanel/Content        # 規則面板內的文字內容
@onready var settings = $VBoxContainer/Settings        # 設定按鈕
@onready var rulesClose = $RulesPanel/Close            # 規則面板的關閉按鈕
@onready var settingsClose = $Settings/Close           # 設定面板的關閉按鈕

# ===== 按鍵重新綁定系統 =====
@onready var inputButton = preload("res://Scene/Component/button.tscn")  # 預載入按鈕場景，用來動態生成按鍵設定項目
@onready var actionList = $Settings/MarginContainer/ActionList           # 設定面板中顯示所有按鍵綁定的容器

# 按鍵重新綁定的狀態追蹤變數
var isRemapping = false        # 標記目前是否正在等待玩家按下新按鍵
var actionToRemap = null       # 儲存正在重新綁定的動作名稱（例如 "rotate_right"）
var remappingButton = null     # 儲存正在編輯的按鈕 UI 元件

# 遊戲內所有可綁定的動作清單（鍵 = 內部動作名稱，值 = UI 顯示文字）
var inputActions = {
	"right": "right",                    # 向右移動
	"left": "left",                      # 向左移動
	"soft_drop": "soft drop",            # 軟降（加速下降）
	"hard_drop": "hard drop",            # 硬降（瞬間落地）
	"rotate_right": "rotate right",      # 順時針旋轉
	"rotate_left": "rotate left",        # 逆時針旋轉
	"hold_piece": "hold piece",          # 保留方塊
}

# ===== 初始化函式 =====
# _ready() 是 Godot 的生命週期函式，當節點首次進入場景樹時被調用（只執行一次）
func _ready():
	# 創建按鍵設定列表（動態生成所有按鍵綁定的 UI）
	createActionList()
	
	# 從全域常數載入遊戲說明文字並設定到規則面板
	rulesContent.text = Consts.howToPlay
	
	# 設定按鈕的縮放中心點（用於滑鼠懸停時的放大效果）
	# Vector2(112, 56) 代表按鈕中心座標，讓縮放從中心展開而不是左上角
	start.pivot_offset = Vector2(112, 56)
	rules.pivot_offset = Vector2(112, 56)
	settings.pivot_offset = Vector2(112, 56)
	
	# 連接滑鼠事件與縮放動畫（製作 hover 效果）
	# bind() 將按鈕本身作為參數傳遞給 Utilities 的縮放函式
	start.connect("mouse_entered", Utilities.scaleUp.bind(start))      # 滑鼠進入 → 放大
	start.connect("mouse_exited", Utilities.scaleDown.bind(start))     # 滑鼠離開 → 縮小
	rules.connect("mouse_entered", Utilities.scaleUp.bind(rules))
	rules.connect("mouse_exited", Utilities.scaleDown.bind(rules))
	settings.connect("mouse_entered", Utilities.scaleUp.bind(settings))
	settings.connect("mouse_exited", Utilities.scaleDown.bind(settings))
	rulesClose.connect("mouse_entered", Utilities.scaleUp.bind(rulesClose))
	rulesClose.connect("mouse_exited", Utilities.scaleDown.bind(rulesClose))
	settingsClose.connect("mouse_entered", Utilities.scaleUp.bind(settingsClose))
	settingsClose.connect("mouse_exited", Utilities.scaleDown.bind(settingsClose))
	pass

# ===== 動態建立按鍵設定列表 =====
func createActionList():
	# 從專案設定載入預設的輸入對應（確保使用專案設定檔的內容）
	InputMap.load_from_project_settings()
	
	# 清空舊的子節點（如果有的話）
	for item in actionList.get_children():
		item.queue_free()  # queue_free() 會在當前幀結束時安全刪除節點
	
	# 為每個動作建立一個 UI 按鈕
	for action in inputActions:
		# 從預載入的場景實例化一個新按鈕
		var button = inputButton.instantiate()
		
		# 在按鈕中尋找子節點（用於顯示動作名稱和當前綁定的按鍵）
		var actionLabel = button.find_child("LabelAction")  # 顯示動作名稱（例如 "rotate right"）
		var inputLabel = button.find_child("LabelInput")    # 顯示當前綁定的按鍵（例如 "Up"）
		
		# 設定動作名稱的顯示文字
		actionLabel.text = inputActions[action]
		
		# 從 InputMap 取得這個動作目前綁定的所有按鍵事件
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			# 取第一個綁定的按鍵並轉為文字，同時移除 " (Physical)" 後綴
			inputLabel.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			# 如果沒有綁定任何按鍵，顯示空白
			inputLabel.text = ""
		
		# 將按鈕加入到設定面板的列表容器中
		actionList.add_child(button)
		
		# 連接按鈕的 pressed 訊號，點擊時呼叫 onInputButtonPressed 函式
		# bind() 將按鈕本身和動作名稱作為參數傳遞
		button.pressed.connect(onInputButtonPressed.bind(button, action))
	
# ===== 當玩家點擊按鍵設定按鈕時 =====
func onInputButtonPressed(button, action):
	# 檢查是否已經在重新綁定其他按鍵（防止同時編輯多個）
	if !isRemapping:
		# 播放設定音效
		AudioManager.settings_press.play()
		
		# 進入按鍵重新綁定模式
		isRemapping = true
		actionToRemap = action          # 記錄正在編輯的動作
		remappingButton = button        # 記錄正在編輯的 UI 按鈕
		
		# 更新按鈕文字提示玩家按下新按鍵
		button.find_child("LabelInput").text = "Press key to bind"

# ===== 全域輸入處理（監聽玩家按鍵） =====
# _input() 是 Godot 的生命週期函式，每次有輸入事件時都會被調用
func _input(event):
	# 只有在重新綁定模式下才處理輸入
	if isRemapping:
		# 檢查事件是否為鍵盤按鍵
		if event is InputEventKey:
			# 清除該動作原有的所有按鍵綁定
			InputMap.action_erase_events(actionToRemap)
			
			# 將新按下的按鍵加入到該動作
			InputMap.action_add_event(actionToRemap, event)
			
			# 更新 UI 顯示新的按鍵
			updateActionList(remappingButton, event)
			
			# 退出重新綁定模式，清空狀態變數
			isRemapping = false
			actionToRemap = null
			remappingButton = null
			
			# 標記此事件已處理，防止其他節點再次處理
			accept_event()

# ===== 更新按鍵顯示文字 =====
func updateActionList(button, event):
	# 將按鍵事件轉為可讀文字並移除 " (Physical)" 後綴
	button.find_child("LabelInput").text = event.as_text().trim_suffix(" (Physical)")

# ===== 動畫播放完成的回調 =====
# 當 AnimationPlayer 播放完任何動畫時會觸發此函式
func _on_animation_player_animation_finished(anim_name):
	# 檢查是否為淡出動畫
	if(anim_name == "FadeOut"):
		# 切換到遊戲場景（開始遊戲）
		get_tree().change_scene_to_file("res://Scene/GameplayScene.tscn")

# ===== 開始遊戲按鈕被按下 =====
func _on_start_pressed():
	# 停用所有主選單按鈕（防止重複點擊）
	disableAll(true)
	
	# 播放按鈕按下的視覺/音效效果
	Utilities.onPressed(start)
	
	# 播放淡出動畫（動畫結束後會觸發場景切換）
	$AnimationPlayer.play("FadeOut")

# ===== 規則說明按鈕被按下 =====
func _on_rules_pressed():
	# 停用所有主選單按鈕
	disableAll(true)
	
	# 啟用規則面板的關閉按鈕
	rulesClose.disabled = false
	
	# 顯示規則面板（使用 Utilities 的動畫效果）
	Utilities.showPanel($RulesPanel)
	
	# 播放按鈕按下效果
	Utilities.onPressed(rules)

# ===== 設定按鈕被按下 =====
func _on_settings_pressed():
	# 停用所有主選單按鈕
	disableAll(true)
	
	# 啟用設定面板的關閉按鈕
	settingsClose.disabled = false
	
	# 顯示設定面板
	Utilities.showPanel($Settings)
	
	# 播放按鈕按下效果
	Utilities.onPressed(settings)

# ===== 停用/啟用所有主選單按鈕 =====
# 輔助函式，用於控制三個主按鈕的啟用狀態
func disableAll(disable): 
	start.disabled = disable       # 開始按鈕
	rules.disabled = disable       # 規則按鈕
	settings.disabled = disable    # 設定按鈕

# ===== 規則面板的關閉按鈕被按下 =====
func _on_close_pressed():
	# 重新啟用所有主選單按鈕
	disableAll(false)
	
	# 停用關閉按鈕本身（避免重複點擊）
	rulesClose.disabled = true
	
	# 播放按鈕按下效果
	Utilities.onPressed(rulesClose)
	
	# 隱藏規則面板（使用 Utilities 的動畫效果）
	Utilities.hidePanel($RulesPanel)

# ===== 設定面板的關閉按鈕被按下 =====
func _on_settings_close_pressed():
	# 重新啟用所有主選單按鈕
	disableAll(false)
	
	# 停用關閉按鈕本身
	settingsClose.disabled = true
	
	# 播放按鈕按下效果
	Utilities.onPressed(settingsClose)
	
	# 隱藏設定面板
	Utilities.hidePanel($Settings)
