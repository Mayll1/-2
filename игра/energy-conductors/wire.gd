extends Area2D

@onready var sprite = $Sprite2D

# Типы проводов
enum WireType {STRAIGHT, CORNER, T_3WAY, CROSS_4WAY}
@export var wire_type: WireType = WireType.STRAIGHT

# Направления
enum Direction {UP, RIGHT, DOWN, LEFT}

const ROTATION_STEP = 90
var current_rotation = 0

# Массив направлений, в которые есть выходы у провода в текущем повороте
var connections: Array = []

# Сигнал, который будет отправляться при повороте провода
signal wire_rotated(connections)

func _ready():
	connect("input_event", Callable(self, "_on_input_event"))
	update_connections()

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		rotate_wire()

func rotate_wire():
	current_rotation += ROTATION_STEP
	if current_rotation >= 360:
		current_rotation = 0
	
	sprite.rotation_degrees = current_rotation
	update_connections()
	
	emit_signal("wire_rotated", connections)
	print("Провод повернут. Угол: ", current_rotation, " Выходы: ", _connections_to_string())

func update_connections():
	connections.clear()
	
	match wire_type:
		WireType.STRAIGHT:
			if current_rotation == 0 or current_rotation == 180:
				connections.append(Direction.LEFT)
				connections.append(Direction.RIGHT)
			else:
				connections.append(Direction.UP)
				connections.append(Direction.DOWN)
		
		WireType.CORNER:
			if current_rotation == 0:
				connections.append(Direction.UP)
				connections.append(Direction.RIGHT)
			elif current_rotation == 90:
				connections.append(Direction.RIGHT)
				connections.append(Direction.DOWN)
			elif current_rotation == 180:
				connections.append(Direction.DOWN)
				connections.append(Direction.LEFT)
			else:  # 270
				connections.append(Direction.LEFT)
				connections.append(Direction.UP)
		
		WireType.T_3WAY:
			if current_rotation == 0:
				connections.append(Direction.LEFT)
				connections.append(Direction.UP)
				connections.append(Direction.RIGHT)
			elif current_rotation == 90:
				connections.append(Direction.UP)
				connections.append(Direction.RIGHT)
				connections.append(Direction.DOWN)
			elif current_rotation == 180:
				connections.append(Direction.RIGHT)
				connections.append(Direction.DOWN)
				connections.append(Direction.LEFT)
			else:  # 270
				connections.append(Direction.DOWN)
				connections.append(Direction.LEFT)
				connections.append(Direction.UP)
		
		WireType.CROSS_4WAY:
			connections.append(Direction.UP)
			connections.append(Direction.RIGHT)
			connections.append(Direction.DOWN)
			connections.append(Direction.LEFT)

# Проверяем, есть ли выход в заданном направлении
func has_connection(direction: Direction) -> bool:
	return direction in connections

# Статический метод для получения противоположного направления
static func get_opposite_direction(direction: Direction) -> Direction:
	match direction:
		Direction.UP:
			return Direction.DOWN
		Direction.DOWN:
			return Direction.UP
		Direction.LEFT:
			return Direction.RIGHT
		Direction.RIGHT:
			return Direction.LEFT
		_:
			return Direction.UP

# Преобразуем направление в вектор смещения
static func direction_to_vector(direction: Direction) -> Vector2:
	match direction:
		Direction.UP:
			return Vector2(0, -1)
		Direction.DOWN:
			return Vector2(0, 1)
		Direction.LEFT:
			return Vector2(-1, 0)
		Direction.RIGHT:
			return Vector2(1, 0)
		_:
			return Vector2.ZERO

# Для отладки: преобразуем connections в строку
func _connections_to_string() -> String:
	var dir_strings = []
	for dir in connections:
		match dir:
			Direction.UP:
				dir_strings.append("UP")
			Direction.RIGHT:
				dir_strings.append("RIGHT")
			Direction.DOWN:
				dir_strings.append("DOWN")
			Direction.LEFT:
				dir_strings.append("LEFT")
	return "[" + ", ".join(dir_strings) + "]"
