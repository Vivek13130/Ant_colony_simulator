extends Node2D


#constants
const FOOD_SCATTER_QUANTITY = 10
const FOOD_SCATTER_RADIUS = 30
const CELL_SIZE = 50

# packed scenes 
const HOME_BASE_SCENE:PackedScene = preload("res://Scenes/home_base/home_base.tscn")
const ANT_SCENE : PackedScene = preload("res://Scenes/ant/ant.tscn")
const FOOD_SCENE : PackedScene = preload("res://Scenes/food_item/food_item.tscn")

# storage 
var food_items_grid = {} # dictionary to store food_items positions in grids 
var pheromones_home = {} # home pheromones storage 
var pheromones_food = {} # food pheromones storage 
var ants = [] # list of all ant instances

# variables 
var home_base_instance = null  # To store the home base
var ants_spawn_position = null # this will store the position of home_base


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	handle_inputs(delta)
	

func handle_inputs(delta):
	if Input.is_action_just_pressed("add_home_base"):
		add_home_base()
	
	if Input.is_action_pressed("add_food"):
		add_food()
	
	if Input.is_action_pressed("spawn_ant"):
		spawn_ant()

func add_home_base():
	var click_position: Vector2 = get_global_mouse_position()
	ants_spawn_position = click_position
	
	if home_base_instance == null :
		home_base_instance = HOME_BASE_SCENE.instantiate()
		home_base_instance.position = click_position
		$".".add_child(home_base_instance)
		
	else:
		home_base_instance.position = click_position


func add_food():
	var click_position = get_global_mouse_position()
	
	for i in range(FOOD_SCATTER_QUANTITY):
		var food_instance = FOOD_SCENE.instantiate()
		
		var random_scatter: Vector2 = Vector2.ZERO
		random_scatter.x = randf() * FOOD_SCATTER_RADIUS
		random_scatter.y = randf() * FOOD_SCATTER_RADIUS
		var final_pos = click_position + random_scatter
		
		food_instance.position = final_pos
		
		var grid_cell_pos = world_pos_to_grid(final_pos)
		if not food_items_grid.has(grid_cell_pos):
			food_items_grid[grid_cell_pos] = []
		food_items_grid[grid_cell_pos].append(food_instance)
		$food_manager.add_child(food_instance)
		
		print("added food to grid cell : ", grid_cell_pos)

func remove_food_from_grid(food):
	var grid_cell_pos = world_pos_to_grid(food.position)
	if food_items_grid.has(grid_cell_pos):
		food_items_grid[grid_cell_pos].erase(food)
		
		if food_items_grid[grid_cell_pos].empty():
			food_items_grid.erase(grid_cell_pos)

func spawn_ant():
	if ants_spawn_position != null :
		var ants_position = get_global_mouse_position()
		var ant_instance = ANT_SCENE.instantiate()
		ant_instance.position = ants_spawn_position
		$ants_manager.add_child(ant_instance)
		ants.append(ant_instance)

func world_pos_to_grid(vec2 : Vector2) -> Vector2:
	return Vector2(floor(vec2.x / CELL_SIZE) , floor(vec2.y / CELL_SIZE))
