extends Control

export var scale = 0.8

const WINNER_SCALE = 0.3

var background

var player1
var player2

var aboutExitting = false

func _ready():
	get_node("AnimationPlayer").play("fade_in")
	background = get_node("SunnyStage")
	
	
	#create twoplayers
	var p1 = load("res://player/Player.tscn") # will load when parsing the script
	player1 = p1.instance()
	player1.initAs("greg",1)
	player1.set_scale(Vector2(scale,scale))
	player1.set_pos(background.get_spawn(1))
	add_child(player1)
	
	var p2 = load("res://player/Player.tscn") # will load when parsing the script
	player2 = p2.instance()
	player2.initAs("greg", 2)
	player2.set_scale(Vector2(scale,scale))
	player2.set_pos(background.get_spawn(2))
	add_child(player2)
	
	player1.set_enemy(player2)
	player2.set_enemy(player1)
	
	get_node("p1ui").initAs("GREG", 1000, "1")
	get_node("p2ui").initAs("GREG", 1000, "2")
	
	player1.connect("hitSignal", self, "applyHit")
	player2.connect("hitSignal", self, "applyHit")
	
	get_node("p1ui").connect("onDeath", self, "endGame")
	get_node("p2ui").connect("onDeath", self, "endGame")


func _fixed_process(delta):
	if(aboutExitting and Input.is_action_pressed("ui_accept")):
		quitMatch()

func applyHit(playerNumber, amount):
	print("apply hit")
	get_node("p"+playerNumber+"ui").damage_taken(amount)
	
func endGame():
	get_node("Kolbl/AnimationPlayer").play("KO")
	get_node("SamplePlayer").play("kosound", true)
	get_node("Flash/AnimationPlayer").play("flash")
	player1.playing = false
	player2.playing = false
	get_node("flashtime").start()
	get_node("flashtime").connect("timeout", self, "resumeAfterEnd")
	
func resumeAfterEnd():
	var winner
	var loser
	if(get_node("p1ui").get_node("ProgressBar").get_val() == 0):
		winner = player2
		loser = player1
	else:
		winner = player1
		loser = player2
	
	env.victories[winner.playerNumber] += 1
	
	winner.playing = true
	loser.playing = true
	loser.allowmove = false
	get_node("Kolbl/AnimationPlayer").play_backwards("KO")
	get_node("SamplePlayer").play("popopo", true)
	
	
	
	if(env.victories[winner.playerNumber] == 3):
		#le joueur a gagné !
		get_node("playwin").set_text("Player "+winner.playerNumber+" wins!")
		get_node("endgame").disconnect("timeout", self, "endLevel")
		get_node("endgame").connect("timeout", self, "endMatch")
	else:
		get_node("endgame").disconnect("timeout", self, "endMatch")
		get_node("endgame").connect("timeout", self, "endLevel")
		
	get_node("endgame").start()
	
	get_node("SamplePlayer").play("koend")

func endLevel():
	get_node("AnimationPlayer").play("fade_out")
	get_node("AnimationPlayer").connect("finished", self, "newMatch")
	
func newMatch():
	get_tree().reload_current_scene()
	
func endMatch():
	get_node("playwin/AnimationPlayer").play("cligne")
	player1.allowmove = false
	player2.allowmove = false
	aboutExitting = true
	set_fixed_process(true)
func quitMatch():
	get_tree().quit()