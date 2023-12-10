extends Node3D

const NEIGHBORS = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]
@export var slack: Vector2i = Vector2i(4, 4)
@export var extents: Vector2i = Vector2i(32, 32)
@export var escape_threshold: int = 24
var handled_floors: Array[Vector2i] = []
var position2d: Vector2i

signal regenerated

func enqueue_tile(where: Vector2i, remove: bool = false):
	if remove and where in handled_floors:
		handled_floors.erase(where)
	elif where not in handled_floors:
		handled_floors.append(where)

func regenerate():
	handled_floors = []
	
	var escape = escape_threshold
	var center = extents / 2.0
	
	# Seed with random data
	for i in range(center.x - slack.x, center.x + slack.x + 1):
		for j in range(center.y - slack.y, center.y + slack.y + 1):
			if (randi() % 2) == 1:
				handled_floors.append(Vector2i(i, j))
				
	# Escape algorithm with "maze" cellular automaton
	while escape > 0:
		for i in range(1, extents.x - 1):
			for j in range(1, extents.y - 1):
				var here = Vector2i(i, j)
				var counted = NEIGHBORS.map(func(a): return a + here)
				match counted.filter(func (a): return a in handled_floors).size():
					0, 6, 7, 8:
						enqueue_tile(here, true)
					1, 2, 4, 5:
						continue
					3:
						enqueue_tile(here)
		escape -= 1
		print(escape, " iterations left, ", handled_floors.size(), " work-in-progress floors")
	
	
	var wall_transforms: Array[Transform3D] = []
	var floor_transforms: Array[Transform3D] = []
	for i in range(extents.x):
		for j in range(extents.y):
			var trans = Transform3D(Basis(), Vector3((extents.x / -2.0) + i, 0, (extents.y / -2.0) + j))
			if Vector2i(i, j) in handled_floors:
				floor_transforms.append(trans)
			else:
				wall_transforms.append(trans)

	$FloorInstancer.multimesh.instance_count = extents.x * extents.y
	$WallInstancer.multimesh.instance_count = extents.x * extents.y
	$FloorInstancer.multimesh.visible_instance_count = floor_transforms.size()
	$WallInstancer.multimesh.visible_instance_count = wall_transforms.size()

	for i in range($FloorInstancer.multimesh.visible_instance_count):
		$FloorInstancer.multimesh.set_instance_transform(i, floor_transforms[i])
	for i in range($WallInstancer.multimesh.visible_instance_count):
		$WallInstancer.multimesh.set_instance_transform(i, wall_transforms[i])

	print($FloorInstancer.multimesh.visible_instance_count, " floors")
	print($WallInstancer.multimesh.visible_instance_count, " walls")
	
	regenerated.emit(self)

# Called when the node enters the scene tree for the first time.
func _ready():
	regenerate()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
