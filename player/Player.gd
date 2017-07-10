extends Node2D

signal hitSignal

# Laws of Physics
const GRAVITY = Vector2(0,2000)


# Movement Constants
const FLOOR_NORMAL = Vector2(0, -1)
const SLOPE_FRICTION = -20

const MOVEMENT_SPEED = 400
const CROUCH_SPEED = 200

const ACCELERATION = 0.3

const JUMP_FORCE = 840
const JUMP_TIME_THRESHOLD = 0.2 # seconds

const DASH_TOLERANCE = 0.2
const DASH_TIME = 0.2
const DASH_ACCELERATION = 2.4

const EJECTION_TIME = 0.20
const EJECTION_VERTICAL_FRICTION = 0.5
const EJECTION_POWER_COEFF = 0.02
const FINAL_EJECTION_FORCE_COEFF = 2

const BEAT_FORCE = 1000

# Player Variables
var velocity = Vector2()
var can_jump = false
var jump_timer = 0
var raycast
var raylength
var currentRange
var recovering = false
var hitting = false
var allowmove = true
var guarding = false
var coefav = 1



#Controls
var playerNumber
var body
var in_movement
var crouching = false
var dashdirection = 1
var ejectiondirection = -1
var ejectionpower = 0

var final_ejection = false

var enemy

var actionTimer = 0.0

var victories = 0


var playing = true

#RANGES
var ranges = {
	"default": { "range" : 68, "time" : 0.0, "power" : 0.0, "hitsound" : ""
	},
	"punch": { "range": 110, "time": 0.3, "power" : 100.1, "hitsound" : "punchhit"
	}
}

# Start
func _ready():
	in_movement = false
	get_node("dashtimer").set_wait_time(DASH_TOLERANCE)
	get_node("dashtimer").set_active(false)
	get_node("dashtimer").connect("timeout", self, "timerout", [get_node("dashtimer")])
	
	get_node("dashtimetimer").set_wait_time(DASH_TIME)
	get_node("dashtimetimer").set_active(false)	
	get_node("dashtimetimer").connect("timeout", self, "timerout", [get_node("dashtimetimer")])
	
	get_node("ejectiontimer").set_wait_time(EJECTION_TIME)
	get_node("ejectiontimer").set_active(false)
	get_node("ejectiontimer").connect("timeout", self, "timerout", [get_node("ejectiontimer")])
	
	set_fixed_process(true)



#player one or player two ?
func initAs(var name, var num):
	
	resetAction()
	
	body = get_node("body")
	var sprite = body.get_node("Sprite")
	
	raycast = body.get_node("RayCast")
	
	
	playerNumber = str(num)
	var texture_name = "res://graphics/sprites/"+name+"/cost"+playerNumber+"/idle.png"
	var texture = load(texture_name)
	sprite.set_texture(texture)
	
	if(num == 2):
		coefav = -1
	
	print("init player " + playerNumber + " as " + name + "(" + texture_name + ")")


func timerout(timer):
	timer.stop()
	timer.set_active(false)

