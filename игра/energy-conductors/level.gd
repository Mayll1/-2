extends Node2D

@onready var grid = $Grid
@onready var win_label = $UI/WinLabel
@onready var restart_button = $UI/RestartButton
@onready var moves_label = $UI/MovesLabel

# Будем создавать простые узлы вместо загрузки сцен
var cells = []
var moves_count = 0

func _ready():
	print("=== ЗАПУСК ИГРЫ ===")
	
	# Подключаем кнопку
	restart_button.connect("pressed", Callable(self, "_restart_level"))
	
	# Создаем простой уровень без загрузки сцен
	_create_simple_level()
	
	win_label.text = "Тестовый режим"
	win_label.visible = true

func _create_simple_level():
	# Очищаем сетку
	for child in grid.get_children():
		child.queue_free()
	
	# Создаем простые квадратики
	for y in range(5):
		for x in range(5):
			# Просто Node2D с позицией
			var cell = Node2D.new()
			cell.position = Vector2(x * 64, y * 64)
			grid.add_child(cell)
			
			# Добавляем спрайт для видимости
			var sprite = Sprite2D.new()
			cell.add_child(sprite)
			
			# Разные цвета для разных типов
			if x == 0 and y == 0:
				sprite.modulate = Color.GREEN
			elif x == 4 and y == 4:
				sprite.modulate = Color.RED
			elif (x + y) % 2 == 0:
				sprite.modulate = Color.GRAY
			
			print("Создана клетка (", x, ",", y, ")")

func _restart_level():
	print("Рестарт")
	moves_count += 1
	moves_label.text = "Клики: " + str(moves_count)
const CELL_SIZE = 64
var level_scale = 0.8  # Масштаб от 0.5 до 1.0
