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
	
	var alpha 
	if pheromone_type == "food" :
		alpha = strength / auto_load.FOOD_PHEROMONE_STRENGTH
	else:
		alpha = strength / auto_load.HOME_PHEROMONE_STRENGTH
		
	sprite.modulate.a = alpha
	
	if strength <= 0 :
		auto_load.reset_pheromone(self)

