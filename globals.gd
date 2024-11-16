# Script containing data that needs to be persisted between scenes
extends Node


var gravity = 16
## How much the player slows down each physics frame when there's no input
var friction = .9
var max_speed = 288


## The time that the game started
@onready var game_start = Time.get_ticks_msec()
