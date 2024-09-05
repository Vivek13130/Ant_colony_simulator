extends CharacterBody2D


var acceleration :Vector2 = Vector2.ZERO

var initial_strength_food_ph = auto_load.FOOD_PHEROMONE_STRENGTH
var initial_strength_home_ph = auto_load.HOME_PHEROMONE_STRENGTH

var current_direction = Vector2.ZERO

var time_since_last_change = 0.0
var direction_change_interval = 20
var window_margin :int = 10

var ant_has_food : bool = false

var food_found = null # a var to store the food found by an ant for debugging purposes
var fps_counter : int = 0 # to remove the lines from the ants that are not detecting the food now 
var ph_counter : int = 0 

const PHEROMONE_SCENE : PackedScene = preload("res://Scenes/pheromone/pheromone.tscn")
var food_pheromone_manager_node
var home_pheromone_manager_node

var max_speed = 200
var max_acc = 50
var mass = 20
var min_speed = 100  # Ensure constant movement with a minimum speed

var target_offset = 50
var target_update_duration = 4  # Fixed typo in the variable name
var time_passed = 0
var target
var screen_size
var target_found = false

var boundary_buffer = 100  # Distance from the screen edge to start deflecting
var deflection_strength = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	food_pheromone_manager_node = get_tree().root.get_node("main_scene").get_node("food_pheromone_manager")
	home_pheromone_manager_node = get_tree().root.get_node("main_scene").get_node("home_pheromone_manager")
	
	$marker_manager/center.position.y = -auto_load.CELL_SIZE
	
	$marker_manager/left.position.y = -auto_load.CELL_SIZE
	$marker_manager/left.position.x = auto_load.CELL_SIZE
	
	$marker_manager/right.position.y = -auto_load.CELL_SIZE
	$marker_manager/right.position.x = -auto_load.CELL_SIZE
	
	target = global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
	screen_size = get_viewport_rect().size

func _process(delta):
	fps_counter += 1;
	
	if ant_has_food:
		check_if_ant_reached_home()
		if fps_counter >= auto_load.FOOD_PHEROMONE_DROP_RATE :  
			fps_counter = 0
			if initial_strength_food_ph > 0 : drop_pheromones(delta , "food")
	else :
		if fps_counter >= auto_load.HOME_PHEROMONE_DROP_RATE:  
			fps_counter = 0
			detect_food()
			if initial_strength_home_ph > 0 : drop_pheromones(delta , "home")
	
	move(delta)

	# Make the ant face the direction of movement
	if velocity.length() > 0:  # Only rotate when the ant is moving
		rotation = velocity.angle() + deg_to_rad(90)  # Rotate to match the movement direction
	

func move(delta):
	ph_counter += 1
	var temp = global_position
	# Update direction based on pheromones at intervals
	if ph_counter >= direction_change_interval :
		var newtarget = process_pheromones_and_get_direction()
		if newtarget != Vector2.ZERO:
			target = newtarget
			target_found = true
		ph_counter = 0

	time_passed += delta
	if time_passed >= target_update_duration and not target_found : 
		time_passed = 0
		# Ensure the new target is in the forward direction to avoid abrupt turns
		var forward_dir = velocity.normalized() * 200
		target = global_position + forward_dir + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		
	# Calculate desired velocity
	var desired_vel = (target - global_position).normalized()
	var scaled_desired_vel = desired_vel * max_speed

	# Steering acceleration
	var steer_acc = (scaled_desired_vel - velocity)
	if steer_acc.length() > max_acc:
		steer_acc = steer_acc.normalized() * max_acc
		
	steer_acc += deflect_from_boundary()
	
	# Update velocity with a minimum speed to prevent stopping
	velocity += steer_acc / mass
	if velocity.length() < min_speed:
		velocity = velocity.normalized() * min_speed  # Maintain minimum speed

	rotation = velocity.angle() + deg_to_rad(90)
	
	if target_found : 
		check_if_ant_reached_target()
	check_if_ant_reached_home()
#	check_teleportation()
	move_and_slide()

func check_if_ant_reached_target():
	if global_position.distance_to(target) <= 10 :
		target_found = false

# Teleportation function to wrap around the screen edges
func check_teleportation():
	if position.x < 0:
		position.x = screen_size.x
	elif position.x > screen_size.x:
		position.x = 0

	if position.y < 0:
		position.y = screen_size.y
	elif position.y > screen_size.y:
		position.y = 0
	
	










func detect_food() -> void :
	var ant_position = global_position
	var cell_pos = auto_load.world_pos_to_grid(ant_position)
	
	# we have the current cell, we have to detect food in neigh. 8 cells as well as this cell
	for dx in range(-1, 2):
		if ant_has_food : break
		for dy in range(-1, 2):
			if ant_has_food : break
			var neighbour_cell = cell_pos + Vector2(dx , dy)
			
			if auto_load.food_items_grid.has(neighbour_cell):
				
				for food in auto_load.food_items_grid[neighbour_cell]:
					
					if global_position.distance_to(food.global_position) < auto_load.FOOD_DETECTION_RADIUS:
						$CPUParticles2D.emitting = true
						ant_has_food = true
						current_direction -= current_direction
						auto_load.food_items_grid[neighbour_cell].erase(food)
						change_ant_appearence()
						break
					else:
						food_found = null


