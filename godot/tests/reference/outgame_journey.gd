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
	await _prologue()
	await _credits_and_ending()
	await _test_room()
	await _reset_progress()
	await _reset_progress_landscape()
	await _korean_scenes()
	quit(e2e.finish({"sourceSha": OS.get_environment("GITHUB_SHA")}))

func _mount(path: String, sdk: Node = null, fixtures: bool = true, profile: String = "hero", hook: Dictionary = {}) -> Control:
	var main: Control = load("res://reference/bootstrap/main.tscn").instantiate()
	main.show_studio_splash = false
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
	e2e.step("reward ceremony impact", await e2e.wait_for(func(): return main.ceremony.phase == "impact"))
	await e2e.shot("reward-impact", false)
	e2e.step("reward ceremony settle", await e2e.wait_for(func(): return main.ceremony.phase == "settle"))
	await e2e.shot("reward-settle", false)
	if main.size.x > main.size.y:
		# 가로는 연출 열이 버튼 열과 겹치지 않고 프레임 안쪽 사각형 안에 있다.
		var column: Control = main.ceremony.get_node("Stage/Column")
		var backing: Control = main.backing
		var frame: StyleBox = backing.get_theme_stylebox("panel")
		var inner: Rect2 = backing.get_global_rect().grow_individual(-frame.get_content_margin(SIDE_LEFT), -frame.get_content_margin(SIDE_TOP), -frame.get_content_margin(SIDE_RIGHT), -frame.get_content_margin(SIDE_BOTTOM))
		e2e.step("wide reward column clear of buttons", not column.get_global_rect().intersects(_button(main, "reward_continue").get_global_rect()) and inner.encloses(column.get_global_rect()))
	e2e.step("reward ceremony finished", await e2e.wait_for(func(): return main.ceremony.phase == "done"))
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
	await e2e.shot("popup-open", false)
	e2e.step("analytics defaults enabled", main.state.data.settings.analytics and main.analytics.effective)
	e2e.step("turn analytics off", await e2e.tap(_button(main, "analytics")))
	e2e.step("collection and queue off", not main.analytics.effective and main.analytics.port.queue.is_empty())
	e2e.step("support direct entry", await e2e.tap(_button(main, "support")))
	# 입력란은 스킨 테마의 read_only 판으로 그린다(고정 색 덮어쓰기 없음).
	var code: Control = main.find_child("support_code", true, false)
	e2e.step("support code uses the skin theme", code != null and code.get_theme_stylebox("read_only") is StyleBoxTexture and not code.has_theme_stylebox_override("read_only"))
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
	for product in ["skyway", "map", "windharbor"]:
		var hook: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://reference/config/" + product + ".json"))
		var main: Control = await _mount(dir + "/hook-" + product + ".json", null, true, hook.homeProfile, hook)
		e2e.step("own product title", _has_text(main, hook.title))
		e2e.step("same common version for " + product, hook.commonVersion == "1.3.0" and hook.runtime == "res://addons/seorilabs_game/flow/outgame_main.gd")
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
	sdk.messages = [{"id":"late","title":"Late message","body":"One reward","rewards":[],"readAt":0,"claimedAt":0,"expiresAt":0},
		{"id":"named","title":"Named rewards","body":"Product names","rewards":[{"entitlementId":"pearl_pack","quantity":2},{"entitlementId":"unknown_item","quantity":1}],"readAt":0,"claimedAt":0,"expiresAt":0}]
	var main: Control = await _home(dir + "/late.json", sdk)
	# 제품이 보상 이름을 주면 우편 카드에 ID 대신 그 이름을 쓰고, 빈 이름이면 "보상"으로 쓴다.
	main.mail_reward_name_provider = func(id: String) -> String: return "Pearl pack" if id == "pearl_pack" else ""
	e2e.step("inbox", await e2e.tap(_button(main, "inbox")))
	e2e.step("mail rewards use product names", _has_text(main.content, "Pearl pack ×2") and _has_text(main.content, "Reward ×1") and not _has_text(main.content, "pearl_pack"))
	sdk.hold_claim = true
	e2e.step("pending claim", await e2e.tap(_text_button(main, "Claim")))
	e2e.step("close while pending", await e2e.tap(_button(main, "close")))
	sdk.release_claim()
	await e2e.frames()
	e2e.step("late claim does not reopen inbox", main.screen == "home")
	e2e.end()
	await e2e.unmount(main)

