extends SceneTree
const Driver = preload("res://tests/common/e2e_driver.gd")
const State = preload("res://addons/seorilabs_game/flow/state.gd")
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

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var dimensions := arg(args, "--size", "1280x720").split("x")
	d = Driver.new(self, Vector2i(int(dimensions[0]), int(dimensions[1])), arg(args, "--out", "user://camp-probe"), args.has("--capture"))
	var main: Control = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	main.landscape = true
	main.game_title = "Game Starter"
	main.device_locale = arg(args, "--locale", "ko-KR")
	main.accounts.port = AccountPort.new()
	var path := "user://camp-probe-%d.json" % Time.get_ticks_usec()
	main.state = State.new(path)
	d.begin("landscape-account-buttons", ["startup", "ui_landscape", "account_save", "ui_navigation"])
	await d.mount(main)
	d.step("startup", await d.wait_for(func() -> bool: return main.initialized))
	await d.shot("camp-title")
	for button in main.find_children("*", "Button", true, false):
		d.step("large target " + str(button.name), button.size.y >= 55.9)
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
	quit(d.finish({"sourceSha": OS.get_environment("GITHUB_SHA"), "scope": "development boundary substitutes only"}))
