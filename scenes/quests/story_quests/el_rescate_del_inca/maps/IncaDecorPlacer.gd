# IncaDecorPlacer.gd (Godot 4.x) - STRICT TYPES
extends Node2D

@export var base_dir: String = "res://scenes/game_elements/props/decoration"
@export var max_per_kind: int = 40
@export var scale_decor: float = 1.0

var CANDIDATES: Dictionary = {
	"torch": PackedStringArray(["torch.tscn", "Torch.tscn", "antorcha.tscn"]),
	"banner": PackedStringArray(["banner.tscn", "estandarte.tscn"]),
	"statue": PackedStringArray(["statue.tscn", "idol.tscn", "idolo.tscn", "stela.tscn"]),
	"rock": PackedStringArray(["rock.tscn", "piedra.tscn", "boulder.tscn"]),
	"bush": PackedStringArray(["bush.tscn", "arbusto.tscn"]),
	"pot": PackedStringArray(["jar.tscn", "vasija.tscn", "olla.tscn"]),
	"flower": PackedStringArray(["flower.tscn", "flor.tscn"]),
	"deco": PackedStringArray(["deco.tscn", "decor_*.tscn"]),
}

func _ready() -> void:
	var found: Dictionary = {}
	for kind in CANDIDATES.keys():
		var arr: PackedStringArray = CANDIDATES[kind]
		found[kind] = _find_first_existing(arr)

	var root: Node = get_parent()
	var mazes: Node = root.get_node_or_null("TileMapLayers/Mazes")
	var arenas: Node = root.get_node_or_null("TileMapLayers/Arenas")
	var decor: Node2D = root.get_node_or_null("TileMapLayers/Decor")
	if decor == null:
		decor = Node2D.new()
		decor.name = "Decor"
		var tml: Node = root.get_node("TileMapLayers")
		tml.add_child(decor)

	_place_on_maze_edges(mazes, decor, String(found.get("torch")), 48.0, 256.0, 0.0)
	_place_on_maze_edges(mazes, decor, String(found.get("banner")), 96.0, 384.0, 24.0)

	_place_statues_in_arenas(arenas, decor, String(found.get("statue")))
	_place_border_stones(root, decor, String(found.get("rock")))
	_place_small_details(root, decor, String(found.get("pot")), String(found.get("flower")))


func _find_first_existing(names: PackedStringArray) -> String:
	var dir: DirAccess = DirAccess.open(base_dir)
	if dir:
		for n in names:
			var p: String = base_dir.path_join(n)
			if ResourceLoader.exists(p):
				return p
		dir.list_dir_begin()
		while true:
			var f: String = dir.get_next()
			if f == "":
				break
			if dir.current_is_dir() and not f.begins_with("."):
				for n in names:
					var p2: String = base_dir.path_join(f).path_join(n)
					if ResourceLoader.exists(p2):
						return p2
		dir.list_dir_end()
	return ""


func _instance_safe(packed_path: String) -> Node2D:
	if packed_path == "" or not ResourceLoader.exists(packed_path):
		return null
	var ps: PackedScene = load(packed_path)
	if ps == null:
		return null
	var inst: Node = ps.instantiate()
	if inst is Node2D:
		var n2d := inst as Node2D
		n2d.scale = Vector2(scale_decor, scale_decor)
		return n2d
	return null


func _place_on_maze_edges(mazes: Node, parent: Node, packed_path: String, margin: float = 64.0, every_px: float = 256.0, y_offset: float = 0.0) -> void:
	if mazes == null or packed_path == "":
		return
	var count: int = 0
	for child in mazes.get_children():
		if child is StaticBody2D and ("Border" in child.name):
			var sb: StaticBody2D = child as StaticBody2D
			var poly: Polygon2D = sb.get_node_or_null("Poly")
			if poly:
				var aabb: Rect2 = poly.get_item_rect()
				var x0: float = aabb.position.x + margin
				var x1: float = aabb.position.x + aabb.size.x - margin
				var y: float = aabb.position.y + y_offset
				var x: float = x0
				while x <= x1 and count < max_per_kind:
					var node := _instance_safe(packed_path)
					if node:
						node.position = Vector2(x, y)
						parent.add_child(node)
						count += 1
					x += every_px


func _place_statues_in_arenas(arenas: Node, parent: Node, packed_path: String) -> void:
	if arenas == null or packed_path == "":
		return
	for a in arenas.get_children():
		if a is Node2D and ("Arena" in a.name):
			var a_node: Node2D = a as Node2D
			var rect: Rect2
			var first: bool = true
			for sb in a_node.get_children():
				if sb is StaticBody2D:
					var poly: Polygon2D = (sb as StaticBody2D).get_node_or_null("Poly")
					if poly:
						var r: Rect2 = poly.get_item_rect()
						if first:
							rect = r
							first = false
						else:
							rect = rect.merge(r)
			if rect.size != Vector2.ZERO:
				var pad: float = 64.0
				var positions: Array[Vector2] = [
					rect.position + Vector2(pad, pad),
					rect.position + Vector2(rect.size.x - pad, pad),
					rect.position + Vector2(pad, rect.size.y - pad),
					rect.position + Vector2(rect.size.x - pad, rect.size.y - pad),
				]
				for pos in positions:
					var node := _instance_safe(packed_path)
					if node:
						node.position = pos
						parent.add_child(node)


func _place_border_stones(root: Node, parent: Node, packed_path: String) -> void:
	if packed_path == "":
		return
	var floor_poly: Polygon2D = root.get_node_or_null("TileMapLayers/Floor/FloorPoly")
	if floor_poly:
		var r: Rect2 = floor_poly.get_item_rect()
		var step: float = 256.0
		var x: float = r.position.x
		while x <= r.position.x + r.size.x:
			var y_top: float = r.position.y
			var y_bottom: float = r.position.y + r.size.y
			for y in [y_top, y_bottom]:
				var n := _instance_safe(packed_path)
				if n:
					n.position = Vector2(x, y)
					parent.add_child(n)
			x += step


func _place_small_details(root: Node, parent: Node, pot_path: String, flower_path: String) -> void:
	var extras: Array = [
		root.get_node_or_null("TileMapLayers/Decor/Door_M1_TL"),
		root.get_node_or_null("TileMapLayers/Decor/Door_M1_BR"),
		root.get_node_or_null("TileMapLayers/Decor/Door_M2_TR"),
		root.get_node_or_null("TileMapLayers/Decor/Door_M2_BL"),
		root.get_node_or_null("TileMapLayers/Decor/Canal_Top"),
		root.get_node_or_null("TileMapLayers/Decor/Canal_Bottom"),
	]
	for e in extras:
		if e and e is Node2D:
			if pot_path != "":
				var p := _instance_safe(pot_path)
				if p:
					p.position = (e as Node2D).position + Vector2(24, 24)
					parent.add_child(p)
			if flower_path != "":
				var f := _instance_safe(flower_path)
				if f:
					f.position = (e as Node2D).position + Vector2(-24, -24)
					parent.add_child(f)
