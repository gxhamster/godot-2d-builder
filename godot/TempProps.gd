extends TileMap


enum Directions { N = 1, E = 2, S = 4, W = 8 }


export var StirlingEngine: PackedScene
export var Slab: PackedScene
export var Wire: PackedScene
export var Battery: PackedScene

var held_blueprint: Node2D

var wiring := false
var last_hovered: Node2D = null

onready var wires := get_node("../../Wires")
onready var timer := $Timer
onready var indicator := $TextureProgress
onready var tween := $Tween


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		timer.stop()
		indicator.hide()
	
	if event is InputEventKey:
		match event.scancode:
			KEY_1:
				_replace_blueprint(StirlingEngine)
			KEY_2:
				_replace_blueprint(Slab)
			KEY_3:
				_replace_blueprint(Wire)
			KEY_4:
				_replace_blueprint(Battery)
			KEY_Q:
				_clear_blueprint()
	
	if event is InputEventMouseButton and event.pressed:
		var cellv := world_to_map(event.position)
		
		if held_blueprint and event.button_index == BUTTON_LEFT:
			if not owner.is_cell_occupied(cellv):
				var new_position: Vector2 = event.position
				if wiring:
					place_wire(cellv, get_powered_neighbors(cellv))
				else:
					place_entity(cellv)
				replace_neighbor_wires(cellv)

		elif not held_blueprint and event.button_index == BUTTON_RIGHT:
			if owner.is_cell_occupied(cellv):
				indicator.show()
				indicator.rect_position = event.position
				tween.interpolate_property(indicator, "value", 0, 100, 0.2)
				tween.start()
				timer.start()
				yield(timer, "timeout")
				owner.remove_entity(cellv)
				replace_neighbor_wires(cellv)
				indicator.hide()

	elif event is InputEventMouseMotion:
		var cellv := world_to_map(event.position)
		
		if held_blueprint:
			if not owner.is_cell_occupied(cellv):
				held_blueprint.modulate = Color.white
			else:
				held_blueprint.modulate = Color.red
			held_blueprint.global_position = map_to_world(cellv)
			if wiring:
				held_blueprint.set_sprite_for_direction(get_powered_neighbors(cellv))
		else:
			if owner.is_cell_occupied(cellv):
				if last_hovered:
					last_hovered.modulate = Color.white
				
				var entity: Node2D = owner.get_entity_at(cellv)
				entity.modulate = Color.green
				
				last_hovered = entity
			else:
				if last_hovered:
					last_hovered.modulate = Color.white


func get_powered_neighbors(cellv: Vector2) -> int:
	var neighbors := [
		{"direction": Directions.E, "cellv": cellv + Vector2(1, 0)},
		{"direction": Directions.S, "cellv": cellv + Vector2(0, 1)},
		{"direction": Directions.W, "cellv": cellv + Vector2(-1, 0)},
		{"direction": Directions.N, "cellv": cellv + Vector2(0, -1)}
	]
	
	var direction := 0
	
	for neighbor in neighbors:
		if owner.is_cell_occupied(neighbor.cellv):
			direction |= neighbor.direction
	
	return direction


func replace_neighbor_wires(cellv: Vector2) -> void:
	var neighbors := [
		cellv + Vector2(1, 0),
		cellv + Vector2(0, 1),
		cellv + Vector2(-1, 0),
		cellv + Vector2(0, -1)
	]
	
	for neighbor in neighbors:
		var object = owner.get_entity_at(neighbor)
		if object and object is WireEntity:
			var tile_directions := get_powered_neighbors(neighbor)
			replace_wire(object, tile_directions)


func replace_wire(wire: Node2D, directions: int) -> void:
	wire.sprite.region_rect = WireBlueprint.get_region_for_direction(directions)


func place_wire(cellv: Vector2, directions: int) -> void:
	var new_wire: Node2D = held_blueprint.Entity.instance()
	wires.add_child(new_wire)
	new_wire.sprite.region_rect = WireBlueprint.get_region_for_direction(directions)
	
	new_wire.global_position = map_to_world(cellv)
	
	owner.place_entity(new_wire, cellv, Types.TYPE_ACTOR)
	_clear_blueprint()


func place_entity(cellv: Vector2) -> void:
	var new_entity: Node2D = held_blueprint.Entity.instance()
	add_child(new_entity)
	
	new_entity.global_position = map_to_world(cellv)
	
	owner.place_entity(new_entity, cellv, Types.TYPE_ACTOR)
	
	_clear_blueprint()


func _clear_blueprint() -> void:
	if held_blueprint:
		held_blueprint.queue_free()


func _set_blueprint(entity: PackedScene) -> void:
	held_blueprint = entity.instance()
	add_child(held_blueprint)
	
	var cellv := world_to_map(get_global_mouse_position())
	held_blueprint.global_position = map_to_world(cellv)
	
	wiring = entity == Wire
	if wiring:
		held_blueprint.set_sprite_for_direction(get_powered_neighbors(cellv))
	if not owner.is_cell_occupied(cellv):
		held_blueprint.modulate = Color.white
	else:
		held_blueprint.modulate = Color.red


func _replace_blueprint(entity: PackedScene) -> void:
	_clear_blueprint()
	_set_blueprint(entity)


func _snap_to_map(world_position: Vector2) -> Vector2:
	return map_to_world(world_to_map(world_position))