## map 제품(프롤로그·엔딩·크레딧이 있는 레퍼런스)을 격리 저장으로 띄운다. 다른 제품과 기존 여정은 프롤로그가 없다.
func _map(path: String) -> Control:
	var main: Control = load("res://reference/bootstrap/main.tscn").instantiate()
	main.show_studio_splash = false
	main.apply_product("map")
	main.state = State.new(path)
	main.device_locale = "en-US"
	await e2e.mount(main)
	e2e.step("map ready", await e2e.wait_for(func(): return main.initialized))
	return main

## 컷신 시간은 _process에서만 흐른다. 창 포커스와 무관하게 같은 화면을 찍도록 시계를 직접 넘긴다.
func _play_for(main: Control, seconds: float) -> void:
	for i in roundi(seconds / 0.1):
		main.cutscene._process(0.1)
	await e2e.frames(2)

func _subtitle(main: Control) -> String:
	return main.cutscene.get_node("Captions/Column/Subtitle").text

func _prologue() -> void:
	e2e.begin("map-prologue-first-start-once", ["cutscene", "startup", "tutorial", "account_save"])
	for product in ["skyway", "windharbor"]:
		var hook: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://reference/config/" + product + ".json"))
		e2e.step(product + " keeps the 1.1.0 start without a prologue", not hook.has("introScript") and not hook.has("endingScript"))
	var path := dir + "/prologue.json"
	var main: Control = await _map(path)
	e2e.step("first start opens the prologue", await e2e.tap(_button(main, "start")) and main.cutscene.state() == "cut" and main.screen == "title")
	await _play_for(main, 1.0)
	e2e.expect_equal("first cut subtitle", _subtitle(main), "Long ago, the wind charts of the sky isles were scattered.")
	await e2e.shot("prologue-1")
	e2e.step("tap shows the next cut", await e2e.tap(main.cutscene) and main.cutscene.current_cut() == 1)
	await _play_for(main, 1.0)
	await e2e.shot("prologue-2")
	e2e.step("tap shows the title cut", await e2e.tap(main.cutscene) and main.cutscene.current_cut() == 2)
	await _play_for(main, 2.0)
	e2e.step("title card shows the product name", main.cutscene.get_node("Captions/Column/TitleCard").visible and main.cutscene.get_node("Captions/Column/TitleCard/Title").text == "SKY ATLAS")
	await e2e.shot("prologue-title")
	var skip: Button = main.cutscene.get_node("Skip")
	e2e.step("skip goes to play", await e2e.tap(skip) and await e2e.wait_for(func(): return main.screen == "play" and main.cutscene.state() == "idle"))
	var saved := State.new(path)
	e2e.step("seen flag saved without a new save version", saved.load_state() and saved.intro_seen() and int(saved.data.version) == State.SAVE_VERSION)
	await e2e.frames(30)
	e2e.step("play takes taps after the prologue", await e2e.tap(_text_button(main, "★")))
	await e2e.unmount(main)
	main = await _map(path)
	e2e.step("restart starts play without the prologue", await e2e.tap(_button(main, "start")) and main.screen == "play" and main.cutscene.state() == "idle")
	await e2e.unmount(main)
	# 길이 0인 컷만 있는 프롤로그도 시작 흐름이 끝나고 본 기록이 남아야 한다(재생 안에서 끝나는 신호를 놓치지 않는다).
	var flash_path := dir + "/prologue-flash.json"
	main = await _map(flash_path)
	main.intro_script = {"id": "flash", "cuts": [{"art": "", "dur": 0}]}
	e2e.step("zero-length prologue still enters the game", await e2e.tap(_button(main, "start")) and main.screen == "play" and main.cutscene.state() == "idle")
	var flash_saved := State.new(flash_path)
	e2e.step("zero-length prologue is recorded as seen", flash_saved.load_state() and flash_saved.intro_seen())
	e2e.end()
	await e2e.unmount(main)

