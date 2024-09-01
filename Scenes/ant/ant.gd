extends CharacterBody2D


#movement variables
var speed := 50
var current_direction = Vector2.ZERO
var time_since_last_change = 0.0
var direction_change_interval = 0.5
var window_margin :int = 10

var target_position = null
var returning_home = false
var random_direction = Vector2.ZERO

const PHEROMONE_SCENE : PackedScene = preload("res://Scenes/pheromone/pheromone.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if returning_home:
		drop_pheromones(delta)
	
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
			


func avoid_obstacle(x , y):
	# Move the ant away from the obstacle by reversing direction
	position.x += x
	position.y += y
	current_direction = -current_direction

func move_randomly(delta):
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


func set_new_target(new_target):
	target_position = new_target

func is_near_window_edge() :
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
	
	
