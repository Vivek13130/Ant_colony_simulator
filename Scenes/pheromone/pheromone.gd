extends Sprite2D

var pheromone_type : String
var strength : float
var decay_rate : float
var is_active:bool = false

var sprite = null

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite = $"."

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	strength -= decay_rate 
	sprite.modulate.a = strength
	if strength <= 0 :
		auto_load.reset_pheromone(self)

