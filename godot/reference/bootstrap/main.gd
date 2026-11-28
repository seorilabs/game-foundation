extends "res://addons/seorilabs_game/flow/outgame_main.gd"
const Sample = preload("res://reference/features/sample_round/sample_round.tscn")
const Stage = preload("res://reference/features/home/home_stage.gd")
var sample: Node


func _init() -> void:
 lobby_art = load("res://reference/assets/soft-adventure.png")
 home_text = {"hero": ["Mira", "미라"], "destination": ["WINDWARD ISLES, STAGE 12", "바람의 군도, 스테이지 12"], "action": ["Set out", "원정 출발"], "account": ["Crew", "원정대"]}
 stage_factory = _create_stage
 home_actions = _home_actions
 feature_routes.building = _building
 launch_game = _launch_round
 test_room_setup = _setup_test_room
 # 이 예제의 진행은 모두 공용 저장에 있어 공용 초기화 결과를 그대로 쓴다. 엔딩 본 기록은 메모리에만 있어 함께 지운다.
 progress_reset = func(_previous: Dictionary, next: Dictionary) -> Dictionary: return next
 progress_reset_notes = [["Coins, the guide and the lighthouse level start over.", "코인, 안내, 등대 레벨이 처음으로 돌아가요."]]
 progress_was_reset.connect(func() -> void: set_ending_seen(false))
 var runtime: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/runtime.json"))
 var product := str(runtime.get("product", "skyway"))
 var args := OS.get_cmdline_user_args()
 if args.has("--product"):
  var index := args.find("--product") + 1
  if index < args.size() and args[index] in ["skyway", "map", "windharbor"]:
   product = args[index]
  else:
   push_warning("Use --product skyway, map or windharbor; using skyway")
   product = "skyway"
 if product not in ["skyway", "map", "windharbor"]: product = "skyway"
 apply_product(product)
 studio_name = "SEORILABS REFERENCE"
 if not OS.get_cmdline_user_args().has("--scenarios"):
  return
 var Ports = load("res://reference/scenarios/reference_ports.gd")
 config.analytics_policy_allowed = true
 analytics.port = Ports.AnalyticsPort.new()
 commerce.port = Ports.CommercePort.new()
 ranking.port = Ports.RankingPort.new()
 ranking.config = {"enabled": true, "appId": config.appId, "boardId": "reference", "rulesVersion": 1, "seasonId": "example-week"}
 identity_provider = func() -> String: return str(config.appId) + ":example-user"
 support_provider = func(callback: Callable) -> void: callback.call({"ok": true, "identity": current_identity(), "code": "SK-7H2K9X4Q"})

 score_provider = func() -> Dictionary: return {"score": int(state.data.tutorial.hits) * 100, "runId": state.data.ui.get("runId", ""), "completed": state.data.tutorial.status == "complete"}

## 제품 설정(reference/config/<product>.json)의 이름, 홈 모양, 컷신, 크레딧을 적용한다. 프롤로그와 엔딩은 map에만 있다.
func apply_product(product: String) -> void:
 var file := FileAccess.open("res://reference/config/" + product + ".json", FileAccess.READ)
 if file != null:
  var hook: Dictionary = JSON.parse_string(file.get_as_text())
  game_title = hook.title
  home_profile = hook.homeProfile
  config.appId = hook.id
  intro_script = hook.get("introScript", {})
  credits = hook.get("credits", {})
  ending_script = hook.get("endingScript", {})
  # 엔딩 크레딧은 설정 크레딧과 같은 목록(제품 크레딧 + 글꼴 라이선스)을 쓴다.
  if ending_script.get("credits") is Dictionary and not ending_script.credits.has("sections"):
   ending_script.credits.sections = credit_sections()
 state = State.new("user://reference-" + product + ".json")

