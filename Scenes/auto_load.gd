extends Node

#constants
const FOOD_SCATTER_QUANTITY = 10
const FOOD_SCATTER_RADIUS = 30

const CELL_SIZE = 100 # screen is divided into grid 

const PHEROMONE_LIFETIME = 5.0
const PHEROMONE_STRENGTH = 1.0
const PHEROMONE_DECAY_RATE = PHEROMONE_STRENGTH / PHEROMONE_LIFETIME 

const FOOD_DETECTION_RADIUS = 100

const DEBUGGING_COLOR :Color = Color(1, 0, 0, 0.5)

var home_base_position = null

# packed scenes 
const HOME_BASE_SCENE:PackedScene = preload("res://Scenes/home_base/home_base.tscn")
const ANT_SCENE : PackedScene = preload("res://Scenes/ant/ant.tscn")
const FOOD_SCENE : PackedScene = preload("res://Scenes/food_item/food_item.tscn")


# storage 
var food_items_grid = {} # Dictionary to store food_items positions in grids 
var pheromones_home = {}  # Dictionary for home pheromones
var pheromones_food = {}  # Dictionary for food pheromones
var ants = [] # list of all ant instances

func set_ant_target_to_home(body):
	pass


func world_pos_to_grid(vec2 : Vector2) -> Vector2:
	return Vector2(floor(vec2.x / CELL_SIZE) , floor(vec2.y / CELL_SIZE))
