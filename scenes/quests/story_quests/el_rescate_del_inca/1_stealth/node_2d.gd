extends Node2D
@onready var animation_hada_1 = $hada
@onready var animation_hada_2 = $hada2
@onready var animation_hada_3 = $hada3
@onready var animation_hada_4 = $hada4
@onready var animation_hada_5 = $hada5
@onready var animation_hada_6 = $hada6
@onready var animation_hada_7 = $hada7
@onready var animation_hada_8 = $hada8

func _ready():
	animation_hada_1.play("fly")
	animation_hada_2.play("fly")
	animation_hada_3.play("fly")
	animation_hada_4.play("fly")
	animation_hada_5.play("fly")
	animation_hada_6.play("fly")
	animation_hada_7.play("fly")
	animation_hada_8.play("fly")
