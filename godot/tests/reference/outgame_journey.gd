extends SceneTree
const Driver = preload("res://tests/common/e2e_driver.gd")
const State = preload("res://addons/seorilabs_game/flow/state.gd")
const Ports = preload("res://reference/scenarios/reference_ports.gd")
const SDK = preload("res://tests/common/fakes/platform_sdk.gd")
var e2e
var dir := ""

func _initialize() -> void:
	call_deferred("_run")

func _arg(args: PackedStringArray, key: String, fallback: String) -> String:
	return args[args.find(key) + 1] if args.has(key) else fallback

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var parts := _arg(args, "--size", "390x844").split("x")
	e2e = Driver.new(self, Vector2i(int(parts[0]), int(parts[1])), _arg(args, "--out", "user://e2e/ui-standard"), args.has("--capture"))
	dir = "user://e2e-ui-standard-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)
	print("Isolated save: ", ProjectSettings.globalize_path(dir))
	await _startup()
	await _first_play()
	await _settings_support_language()
	await _inbox()
	await _commerce()
	await _ranking()
	await _homes()
	await _save_integrity()
	await _server_inbox()
	await _late_response()
	quit(e2e.finish({"sourceSha": OS.get_environment("GITHUB_SHA")}))

func _mount(path: String, sdk: Node = null, fixtures: bool = true, profile: String = "hero", hook: Dictionary = {}) -> Control:
	var main: Control = load("res://reference/bootstrap/main.tscn").instantiate()
	main.state = State.new(path)
	main.device_locale = "en-US"
	main.home_profile = profile
	main.game_title = str(hook.get("title", "SKYWAY"))
	main.config.appId = str(hook.get("id", "example"))
	var identity: String = str(main.config.appId) + ":user"
	main.identity_provider = func() -> String: return identity
	main.support_provider = func(callback: Callable) -> void: callback.call({"ok": true, "identity": identity, "code": "SK-7H2K9X4Q"})
	main.clipboard_writer = func(value: String) -> bool: return value == "SK-7H2K9X4Q"
	if fixtures:
		main.config.analytics_policy_allowed = true
		main.analytics.port = Ports.AnalyticsPort.new()
		main.commerce.port = Ports.CommercePort.new()
		main.ranking.port = Ports.RankingPort.new()
		main.score_provider = func() -> Dictionary: return {"score": int(main.state.data.tutorial.hits) * 100, "runId": main.state.data.ui.get("runId", ""), "completed": main.state.data.tutorial.status == "complete"}
		main.ranking.config = {"enabled": true, "appId": main.config.appId, "boardId": "main", "rulesVersion": 1, "seasonId": "example-week"}
	if sdk != null:
		main.configure_platform(sdk, func() -> Dictionary: return {"kind": "fixture"}, {})
	await e2e.mount(main)
	return main

func _button(main: Node, name: String) -> Control:
	return main.find_child(name, true, false) as Control

func _text_button(main: Node, text: String) -> Button:
	for child in main.get_children():
		if child is Button and child.text == text:
			return child
		var found := _text_button(child, text)
		if found != null: return found
	return null

func _has_text(main: Node, text: String) -> bool:
	for child in main.get_children():
		if child is Label and text in child.text: return true
		if _has_text(child, text): return true
	return false

func _seed(path: String) -> void:
	var saved = State.new(path)
	saved.load_state()
	saved.skip_tutorial()

func _home(path: String, sdk: Node = null, profile: String = "hero", hook: Dictionary = {}) -> Control:
	_seed(path)
	var main: Control = await _mount(path, sdk, true, profile)
	e2e.step("ready", await e2e.wait_for(func(): return main.initialized))
	e2e.step("start", await e2e.tap(_button(main, "start")))
	return main