## 테스트실 예제: 재화 행동, 진행 덮어쓰기(두 번 눌러 적용), 플레이 시점 프리셋, 연출 다시 보기, 봐줄 점.
func _setup_test_room(room: Control) -> void:
 room.register_action("coins", ["Add 100 coins", "코인 100 추가"], _test_add_coins, {"group": ["Economy", "재화"]})
 room.register_action("guide", ["Finish the guide", "안내 끝내기"], _test_finish_guide, {"confirm": "double_tap", "group": ["Progress", "진행"]})
 if not ending_script.is_empty():
  room.register_action("ending", ["Reach the ending", "엔딩 도달"], _test_reach_ending, {"confirm": "double_tap", "group": ["Progress", "진행"]})
 room.register_snapshots([{"id": "start", "label_pair": ["Fresh start", "처음 시작"], "minutes": 0}, {"id": "m10", "label_pair": ["10 min", "10분"], "minutes": 10}, {"id": "m30", "label_pair": ["30 min", "30분"], "minutes": 30}], _test_snapshot)
 if not intro_script.is_empty():
  room.register_replay("prologue", ["Replay prologue", "프롤로그 다시 보기"], intro_script)
 if not ending_script.is_empty():
  room.register_replay("ending", ["Replay ending", "엔딩 다시 보기"], ending_script)
 room.set_notes([["Presets overwrite progress, so tap twice to apply.", "시점 프리셋은 진행을 덮어써요. 두 번 눌러 적용해요."],
  ["Settings, Credits lists the team, the AI notice and font licenses.", "설정의 크레딧에 제작진, AI 고지, 글꼴 라이선스가 있어요."]])

func _test_blocked() -> Dictionary:
 return {"ok": false, "blocked_reason_pair": ["Finish the current round first", "진행 중인 판을 먼저 끝내 주세요"]}

func _test_commit(next: Dictionary, message: Array) -> Dictionary:
 if not state.commit(next):
  return {"ok": false, "blocked_reason_pair": [_error_text(state.error), _error_text(state.error)]}
 if screen == "home": _home()
 return {"ok": true, "message_pair": message}

func _test_add_coins() -> Dictionary:
 if screen == "play": return _test_blocked()
 var next: Dictionary = state.data.duplicate(true)
 next.coins += 100
 return _test_commit(next, ["Coins %d → %d" % [state.data.coins, next.coins], "코인 %d → %d" % [state.data.coins, next.coins]])

func _test_finish_guide() -> Dictionary:
 if screen == "play": return _test_blocked()
 var next: Dictionary = state.data.duplicate(true)
 next.tutorial.status = "complete"
 next.tutorial.step = 2
 return _test_commit(next, ["Guide marked complete. Start now opens home.", "안내를 끝냈어요. 이제 시작하면 홈으로 가요."])

## 제품이 최종 목표를 처음 이뤘을 때처럼 엔딩을 띄우고 본 기록을 알린다(이 예제는 기록을 저장하지 않는다).
func _test_reach_ending() -> Dictionary:
 var result := play_cutscene(ending_script)
 if result.get("ok", false):
  set_ending_seen(true)
  return {"ok": true, "message_pair": ["Ending shown. Settings now offers Replay ending.", "엔딩을 보여 줬어요. 설정에 엔딩 다시 보기가 생겨요."]}
 return result

func _test_snapshot(snapshot: Dictionary) -> Dictionary:
 if screen == "play": return _test_blocked()
 var minutes := int(snapshot.get("minutes", 0))
 var preset: Array = {0: [0, 2], 10: [120, 3], 30: [480, 5]}.get(minutes, [0, 2])
 var next: Dictionary = state.data.duplicate(true)
 next.coins = preset[0]
 next.ui.home.level = preset[1]
 next.ui.home.collected = false
 next.tutorial = {"version": State.TUTORIAL_VERSION, "step": 0 if minutes == 0 else 2, "status": "active" if minutes == 0 else "complete", "hits": 0, "replay": false}
 # 처음 시작 시점은 프롤로그를 다시 보게 본 기록을 지운다.
 if minutes == 0: next.erase("intro_seen")
 else: next.intro_seen = true
 return _test_commit(next, ["%d-minute preset: %d coins, lighthouse Lv.%d" % [minutes, preset[0], preset[1]], "%d분 시점: 코인 %d, 등대 Lv.%d" % [minutes, preset[0], preset[1]]])