func change_ant_appearence():
	$Sprite2D/food_in_ant_mouth.visible = !$Sprite2D/food_in_ant_mouth.visible

func check_if_ant_reached_home():
	if global_position.distance_to(auto_load.home_base_position) <= 30 :
		if ant_has_food : 
			change_ant_appearence()
			ant_has_food = false
			$CPUParticles2D.emitting = true
		initial_strength_food_ph = auto_load.FOOD_PHEROMONE_STRENGTH
		initial_strength_home_ph = auto_load.HOME_PHEROMONE_STRENGTH

func drop_pheromones(_delta, type : String):
	var pheromone = auto_load.get_pheromone(self, type)
#	print("pheromone with strength " , pheromone.strength)
	pheromone.global_position = global_position
	pheromone.visible = true
	
	var grid_cell_pos = auto_load.world_pos_to_grid(pheromone.global_position)
	
	if pheromone.pheromone_type == "food":
		if not auto_load.food_pheromones_grid.has(grid_cell_pos):
			auto_load.food_pheromones_grid[grid_cell_pos] = []
		auto_load.food_pheromones_grid[grid_cell_pos].append(pheromone)
	else:
		if not auto_load.home_pheromones_grid.has(grid_cell_pos):
			auto_load.home_pheromones_grid[grid_cell_pos] = []
		auto_load.home_pheromones_grid[grid_cell_pos].append(pheromone)
	
	
	if type == "food" :
		food_pheromone_manager_node.add_child(pheromone)
	else:
		home_pheromone_manager_node.add_child(pheromone)



#func process_pheromones_and_get_direction() -> Vector2:
#	var total_strength = 0.0
#	var weighted_sum = Vector2.ZERO # it is weighted sum of postions 
#
#	var all_markers = $marker_manager.get_children()
#	var total_influence = Vector2.ZERO
#
#	for marker in all_markers:
#		var neighbour_cell =  auto_load.world_pos_to_grid(marker.global_position)
#
#		if not(ant_has_food):
#			if auto_load.food_pheromones_grid.has(neighbour_cell):
#				for pheromone in auto_load.food_pheromones_grid[neighbour_cell]:
#					weighted_sum += pheromone.global_position * pheromone.strength  # Weighting by strength
#					total_strength +=  pheromone.strength  # Sum of all strengths
#
#		else:
#			if auto_load.home_pheromones_grid.has(neighbour_cell):
#				for pheromone in auto_load.home_pheromones_grid[neighbour_cell]:
#					weighted_sum += pheromone.global_position  * (pheromone.strength)  # Weighting by inverse strength
#					total_strength += (pheromone.strength)  # Sum of all strengths
#
#	if total_strength == 0:
#		return Vector2.ZERO
#
#	return weighted_sum / total_strength


func deflect_from_boundary() -> Vector2:
	var deflection = Vector2()
	
	# Check proximity to left/right boundaries
	if global_position.x < boundary_buffer:
		deflection.x = deflection_strength  # Steer right
	elif global_position.x > screen_size.x - boundary_buffer:
		deflection.x = -deflection_strength  # Steer left
	
	# Check proximity to top/bottom boundaries
	if global_position.y < boundary_buffer:
		deflection.y = deflection_strength  # Steer down
	elif global_position.y > screen_size.y - boundary_buffer:
		deflection.y = -deflection_strength  # Steer up
	
	return deflection


func process_pheromones_and_get_direction() -> Vector2:
	var ant_grid_pos = auto_load.world_pos_to_grid(global_position)
	var max_pheromone_strength = 0.0
	var max_pheromone_cell = Vector2.ZERO
	
	# Loop through all 8 neighboring cells, including the current one
	for x_offset in range(-1,2):  # Checking x: -1, 0, 1
		for y_offset in range(-1,2):  # Checking y: -1, 0, 1
			var neighbor_cell = ant_grid_pos + Vector2(x_offset, y_offset)

			# Check for pheromones in food grid
			if auto_load.food_pheromones_grid.has(neighbor_cell):
				var pheromone_strength = 0.0
				for pheromone in auto_load.food_pheromones_grid[neighbor_cell]:
					pheromone_strength += pheromone.strength

				# If this cell has more pheromones, update the max_pheromone_cell
				if pheromone_strength > max_pheromone_strength:
					max_pheromone_strength = pheromone_strength
					max_pheromone_cell = neighbor_cell
	
	# If no pheromones are found, return a neutral direction
	if max_pheromone_strength == 0:
		return Vector2.ZERO
	
	# Convert the max pheromone grid cell to world position
	return auto_load.grid_to_world_pos(max_pheromone_cell)



# Helper function to get the 8 surrounding cells (including diagonals) for a given grid cell
func get_surrounding_cells(center_cell: Vector2) -> Array:
	var surrounding_cells = []
	for x_offset in range(-1,2):  # Range is -1, 0, 1
		for y_offset in range(-1,2):
			if not (x_offset == 0 and y_offset == 0):  # Skip the center cell itself
				var cell = center_cell + Vector2(x_offset, y_offset)
				surrounding_cells.append(cell)
	return surrounding_cells
