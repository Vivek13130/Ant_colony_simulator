extends Node2D

var pheromone_type : String
var strength : float
var decay_rate : float
var is_active:bool = false

var sprite = null

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite = $"."

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	sprite.modulate = auto_load.HOME_PHEROMONE_COLOR
	strength -= decay_rate 
	if strength <= 0 :
		print("pheromone deleted from the screen ")
		queue_free()