func _credits_and_ending() -> void:
	e2e.begin("settings-credits-and-ending-replay", ["credits", "cutscene", "settings_support", "ui_navigation"])
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://addons/seorilabs_game/fonts/manifest.json"))
	var fonts: Array = []
	for entry in manifest.files:
		if str(entry.path).get_extension() == "ttf": fonts.append(RegEx.create_from_string("([a-z])([A-Z])").sub(str(entry.path).get_basename(), "$1 $2", true))
	# 제품 크레딧이 없는 제품도 글꼴 라이선스는 보인다.
	var main: Control = await _mount(dir + "/credits-skyway.json")
	await e2e.wait_for(func(): return main.initialized)
	e2e.step("skyway settings", await e2e.tap(_button(main, "settings")))
	e2e.step("credits entry is always in settings", await e2e.tap(_button(main, "credits")) and main.screen == "credits")
	e2e.step("font licenses without product credits", fonts.all(func(font): return _has_text(main.content, font)) and _has_text(main.content, "SIL Open Font License 1.1") and not _has_text(main.content, "AI-generated content"))
	await e2e.unmount(main)
	var path := dir + "/credits-map.json"
	_seed(path)
	main = await _map(path)
	e2e.step("map settings", await e2e.tap(_button(main, "settings")))
	e2e.step("no ending replay before the ending", _button(main, "replay_ending") == null)
	e2e.step("open credits", await e2e.tap(_button(main, "credits")) and main.screen == "credits")
	e2e.step("product credits and AI notice", _has_text(main.content, "Made by the Seorilabs game foundation team") and _has_text(main.content, "AI-generated content") and _has_text(main.content, "made with AI tools"))
	e2e.step("%d font licenses from the manifest" % fonts.size(), fonts.size() >= 3 and fonts.all(func(font): return _has_text(main.content, font)) and _has_text(main.content, "Copyright 2018 The Jua Project Authors"))
	await e2e.shot("credits")
	var labels: Array = main.content.find_children("*", "Label", true, false)
	e2e.step("credits scroll to the last license", await e2e.scroll_into_view(labels.back()))
	await e2e.shot("credits-end")
	e2e.step("credits back to settings", await e2e.tap(_button(main, "back")) and main.screen == "settings")
	main.set_ending_seen(true)
	await e2e.frames(2)
	var replay := _button(main, "replay_ending")
	e2e.step("ending seen adds Replay ending", replay != null and await e2e.scroll_into_view(replay))
	await e2e.shot("settings-ending")
	var before := FileAccess.get_file_as_bytes(path)
	e2e.step("replay ending", await e2e.tap(replay) and main.cutscene.state() == "cut")
	e2e.step("replay unlocks the locked first cut", main.cutscene.can_skip())
	await _play_for(main, 1.0)
	await e2e.shot("ending-1")
	e2e.step("next ending cut", await e2e.tap(main.cutscene) and main.cutscene.current_cut() == 1)
	await _play_for(main, 3.0)
	e2e.expect_equal("count-up uses the shared number format", main.cutscene.get_node("Captions/Column/Count").text, "12,800")
	await e2e.shot("ending-count")
	e2e.step("last cut rolls the credits", await e2e.tap(main.cutscene) and main.cutscene.state() == "credits")
	await _play_for(main, 5.0)
	var roll := ""
	for label in main.cutscene.get_node("Credits/Roll").find_children("*", "Label", true, false): roll += label.text + "\n"
	e2e.step("credits roll lists the product and font credits", "AI-generated content" in roll and "Jua" in roll)
	await e2e.shot("ending-credits")
	e2e.step("credits tap opens the end screen", await e2e.tap(main.cutscene) and main.cutscene.state() == "end")
	await e2e.shot("ending-end")
	e2e.step("continue returns to settings", await e2e.tap(main.cutscene.get_node("End/Continue")) and await e2e.wait_for(func(): return main.cutscene.state() == "idle") and main.screen == "settings")
	e2e.step("ending replay leaves the save bytes identical", FileAccess.get_file_as_bytes(path) == before)
	e2e.end()
	await e2e.unmount(main)

