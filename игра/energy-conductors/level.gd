extends Node2D

# === 1. ССЫЛКИ НА УЗЛЫ ===
@onready var grid = $Grid
@onready var win_label = $UI/WinLabel
@onready var restart_button = $UI/RestartButton
@onready var moves_label = $UI/MovesLabel

# === 2. ПРЕФАБЫ ===
# Используем строковые пути вместо preload, если сцены еще не созданы
# var cell_scene = preload("res://Scenes/cell.tscn")
# var wire_scene = preload("res://Scenes/wire.tscn")

# Временное решение: будем создавать узлы вручную или использовать строковые пути
var cell_scene_path = "res://Scenes/cell.tscn"
var wire_scene_path = "res://Scenes/wire.tscn"

# === 3. ПЕРЕМЕННЫЕ УРОВНЯ ===
var grid_width = 5
var grid_height = 5
var cells = []  # Двумерный массив: cells[y][x]

var start_cell = null  # Клетка-источник
var end_cell = null    # Клетка-потребитель

var moves_count = 0
var is_level_complete = false

# === 4. READY ФУНКЦИЯ ===
func _ready():
	# Проверяем существование файлов
	if not FileAccess.file_exists(cell_scene_path):
		print("ОШИБКА: Файл ", cell_scene_path, " не существует!")
		return
	
	# Подключаем кнопку рестарта
	restart_button.connect("pressed", Callable(self, "restart_level"))
	
	# Создаем тестовый уровень
	create_test_level()
	
	# Скрываем сообщение о победе
	win_label.visible = false

# === 5. СОЗДАНИЕ ТЕСТОВОГО УРОВНЯ (упрощенная версия) ===
func create_test_level():
	# Очищаем сетку
	for child in grid.get_children():
		child.queue_free()
	
	# Сбрасываем переменные
	cells = []
	moves_count = 0
	is_level_complete = false
	win_label.visible = false
	start_cell = null
	end_cell = null
	
	# Создаем сетку клеток
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			# Загружаем сцену клетки
			if FileAccess.file_exists(cell_scene_path):
				var cell_scene = load(cell_scene_path)
				var cell = cell_scene.instantiate()
				grid.add_child(cell)
				
				# Определяем тип клетки
				var cell_type = "empty"
				var use_wire = false
				
				# Тестовое расположение:
				if x == 0 and y == 0:
					cell_type = "start"
				elif x == 4 and y == 4:
					cell_type = "end"
				elif (x + y) % 2 == 0:  # Каждая вторая клетка
					cell_type = "wire"
					use_wire = true
				
				# Инициализируем клетку
				if use_wire and FileAccess.file_exists(wire_scene_path):
					cell.init(Vector2(x, y), cell_type, wire_scene_path)
				else:
					cell.init(Vector2(x, y), cell_type)
				
				# Подключаем сигнал от клетки
				if cell.has_signal("wire_rotated_in_cell"):
					cell.connect("wire_rotated_in_cell", Callable(self, "_on_cell_wire_rotated"))
				
				# Сохраняем старт и финиш
				if cell_type == "start":
					start_cell = cell
				elif cell_type == "end":
					end_cell = cell
				
				row.append(cell)
			else:
				# Создаем простую клетку вручную
				var cell = Node2D.new()
				cell.position = Vector2(x * 64, y * 64)
				grid.add_child(cell)
				row.append(cell)
		
		cells.append(row)
	
	# Обновляем UI
	update_moves_display()

# === 6. ОБРАБОТКА ПОВОРОТА ПРОВОДА В КЛЕТКЕ ===
func _on_cell_wire_rotated(cell_position, connections_array):
	# Игнорируем, если уровень уже пройден
	if is_level_complete:
		return
	
	# Увеличиваем счетчик ходов
	moves_count += 1
	update_moves_display()
	
	# Для отладки
	print("Провод повернут в клетке ", cell_position, " Выходы: ", connections_array)
	
	# Проверяем, не победили ли мы
	if check_win_condition():
		show_win_message()

# === 7. ПРОВЕРКА УСЛОВИЯ ПОБЕДЫ (АЛГОРИТМ BFS) ===
func check_win_condition() -> bool:
	# Если нет старта или финиша, победа невозможна
	if not start_cell or not end_cell:
		print("Нет старта или финиша!")
		return false
	
	# Используем BFS (поиск в ширину) для поиска пути
	
	# 1. Подготовка
	var visited = []  # Посещенные клетки
	var queue = []    # Очередь для обхода
	
	# 2. Начинаем со стартовой клетки
	queue.append(start_cell)
	visited.append(start_cell)
	
	# 3. Пока есть клетки в очереди
	while queue.size() > 0:
		# Берем первую клетку из очереди
		var current_cell = queue.pop_front()
		
		# Проверяем, не дошли ли до финиша
		if current_cell == end_cell:
			print("Найден путь до финиша!")
			return true
		
		# 4. Получаем всех соединенных соседей
		var neighbors = get_connected_neighbors(current_cell)
		
		# 5. Добавляем непосещенных соседей в очередь
		for neighbor in neighbors:
			if not neighbor in visited:
				visited.append(neighbor)
				queue.append(neighbor)
	
	# Если очередь опустела и финиш не найден - нет пути
	print("Путь до финиша не найден")
	return false

