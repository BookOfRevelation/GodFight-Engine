extends Control

signal onDeath

var health = 0
var playerName

#ui elements
var label
var progressBar

var playerNumber = "0"


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_fixed_process(true)


func damage_taken(amount):
	health -= amount
	if(health < 0):
		health = 0
		emit_signal("onDeath")

func _fixed_process(delta):
	progressBar.set_val(health)
	var victories = env.victories[playerNumber]
	if(victories<=3):
		for i in range(1,victories+1):
			get_node("sc"+str(i)).set_scale(Vector2(0.25,0.25))


func initAs(name, life, number):
	health = life
	playerName = name
	playerNumber = number 
	
	label = get_node("Label")
	progressBar = get_node("ProgressBar")
	
	progressBar.set_max(life)
	progressBar.set_val(life)
	
	label.set_text(name)