func _f9(main: Control) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_F9
	key.pressed = true
	e2e.viewport.push_input(key)
	await e2e.frames(3)

func _toasts(main: Control) -> Array:
	var texts: Array = []
	for label in main.layers.layer("Toast").find_children("*", "Label", true, false):
		if not label.is_queued_for_deletion(): texts.append(label.text)
	return texts

func _test_room() -> void:
	e2e.begin("debug-test-room", ["test_room", "cutscene", "ui_navigation"])
	var path := dir + "/test-room.json"
	_seed(path)
	var seen := State.new(path)
	seen.load_state()
	seen.mark_intro_seen()
	var main: Control = await _map(path)
	e2e.step("debug run attaches the test room", OS.is_debug_build() and main.test_room != null and not main.test_room.is_open())
	e2e.step("start home", await e2e.tap(_button(main, "start")) and main.screen == "home")
	await _f9(main)
	e2e.step("F9 opens the test room", main.test_room.is_open())
	await e2e.shot("test-room")
	var coins := int(main.state.data.coins)
	e2e.step("plain action applies", await e2e.tap(_button(main, "test_action_coins")) and int(main.state.data.coins) == coins + 100)
	var result: Label = main.test_room.get_node("Frame/Body/Result")
	var height := result.size.y
	var preset: Button = _button(main, "test_snapshot_m10")
	var before := FileAccess.get_file_as_bytes(path)
	e2e.step("first tap arms the preset", await e2e.tap(preset) and preset.text == "Tap again to apply" and FileAccess.get_file_as_bytes(path) == before)
	await e2e.shot("test-room-armed")
	e2e.step("second tap applies the preset", await e2e.tap(preset) and int(main.state.data.coins) == 120 and int(main.state.data.ui.home.level) == 3)
	e2e.step("result line keeps its height", absf(result.size.y - height) < 0.5 and "10-minute preset" in result.text)
	before = FileAccess.get_file_as_bytes(path)
	e2e.step("replay prologue closes the room", await e2e.tap(_button(main, "test_replay_prologue")) and not main.test_room.is_open() and main.cutscene.state() == "cut")
	await _f9(main)
	e2e.step("F9 is ignored while a scene plays", not main.test_room.is_open())
	e2e.step("skip the replay", await e2e.tap(main.cutscene.get_node("Skip")) and await e2e.wait_for(func(): return main.cutscene.state() == "idle"))
	e2e.step("replay leaves the save bytes identical", FileAccess.get_file_as_bytes(path) == before)
	await e2e.frames(30)
	e2e.step("settings", await e2e.tap(_button(main, "settings")))
	e2e.step("settings entry opens the test room", await e2e.tap(_button(main, "test_room")) and main.test_room.is_open())
	e2e.step("close button", await e2e.tap(_button(main, "test_room_close")) and not main.test_room.is_open() and main.screen == "settings")
	e2e.step("back home", await e2e.tap(_button(main, "close")) and main.screen == "home")
	e2e.step("enter play", await e2e.tap(_button(main, "play")) and main.screen == "play")
	await _f9(main)
	before = FileAccess.get_file_as_bytes(path)
	e2e.step("blocked action during a round", await e2e.tap(_button(main, "test_action_coins")) and _toasts(main).has("Finish the current round first"))
	e2e.step("blocked action leaves the save unchanged", FileAccess.get_file_as_bytes(path) == before)
	await e2e.shot("test-room-blocked")
	await _f9(main)
	e2e.step("F9 closes the test room", not main.test_room.is_open())
	e2e.end()
	await e2e.unmount(main)

