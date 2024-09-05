extends CharacterBody2D


#movement variables

var speed := 2500
var current_direction = Vector2.ZERO

var time_since_last_change = 0.0
var direction_change_interval = 1
var window_margin :int = 10

var target_position = null
var ant_has_food : bool = false
var returning_home = false
var random_direction = Vector2.ZERO

var food_found = null # a var to store the food found by an ant for debugging purposes
var fps_counter : int = 0 # to remove the lines from the ants that are not detecting the food now 
var pheromones_processing_counter :int = 0

const PHEROMONE_SCENE : PackedScene = preload("res://Scenes/pheromone/pheromone.tscn")
var food_pheromone_manager_node
var home_pheromone_manager_node

# Called when the node enters the scene tree for the first time.
func _ready():
	food_pheromone_manager_node = get_tree().root.get_node("main_scene").get_node("food_pheromone_manager")
	home_pheromone_manager_node = get_tree().root.get_node("main_scene").get_node("home_pheromone_manager")
	
	$marker_manager/center.position.y = -auto_load.CELL_SIZE
#	$marker_manager/center2.position.y = -2*auto_load.CELL_SIZE
	
	$marker_manager/left.position.y = -auto_load.CELL_SIZE
	$marker_manager/left.position.x = auto_load.CELL_SIZE
#	$marker_manager/left2.position.y = -2*auto_load.CELL_SIZE
#	$marker_manager/left2.position.x = 2*auto_load.CELL_SIZE
	
	$marker_manager/right.position.y = -auto_load.CELL_SIZE
	$marker_manager/right.position.x = -auto_load.CELL_SIZE
#	$marker_manager/right2.position.y = -2*auto_load.CELL_SIZE
#	$marker_manager/right2.position.x = -2*auto_load.CELL_SIZE
#
#	$Node2D/Sprite2D.position = $marker_manager/center.position
#	$Node2D/Sprite2D2.position = $marker_manager/left.position
#	$Node2D/Sprite2D3.position = $marker_manager/right.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fps_counter += 1;
	
	if ant_has_food:
		check_if_ant_reached_home()
		if fps_counter >= auto_load.FOOD_PHEROMONE_DROP_RATE:
			fps_counter = 0
			drop_pheromones(delta , "food")
	else :
		if fps_counter >= auto_load.HOME_PHEROMONE_DROP_RATE:
			fps_counter = 0
			drop_pheromones(delta , "home")
			detect_food()
	
	move(delta)

	# Make the ant face the direction of movement
	if velocity.length() > 0:  # Only rotate when the ant is moving
		rotation = velocity.angle() + deg_to_rad(90)  # Rotate to match the movement direction
	

func move(delta):
	pheromones_processing_counter += 1
	var new_direction = Vector2.ZERO
	
	if pheromones_processing_counter >= 0 :
		pheromones_processing_counter = 0
		new_direction = process_pheromones_and_get_direction()
	
	if new_direction == Vector2.ZERO:
		move_randomly(delta)
	else:
		move_to_target(delta, new_direction)

func move_randomly(delta) -> void:
	time_since_last_change += delta
	
	if current_direction == Vector2.ZERO or time_since_last_change >= direction_change_interval:
		time_since_last_change = 0
		# Slightly adjust the random direction without full recalculation
		var new_direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
		# Blend the new direction with the current one for smoother transitions
		current_direction = current_direction.lerp(new_direction, 0.3).normalized()
	
	is_near_window_edge()
	
	# Apply velocity and movement
	velocity = current_direction * speed * delta
	move_and_slide()

func move_to_target(delta , target_position): # this function will be removed soon 
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed * delta
	move_and_slide()


func is_near_window_edge() -> void:
	var viewport_rect = get_viewport_rect()
	var pos = global_position
	
	if pos.x < window_margin :
		avoid_obstacle(window_margin, 0)
		
	if pos.x > viewport_rect.size.x - window_margin:
		avoid_obstacle(-window_margin , 0)
		
	if pos.y < window_margin :
		avoid_obstacle(0 , window_margin)
		
	if pos.y > viewport_rect.size.y - window_margin:
		avoid_obstacle(0 , -window_margin)


func avoid_obstacle(x , y) -> void:
	# Move the ant away from the obstacle by reversing direction
	position.x += x
	position.y += y
	current_direction = -current_direction


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
		ant_has_food = false
		$CPUParticles2D.emitting = true
		print("ant with food reached home, reset state")

func drop_pheromones(_delta, type : String):
	var pheromone = auto_load.get_pheromone(type)
	
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



