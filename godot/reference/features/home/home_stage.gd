extends Control
## 지도와 공간 구성의 원본 도형. 제품은 이 장면만 자신의 콘텐츠로 교체한다.
var profile := "map"
var level := 2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func _draw() -> void:
	var s := size / Vector2(390, 450)
	draw_set_transform(Vector2.ZERO, 0, s)
	draw_rect(Rect2(0, 0, 390, 450), Color("b4d9df"))
	for cloud in [Vector2(70, 60), Vector2(310, 95), Vector2(35, 240)]:
		draw_circle(cloud, 36, Color("ebf4df"))
		draw_circle(cloud + Vector2(32, 4), 26, Color("ebf4df"))
	if profile == "map":
		var path := PackedVector2Array([Vector2(110, 370), Vector2(230, 285), Vector2(145, 190), Vector2(265, 95)])
		draw_polyline(path, Color("729e8f"), 38, true)
		draw_polyline(path, Color("f1ddaa"), 18, true)
		for point in path:
			draw_circle(point + Vector2(0, 10), 45, Color("58776b"))
			draw_circle(point, 45, Color("9bbb78"))
	else:
		draw_circle(Vector2(195, 275), 160, Color("637c66"))
		draw_circle(Vector2(195, 250), 160, Color("9cba7a"))
		for item in [[Vector2(65, 175), 68], [Vector2(235, 140), 50 + level * 12], [Vector2(145, 305), 45]]:
			var pos: Vector2 = item[0]
			var height: float = item[1]
			draw_style_box(_box(Color("66816c")), Rect2(pos + Vector2(5, 12), Vector2(88, height)))
			draw_style_box(_box(Color("ead4a5")), Rect2(pos, Vector2(88, height)))
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-9, 0), pos + Vector2(44, -38), pos + Vector2(97, 0)]), Color("41737b"))
			draw_rect(Rect2(pos + Vector2(33, height - 30), Vector2(24, 30)), Color("3f6667"))

func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(12)
	return box
