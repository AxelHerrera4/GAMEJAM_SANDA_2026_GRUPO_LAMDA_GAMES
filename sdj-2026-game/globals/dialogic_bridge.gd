extends Node

var _shattered: bool = false


func _ready() -> void:
	if is_instance_valid(Dialogic):
		Dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogic_signal(argument: Variant) -> void:
	var sig_name: String = str(argument)
	match sig_name:
		"shatter":
			if _shattered:
				return
			_shattered = true
			Dialogic.paused = true
			SignalHub.emit_on_shatter_requested()
			await SignalHub.shatter_finished

			Dialogic.paused = false
		_:
			pass
