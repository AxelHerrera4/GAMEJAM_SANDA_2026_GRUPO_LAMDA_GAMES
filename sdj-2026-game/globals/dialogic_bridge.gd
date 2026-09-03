extends Node

var _is_busy: bool = false


func _ready() -> void:
	if is_instance_valid(Dialogic):
		Dialogic.signal_event.connect(_on_dialogic_signal)


func _on_dialogic_signal(argument: Variant) -> void:
	var sig_name: String = str(argument)
	if sig_name.begins_with("shatter"):
		if _is_busy:
			return
		_is_busy = true
		Dialogic.paused = true
		SignalHub.emit_on_shatter_requested(StringName(sig_name))
		await SignalHub.shatter_finished
		Dialogic.paused = false
		_is_busy = false
