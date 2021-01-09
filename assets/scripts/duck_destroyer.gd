extends Area


var duck_spawner

func _ready() -> void:
	connect("body_entered", self, "on_body_entered")
	duck_spawner = get_parent().get_node("Camera/DuckSpawner")

func on_body_entered(body) -> void:
	if body is RigidBody:
		duck_spawner.ducks.erase(body)
		body.queue_free()
