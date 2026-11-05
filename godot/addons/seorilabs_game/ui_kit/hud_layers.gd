extends Node
## HUD 레이어 스택. World(0) < Hud(10) < Popup(20) < Toast(30) < Ftue(40) < System(50).
const Juice = preload("res://addons/seorilabs_game/ui_kit/juice.gd")
const NAMES := ["World", "Hud", "Popup", "Toast", "Ftue", "System"]
var toasts := 0

func layer(name: String) -> Control:
	return get_node(name + "/Root")

## CanvasLayer는 Control 테마 상속을 끊으므로 각 층 루트에 같은 테마를 준다.
func apply_theme(theme: Theme) -> void:
	for name in NAMES:
		layer(name).theme = theme

## 짧은 안내를 Toast 층에 띄운다. 입력을 가로채지 않고 지정 시간 뒤 사라진다.
func toast(text: String, seconds := 2.0) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.theme_type_variation = "ChipPanel"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.theme_type_variation = "NumberLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)
	var root := layer("Toast")
	root.add_child(chip)
	chip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	chip.position = Vector2((root.size.x - chip.size.x) / 2.0, 24.0 + toasts * 48.0)
	toasts += 1
	Juice.pop_in(chip, 0.2)
	chip.create_tween().tween_interval(seconds).finished.connect(func() -> void:
		toasts = maxi(0, toasts - 1)
		Juice.pop_out(chip, 0.14).finished.connect(chip.queue_free))
	return chip