func _startup() -> void:
	e2e.begin("startup-gates", ["startup", "operations"])
	var sdk := SDK.FakeSDK.new()
	sdk.hold_sign_in = true
	var main: Control = await _mount(dir + "/startup.json", sdk)
	e2e.step("wait for actual initialization", not main.initialized and main.progress == 2)
	e2e.step("disabled start cannot run", not await e2e.tap(_button(main, "start")))
	await e2e.shot("title-loading")
	sdk.release_sign_in({"ok": false, "code": "auth_expired"})
	await e2e.frames()
	e2e.step("failed startup remains on title", not main.initialized and _button(main, "retry") != null)
	await e2e.shot("error")
	sdk.hold_sign_in = false
	sdk.maintenance = true
	e2e.step("retry maintenance", await e2e.tap(_button(main, "retry")))
	e2e.step("maintenance result", await e2e.wait_for(func(): return main.startup_error == "maintenance"))
	sdk.maintenance = false
	sdk.required_update = true
	e2e.step("retry required update", await e2e.tap(_button(main, "retry")))
	e2e.step("required update result", await e2e.wait_for(func(): return main.startup_error == "update_required"))
	sdk.required_update = false
	e2e.step("retry recovery", await e2e.tap(_button(main, "retry")))
	e2e.step("real tasks complete", await e2e.wait_for(func(): return main.initialized and main.progress == 3))
	await e2e.shot("title-ready")
	e2e.end()
	await e2e.unmount(main)

func _first_play() -> void:
	e2e.begin("first-play-reward-and-replay", ["startup", "tutorial", "account_save", "observability"])
	var path := dir + "/first.json"
	var main: Control = await _mount(path)
	await e2e.wait_for(func(): return main.initialized)
	e2e.step("start without analytics question", await e2e.tap(_button(main, "start")) and main.screen == "play")
	await e2e.shot("tutorial")
	for i in 3:
		e2e.step("actual target hit", await e2e.tap(_text_button(main, "★")))
	e2e.expect_equal("no premature reward", main.state.data.coins, 0)
	e2e.step("collect", await e2e.tap(_text_button(main, "Collect +10")))
	e2e.expect_equal("first reward committed", main.state.data.coins, 10)
	await e2e.shot("reward")
	e2e.expect_equal("completed run submitted once", main.ranking.port.submit_count, 1)
	e2e.step("result rank entry", await e2e.tap(_button(main, "result_leaderboard")))
	e2e.step("rank returns to result", await e2e.tap(_button(main, "back")) and main.screen == "result")
	e2e.expect_equal("return did not resubmit run", main.ranking.port.submit_count, 1)
	e2e.step("confirm reward", await e2e.tap(_button(main, "reward_continue")))
	await e2e.shot("home")
	await e2e.unmount(main)
	main = await _mount(path)
	await e2e.wait_for(func(): return main.initialized)
	e2e.step("restart starts at home", await e2e.tap(_button(main, "start")) and main.screen == "home")
	e2e.expect_equal("reward survives restart", main.state.data.coins, 10)
	e2e.step("open settings", await e2e.tap(_button(main, "settings")))
	e2e.step("replay guide", await e2e.tap(_button(main, "replay")))
	for i in 3: e2e.step("replay target", await e2e.tap(_text_button(main, "★")))
	e2e.step("collect practice", await e2e.tap(_text_button(main, "Collect · practice")))
	e2e.expect_equal("replay never grants twice", main.state.data.coins, 10)
	e2e.step("confirm practice", await e2e.tap(_button(main, "reward_continue")))
	e2e.end()
	await e2e.unmount(main)