## 진행 초기화: 두 번 눌러 확인, 취소와 거부는 저장을 바꾸지 않고, 적용하면 설정·프롤로그 본 기록·제품이 고른 값만 남는다.
func _reset_progress() -> void:
	e2e.begin("settings-reset-progress", ["progress_reset", "account_save", "settings_support", "ui_navigation"])
	var path := dir + "/reset.json"
	_seed(path)
	var seeded := State.new(path)
	seeded.load_state()
	seeded.mark_intro_seen()
	var progressed: Dictionary = seeded.data.duplicate(true)
	progressed.coins = 340
	progressed.settings.music = false
	progressed.ui.home.level = 4
	progressed.ui.commerce = {"pending": "example-receipt"}
	progressed.product_progress = {"stage": 12}
	progressed.product_seen = true
	seeded.commit(progressed)
	var main: Control = await _home(path)
	var signals := [0]
	main.progress_was_reset.connect(func() -> void: signals[0] += 1)
	e2e.step("settings", await e2e.tap(_button(main, "settings")))
	var entry := _button(main, "reset_progress")
	e2e.step("local save offers Reset progress", entry != null and await e2e.scroll_into_view(entry))
	e2e.step("open reset screen", await e2e.tap(entry) and main.screen == "reset_progress")
	e2e.step("screen says what is kept", _has_text(main.content, "cannot be undone") and _has_text(main.content, "restorable purchases stay"))
	await e2e.shot("reset-progress")
	var before := FileAccess.get_file_as_bytes(path)
	var confirm: Button = _button(main, "reset_progress_confirm")
	var unarmed_height := confirm.size.y
	e2e.step("first tap only arms", await e2e.tap(confirm) and confirm.text == "Tap again to reset" and confirm.theme_type_variation == &"PrimaryButton" and FileAccess.get_file_as_bytes(path) == before)
	# A habitual double tap must not confirm before the player can read the armed label (round 1 R1-2).
	await e2e.frames(2)
	e2e.step("arming keeps the button height", absf(confirm.size.y - unarmed_height) < 0.5)
	e2e.step("a quick second tap is ignored", await e2e.tap(confirm) and main.screen == "reset_progress" and FileAccess.get_file_as_bytes(path) == before)
	await e2e.shot("reset-progress-armed")
	e2e.step("cancel returns to settings", await e2e.tap(_button(main, "reset_progress_cancel")) and main.screen == "settings")
	e2e.step("cancel leaves the save bytes identical", FileAccess.get_file_as_bytes(path) == before)
	e2e.step("reopen", await e2e.tap(_button(main, "reset_progress")) and main.screen == "reset_progress")
	confirm = _button(main, "reset_progress_confirm")
	e2e.step("reopened screen starts disarmed", confirm.text == "Reset progress")
	var product_hook: Callable = main.progress_reset
	main.progress_reset = func(_previous: Dictionary, _next: Dictionary) -> Dictionary: return {}
	e2e.step("refused reset", await e2e.tap(confirm) and await _confirm_after_delay(main))
	e2e.step("refusal keeps the screen and explains", main.screen == "reset_progress" and _has_text(main.content, "Nothing was changed") and _toasts(main).has("Progress could not be reset. Nothing was changed."))
	var reason: Label = _button(main, "reset_progress_notice")
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(e2e.viewport.size))
	e2e.step("the reason sits above the buttons on screen", reason != null and viewport_rect.encloses(reason.get_global_rect()) and reason.get_global_rect().end.y <= _button(main, "reset_progress_confirm").get_global_rect().position.y)
	e2e.step("refusal leaves the save bytes identical", FileAccess.get_file_as_bytes(path) == before and signals[0] == 0)
	e2e.step("refusal disarms the button", _button(main, "reset_progress_confirm").text == "Reset progress")
	await e2e.shot("reset-progress-refused")
	main.progress_reset = func(previous: Dictionary, next: Dictionary) -> Dictionary:
		next.product_seen = previous.get("product_seen", false)
		return product_hook.call(previous, next)
	e2e.step("arm again", await e2e.tap(_button(main, "reset_progress_confirm")))
	e2e.step("second tap resets", await _confirm_after_delay(main) and await e2e.wait_for(func(): return main.screen == "title"))
	e2e.step("reset notifies the product once", signals[0] == 1 and _toasts(main).has("Progress reset. Start again from the title."))
	e2e.step("the earlier refusal toast is gone", not _toasts(main).has("Progress could not be reset. Nothing was changed."))
	await e2e.shot("reset-progress-done")
	var saved := State.new(path)
	e2e.step("reset save loads", saved.load_state())
	e2e.expect_equal("coins start over", int(saved.data.coins), 0)
	e2e.expect_equal("guide starts over", saved.data.tutorial.status, "active")
	e2e.expect_equal("home starts over", int(saved.data.ui.home.level), 2)
	e2e.expect_equal("settings kept", saved.data.settings.music, false)
	e2e.expect_equal("prologue seen kept", saved.intro_seen(), true)
	e2e.expect_equal("purchase records kept", saved.data.ui.commerce, {"pending": "example-receipt"})
	e2e.expect_equal("save version unchanged", int(saved.data.version), State.SAVE_VERSION)
	e2e.step("product key cleared unless the product keeps it", not saved.data.has("product_progress") and saved.data.get("product_seen", false) == true)
	e2e.step("start again opens the guide", await e2e.tap(_button(main, "start")) and main.screen == "play")
	await e2e.unmount(main)
	# 서버 계정 저장은 이 기기만 지울 수 없으므로 항목을 보여 주지 않는다.
	var sdk := SDK.FakeSDK.new()
	main = await _home(dir + "/reset-server.json", sdk)
	e2e.step("server settings", main.services.mode == "server" and await e2e.tap(_button(main, "settings")))
	e2e.step("server save has no Reset progress", _button(main, "reset_progress") == null)
	await e2e.unmount(main)
	# 제품이 정하지 않으면 항목이 없다.
	main = await _home(dir + "/reset-none.json")
	main.progress_reset = Callable()
	e2e.step("settings without a product hook", await e2e.tap(_button(main, "settings")) and _button(main, "reset_progress") == null)
	e2e.end()
	await e2e.unmount(main)

