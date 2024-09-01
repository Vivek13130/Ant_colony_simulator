extends CharacterBody2D


#movement variables
var speed := 50
var current_direction = Vector2.ZERO

var time_since_last_change = 0.0
var direction_change_interval = 0.5
var window_margin :int = 10

var target_position = null
var ant_has_food : bool = false
var returning_home = false
var random_direction = Vector2.ZERO

var food_found = null # a var to store the food found by an ant for debugging purposes
var fps_counter : int = 0 # to remove the lines from the ants that are not detecting the food now 

const PHEROMONE_SCENE : PackedScene = preload("res://Scenes/pheromone/pheromone.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#randomize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	if ant_has_food:
		drop_pheromones(delta)
	else :
		detect_food()
	
	if target_position != null:
		move_to_target(delta)
	else:
		move_randomly(delta)

	# Make the ant face the direction of movement
	if velocity.length() > 0:  # Only rotate when the ant is moving
		rotation = velocity.angle() + deg_to_rad(90)  # Rotate to match the movement direction
	

func move_to_target(delta):
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed * delta
	move_and_slide()
	
	if global_position.distance_to(target_position) <= 5:
		if returning_home:
			target_position = null
			velocity = Vector2.ZERO
			returning_home = false
		else:
			returning_home = true
			


func avoid_obstacle(x , y) -> void:
	# Move the ant away from the obstacle by reversing direction
	position.x += x
	position.y += y
	current_direction = -current_direction

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
	velocity = current_direction * speed
	move_and_slide()


func set_new_target(new_target) -> void:
	target_position = new_target

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


func drop_pheromones(delta):
	var pheromone_instance = PHEROMONE_SCENE.instantiate()
	pheromone_instance.position = $".".global_position
	get_tree().root.get_node("main_scene").get_node("pheromone_manager").add_child(pheromone_instance)
	
	

func detect_food() -> void :
	var ant_position = global_position
	var cell_pos = auto_load.world_pos_to_grid(ant_position)
	
	# we have the current cell, we have to detect food in neigh. 8 cells as well as this cell
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var neighbour_cell = cell_pos + Vector2(dx , dy)
			
			if auto_load.food_items_grid.has(neighbour_cell):
				
				for food in auto_load.food_items_grid[neighbour_cell]:
					
					if global_position.distance_to(food.global_position) < auto_load.FOOD_DETECTION_RADIUS:
						$CPUParticles2D.emitting = true
						ant_has_food = true
						target_position = auto_load.home_base_position
#						food_found = food
						#queue_redraw()
					else:
						food_found = null
					

#func _draw():
#	if food_found != null:
#		var local_ant_pos = to_local(global_position)  # Convert ant's global position to local
#		var local_food_pos = to_local(food_found.global_position)  # Convert food's global position to local
#		draw_line(local_ant_pos, local_food_pos, auto_load.DEBUGGING_COLOR)
#		print("line drawn for ", food_found.global_position)
#	else:
#		draw_line(Vector2.ZERO, Vector2.ZERO , auto_load.DEBUGGING_COLOR)
#		print("line reset ")