# === 8. ПОЛУЧЕНИЕ СОЕДИНЕННЫХ СОСЕДЕЙ ДЛЯ КЛЕТКИ ===
func get_connected_neighbors(cell) -> Array:
	var neighbors = []
	
	# Все возможные направления
	var directions = ["up", "right", "down", "left"]
	
	for direction in directions:
		# Получаем смещение для этого направления
		var offset = get_direction_vector(direction)
		
		# Вычисляем позицию соседа
		var neighbor_pos = get_grid_position(cell) + offset
		
		# Проверяем, не выходит ли за границы сетки
		if (neighbor_pos.x < 0 or neighbor_pos.x >= grid_width or
			neighbor_pos.y < 0 or neighbor_pos.y >= grid_height):
			continue  # Пропускаем, если за границей
		
		# Получаем клетку-соседа
		var neighbor = cells[neighbor_pos.y][neighbor_pos.x]
		
		# Получаем противоположное направление
		var opposite_direction = get_opposite_direction(direction)
		
		# Проверяем соединение (если у клеток есть методы can_connect_in_direction)
		var cell_can_connect = false
		var neighbor_can_connect = false
		
		if cell.has_method("can_connect_in_direction"):
			cell_can_connect = cell.can_connect_in_direction(direction)
		
		if neighbor.has_method("can_connect_in_direction"):
			neighbor_can_connect = neighbor.can_connect_in_direction(opposite_direction)
		
		if cell_can_connect and neighbor_can_connect:
			neighbors.append(neighbor)
	
	return neighbors

# === 9. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===

# Получаем позицию клетки в сетке
func get_grid_position(cell) -> Vector2:
	if cell.has_method("get_grid_position"):
		return cell.get_grid_position()
	else:
		# Пытаемся вычислить из позиции
		return Vector2(int(cell.position.x / 64), int(cell.position.y / 64))

# Преобразует направление в вектор
func get_direction_vector(direction: String) -> Vector2:
	match direction:
		"up":
			return Vector2(0, -1)
		"down":
			return Vector2(0, 1)
		"left":
			return Vector2(-1, 0)
		"right":
			return Vector2(1, 0)
		_:
			return Vector2.ZERO

# Получает противоположное направление
func get_opposite_direction(direction: String) -> String:
	match direction:
		"up":
			return "down"
		"down":
			return "up"
		"left":
			return "right"
		"right":
			return "left"
		_:
			return ""

# === 10. ПОКАЗ СООБЩЕНИЯ О ПОБЕДЕ ===
func show_win_message():
	is_level_complete = true
	win_label.text = "УРОВЕНЬ ПРОЙДЕН!\nХодов: " + str(moves_count)
	win_label.visible = true
	
	# Анимация победы (опционально)
	var tween = create_tween()
	tween.tween_property(win_label, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(win_label, "scale", Vector2(1.1, 1.1), 0.3)
	tween.tween_property(win_label, "scale", Vector2(1.0, 1.0), 0.3)

# === 11. РЕСТАРТ УРОВНЯ ===
func restart_level():
	create_test_level()

# === 12. ОБНОВЛЕНИЕ СЧЕТЧИКА ХОДОВ ===
func update_moves_display():
	moves_label.text = "Ходы: " + str(moves_count)

# === 13. УПРОЩЕННЫЙ МЕТОД ИНИЦИАЛИЗАЦИИ ===
func create_simple_level():
	# Это временное решение, чтобы протестировать логику без сцен
	print("Создаем упрощенный уровень...")
	
	# Очищаем сетку
	for child in grid.get_children():
		child.queue_free()
	
	# Создаем простые квадратики вместо клеток
	for y in range(5):
		var row = []
		for x in range(5):
			# Создаем простую ноду
			var cell = Node2D.new()
			cell.position = Vector2(x * 64, y * 64)
			grid.add_child(cell)
			
			# Добавляем спрайт для визуализации
			var sprite = Sprite2D.new()
			# Можно добавить цветной квадрат
			cell.add_child(sprite)
			
			row.append(cell)
		cells.append(row)
	
	print("Упрощенный уровень создан")

func _on_restart_button_pressed() -> void:
	pass # Replace with function body.
