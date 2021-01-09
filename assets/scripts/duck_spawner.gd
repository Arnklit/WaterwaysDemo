extends Spatial


export(String, FILE) var spawn_object_path
export(float, 0.0, 50.0) var throw_force = 10.0
export(float, 0.0, 10.0) var random_rotation_force = 1.0
export(int) var max_ducks = 10

var ducks := []

var _spawn_object

func _ready() -> void:
	_spawn_object = load(spawn_object_path)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_spawn_duck()
	

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_select"):
		_spawn_duck()


func _spawn_duck() -> void:
	var obj = _spawn_object.instance() as RigidBody
	owner.add_child(obj)
	obj.translation = global_transform.origin
	obj.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	obj.apply_central_impulse(global_transform.basis.z * -throw_force)
	obj.angular_velocity = Vector3((-0.5 + randf()) * random_rotation_force, (-0.5 + randf()) * random_rotation_force, (-0.5 + randf()) * random_rotation_force)
	ducks.push_front(obj)
	if ducks.size() >= max_ducks:
		ducks[ducks.size() -1].queue_free()
		ducks.pop_back()
