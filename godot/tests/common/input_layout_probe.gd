extends SceneTree
## 입력 도우미의 배치 변경 판정만 검사하는 component fixture.
const Driver = preload("res://tests/common/e2e_driver.gd")

class LayoutDriver extends Driver:
	var resize_during_drag := false
	var scroll: ScrollContainer
	func drag(_from: Vector2, _to: Vector2, _steps := 10, _hold := 0.0) -> void:
		if resize_during_drag: scroll.size.y = 400
		await frames(3)

class MovingScroll extends ScrollContainer:
	var layout_steps := 0
	func _process(_delta: float) -> void:
		if layout_steps > 0:
			size.y += 1
			layout_steps -= 1

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[args.find("--out") + 1] if args.has("--out") else "user://input-layout-probe"
	var d := LayoutDriver.new(self, Vector2i(390, 844), out, false)
	var frame := Control.new()
	var scroll := MovingScroll.new()
	scroll.size = Vector2(300, 100)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := Control.new()
	body.custom_minimum_size = Vector2(280, 300)
	var button := Button.new()
	button.position = Vector2(0, 240)
	button.size = Vector2(280, 48)
	body.add_child(button); scroll.add_child(body); frame.add_child(scroll)
	d.scroll = scroll
	d.begin("input-layout-components", ["ui_navigation"])
	await d.mount(frame)
	d.step("fixture is clipped", button.get_global_rect().end.y > scroll.get_global_rect().end.y)
	d.resize_during_drag = true
	d.step("layout revealing target without scroll is accepted", await d.scroll_into_view(button))
	d.expect_equal("layout fixture did not move scroll position", scroll.scroll_vertical, 0)
	scroll.size.y = 100
	d.resize_during_drag = false
	await d.frames(3)
	d.step("unchanged clipped target still fails", not await d.scroll_into_view(button))
	scroll.layout_steps = 12
	await d._settle(scroll)
	d.step("settle waits for changing viewport geometry", scroll.layout_steps == 0)
	d.end()
	var result := d.finish({"role": "component; drag is controlled, not a production UI journey"})
	d.scroll = null
	await d.unmount(frame)
	d.viewport.queue_free()
	await process_frame
	quit(result)