func _launch_round(owner: Control) -> void:
 if state.data.tutorial.status != "active" and not state.replay_tutorial():
  _show_error(state.error)
  return
 if sample == null:
  sample = Sample.instantiate()
  add_child(sample)
 sample.begin(owner)

func _create_stage(profile: String) -> Control:
 var stage := Stage.new()
 stage.profile = profile
 stage.level = int(state.data.ui.home.level)
 if size.y >= 500:
  if profile == "map":
   var next := _button(tr_text("12  Lost lighthouse", "12  잃어버린 등대"), func() -> void: _open("play"), stage, true)
   next.position = Vector2(60, 75)
   next.name = "map_stage"
   next.custom_minimum_size.x = 180
   var locked := _button(tr_text("13 Locked", "13 잠김"), func() -> void: pass, stage)
   locked.position = Vector2(130, 10)
   locked.name = "locked_stage"
   locked.disabled = true
   var completed := _label("11 ✓", 18)
   completed.custom_minimum_size = Vector2(80, 28)
   completed.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
   completed.offset_left = 24
   completed.offset_top = -32
   stage.add_child(completed)
  else:
   var build := _button(tr_text("Lighthouse Lv.%d", "등대 Lv.%d") % stage.level, func() -> void: _open("building"), stage)
   build.name = "world_building"
   build.position = Vector2(80, 80)
   build.custom_minimum_size.x = 170
   var collect := _button(tr_text("Collect 20", "20 수집"), _collect_world, stage)
   collect.position = Vector2(70, 170)
   collect.name = "world_collect"
   collect.custom_minimum_size.x = 150
   collect.disabled = bool(state.data.ui.home.collected)
 return stage

func _home_actions(actions: Node) -> void:
 if home_profile == "map": _button(tr_text("Stage 12", "스테이지 12"), func() -> void: _open("play"), actions).name = "map_stage"
 if home_profile == "world":
  _button(tr_text("Lighthouse", "등대"), func() -> void: _open("building"), actions).name = "world_building"
  var collect := _button(tr_text("Collect 20", "20 수집"), _collect_world, actions)
  collect.name = "world_collect"
  collect.disabled = state.data.ui.home.collected

func _collect_world() -> void:
 if state.data.ui.home.collected:
  return
 var next: Dictionary = state.data.duplicate(true)
 next.coins += 20
 next.ui.home.collected = true
 if state.commit(next): _home()
 else: _show_error(state.error)

func _building() -> void:
 _clear(tr_text("Lighthouse", "등대"))
 content.add_child(_label(tr_text("Level %d → %d", "레벨 %d → %d") % [state.data.ui.home.level, int(state.data.ui.home.level) + 1], 24))
 content.add_child(_label(tr_text("A taller lighthouse guides the next expedition.", "높아진 등대가 다음 원정을 안내합니다.")))
 var upgrade := _button(tr_text("Upgrade, 20 coins", "강화, 코인 20"), func() -> void:
  if state.data.coins < 20: return
  var next: Dictionary = state.data.duplicate(true)
  next.coins -= 20
  next.ui.home.level += 1
  if state.commit(next): _building()
  else: _show_error(state.error)
 , null, true)
 upgrade.name = "upgrade"
 upgrade.disabled = state.data.coins < 20


func _ready() -> void:
 var runtime: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/runtime.json"))
 if runtime.get("mode") != "local" or runtime.get("networkRequired", true):
  push_error("Reference runtime requires offline local mode")
  get_tree().quit(1)
  return
 super._ready()
