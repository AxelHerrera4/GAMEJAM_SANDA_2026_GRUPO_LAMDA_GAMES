class_name FragmentCutscene
extends CanvasLayer

signal finished

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var break_sfx: AudioStreamPlayer = $BreakSFX


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func play_cutscene(anim_name: StringName = &"shatter") -> void:
	show()
	var target_anim: StringName = anim_name
	if animation_player.has_animation(target_anim):
		animation_player.play(target_anim)

	await animation_player.animation_finished
	hide()
	finished.emit()