func _settings_support_language() -> void:
	e2e.begin("settings-support-language-restart", ["settings_support", "account_save", "observability", "ui_support_entry", "ui_analytics_opt_out", "ui_locale_offline", "ui_navigation"])
	var path := dir + "/preferences.json"
	var main: Control = await _mount(path)
	await e2e.wait_for(func(): return main.initialized)
	e2e.step("title settings entry", await e2e.tap(_button(main, "settings")))
	e2e.step("analytics defaults enabled", main.state.data.settings.analytics and main.analytics.effective)
	e2e.step("turn analytics off", await e2e.tap(_button(main, "analytics")))
	e2e.step("collection and queue off", not main.analytics.effective and main.analytics.port.queue.is_empty())
	e2e.step("support direct entry", await e2e.tap(_button(main, "support")))
	e2e.step("ready support code", main.support.code == "SK-7H2K9X4Q" and not _button(main, "copy").disabled)
	await e2e.shot("support")
	e2e.step("copy with boundary result", await e2e.tap(_button(main, "copy")) and _has_text(main, "Code copied"))
	e2e.step("back to settings", await e2e.tap(_button(main, "back")) and main.screen == "settings")
	e2e.step("close restores title origin", await e2e.tap(_button(main, "close")) and main.screen == "title")
	e2e.step("focus returns to entry", _button(main, "settings").has_focus())
	e2e.step("settings again", await e2e.tap(_button(main, "settings")))
	e2e.step("account and save", await e2e.tap(_text_button(main, "Account and save")) and _has_text(main, "saved on this device"))
	e2e.step("account back", await e2e.tap(_button(main, "back")))
	e2e.step("language", await e2e.tap(_button(main, "language")))
	e2e.step("switch offline Korean", await e2e.tap(_button(main, "ko")) and main.language() == "ko")
	e2e.step("back Korean settings", await e2e.tap(_button(main, "back")))
	await e2e.shot("settings-ko")
	e2e.step("accessibility", await e2e.tap(_button(main, "accessibility")))
	e2e.step("larger text", await e2e.tap(_button(main, "large_text")))
	await e2e.shot("large-text-ko")
	await e2e.unmount(main)
	main = await _mount(path)
	await e2e.wait_for(func(): return main.initialized)
	e2e.step("opt-out applied before collection", not main.analytics.effective and not main.state.data.settings.analytics)
	e2e.step("language persisted", main.language() == "ko")
	e2e.step("offline title settings still open", await e2e.tap(_button(main, "settings")))
	e2e.end()
	await e2e.unmount(main)

func _inbox() -> void:
	e2e.begin("inbox-read-claim-scroll", ["inbox", "account_save", "observability"])
	var path := dir + "/mail.json"
	var saved = State.new(path)
	saved.load_state()
	var next: Dictionary = saved.data.duplicate(true)
	for i in 12: next.mail.append({"id": "local-%d" % i, "title": "A message %d" % i, "body": "Scroll from this card", "amount": 1, "readAt": 0, "claimedAt": 0, "expiresAt": 0})
	next.mail.append({"id": "expired", "title": "Expired reward", "body": "No longer claimable", "amount": 999, "readAt": 0, "claimedAt": 0, "expiresAt": 1})
	saved.commit(next)
	var main: Control = await _home(path)
	e2e.step("open inbox", await e2e.tap(_button(main, "inbox")))
	e2e.step("read first mail", await e2e.tap(_text_button(main, "Mark read")))
	e2e.expect_equal("read does not grant", main.state.data.coins, 0)
	e2e.step("claim first", await e2e.tap(_text_button(main, "Claim")))
	e2e.expect_equal("one grant", main.state.data.coins, 5)
	var scroll: ScrollContainer = main.content.find_children("*", "ScrollContainer", true, false)[0]
	var rect := scroll.get_global_rect()
	await e2e.drag(rect.position + rect.size * Vector2(0.5, 0.8), rect.position + rect.size * Vector2(0.5, 0.3), 10, 0.3)
	e2e.step("drag over card scrolls", scroll.scroll_vertical > 0)
	await e2e.shot("inbox-scroll")
	var expired := _text_button(main, "Expired")
	e2e.step("expired message is visible", await e2e.scroll_into_view(expired))
	e2e.step("expired reward cannot be claimed", expired.disabled and not await e2e.tap(expired))
	await e2e.shot("inbox-expired")
	e2e.step("claim remaining", await e2e.tap(_text_button(main, "Claim all available")))
	e2e.expect_equal("all exactly once", main.state.data.coins, 17)
	e2e.step("nothing left to claim", _text_button(main, "Claim all available").disabled)
	e2e.end()
	await e2e.unmount(main)

