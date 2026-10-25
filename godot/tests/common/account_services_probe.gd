extends SceneTree
const Services = preload("res://addons/seorilabs_game/services/services.gd")

class Client extends Node:
	var sign_in_calls := 0
	func sign_in(_credential: Dictionary, callback: Callable) -> void:
		sign_in_calls += 1
		callback.call({"ok": false, "code": "credential_invalid"})

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var client := Client.new()
	root.add_child(client)
	var services := Services.new()
	root.add_child(services)
	services.configure(client, func() -> Dictionary: return {})
	var responses: Array[Dictionary] = []
	services.initialize(func(response: Dictionary) -> void: responses.append(response))
	if client.sign_in_calls != 0 or responses.size() != 1 or responses[0].get("status") != "account_required":
		push_error("Signed-out startup must wait for the create-account button without sending an empty credential")
		quit(1)
		return
	services.queue_free()
	client.queue_free()
	print("Account-required startup passed")
	quit(0)