## 무장한 확인 버튼은 0.6초 뒤부터 둘째 누름을 받는다.
func _confirm_after_delay(main: Control) -> bool:
	await create_timer(0.7).timeout
	return await e2e.tap(_button(main, "reset_progress_confirm"))

## 가로 제품을 가장 낮은 568x320에서 띄운다: 확인과 취소가 한 줄이고, 지워지는 것과 남는 것, 거부 이유가 첫 화면에 보인다.
func _reset_progress_landscape() -> void:
	e2e.begin("landscape-reset-progress", ["progress_reset", "ui_landscape"])
	var path := dir + "/reset-landscape.json"
	_seed(path)
	var saved_size: Vector2i = e2e.viewport.size
	e2e.viewport.size = Vector2i(568, 320)
	var main: Control = load("res://reference/bootstrap/main.tscn").instantiate()
	main.show_studio_splash = false
	main.landscape = true
	main.state = State.new(path)
	main.device_locale = "en-US"
	await e2e.mount(main)
	e2e.step("landscape product ready", await e2e.wait_for(func(): return main.initialized))
	# A hook that returns a state failing the schema is still a refusal, not an unreadable save (round 1 R1-6).
	main.progress_reset = func(_previous: Dictionary, next: Dictionary) -> Dictionary:
		next.coins = -1
		return next
	main._open("reset_progress")
	await e2e.frames(3)
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(e2e.viewport.size))
	var visible_text := func(text: String) -> bool:
		for label in main.content.find_children("*", "Label", true, false):
			if text in label.text and viewport_rect.encloses(label.get_global_rect()): return true
		return false
	var confirm: Button = _button(main, "reset_progress_confirm")
	var cancel: Button = _button(main, "reset_progress_cancel")
	e2e.step("confirm and cancel share one row", confirm != null and cancel != null and absf(confirm.get_global_rect().position.y - cancel.get_global_rect().position.y) < 1.0)
	e2e.step("both buttons are on the first screen at 568x320", viewport_rect.encloses(confirm.get_global_rect()) and viewport_rect.encloses(cancel.get_global_rect()))
	e2e.step("what stays and what starts over are on the first screen", visible_text.call("restorable purchases stay") and visible_text.call("start over"))
	await e2e.shot("reset-progress-landscape")
	e2e.step("refuse in landscape", await e2e.tap(confirm) and await _confirm_after_delay(main))
	var reason: Label = _button(main, "reset_progress_notice")
	e2e.step("landscape reason is on screen", reason != null and viewport_rect.encloses(reason.get_global_rect()))
	e2e.step("an invalid product result reads as a refusal", reason != null and reason.text == "Progress could not be reset. Nothing was changed.")
	await e2e.shot("reset-progress-landscape-refused")
	# A failed write says the reset was not saved, not that the save is unreadable (round 2 R2-5).
	main.progress_reset = func(_previous: Dictionary, next: Dictionary) -> Dictionary: return next
	var before := FileAccess.get_file_as_bytes(path)
	main.state.path = dir + "/missing-folder/reset.json"
	e2e.step("arm with a failing disk", await e2e.tap(_button(main, "reset_progress_confirm")) and await _confirm_after_delay(main))
	reason = _button(main, "reset_progress_notice")
	e2e.step("a failed write keeps the save and explains", reason != null and reason.text == "Could not save the reset. Nothing was changed. Try again." and FileAccess.get_file_as_bytes(path) == before and main.screen == "reset_progress")
	main.state.path = path
	e2e.end()
	await e2e.unmount(main)
	e2e.viewport.size = saved_size

