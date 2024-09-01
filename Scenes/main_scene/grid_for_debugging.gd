extends Node2D

@export var cell_size = auto_load.CELL_SIZE  # Size of each grid cell
@export var grid_color = auto_load.DEBUGGING_COLOR  # Color for grid lines (semi-transparent red)

func _draw():
	var viewport_rect = get_viewport_rect()
	
	# Draw vertical lines
	for x in range(0, viewport_rect.size.x, cell_size):
		draw_line(Vector2(x, 0), Vector2(x, viewport_rect.size.y), grid_color)
	
	# Draw horizontal lines
	for y in range(0, viewport_rect.size.y, cell_size):
		draw_line(Vector2(0, y), Vector2(viewport_rect.size.x, y), grid_color)

func _ready():
	_draw()  # Call update to redraw the grid
