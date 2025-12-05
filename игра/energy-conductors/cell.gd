extends Node2D

@onready var wire_container = $WireContainer
@onready var marker = $Marker

# Позиция в сетке уровня
var grid_position: Vector2 = Vector2.ZERO

# Ссылка на узел провода, если он есть
var wire_node: Node = null

# Тип клетки
enum CellType {EMPTY, START, END, WIRE}
var cell_type: CellType = CellType.EMPTY

# Сигнал, когда провод в клетке повернулся
signal cell_wire_rotated(cell)

func init(pos: Vector2, type: CellType = CellType.EMPTY, wire_scene: PackedScene = null):
	grid_position = pos
	position = pos * 64  # размер клетки 64x64
	
	cell_type = type
	
	# Настраиваем маркер в зависимости от типа
	match type:
		CellType.START:
			marker.visible = true
			marker.modulate = Color.GREEN
		CellType.END:
			marker.visible = true
			marker.modulate = Color.RED
		_:
			marker.visible = false
	
	# Если передан сцена провода, создаем провод
	if wire_scene and type == CellType.WIRE:
		set_wire(wire_scene)

# Установка провода в клетку
func set_wire(wire_scene: PackedScene):
	if wire_node:
		wire_node.queue_free()
	
	wire_node = wire_scene.instantiate()
	wire_container.add_child(wire_node)
	
	# Подключаем сигнал поворота провода к этой клетке
	wire_node.connect("wire_rotated", Callable(self, "_on_wire_rotated"))

# Обработка поворота провода в клетке
@warning_ignore("unused_parameter")
func _on_wire_rotated(connections):
	# Передаем сигнал наверх, в уровень
	emit_signal("cell_wire_rotated", self)

# Получить направления выходов провода
func get_connections() -> Array:
	if wire_node and wire_node.has_method("update_connections"):
		# Если у провода есть метод update_connections, вызываем его, чтобы обновить connections
		wire_node.update_connections()
		return wire_node.connections
	return []

# Проверка, есть ли у провода в клетке выход в заданном направлении
func can_connect_to(direction: int) -> bool:
	if wire_node and wire_node.has_method("has_connection"):
		return wire_node.has_connection(direction)
	return false

# Повернуть провод в клетке
func rotate_wire():
	if wire_node and wire_node.has_method("rotate_wire"):
		wire_node.rotate_wire()
