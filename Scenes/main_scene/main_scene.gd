extends Node2D


#constants - IN AUTOLOAD
var food_scatter_quantity = auto_load.FOOD_SCATTER_QUANTITY
var food_scatter_radius = auto_load.FOOD_SCATTER_RADIUS
var cell_size = auto_load.CELL_SIZE

# packed scenes - defined in autoload , referenced here  
var home_base_scene = auto_load.HOME_BASE_SCENE
var ant_scene = auto_load.ANT_SCENE
var food_scene = auto_load.FOOD_SCENE


# storage 
var food_items_grid = auto_load.food_items_grid # dictionary to store food_items positions in grids 
var home_pheromones_grid = auto_load.home_pheromones_grid # home pheromones storage 
var food_pheromones_grid = auto_load.food_pheromones_grid # food pheromones storage 
var ants = auto_load.ants # list of all ant instances

# variables 
var home_base_instance = null  # To store the home base
var ants_spawn_position = null # this will store the position of home_base

var initial_ants = 100

func _process(delta):
	handle_inputs(delta)
	

func handle_inputs(_delta):
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
		home_base_instance = auto_load.HOME_BASE_SCENE.instantiate()
		home_base_instance.position = click_position
		$".".add_child(home_base_instance)
		
	else:
		home_base_instance.position = click_position
	
	auto_load.home_base_position = click_position


func add_food():
	var click_position = get_global_mouse_position()
	
	for i in range(food_scatter_quantity):
		var food_instance = food_scene.instantiate()
		
		var random_scatter: Vector2 = Vector2.ZERO
		random_scatter.x = randf() * food_scatter_radius
		random_scatter.y = randf() * food_scatter_radius
		var final_pos = click_position + random_scatter
		
		food_instance.position = final_pos
		
		var grid_cell_pos = auto_load.world_pos_to_grid(final_pos)
		if not food_items_grid.has(grid_cell_pos):
			food_items_grid[grid_cell_pos] = []
		food_items_grid[grid_cell_pos].append(food_instance)
		$food_manager.add_child(food_instance)
		
		# print("added food to grid cell : ", grid_cell_pos)

func remove_food_from_grid(food):
	var grid_cell_pos = auto_load.world_pos_to_grid(food.position)
	if food_items_grid.has(grid_cell_pos):
		food_items_grid[grid_cell_pos].erase(food)
		
		if food_items_grid[grid_cell_pos].empty():
			food_items_grid.erase(grid_cell_pos)

func spawn_ant():
	if ants_spawn_position != null :
#		var ants_position = get_global_mouse_position()
		var ant_instance = auto_load.ANT_SCENE.instantiate()
		ant_instance.position = ants_spawn_position
		$ants_manager.add_child(ant_instance)
		ants.append(ant_instance)