func _commerce() -> void:
	e2e.begin("commerce-pending-reconcile-restore", ["commerce", "ui_navigation"])
	var main: Control = await _home(dir + "/commerce.json")
	e2e.step("shop", await e2e.tap(_button(main, "shop")))
	e2e.step("offer", await e2e.tap(_button(main, "product_scout-pack")))
	await e2e.shot("offer")
	e2e.step("buy enters pending", await e2e.tap(_button(main, "buy")) and main.commerce.state == "pending")
	e2e.expect_equal("one purchase request", main.commerce.port.calls, 1)
	await e2e.shot("purchase-pending")
	e2e.step("support during pending", await e2e.tap(_button(main, "support")))
	e2e.step("return to existing purchase", await e2e.tap(_button(main, "back")) and main.screen == "purchase")
	e2e.step("reconcile existing transaction", await e2e.tap(_button(main, "reconcile")) and main.commerce.state == "completed")
	e2e.expect_equal("reconcile did not repurchase", main.commerce.port.calls, 1)
	e2e.step("close to home", await e2e.tap(_button(main, "close")))
	e2e.step("settings", await e2e.tap(_button(main, "settings")))
	e2e.step("restore", await e2e.tap(_button(main, "restore")) and main.commerce.state == "restored")
	await e2e.shot("restore")
	e2e.end()
	await e2e.unmount(main)

func _ranking() -> void:
	e2e.begin("leaderboard-states-and-pagination", ["ui_leaderboard"])
	var main: Control = await _home(dir + "/ranking.json")
	e2e.step("open ranking", await e2e.tap(_button(main, "leaderboard")))
	e2e.expect_equal("first bounded page", main.ranking.rows.size(), 50)
	e2e.step("next page", await e2e.tap(_button(main, "rank_more")))
	e2e.expect_equal("append page", main.ranking.rows.size(), 55)
	e2e.step("around me", await e2e.tap(_button(main, "around")))
	e2e.expect_equal("two neighbors each side", main.ranking.rows.size(), 5)
	await e2e.shot("leaderboard-around")
	for outcome in ["offline", "failed", "empty", "unranked", "closed"]:
		main.ranking.port.outcome = outcome
		e2e.step("refresh " + outcome, await e2e.tap(_button(main, "rank_refresh")))
		e2e.step("state " + outcome, main.ranking.status == {"offline":"offline_cached", "failed":"failed", "empty":"empty", "unranked":"self_unranked", "closed":"season_closed"}[outcome])
		if outcome == "unranked": e2e.step("personal record message", _has_text(main, "No personal score yet"))
		await e2e.shot("ranking-" + outcome)
	e2e.step("ranking close", await e2e.tap(_button(main, "close")) and main.screen == "home")
	e2e.end()
	await e2e.unmount(main)

func _homes() -> void:
	e2e.begin("shared-version-product-hooks", ["startup", "ui_navigation"])
	for profile in ["hero", "map", "world"]:
		var main: Control = await _home(dir + "/" + profile + ".json", null, profile)
		await e2e.shot("home-" + profile)
		if profile == "world":
			e2e.step("collect changes world state", await e2e.tap(_button(main, "world_collect")))
			e2e.expect_equal("collection saved", main.state.data.coins, 20)
			e2e.step("already collected disabled", _button(main, "world_collect").disabled)
			e2e.step("building context", await e2e.tap(_button(main, "world_building")))
			e2e.step("upgrade target", await e2e.tap(_button(main, "upgrade")))
			e2e.expect_equal("upgrade level committed", main.state.data.ui.home.level, 3)
			e2e.expect_equal("upgrade cost committed", main.state.data.coins, 0)
			e2e.step("back preserves world", await e2e.tap(_button(main, "back")) and main.screen == "home")
		if profile == "map":
			if _button(main, "locked_stage") != null:
				e2e.step("locked stage cannot activate", not await e2e.tap(_button(main, "locked_stage")))
			e2e.step("map target opens play", await e2e.tap(_button(main, "map_stage")) and main.screen == "play")
		await e2e.unmount(main)
	for product in ["skyway", "windharbor"]:
		var hook: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://reference/config/" + product + ".json"))
		var main: Control = await _mount(dir + "/hook-" + product + ".json", null, true, hook.homeProfile, hook)
		e2e.step("own product title", _has_text(main, hook.title))
		e2e.step("same common version for " + product, hook.commonVersion == "1.0.0" and hook.runtime == "res://addons/seorilabs_game/flow/outgame_main.gd")
		await e2e.wait_for(func(): return main.initialized)
		e2e.step("product title settings", await e2e.tap(_button(main, "settings")))
		e2e.step("product support", await e2e.tap(_button(main, "support")) and main.support.status == "ready")
		e2e.step("product returns to own title", await e2e.tap(_button(main, "close")) and main.game_title == hook.title)
		await e2e.unmount(main)
	e2e.end()

