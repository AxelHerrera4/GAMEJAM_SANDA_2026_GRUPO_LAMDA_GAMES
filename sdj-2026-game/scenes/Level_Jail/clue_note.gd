class_name ClueNote
extends Clue


@export var speaker: String = "Eddy"
@export var lines: Array[String] = ["..."]

@export_group("Apagon")
@export var shatter_after_line: int = -1
@export var shatter_only_once: bool = true


func show_clue(first_time: bool) -> void:
	for i in lines.size():
		SignalHub.dialogue_requested.emit(speaker, lines[i])
		await SignalHub.ui_closed

		if i == shatter_after_line and (first_time or not shatter_only_once):
			SignalHub.shatter_requested.emit()
			await SignalHub.shatter_finished
