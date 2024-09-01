extends Node2D

var initial_strength = auto_load.PHEROMONE_STRENGTH
var decay_rate = auto_load.PHEROMONE_DECAY_RATE

var strength = initial_strength
var sprite = null

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite = $Sprite2D 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	strength -= decay_rate * delta
	sprite.modulate = Color(1,1,1, strength)
	if strength <= 0 :
		queue_free()