## 새 화면의 한국어 캡처: 프롤로그 자막, 테스트실, 크레딧(1회차 검수 F-5).
func _korean_scenes() -> void:
	e2e.begin("korean-cutscene-test-room-credits", ["cutscene", "test_room", "credits", "progress_reset"])
	# 튜토리얼을 마친 저장에서 시작해 프롤로그 뒤 홈(설정 버튼이 있는 화면)으로 간다. 프롤로그 본 기록은 비어 있다.
	_seed(dir + "/korean.json")
	var main: Control = load("res://reference/bootstrap/main.tscn").instantiate()
	main.show_studio_splash = false
	main.apply_product("map")
	main.state = State.new(dir + "/korean.json")
	main.device_locale = "ko-KR"
	await e2e.mount(main)
	e2e.step("map ready in Korean", await e2e.wait_for(func(): return main.initialized) and main.language() == "ko")
	e2e.step("first start opens the prologue", await e2e.tap(_button(main, "start")) and main.cutscene.state() == "cut")
	await _play_for(main, 1.0)
	e2e.step("Korean subtitle", _subtitle(main) != "" and _subtitle(main) != "Long ago, the wind charts of the sky isles were scattered.")
	await e2e.shot("prologue-1-ko")
	e2e.step("skip to home", await e2e.tap(main.cutscene.get_node("Skip")) and await e2e.wait_for(func(): return main.cutscene.state() == "idle" and main.screen == "home"))
	await e2e.frames(30)
	await _f9(main)
	e2e.step("F9 opens the Korean test room", main.test_room.is_open())
	await e2e.shot("test-room-ko")
	await _f9(main)
	e2e.step("settings", await e2e.tap(_button(main, "settings")))
	e2e.step("credits", await e2e.tap(_button(main, "credits")) and main.screen == "credits" and _has_text(main.content, "글꼴 라이선스"))
	await e2e.shot("credits-ko")
	e2e.step("back to settings", await e2e.tap(_button(main, "back")) and main.screen == "settings")
	var reset := _button(main, "reset_progress")
	e2e.step("Korean reset entry", reset != null and await e2e.scroll_into_view(reset) and await e2e.tap(reset) and _has_text(main.content, "되돌릴 수 없어요"))
	await e2e.shot("reset-progress-ko")
	e2e.end()
	await e2e.unmount(main)
