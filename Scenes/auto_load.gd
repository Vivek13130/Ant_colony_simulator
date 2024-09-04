extends Node

#constants
const FOOD_SCATTER_QUANTITY = 10
const FOOD_SCATTER_RADIUS = 30

const CELL_SIZE = 50 # screen is divided into grid 


const FOOD_PHEROMONE_STRENGTH = 1.0
const HOME_PHEROMONE_STRENGTH = 1.0

const FOOD_PHEROMONE_DECAY_RATE :float = 0.1
const HOME_PHEROMONE_DECAY_RATE :float = 0.1

# rate of dropping pheromones , ( 1 pheromone per x fps )
const FOOD_PHEROMONE_DROP_RATE = 50
const HOME_PHEROMONE_DROP_RATE = 50

const FOOD_DETECTION_RADIUS = 100

const DEBUGGING_COLOR :Color = Color(1, 0, 0, 0.5)

const MAX_PHEROMONES_IN_POOL : int = 1000


var home_base_position = null

# packed scenes 
const HOME_BASE_SCENE:PackedScene = preload("res://Scenes/home_base/home_base.tscn")
const ANT_SCENE : PackedScene = preload("res://Scenes/ant/ant.tscn")
const FOOD_SCENE : PackedScene = preload("res://Scenes/food_item/food_item.tscn")
const PHEROMONE_SCENE : PackedScene = preload("res://Scenes/pheromone/pheromone.tscn")

# storage 
var food_items_grid = {} # Dictionary to store food_items positions in grids 
var ants = [] # list of all ant instances

var food_pheromones_grid = {}  # Dictionary for food pheromones ( active )
var home_pheromones_grid = {}  # Dictionary for home pheromones ( active )
var food_pheromone_pool = [] # contains all initialized food pheromones , 
var home_pheromone_pool = []  # contians all initialized home pheromones
# these pheromones will later be activated and switched to a type either food or home pheromone

const FOOD_PHEROMONE_COLOR = Color(0.0, 1.0, 0.0)  # (RGB: 51, 153, 204, Alpha: 0.5)
const HOME_PHEROMONE_COLOR = Color(1.0, 0.0 , 0.0) # (RGB: 178, 127, 229, Alpha: 0.5)


func world_pos_to_grid(vec2 : Vector2) -> Vector2:
	return Vector2(floor(vec2.x / CELL_SIZE) , floor(vec2.y / CELL_SIZE))


func initialize_pheromone(pheromone : Node2D ,strength : float , decay_rate:float, pheromone_type : String, color : Color) -> void:
	pheromone.strength = strength
	pheromone.pheromone_type = pheromone_type
	pheromone.decay_rate = decay_rate
	pheromone.is_active = true
	pheromone.modulate = color
	


func get_pheromone(pheromone_type : String) -> Node2D:
	var pheromone : Node2D
	
	var type : String
	var strength : int
	var decay_rate : int
	var color : Color
	
	if pheromone_type == "food" :
		
		type = "food"
		strength = FOOD_PHEROMONE_STRENGTH
		decay_rate = FOOD_PHEROMONE_DECAY_RATE
		color = FOOD_PHEROMONE_COLOR
		
		if food_pheromone_pool.size() > 0:
			pheromone = food_pheromone_pool.pop_back()
		else:
			pheromone = PHEROMONE_SCENE.instantiate()
			
	else :
		
		type = "home"
		strength = HOME_PHEROMONE_STRENGTH
		decay_rate = HOME_PHEROMONE_DECAY_RATE
		color = HOME_PHEROMONE_COLOR
		
		if home_pheromone_pool.size() > 0 : 
			pheromone = home_pheromone_pool.pop_back()
		else:
			pheromone = PHEROMONE_SCENE.instantiate()
	
	print(color)
	initialize_pheromone(pheromone, strength , decay_rate , type, color)
	return pheromone


func reset_pheromone(pheromone) :
	pheromone.is_active = false