func process_pheromones_and_get_direction() -> Vector2:
	var total_strength = 0.0
	var weighted_sum = Vector2.ZERO # it is weighted sum of postions 
	
	var current_cell_pos = auto_load.world_pos_to_grid(global_position)
	var all_markers = $marker_manager.get_children()
	
	var total_influence = Vector2.ZERO

	for marker in all_markers:
		var neighbour_cell = auto_load.world_pos_to_grid(marker.global_position)
		
		if not ant_has_food:
			if auto_load.food_pheromones_grid.has(neighbour_cell):
				for pheromone in auto_load.food_pheromones_grid[neighbour_cell]:
					var distance = global_position.distance_to(pheromone.global_position)
					if distance > 0:
						# Influence decreases with distance and increases with pheromone strength
						var influence_strength = pheromone.strength / distance  # Inverse relation to distance
						var direction = (pheromone.global_position - global_position).normalized()
						total_influence += direction * influence_strength  # Add to total influence
			
		else:
			if auto_load.home_pheromones_grid.has(neighbour_cell):
				for pheromone in auto_load.home_pheromones_grid[neighbour_cell]:
					var distance = global_position.distance_to(pheromone.global_position)
					if distance > 0:
						# Influence decreases with distance and increases with pheromone strength
						var influence_strength = pheromone.strength / distance
						var direction = (pheromone.global_position - global_position).normalized()
						total_influence += direction * influence_strength  # Add to total influence

	# If no influence is detected, return zero movement
	if total_influence == Vector2.ZERO:
		return Vector2.ZERO

	# Return the normalized direction influenced by all nearby pheromones
	return total_influence.normalized()

	# Detect nearby pheromones in the relevant cells
#	for dx in range(-1, 2):
#		for dy in range(-1, 2):
	
#	for marker in all_markers:
#
##			var neighbour_cell = current_cell_pos + Vector2(dx, dy)
#		var neighbour_cell =  auto_load.world_pos_to_grid(marker.global_position)
#
#		if not(ant_has_food):
#			if auto_load.food_pheromones_grid.has(neighbour_cell):
#				for pheromone in auto_load.food_pheromones_grid[neighbour_cell]:
#					var distance = global_position.distance_to(pheromone.global_position)
#					var distance_strength = pheromone.strength / max(distance, 1.0)  # Reduce strength based on distance
#					weighted_sum += pheromone.global_position * distance_strength * pheromone.strength  # Weighting by strength
#					total_strength += distance_strength * pheromone.strength  # Sum of all strengths
#
#		else:
#			if auto_load.home_pheromones_grid.has(neighbour_cell):
#				for pheromone in auto_load.home_pheromones_grid[neighbour_cell]:
#					var distance = global_position.distance_to(pheromone.global_position)
#					var distance_strength = pheromone.strength / max(distance, 1.0)  # Reduce strength based on distance
#					weighted_sum += pheromone.global_position * distance_strength * (auto_load.HOME_PHEROMONE_STRENGTH - pheromone.strength)  # Weighting by inverse strength
#					total_strength += distance_strength * (auto_load.HOME_PHEROMONE_STRENGTH - pheromone.strength)  # Sum of all strengths
#
#	if total_strength == 0:
#		return Vector2.ZERO
#
#	return weighted_sum / total_strength

#
#	var max_strength = 0.0
#	var best_position = Vector2.ZERO
#
#	for marker in all_markers:
#		var neighbour_cell = auto_load.world_pos_to_grid(marker.global_position)
#
#		if not ant_has_food:
#			if auto_load.food_pheromones_grid.has(neighbour_cell):
#				for pheromone in auto_load.food_pheromones_grid[neighbour_cell]:
#					var distance = global_position.distance_to(pheromone.global_position)
#					var distance_strength = pheromone.strength / max(distance, 1.0)  # Reduce strength based on distance
#
#					# Check if this pheromone's strength is the highest
#					if distance_strength > max_strength:
#						max_strength = distance_strength
#						best_position = pheromone.global_position
#
#		else:
#			if auto_load.home_pheromones_grid.has(neighbour_cell):
#				for pheromone in auto_load.home_pheromones_grid[neighbour_cell]:
#					var distance = global_position.distance_to(pheromone.global_position)
#					var distance_strength = pheromone.strength / max(distance, 1.0)  # Reduce strength based on distance
#
#					# Check if this pheromone's strength is the highest (using inverse strength)
#					if distance_strength * (auto_load.HOME_PHEROMONE_STRENGTH - pheromone.strength) > max_strength:
#						max_strength = distance_strength * (auto_load.HOME_PHEROMONE_STRENGTH - pheromone.strength)
#						best_position = pheromone.global_position
#
#	# If no valid pheromones were found, return zero movement
#	if max_strength == 0:
#		return Vector2.ZERO
#
#	# Otherwise, move towards the best position (highest pheromone strength)
#	return (best_position - global_position).normalized()


#func _draw():
#	if food_found != null:
#		var local_ant_pos = to_local(global_position)  # Convert ant's global position to local
#		var local_food_pos = to_local(food_found.global_position)  # Convert food's global position to local
#		draw_line(local_ant_pos, local_food_pos, auto_load.DEBUGGING	_COLOR)
#		print("line drawn for ", food_found.global_position)
#	else:
#		draw_line(Vector2.ZERO, Vector2.ZERO , auto_load.DEBUGGING_COLOR)
#		print("line reset ")
