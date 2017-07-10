extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass


func get_spawn(index):
	return get_node("spawn"+str(index)).get_pos()
	
