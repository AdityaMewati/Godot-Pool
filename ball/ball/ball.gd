#tool # TODO Add back in 3.1
extends RigidBody

const BALL_SIZE = 1.125
const CIRCUMFERENCE = 2.0 * PI * BALL_SIZE

onready var COLLISION_PLAYER = load("collision_player.gd")

enum Ball{
	CUE_BALL,
	SOLID_1, SOLID_2, SOLID_3,
	SOLID_4, SOLID_5, SOLID_6,
	SOLID_7, BALL_8, STRIPE_9,
	STRIPE_10, STRIPE_11, STRIPE_12,
	STRIPE_13, STRIPE_14, STRIPE_15
}

export(Ball) var type setget set_type
var current_style = 0

var unlocked = false

func _ready():
	$BallSimulator/CircleShape.shape.radius = BALL_SIZE
	$BallSimulator.position = Util.to_vec2(translation)
	#$BallSimulator/CircleShape.disabled = false
	
	$BallSimulator.connect("body_entered", self, "_collided")

func _physics_process(delta):
	# This stops the editor from constantly updating
	if unlocked or Engine.editor_hint: return
	
	var position = $BallSimulator.position
	translation = Vector3(position.x, BALL_SIZE, position.y)
	
	var velocity = $BallSimulator.linear_velocity * delta
	if velocity != Vector2():
		var axis = velocity.rotated(PI * -0.5).normalized()
		var angle = velocity.length() / BALL_SIZE
		transform.basis = transform.basis.rotated(Util.to_vec3(axis), angle)

func _collided(body):
	if body.name == "BallSimulator" and is_greater_than(body):
		#print("hit")
		var speed = $BallSimulator.linear_velocity.distance_to(body.linear_velocity)
		speed = sqrt(speed)
		print(speed)
		speed = clamp(speed, 0, 10)
		#print(range_lerp(speed, 0, 5, 0.9, 1.1))
		var player = COLLISION_PLAYER.new(COLLISION_PLAYER.BALL_COLLISION, range_lerp(speed, 0, 10, 0.9, 1.3))
		player.translation = Util.to_vec3((body.global_position + $BallSimulator.global_position) * 0.5)
		Game.world.add_child(player)

func hit(impulse):
	$BallSimulator.apply_impulse(Vector2(), impulse)

func is_still():
	return $BallSimulator.linear_velocity.length_squared() < 0.05

func force_still():
	$BallSimulator.linear_velocity = Vector2()

func cast(dir):
	var result = Physics2DTestMotionResult.new()
	dir.y = -dir.y
	var collided = $BallSimulator.test_motion(dir * 100, 0.1, result)
	if collided:
		var data = {
			"this": self,
			"this_motion": result.motion_remainder,
			
			"distance": result.motion,
			"point": result.collision_point,
			"normal": result.collision_normal
		}
		if result.collider.name == "BallSimulator":
			data["that"] = result.collider
			data["that_motion"] = result.collider_velocity
		return data
	else:
		return {}

func ball_in():
	if type == Ball.CUE_BALL:
		translation = Vector3(-24, 1.125, 0)
		$BallSimulator.position = Vector2(-24, 0)
	else:
		unlock_plane()

func unlock_plane():
	$BallSimulator/CircleShape.disabled = true
	$CollisionSphere.disabled = false
	linear_velocity = Vector3()
	$BallSimulator.linear_velocity = Vector2()
	unlocked = true
	mode = MODE_RIGID

func lock_plane():
	pass

func set_type(new_type):
	if type != new_type:
		type = new_type
		#$BallMesh.material_override.albedo_texture = get_texture()
		$BallMesh.material_override.albedo_texture = get_texture()

func get_texture(): # TODO Create a style class to automate this later
	return load("res://ball/styles/default/" + Ball.keys()[type].to_lower() + ".png")
