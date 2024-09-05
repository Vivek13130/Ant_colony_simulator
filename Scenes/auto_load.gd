extends Node

#constants
const FOOD_SCATTER_QUANTITY = 50
const FOOD_SCATTER_RADIUS = 20

const CELL_SIZE = 100 # screen is divided into grid 

const FOOD_PHEROMONE_STRENGTH = 4.0
const HOME_PHEROMONE_STRENGTH = 4.0

const ANT_FOOD_PH_DROP_STR_DECAY = 0.3
const ANT_HOME_PH_DROP_STR_DECAY = 0.3

const FOOD_PHEROMONE_DECAY_RATE :float = 0.00
const HOME_PHEROMONE_DECAY_RATE :float = 0.00

# rate of dropping pheromones , ( 1 pheromone per x fps )
const FOOD_PHEROMONE_DROP_RATE = 15
const HOME_PHEROMONE_DROP_RATE = 15

const FOOD_DETECTION_RADIUS = 40
const PHEROMONE_DETECTION_RADIUS = 40
const DETECTION_ANGLE = 90 # this is for both food and pheromone.
# the ant will be able to see only 45 deg in left or right of it.

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

func grid_to_world_pos(grid_cell: Vector2) -> Vector2:
	# Multiply the grid cell position by CELL_SIZE and add half CELL_SIZE to get the center of the cell
	return (grid_cell * CELL_SIZE) + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)


func initialize_pheromone(pheromone : Node2D ,strength : float , decay_rate:float, pheromone_type : String, color : Color) -> void:
	pheromone.strength = strength
	pheromone.pheromone_type = pheromone_type
	pheromone.decay_rate = decay_rate
	pheromone.is_active = true
	pheromone.modulate = color


func get_pheromone(ant , pheromone_type : String) -> Node2D:
	var pheromone : Node2D
	
	var type : String
	var strength : float
	var decay_rate : float
	var color : Color
	
	if pheromone_type == "food" :
		
		type = "food"
		strength = ant.initial_strength_food_ph
		ant.initial_strength_food_ph -= ANT_FOOD_PH_DROP_STR_DECAY
		decay_rate = FOOD_PHEROMONE_DECAY_RATE
		color = FOOD_PHEROMONE_COLOR
		
		if food_pheromone_pool.size() > 0:
			pheromone = food_pheromone_pool.pop_back()
		else:
			pheromone = PHEROMONE_SCENE.instantiate()
			
	else :
		
		type = "home"
		strength = ant.initial_strength_home_ph
		ant.initial_strength_home_ph -= ANT_HOME_PH_DROP_STR_DECAY
		decay_rate = HOME_PHEROMONE_DECAY_RATE
		color = HOME_PHEROMONE_COLOR
		
		if home_pheromone_pool.size() > 0 : 
			pheromone = home_pheromone_pool.pop_back()
		else:
			pheromone = PHEROMONE_SCENE.instantiate()
	
	initialize_pheromone(pheromone, strength , decay_rate , type, color)
	return pheromone


func reset_pheromone(pheromone) :
	pheromone.is_active = false
	
	var grid_cell_pos = auto_load.world_pos_to_grid(pheromone.position)
	
	if pheromone.pheromone_type == "food":
		if auto_load.food_pheromones_grid.has(grid_cell_pos):
			auto_load.food_pheromones_grid[grid_cell_pos].erase(pheromone)
	else:
		if auto_load.home_pheromones_grid.has(grid_cell_pos):
			auto_load.home_pheromones_grid[grid_cell_pos].erase(pheromone)
	
	if pheromone.pheromone_type == "food":
		food_pheromone_pool.push_back(pheromone)
	else:
		home_pheromone_pool.push_back(pheromone)
		
	if pheromone.get_parent() != null:
		pheromone.get_parent().remove_child(pheromone)
