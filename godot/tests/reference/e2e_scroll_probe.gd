extends SceneTree

const Driver = preload("res://tests/common/e2e_driver.gd")
var clicks := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var output: String = args[args.find("--out") + 1]
	var d := Driver.new(self, Vector2i(390, 844), output, args.has("--capture"))
	d.begin("fractional-scroll-boundary", ["ui_navigation"])
	var frame := Control.new()
	frame.position = Vector2(0, 368.4)
	frame.size = Vector2(390, 428)
	var scroll := ScrollContainer.new()
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	scroll.position = Vector2(14, 0)
	scroll.size = Vector2(362, 394)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := Control.new()
	body.custom_minimum_size = Vector2(354, 428)
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(body)
	var button := Button.new()
	button.text = "Cancel"
	button.position = Vector2(0, 380)
	button.size = Vector2(354, 48)
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.pressed.connect(func(): clicks += 1)
	body.add_child(button)
	frame.add_child(scroll)
	await d.mount(frame)
	d.step("fixture requires scrolling", button.get_global_rect().end.y > scroll.get_global_rect().end.y)
	d.step("tap reaches button at fractional bottom edge", await d.tap(button))
	d.expect_equal("actual button pressed once", clicks, 1)
	d.expect_equal("scroll reaches actual end", scroll.scroll_vertical, int(scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page))
	await d.shot("fractional-bottom")
	# Keep rejecting truly clipped controls, including the exclusive bottom edge
	# when the control is larger than the viewport.
	d.step("one pixel overflow still requires scrolling", d._axis_move(0, 100, 53, 48) > 0)
	d.step("one pixel above viewport still requires scrolling", d._axis_move(10, 100, 9, 48) < 0)
	d.step("oversized center at exclusive end remains hidden", d._axis_move(0, 100, 0, 200) > 0)
	d.expect_equal("oversized visible center remains usable", d._axis_move(0, 100, -25, 150), 0.0)
	d.expect_equal("sub-pixel overflow from a fractional UI scale is visible", d._axis_move(0, 100, 52.25, 48), 0.0)
	d.expect_equal("0.96px overflow (1024x600 scale) is visible", d._axis_move(0, 100, 52.96, 48), 0.0)
	# 실제 경계: 버튼(높이 48.96)이 정수 높이 내용(428)보다 0.96px 넘쳐 스크롤 끝에서도 완전히 들어오지 않는다.
	var fraction := Button.new()
	fraction.text = "Status"
	fraction.position = Vector2(0, 380)
	fraction.size = Vector2(354, 48.96)
	fraction.mouse_filter = Control.MOUSE_FILTER_PASS
	fraction.pressed.connect(func(): clicks += 1)
	button.visible = false
	body.add_child(fraction)
	scroll.scroll_vertical = 0
	await d.frames(4)
	d.step("tap reaches a button that overflows the content by under a pixel", await d.tap(fraction))
	d.expect_equal("sub-pixel button pressed once", clicks, 2)
	var view := scroll.get_global_rect()
	var rect := button.get_global_rect()
	var scalar_difference := (float(rect.position.y) + float(rect.size.y)) - (float(view.position.y) + float(view.size.y))
	print("GEOMETRY ", JSON.stringify({"viewPosition":str(view.position),"viewSize":str(view.size),"bodyPosition":str(body.get_global_position()),"bodySize":str(body.size),"buttonPosition":str(rect.position),"buttonSize":str(rect.size),"max":scroll.get_v_scroll_bar().max_value,"page":scroll.get_v_scroll_bar().page,"scroll":scroll.scroll_vertical,"value":scroll.get_v_scroll_bar().value,"scalar":scalar_difference}))
	d.end()
	var result := d.finish({"scalarBottomDifference": scalar_difference, "scroll": scroll.scroll_vertical, "clicks": clicks})
	await d.unmount(frame)
	d.viewport.queue_free()
	await process_frame
	quit(result)
