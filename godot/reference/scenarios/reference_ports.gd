extends RefCounted
## 배포 제품의 서비스가 아닌, 네트워크 없는 참조 실행 전용 경계 대역.
class AnalyticsPort extends RefCounted:
 var enabled := false
 var queue: Array = []
 func set_enabled(value: bool) -> bool:
  enabled = value
  return true
 func discard_pending() -> void:
  queue.clear()

class CommercePort extends RefCounted:
 var calls := 0
 var purchase_state := "pending"
 var restore_state := "restored"
 var prices := true
 var held: Callable
 func capabilities() -> Dictionary:
  return {"purchase": true, "restore": true}
 func catalog(callback: Callable) -> void:
  callback.call({"ok": true, "products": [{"id": "scout-pack", "title": "Scout pack", "art": load("res://reference/assets/soft-adventure.png"), "localized": {"ko": {"title": "탐험가 꾸러미", "description": "영구적으로 사용할 수 있는 탐험가 의상입니다. 개발 예제용 상품입니다."}}, "description": "An explorer outfit, permanent and non-consumable. Reference item only.", "price": "US$2.99" if prices else "", "available": true}]})
 func purchase(_id: String, callback: Callable) -> void:
  calls += 1
  callback.call({"ok": true, "state": purchase_state, "transactionId": "reference-transaction", "fulfilled": purchase_state == "completed"})
 func reconcile(_id: String, callback: Callable) -> void:
  callback.call({"ok": true, "state": "completed", "transactionId": "reference-transaction", "fulfilled": true})
 func restore(callback: Callable) -> void:
  callback.call({"state": restore_state})

class RankingPort extends RefCounted:
 var outcome := "ready"
 var submit_count := 0
 var scores: Array = []
 var held: Callable
 var hold := false
 func _init() -> void:
  for i in 55:
   scores.append({"rank": i + 1, "name": ["Cloudrunner", "Juniper", "North Star", "Aster", "Pip"][i % 5] + (str(i) if i > 4 else ""), "score": 48200 - i * 130, "isSelf": false})
 func capabilities() -> Dictionary:
  return {"submit": true, "open": true, "list": true, "periods": ["alltime", "weekly"]}
 func fetch(request: Dictionary, callback: Callable) -> void:
  if hold:
   held = callback
   return
  if outcome in ["offline", "failed", "auth"]:
   callback.call({"ok": false, "offline": outcome == "offline", "authRequired": outcome == "auth"})
   return
  var mine := {} if outcome in ["unranked", "empty"] else {"rank": 128, "name": "Mira", "score": 18420, "isSelf": true}
  var around := [{"rank": 126, "name": "Aurora", "score": 18900}, {"rank": 127, "name": "Parker", "score": 18700}, mine, {"rank": 129, "name": "Sol", "score": 18200}, {"rank": 130, "name": "Wren", "score": 18100}]
  var start := int(request.get("cursor", "0"))
  var rows: Array = [] if outcome == "empty" or (request.scope == "around" and mine.is_empty()) else around if request.scope == "around" else scores.slice(start, start + 50)
  callback.call({"ok": true, "rows": rows, "self": mine, "boardEmpty": outcome == "empty", "checkedAt": 1792823400, "closed": outcome == "closed", "nextCursor": "50" if request.scope == "top" and start == 0 and outcome != "empty" else ""})
 func submit_score(_request: Dictionary, callback: Callable) -> void:
  submit_count += 1
  callback.call({"ok": outcome != "failed"})
 func open_board(callback: Callable) -> void:
  callback.call({"ok": true})
