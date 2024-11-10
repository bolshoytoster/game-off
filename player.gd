class_name Player extends CharacterBody2D


## Can the player die in this scene? (is there a blood emitter)
@export var mortal = true


## Position at the last touched checkpoint
@onready var checkpoint_position = position
	
## The sprites of keys that we have
var keys: Array[Sprite2D]
## The keys at the last checkpoint
var keys_snapshot: Array[Sprite2D]

## Has the player collected the diamond
var diamond = false
## Did the player have the diamond at the last checkpoint
var diamond_snapshot = false

## The time that this level started
@onready var level_start = Time.get_ticks_msec()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var blood_emitter: CPUParticles2D = $"../CPUParticles2D" if mortal else null

## Nodes that need to be updated on reset
class DynamicNode:
	var node: Area2D
	# Was this node enabled at the last checkpoint?
	var enabled: bool
@onready var checkpoint = snapshot()

func add_key():
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://Tiles/tile_0027.png")
	sprite.material = preload("res://greeninator.material")
	sprite.scale = Vector2(3, 3)
	sprite.z_index = 2
	add_child(sprite)

	# Move the key to the top left, after any other keys
	sprite.position = Vector2(keys.size() * 72 - 528, -288)
	keys.push_back(sprite)


## Array of `DynamicNode`s
func snapshot() -> Array:
	keys_snapshot = keys.duplicate()
	diamond_snapshot = diamond

	return get_tree().get_nodes_in_group("dynamic").map(
		func(node):
			var data = DynamicNode.new()
			data.node = node
			data.enabled = node.visible
			return data
	)


## Load from the previous checkpoint
func restart():
	position = checkpoint_position
	diamond = diamond_snapshot

	if keys.size() < keys_snapshot.size():
		# If there are less keys now, we need to add more
		for _i in keys_snapshot.size() - keys.size():
			add_key()
	elif keys_snapshot.size() < keys.size():
		# If there are more keys now, we need to remove some
		for i in keys.size() - keys_snapshot.size():
			keys[keys.size() - i - 1].free()

		keys.resize(keys_snapshot.size())

	# Wait until the player has been moved to re-enable things
	await get_tree().process_frame

	for node in checkpoint:
		# TODO: should we bother supporting objects coming into existance?
		if node.enabled:
			node.node.process_mode = ProcessMode.PROCESS_MODE_INHERIT
			node.node.visible = true


## Called when the exit button is pressed
func exit():
	get_tree().change_scene_to_file("res://menu.tscn")


## Reset to the last checkpoint and spawn blood
func die():
	blood_emitter.position = position
	blood_emitter.emitting = true

	position = checkpoint_position


func _unhandled_input(event: InputEvent):
	# Jump
	if event.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = -512


func _physics_process(_delta: float):
	var on_floor = is_on_floor()

	# Add the gravity
	if not on_floor:
		velocity.y += Globals.gravity

		# Have the legs out while in the air
		animated_sprite.frame = 1
		# Put us halfway through the frame, so it quickly goes back to the first on when we land
		animated_sprite.frame_progress = .5

	# If we go too low, respawn at the last checkpoint
	if position.y > 384:
		die()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = clamp(velocity.x + direction * 16, -Globals.max_speed, Globals.max_speed)

		# Make sure the sprite is facing the right direction and the walking animation is playing
		animated_sprite.flip_h = direction > 0
		if on_floor:
			animated_sprite.play()
	else:
		# Slow down when there's no input
		velocity.x *= Globals.friction

		animated_sprite.pause()
		# Don't reset animation when we're in the air
		if on_floor:
			animated_sprite.frame = 0

	move_and_slide()
