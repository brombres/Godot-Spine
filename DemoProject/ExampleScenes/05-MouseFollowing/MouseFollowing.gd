@tool
extends Node2D

@onready var spineboy:SpineSprite = $Spineboy
#@onready var crosshair_bone:SpineBone = $Spineboy/CrosshairBone

func _ready():
	spineboy.set_animation( "walk", true, 0 )
	spineboy.set_animation( "aim", true, 1 )

func _process(_delta):
	pass
	#crosshair_bone.global_position = get_viewport().get_mouse_position()

