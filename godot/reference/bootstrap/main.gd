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
 var file := FileAccess.open("res://reference/config/" + product + ".json", FileAccess.READ)
 if file != null:
  var hook: Dictionary = JSON.parse_string(file.get_as_text())
  game_title = hook.title
  home_profile = hook.homeProfile
  config.appId = hook.id
 state = State.new("user://reference-" + product + ".json")
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