func _save_integrity() -> void:
	e2e.begin("save-corruption-and-guide-recovery", ["account_save", "tutorial"])
	var path := dir + "/corrupt.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken"); file.close()
	var main: Control = await _mount(path)
	e2e.step("corruption blocks start", main.startup_error == "save_corrupt" and not main.initialized)
	e2e.expect_equal("corrupt bytes preserved", FileAccess.get_file_as_string(path), "{broken")
	await e2e.unmount(main)
	path = dir + "/interrupted.json"
	main = await _mount(path)
	await e2e.wait_for(func(): return main.initialized)
	e2e.step("start interrupted guide", await e2e.tap(_button(main, "start")))
	e2e.step("one action", await e2e.tap(_text_button(main, "★")))
	await e2e.unmount(main)
	main = await _mount(path)
	await e2e.wait_for(func(): return main.initialized)
	e2e.step("resume guide", await e2e.tap(_button(main, "start")))
	e2e.expect_equal("guide hits restored", main.state.data.tutorial.hits, 1)
	e2e.end()
	await e2e.unmount(main)

func _server_inbox() -> void:
	e2e.begin("server-claim-batches-and-failure", ["inbox", "operations", "observability"])
	var sdk := SDK.FakeSDK.new()
	for i in 101: sdk.messages.append({"id":"remote-%d" % i,"title":"Message %d" % i,"body":"Server reward","rewards":[],"readAt":0,"claimedAt":0,"expiresAt":0})
	var main: Control = await _home(dir + "/server.json", sdk)
	e2e.step("server inbox", await e2e.tap(_button(main, "inbox")))
	sdk.claim_code = "network_error"
	e2e.step("failed batch", await e2e.tap(_text_button(main, "Claim all available")))
	e2e.step("failed items remain claimable", not _text_button(main, "Claim all available").disabled)
	sdk.claim_code = ""
	sdk.failed_mail_ids = ["remote-1"]
	sdk.batch_sizes.clear()
	e2e.step("mixed item response", await e2e.tap(_text_button(main, "Claim all available")))
	e2e.expect_equal("API batch cap respected", sdk.batch_sizes, [50,50,1])
	e2e.step("only failed item remains", main._unclaimed() == 1 and _has_text(main, "Some rewards remain"))
	sdk.failed_mail_ids.clear()
	sdk.batch_sizes.clear()
	e2e.step("retry only failed item", await e2e.tap(_text_button(main, "Claim all available")))
	e2e.expect_equal("only one item retried", sdk.batch_sizes, [1])
	e2e.step("all server items claimed", _text_button(main, "Claim all available").disabled)
	e2e.expect_equal("server never grants local currency", main.state.data.coins, 0)
	e2e.end()
	await e2e.unmount(main)

func _late_response() -> void:
	e2e.begin("late-server-response-preserves-navigation", ["inbox", "ui_navigation"])
	var sdk := SDK.FakeSDK.new()
	sdk.messages = [{"id":"late","title":"Late message","body":"One reward","rewards":[],"readAt":0,"claimedAt":0,"expiresAt":0}]
	var main: Control = await _home(dir + "/late.json", sdk)
	e2e.step("inbox", await e2e.tap(_button(main, "inbox")))
	sdk.hold_claim = true
	e2e.step("pending claim", await e2e.tap(_text_button(main, "Claim")))
	e2e.step("close while pending", await e2e.tap(_button(main, "close")))
	sdk.release_claim()
	await e2e.frames()
	e2e.step("late claim does not reopen inbox", main.screen == "home")
	e2e.end()
	await e2e.unmount(main)
