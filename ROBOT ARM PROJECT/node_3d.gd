extends Node3D

# Speed of movement (adjust these values to control the smoothness)
var rotation_speed: float = 0.5  # Rotation speed for base (left/right)
var tilt_speed: float = 0.5      # Tilt speed for arm (up/down)
var clamp_speed_open: float = 1  # Faster speed for clamp opening
var clamp_speed_close: float = 1  # Slower speed for clamp closing

# Smoothness parameters
var base_target_rotation: float = 0.0
var arm_target_rotation: float = 0.0
var smooth_factor: float = 0.1  # Smoothing factor, smaller = slower and smoother

# Clamp angles (open and close)
var clamp1_open = Vector3(0, 0, 0)
var clamp1_close = Vector3(0.25, 0, 0)

var clamp2_open = Vector3(0, 0, 0)
var clamp2_close = Vector3(0, 0, -0.10)

var clamp3_open = Vector3(0, 0, 0)
var clamp3_close = Vector3(0, 0, 0.25)

# Target angles for each clamp (used for lerping)
var target_clamp1_angle = clamp1_open
var target_clamp2_angle = clamp2_open
var target_clamp3_angle = clamp3_open

# Nodes for controlling the arm
@onready var base = $Node3D/RoboticHand/Base_Hand/BaseSphere_Hand/ud1/Hand_Part1/lr2  # Node for base rotation
@onready var arm = $Node3D/RoboticHand/Base_Hand/BaseSphere_Hand/ud1  # Node for arm tilt
@onready var clamp1 = $Node3D/RoboticHand/Base_Hand/BaseSphere_Hand/ud1/Hand_Part1/lr2/Hand_Part2/ClampRotater/ClampEngie_Hand/ClampEngie_Base/ClampEngie/clamp1  # Node for clamp1
@onready var clamp2 = $Node3D/RoboticHand/Base_Hand/BaseSphere_Hand/ud1/Hand_Part1/lr2/Hand_Part2/ClampRotater/ClampEngie_Hand/ClampEngie_Base/ClampEngie/clamp2  # Node for clamp2
@onready var clamp3 = $Node3D/RoboticHand/Base_Hand/BaseSphere_Hand/ud1/Hand_Part1/lr2/Hand_Part2/ClampRotater/ClampEngie_Hand/ClampEngie_Base/ClampEngie/clamp3  # Node for clamp3

func _ready():
	# Debug the node paths to confirm they are correct
	print("Base node: ", base)
	print("Arm node: ", arm)
	print("Clamp 1 node: ", clamp1)
	print("Clamp 2 node: ", clamp2)
	print("Clamp 3 node: ", clamp3)

func _process(delta):
	# Reset target rotations
	base_target_rotation = base.rotation.z
	arm_target_rotation = arm.rotation.x

	# Check if keys are pressed and update target rotation gradually (WASD)
	if Input.is_action_pressed("move_left"):  # A key
		print("Left key pressed: Rotating base left")
		base_target_rotation -= rotation_speed * delta  # Rotate left
	elif Input.is_action_pressed("move_right"):  # D key
		print("Right key pressed: Rotating base right")
		base_target_rotation += rotation_speed * delta  # Rotate right

	if Input.is_action_pressed("move_up"):  # W key
		print("Up key pressed: Tilting arm up")
		arm_target_rotation -= tilt_speed * delta  # Tilt up
	elif Input.is_action_pressed("move_down"):  # S key
		print("Down key pressed: Tilting arm down")
		arm_target_rotation += tilt_speed * delta  # Tilt down

	# Smoothly interpolate the current rotation towards the target rotation for base and arm
	base.rotation.z = lerp(base.rotation.z, base_target_rotation, smooth_factor)
	arm.rotation.x = lerp(arm.rotation.x, arm_target_rotation, smooth_factor)

	# Check for input for clamp control (O and P keys for open/close)
	if Input.is_action_pressed("clamp_open"):  # O key for open
		print("Opening clamps")
		target_clamp1_angle = clamp1_open
		target_clamp2_angle = clamp2_open
		target_clamp3_angle = clamp3_open
	elif Input.is_action_pressed("clamp_close"):  # P key for close
		print("Closing clamps")
		target_clamp1_angle = clamp1_close
		target_clamp2_angle = clamp2_close
		target_clamp3_angle = clamp3_close

	# Adjust the speed for opening and closing clamps
	var clamp_speed = clamp_speed_open if target_clamp1_angle == clamp1_open else clamp_speed_close

	# Smoothly interpolate the current rotation towards the target rotation for clamps with different speeds
	clamp1.rotation = lerp(clamp1.rotation, target_clamp1_angle, clamp_speed * delta)
	clamp2.rotation = lerp(clamp2.rotation, target_clamp2_angle, clamp_speed * delta)
	clamp3.rotation = lerp(clamp3.rotation, target_clamp3_angle, clamp_speed * delta)

	# Debug current rotation of base, arm, and clamps
	print("Base rotation (z-axis): ", base.rotation.z)
	print("Arm rotation (x-axis): ", arm.rotation.x)
	print("Clamp 1 rotation: ", clamp1.rotation)
	print("Clamp 2 rotation: ", clamp2.rotation)
	print("Clamp 3 rotation: ", clamp3.rotation)
