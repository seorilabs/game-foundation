extends SceneTree
const D=preload("res://tests/common/e2e_driver.gd")
const S=preload("res://addons/seorilabs_game/flow/state.gd")
const P=preload("res://reference/scenarios/reference_ports.gd")
class HeldNative extends RefCounted:
 var held: Callable
 var opens:=0
 func capabilities()->Dictionary:return {"open":true,"submit":true,"list":false,"periods":["alltime"]}
 func open_board(callback:Callable)->void:
  opens+=1;held=callback
 func submit_score(_r:Dictionary,callback:Callable)->void:callback.call({"ok":true})
class HeldCommerce extends P.CommercePort:
 var cb:Callable
 func purchase(_id:String, callback:Callable)->void:
  calls+=1;cb=callback
var d
var out:="user://e2e/ui-navigation"
func _initialize():call_deferred("run")
func b(m:Node,name:String)->Control:return m.find_child(name,true,false) as Control
func mount_case(name:String,native:bool=false)->Control:
 var m:Control=load("res://reference/bootstrap/main.tscn").instantiate()
 var path:="user://e2e-review-1-%s-%d.json" % [name,Time.get_ticks_usec()]
 m.state=S.new(path);m.state.load_state();m.state.skip_tutorial();m.device_locale="en-US"
 m.identity_provider=func()->String:return "review:alice"
 m.support_provider=func(cb:Callable)->void:cb.call({"ok":true,"identity":"review:alice","code":"SK-7H2K9X4Q"})
 m.commerce.port=HeldCommerce.new()
 m.ranking.port=HeldNative.new() if native else P.RankingPort.new()
 m.ranking.config={"enabled":true,"appId":"review","boardId":"scores","rulesVersion":1}
 await d.mount(m)
 await d.wait_for(func():return m.initialized)
 d.step("start",await d.tap(b(m,"start")))
 return m
func run():
 var args:=OS.get_cmdline_user_args()
 if args.has("--out"): out=args[args.find("--out")+1]
 d=D.new(self,Vector2i(320,568),out,args.has("--capture"))
 d.begin("native-open-late-callback",["ui_navigation","ui_leaderboard"])
 var m:Control=await mount_case("native",true)
 d.step("request provider UI",await d.tap(b(m,"leaderboard")))
 d.step("provider request held",m.screen=="leaderboard" and m.ranking.port.opens==1)
 m.notification(Control.NOTIFICATION_WM_GO_BACK_REQUEST)
 await d.frames()
 d.step("OS back returns home",m.screen=="home")
 d.step("open settings after returning",await d.tap(b(m,"settings")))
 await d.shot("native-before-late-callback")
 m.ranking.port.held.call({"ok":true})
 await d.frames()
 d.step("late provider callback preserves new settings",m.screen=="settings", "actual screen="+m.screen)
 await d.shot("native-after-late-callback")
 m.ranking.port.held=Callable()
 await d.unmount(m)
 d.end()
 d.begin("terminal-commerce-response-order",["commerce"])
 m=await mount_case("commerce")
 d.step("shop",await d.tap(b(m,"shop")))
 d.step("offer",await d.tap(b(m,"product_scout-pack")))
 d.step("buy",await d.tap(b(m,"buy")))
 m.commerce.port.cb.call({"ok":true,"state":"completed","transactionId":"same-transaction","fulfilled":true})
 await d.frames()
 d.step("verified delivery complete",m.commerce.state=="completed")
 await d.shot("commerce-completed")
 m.commerce.port.cb.call({"ok":false,"state":"pending","transactionId":"same-transaction"})
 await d.frames()
 d.step("stale pending cannot regress completed delivery",m.commerce.state=="completed","actual state="+m.commerce.state)
 await d.shot("commerce-late-pending")
 m.commerce.port.cb=Callable()
 await d.unmount(m)
 d.end()
 d.begin("keyboard-focus-visible-in-scroll",["settings_support","ui_navigation"])
 m=await mount_case("keyboard")
 d.step("settings",await d.tap(b(m,"settings")))
 # 실제 Tab 입력으로 초점을 옮긴다. 스크롤 값이나 초점을 직접 바꾸지 않는다.
 var reached:=false
 for i in 20:
  var ev:=InputEventKey.new();ev.keycode=KEY_TAB;ev.pressed=true
  d.viewport.push_input(ev,true)
  ev=InputEventKey.new();ev.keycode=KEY_TAB;ev.pressed=false
  d.viewport.push_input(ev,true)
  await d.frames()
  var f:Control=d.viewport.gui_get_focus_owner()
  if f!=null and str(f.name)=="support":
   reached=true
   var scroll:ScrollContainer=m.content.find_children("*","ScrollContainer",true,false)[0]
   var visible:=scroll.get_global_rect().encloses(f.get_global_rect())
   d.step("tabbed support focus is visible",visible,"focus="+str(f.get_global_rect())+", scroll="+str(scroll.get_global_rect())+", offset="+str(scroll.scroll_vertical))
   await d.shot("keyboard-support-focus")
   break
 d.step("Tab reaches support entry",reached)
 await d.unmount(m)
 d.end()
 quit(d.finish())
