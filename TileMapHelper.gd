extends Node2D
class_name TileMapHelper

static func tilemap_simple_mesh(tilemap:TileMap,
navigable_tiles := PackedVector2Array([Vector2i.ZERO]),
start_tile := Vector2i.ZERO,
layer : int = 0,vocal : int = 0):
	var time = Time.get_ticks_msec()
	if vocal > 0 : print("Starting TileMap to NavigationPolygon...")
#	var rects : Array = tilemap_greedy_squares(tilemap,navigable_tiles,start_tile,layer,vocal)
#	var polys : Array = polyfy_rects(rects)
	
	var polys : Array = polyfy_rects(
		tilemap_greedy_squares(tilemap,navigable_tiles,start_tile,layer,vocal),vocal)
	
	if vocal > 0: print("Converting polyfied rects to Nav mesh format...")
	var vertices : PackedVector2Array = []
	var polys_by_index : Array = []
	for poly in polys:
		var index_poly : PackedInt32Array = []
		for vertex in poly :
			vertex *= Vector2(tilemap.tile_set.tile_size)
			var index : int = vertices.find(vertex)
			if index == -1 : #new vertex
				index = vertices.size()
				vertices.append(vertex)
			index_poly.append(index)
		polys_by_index.append(index_poly)
	if vocal > 0 : print("Poly-Rects converted. Building NavigationPolygon...")
	var navpoly := NavigationPolygon.new()
	navpoly.vertices=vertices
	for poly in polys_by_index:
		navpoly.add_polygon(poly)
	time = Time.get_ticks_msec() - time
	if vocal > 0 : print("NavigationPolygon built.
		TileMap to Navigation Mesh complete!
		Time Taken(ms): ",time)
	return navpoly

static func get_rect_verteces(rect:Rect2i) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2i(rect.end.x,rect.position.y),
		rect.end,
		Vector2i(rect.position.x,rect.end.y)
	])

static func polyfy_rects(rects:Array,vocal:int=0):
	if vocal > 0 : print("Poly-fying Rects...")
	var polys : Array = []
	for rect in rects:
		var polyfied_rect : Array = []
		var rectverts : Array = get_rect_verteces(rect)
		for i in range(rectverts.size()):
			var polyfied_rect_side : Array = []
			for subrect in rects:
				for subrectvert in get_rect_verteces(subrect):
					if get_line(rectverts[i],rectverts[(i+1)%rectverts.size()],true).has(subrectvert):
						if !polyfied_rect_side.has(subrectvert):
							polyfied_rect_side.append(subrectvert)
			
			polyfied_rect_side.sort()
			if i >= (rectverts.size()/2): #warning-ignore:integer_division
				polyfied_rect_side.reverse()
			polyfied_rect.append_array(polyfied_rect_side)
			
		polys.append(polyfied_rect)
	if vocal > 0 : print("Done poly-fying rects.")
	return polys

static func tilemap_greedy_squares(tilemap:TileMap,
navigable_tiles := PackedVector2Array([Vector2i.ZERO]),
start_tile := Vector2i.ZERO,
layer : int = 0,vocal:int=0):
	if vocal >0: print("Getting greedy rects from tilemap...")
	var next_tiles := PackedVector2Array([start_tile])
	var nav_rects : Array = []
	for current_box_start in next_tiles:
		if vocal > 1 : print("Now starting at: ",current_box_start)
		if is_point_in_rects(current_box_start,nav_rects):
			if vocal > 2 : print("Already done, skipping...")
			continue
		
		var current_box := Rect2i(current_box_start,Vector2i.ZERO)
		while true: #extend along +X
			if !navigable_tiles.has(tilemap.get_cell_atlas_coords(0,current_box.grow_side(SIDE_RIGHT,1).end)):
				break
			elif is_point_in_rects(current_box.grow_side(SIDE_RIGHT,1).end,nav_rects):
				break
			else:
				current_box = current_box.grow_side(SIDE_RIGHT,1)
		
		while true: #extend along -X
			if !navigable_tiles.has(tilemap.get_cell_atlas_coords(0,current_box.grow_side(SIDE_LEFT,1).position)):
				break
			elif is_point_in_rects(current_box.grow_side(SIDE_LEFT,1).position,nav_rects):
				break
			else:
				current_box = current_box.grow_side(SIDE_LEFT,1)
		
		var top_row : PackedVector2Array =[]
		while true: #extend along -Y
			var test_row = check_line_navigable(
				current_box.grow_side(SIDE_TOP,1).position,
				Vector2i(current_box.end.x,current_box.position.y-1),
				tilemap,navigable_tiles,nav_rects,layer)
			assert(test_row != null,"Null checkline")
			if test_row is bool: #keep expanding in -y
				current_box = current_box.grow_side(SIDE_TOP,1)
			else:
				top_row=test_row
				break
		
		var bottom_row : PackedVector2Array =[]
		while true: #extend along +Y
			var test_row= check_line_navigable(
				Vector2i(current_box.position.x,current_box.end.y+1),
				current_box.grow_side(SIDE_BOTTOM,1).end,
				tilemap,navigable_tiles,nav_rects,layer)
			
			if test_row is bool: #keep expanding in +y
				current_box = current_box.grow_side(SIDE_BOTTOM,1)
			else: #rect is done
				bottom_row = test_row
				break
		
		var new_tiles: PackedVector2Array = bottom_row
		new_tiles.append_array(top_row)
		new_tiles.append_array(other_sides_navigable(current_box,tilemap,navigable_tiles,nav_rects,layer))
		for tile in new_tiles:
			if not (is_point_in_rects(tile,nav_rects) or next_tiles.has(tile)):
				next_tiles.append(tile)
		
		if vocal > 2 : print("Current box done: ",current_box)
		nav_rects.append(current_box.grow_individual(0,0,1,1))
		assert(current_box == current_box.abs())
	if vocal > 0 :print("Done getting greedy rects.")
	if vocal > 3 :print("List of rects: ",nav_rects)
	return(nav_rects)

