extends Node2D

var initial_strength = 1.0
var decay_rate = 0.01

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