# Processing
func _fixed_process(delta):
	
	if(playing):
		if(final_ejection):
			final_ejection = false;
			#make it awesome
			get_node("ejectiontimer").set_wait_time(EJECTION_TIME*FINAL_EJECTION_FORCE_COEFF)
			
			get_node("ejectiontimer").set_active(true)
			get_node("ejectiontimer").start()
		if(get_node("dashtimetimer").is_active()):
			var speed
			if(crouching):
				speed = CROUCH_SPEED
			else:
				speed = MOVEMENT_SPEED
			body.move_and_slide(Vector2(speed*DASH_ACCELERATION,0)*dashdirection, FLOOR_NORMAL, SLOPE_FRICTION)
		elif(get_node("ejectiontimer").is_active()):
			if(get_node("ejectiontimer").get_time_left() < get_node("ejectiontimer").get_wait_time()/2):
				body.move_and_slide(Vector2(MOVEMENT_SPEED*ejectionpower*ejectiondirection, MOVEMENT_SPEED*ejectionpower*EJECTION_VERTICAL_FRICTION), FLOOR_NORMAL, SLOPE_FRICTION)
			else:
				body.move_and_slide(Vector2(MOVEMENT_SPEED*ejectionpower*ejectiondirection, MOVEMENT_SPEED*ejectionpower*-1* EJECTION_VERTICAL_FRICTION), FLOOR_NORMAL, SLOPE_FRICTION)
			
			
		else:
			
			if(Input.is_action_just_pressed("p"+playerNumber+"-right") and allowmove and can_jump):
				if(get_node("dashtimer").is_active() and dashdirection == 1):
					get_node("dashtimer").stop()
					get_node("dashtimer").set_active(false)
					#dashing
					get_node("SamplePlayer").play("dash")
					get_node("dashtimetimer").start()
					get_node("dashtimetimer").set_active(true)
					
				else:
					get_node("dashtimer").start()
					get_node("dashtimer").set_active(true)
					dashdirection = 1
			elif(Input.is_action_just_pressed("p"+playerNumber+"-left") and allowmove and can_jump):
				if(get_node("dashtimer").is_active() and dashdirection == -1):
					get_node("dashtimer").stop()
					get_node("dashtimer").set_active(false)
					#dashing
					get_node("SamplePlayer").play("dash")
					get_node("dashtimetimer").start()
					get_node("dashtimetimer").set_active(true)
					
				else:
					get_node("dashtimer").start()
					get_node("dashtimer").set_active(true)
					dashdirection = -1
			
			actionTimer += delta
			
			if(actionTimer > ranges[currentRange]["time"]):
				#le coup est donné, on repasse en standard
				self.resetAction()
			
			# Add Gravity
			velocity += GRAVITY * delta
			
			# Increment time
			jump_timer += delta
			
			
			
			# Jump Timer Controller
			if(body.is_move_and_slide_on_floor()):
				jump_timer = 0
			
			# Can jump?
			can_jump = jump_timer < JUMP_TIME_THRESHOLD
			
			# Movement
			var movement = 0
			
			if(currentRange == "default" and allowmove): #on ne peut bouger que si on ne donne pas de coup
				# Input: LEFT
				if(Input.is_action_pressed("p"+playerNumber+"-left")):
					movement -= 1
					in_movement = true
				# Input: RIGHT
				elif(Input.is_action_pressed("p"+playerNumber+"-right")):
					movement += 1
					in_movement = true
				else:
					in_movement = false
				if(Input.is_action_pressed("p"+playerNumber+"-guard") and can_jump):
					guarding = true
				else:
					guarding = false
					
				if(Input.is_action_pressed("p"+playerNumber+"-crouch") and can_jump):
					crouching = true
					var hb = get_node("body/hb")
					var crouchref = get_node("reference_hb/ref-crouch")
					
					get_node("body/RayCast").set_pos(get_node("reference_raycast/ref-crouch").get_pos())
					
					hb.set_pos(crouchref.get_pos())
					hb.set_scale(crouchref.get_scale())
				else:
					var hb = get_node("body/hb")
					var defref = get_node("reference_hb/ref-def")
					
					get_node("body/RayCast").set_pos(get_node("reference_raycast/ref-def").get_pos())
					
					hb.set_pos(defref.get_pos())
					hb.set_scale(defref.get_scale())
					crouching = false
				
			
			#Gestion des coups
			if(!hitting and allowmove and !guarding):
				if(Input.is_action_just_pressed("p"+playerNumber+"-punch")):
					self.get_node("SamplePlayer").play("punch", true)
					resetAction()
					currentRange = "punch"
					hitting = true
			
			# Set movement speed
			if(crouching):
				movement *= CROUCH_SPEED
			else:
				movement *= MOVEMENT_SPEED
			
			# Change horizontal velocity
			velocity.x = lerp(velocity.x, movement, ACCELERATION)
			
			# Input: Jump
			if(can_jump && Input.is_action_pressed("p"+playerNumber+"-jump") and allowmove):
				print("press jump for " + playerNumber)
				velocity.y -= JUMP_FORCE
				jump_timer = JUMP_TIME_THRESHOLD
			elif(!Input.is_action_pressed("p"+playerNumber+"-jump") && velocity.y < 0):
				velocity.y = 0
				
			
	
			
			# New:
			# Move and Slide
			velocity = body.move_and_slide(velocity, FLOOR_NORMAL, SLOPE_FRICTION)
			
			if(!recovering and allowmove):
				self.cast_ray()
				if(raycast.is_colliding()):
					if(currentRange == "default"):
						enemy.ispushed()
					elif(currentRange == "punch"):
						#we hit with a simple punch
						enemy.beaten(ranges[currentRange], velocity)
						recovering = true
	else: #if playing
		if(!final_ejection):
			if(get_node("ejectiontimer").is_active()):
				final_ejection = true #final ejection







func is_in_movement():
	return in_movement
	
func set_enemy(e):
	enemy = e
	
func resetAction():
	currentRange = "default"
	actionTimer = 0.0
	recovering = false
	hitting = false

func cast_ray():
	if(enemy.get_node("body").get_global_pos().x > body.get_global_pos().x):
		#le perso est à notre droite
		coefav = 1
	else:
		coefav = -1
	
	if(coefav == -1):
		get_node("body/Sprite").set_flip_h(true)
	else:
		get_node("body/Sprite").set_flip_h(false)
	raylength = ranges[currentRange]["range"]*coefav

	raycast.set_cast_to(Vector2(raylength,0))

func beaten(action, velocity):
	#we hit if no dash occurs
	if(!get_node("dashtimetimer").is_active() and allowmove):
		
		var powercoef = 1
		#if guard occurs, reduce damage
		if(guarding):
			powercoef = 0.1
			self.get_node("SamplePlayer").play("guard")
		else:
			self.get_node("SamplePlayer").play(action["hitsound"])
		
		print("Player"+playerNumber+" hit with a power of " + str(action["power"]))
		var ejection = get_node("ejectiontimer")
		var power = action["power"]*powercoef
		ejectionpower = power*EJECTION_POWER_COEFF
		ejectiondirection = coefav * -1
		
		ejection.set_active(true)
		ejection.start()
		
		
		
		
		emit_signal("hitSignal", playerNumber, power)
	
func ispushed():
	if(!self.is_in_movement() and !crouching):
		velocity.x = lerp(velocity.x, MOVEMENT_SPEED, ACCELERATION) * (-coefav)
		velocity = body.move_and_slide(velocity, FLOOR_NORMAL, SLOPE_FRICTION)