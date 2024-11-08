class_name Player extends CharacterBody2D


# Position of the last touched checkpoint
var checkpoint = Vector2()

# The sprites of keys that we have
var keys: Array[Sprite2D]


func _unhandled_input(event: InputEvent):
	# Jump
	if event.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = -512


func _physics_process(_delta: float):
	var on_floor = is_on_floor()

	# Add the gravity
	if not on_floor:
		velocity.y += 16

		# If we go too low, respawn at the last checkpoint
		if position.y > 512:
			position = checkpoint

		# Have the legs out while in the air
		$AnimatedSprite2D.frame = 1
		# Put us halfway through the frame, so it quickly goes back to the first on when we land
		$AnimatedSprite2D.frame_progress = .5

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = clamp(velocity.x + direction * 64, -256, 256)

		# Make sure the sprite is facing the right direction and the walking animation is playing
		$AnimatedSprite2D.flip_h = direction > 0
		if on_floor:
			$AnimatedSprite2D.play()
	else:
		# Slow down when there's no input
		velocity.x *= .9

		$AnimatedSprite2D.pause()
		# Don't reset animation when we're in the air
		if on_floor:
			$AnimatedSprite2D.frame = 0

	move_and_slide()
