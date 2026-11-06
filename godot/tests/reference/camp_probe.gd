extends SceneTree
const Driver = preload("res://tests/common/e2e_driver.gd")
const State = preload("res://addons/seorilabs_game/flow/state.gd")
const Ports = preload("res://reference/scenarios/reference_ports.gd")
var d

class AccountPort extends RefCounted:
	var current: Dictionary = {}
	func capabilities() -> Dictionary:
		return {"create": true, "recover": true, "link": true, "logout": true, "delete": true, "providers": ["google", "apple"]}
	func snapshot() -> Dictionary: return current.duplicate(true)
	func execute(action: String, _payload: Dictionary, callback: Callable) -> void:
		if action in ["logout", "delete"]: current = {}
		else: current = {"uid": "isolated-test-uid", "platformUserId": "isolated-test-puid", "supportCode": "SK-TESTONLY"}
		callback.call({"ok": true, "account": current})

func _initialize() -> void: call_deferred("run")

func arg(args: PackedStringArray, key: String, fallback: String) -> String:
	return args[args.find(key) + 1] if args.has(key) else fallback

func node(main: Node, id: String) -> Control: return main.find_child(id, true, false) as Control

## 상점이 열린 캠프에서 긴 재화 문자열과 두 줄 헤드라인이 함께 와도 칩이 헤드라인과 겹치지 않고 (+)가 터치 기준을 지킨다.
func _chip_with_shop(dimensions: PackedStringArray) -> void:
	var main: Control = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	main.landscape = true
	main.game_title = "Game Starter"
	main.device_locale = "en-US"
	main.accounts.port = AccountPort.new()
	main.commerce.port = Ports.CommercePort.new()
	main.resource_provider = func() -> String: return "★ 1,234,567    🎟 99,999"
	var path := "user://camp-chip-%d.json" % Time.get_ticks_usec()
	main.state = State.new(path)
	d.begin("landscape-currency-chip-with-shop", ["ui_landscape", "commerce"])
	await d.mount(main)
	d.step("startup", await d.wait_for(func() -> bool: return main.initialized))
	main.transient_notice = "We could not reach the server. Check your connection and try again."
	main._title()
	await d.frames(6)
	await d.shot("camp-chip-shop")
	var chip := node(main, "coins")
	var add: Control = chip.get_node("Row/Add")
	var value: Label = chip.get_node("Row/Value")
	var headline: Label = null
	for label in main.find_children("*", "Label", true, false):
		if (label as Label).text == main.transient_notice: headline = label
	d.step("shop add button is shown", add.visible)
	d.step("add button keeps the camp touch target (%dx%d)" % [int(add.get_global_rect().size.x), int(add.get_global_rect().size.y)], add.get_global_rect().size.y >= 55.9 and add.get_global_rect().size.x >= 43.9)
	d.step("chip value stays at 12px or larger", value.get_theme_font_size("font_size") >= 12)
	d.step("chip does not overlap the headline", headline != null and not chip.get_global_rect().intersects(headline.get_global_rect()))
	await d.unmount(main)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
	d.end()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var dimensions := arg(args, "--size", "1280x720").split("x")
	d = Driver.new(self, Vector2i(int(dimensions[0]), int(dimensions[1])), arg(args, "--out", "user://camp-probe"), args.has("--capture"))
	var main: Control = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	main.landscape = true
	main.game_title = "Game Starter"
	main.device_locale = arg(args, "--locale", "ko-KR")
	main.accounts.port = AccountPort.new()
	# 플랫폼 게임처럼 긴 재화 문자열을 주는 제품도 칩이 자리 폭을 넘지 않는다.
	main.resource_provider = func() -> String: return "★ 10    🎟 2"
	var path := "user://camp-probe-%d.json" % Time.get_ticks_usec()
	main.state = State.new(path)
	d.begin("landscape-account-buttons", ["startup", "ui_landscape", "account_save", "ui_navigation"])
	await d.mount(main)
	d.step("startup", await d.wait_for(func() -> bool: return main.initialized))
	await d.shot("camp-title")
	for button in main.find_children("*", "Button", true, false):
		d.step("large target " + str(button.name), button.size.y >= 55.9)
	var chip := node(main, "coins")
	d.step("currency chip replaces the plain label", chip != null and chip.get_node_or_null("Row/Value") != null and chip.get_node_or_null("Row/Icon") != null)
	await d.frames(3)
	var slot: float = 420.0 * minf(main.size.x / 1280.0, main.size.y / 720.0)
	d.step("currency chip fits its slot (%d <= %d)" % [int(chip.get_global_rect().size.x), int(slot)], chip.get_global_rect().size.x <= slot + 1.0)
	d.step("settings menu", await d.tap(node(main, "settings")) and main.screen == "settings")
	# 프레임 pop_in(0.22초)이 끝난 뒤 잰다. 모션 중에는 backing이 0.94배라 안쪽 사각형이 작다.
	await d.frames(40)
	var backing: Control = main.backing
	var content: Control = main.content
	var frame: StyleBox = backing.get_theme_stylebox("panel")
	var inner: Rect2 = backing.get_global_rect().grow_individual(-frame.get_content_margin(SIDE_LEFT), -frame.get_content_margin(SIDE_TOP), -frame.get_content_margin(SIDE_RIGHT), -frame.get_content_margin(SIDE_BOTTOM))
	d.step("modal content stays inside the frame art", inner.encloses(content.get_global_rect()))
	await d.shot("camp-settings")
	d.step("settings close", await d.tap(node(main, "close")) and main.screen in ["home", "title"])
	d.step("account menu", await d.tap(node(main, "account")) and main.screen == "account")
	await d.shot("account-signed-out")
	d.step("button creates account", await d.tap(node(main, "account_create")) and main.accounts.connected())
	await d.shot("account-connected")
	d.step("manage", await d.tap(node(main, "account_manage")))
	d.step("logout requires confirmation", await d.tap(node(main, "account_logout")) and main.accounts.connected())
	d.step("cancel preserves account", await d.tap(node(main, "account_cancel")) and main.accounts.connected())
	d.step("logout request again", await d.tap(node(main, "account_logout")))
	d.step("logout confirmed", await d.tap(node(main, "account_confirm")) and not main.accounts.connected())
	await d.unmount(main)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
	d.end()
	await _chip_with_shop(dimensions)
	quit(d.finish({"sourceSha": OS.get_environment("GITHUB_SHA"), "scope": "development boundary substitutes only"}))