static func is_point_in_rects(point:Vector2i,rects:Array) -> bool:
	for rect in rects:
		if rect.has_point(point):
			return true
	return false

static func check_line_navigable(start:Vector2i,end:Vector2i,
tilemap:TileMap,navigable_tiles:=PackedVector2Array([Vector2i.ZERO]),nav_rects:Array=[],layer:int=0):
	var line : PackedVector2Array = get_line(start,end)
	var check_next_line : bool = true
	var previous_tile_navigable : bool = false
	var new_tiles : PackedVector2Array = []
	for check_tile in line:
		if is_point_in_rects(check_tile,nav_rects):
			check_next_line=false
		elif (navigable_tiles.has(tilemap.get_cell_atlas_coords(layer,check_tile))):
			if not previous_tile_navigable:
				new_tiles.append(check_tile)
			previous_tile_navigable = true
		else:
			check_next_line = false
			previous_tile_navigable = false
	if !check_next_line:
		assert(new_tiles != null)
		return new_tiles
	else:
		return check_next_line

static func get_line(start: Vector2i,end: Vector2i,skip_end:bool=false) -> PackedVector2Array:
	var line : PackedVector2Array = []
	if start.y==end.y:
		var add_tile : Vector2i = start
		for x in range(min(start.x,end.x),max(start.x,end.x)+1):
			add_tile.x=x
			line.append(add_tile)
		if Vector2i(line[0]) != start:
			line.reverse()
	
	elif start.x==end.x:
		var add_tile : Vector2i = start
		for y in range(min(start.y,end.y),max(start.y,end.y)+1):
			add_tile.y=y
			line.append(add_tile)
		if Vector2i(line[0]) != start:
			line.reverse()
	
	elif start.x-end.x == start.y-end.y:
		var add_tile : Vector2i = start
		for y in range(min(start.y,end.y),max(start.y,end.y)+1):
			add_tile = start + Vector2i.RIGHT*y
			add_tile.y = y
			line.append(add_tile)
		if Vector2i(line[0]) != start:
			line.reverse()
	
	elif start.x-end.x == end.y-start.y:
		var add_tile : Vector2i = start
		for y in range(min(start.y,end.y),max(start.y,end.y)+1):
			add_tile = start + Vector2i.LEFT*y
			add_tile.y = y
			line.append(add_tile)
		if Vector2i(line[0]) != start:
			line.reverse()
	if skip_end:
		line.resize(line.size()-1)
	assert(not line.is_empty())
	return line

static func other_sides_navigable(current_box:Rect2i,tilemap:TileMap,
navigable_tiles:=PackedVector2Array([Vector2i.ZERO]),nav_rects:Array=[],layer:int=0) -> PackedVector2Array:
	var right_column = check_line_navigable(
		Vector2i(current_box.end.x+1,current_box.position.y),
		current_box.grow_side(SIDE_RIGHT,1).end,
		tilemap,navigable_tiles,nav_rects,layer)
	var left_column = check_line_navigable(
		current_box.grow_side(SIDE_LEFT,1).position,
		Vector2i(current_box.position.x-1,current_box.end.y),
		tilemap,navigable_tiles,nav_rects,layer)
	
	var new_start_tiles : PackedVector2Array = []
	if (right_column is PackedVector2Array) : new_start_tiles.append_array(right_column)
	if (left_column is PackedVector2Array) : new_start_tiles.append_array(left_column)
	return new_start_tiles
