extends Node2D

@export var speed : int = 100
@onready var nav_agent : NavigationAgent2D = $CharacterBody2d/NavigationAgent2d
@onready var character : CharacterBody2D = $CharacterBody2d
@onready var nav_region : NavigationRegion2D = $NavigationRegion2d
var show_polys : int = 0

var TileMapHelper = preload("res://TileMapHelper.gd")

func _ready():
	nav_agent.set_target_location(character.position)
	var tilemap : TileMap = $TileMap
	
	nav_region.navpoly = TileMapHelper.tilemap_simple_mesh(
		tilemap,PackedVector2Array([Vector2i.ZERO]),Vector2i.ZERO,0,1)
	nav_region.navpoly.get_mesh().agent_radius = 100

func _physics_process(_delta):
	var velocity : Vector2
	if !nav_agent.is_target_reached():
		var next_path_location = nav_agent.get_next_location()
		velocity = (next_path_location - character.position).normalized() * speed
	else :
		velocity = Vector2.ZERO
	nav_agent.set_velocity(velocity)

func _update_navigation_path(target:Vector2):
	nav_agent.set_target_location(target)

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	character.velocity=safe_velocity
	character.move_and_slide()

func _on_navigation_agent_2d_path_changed():
	print("New navpath, has ",nav_agent.get_nav_path().size()," waypoints.")


func _unhandled_input(event):
	if event.is_action_pressed("click"):
		nav_agent.set_target_location(get_local_mouse_position())
	elif event.is_action_pressed("ui_up"):
		nav_region.navpoly.get_mesh().agent_radius +=1
		print("Navigation mesh agent radius increased to: ",
		nav_region.navpoly.get_mesh().agent_radius)
	elif event.is_action_pressed("ui_down"):
		nav_region.navpoly.get_mesh().agent_radius -=1
		print("Navigation mesh agent radius decreased to: ",
		nav_region.navpoly.get_mesh().agent_radius)
	elif event.is_action_pressed("ui_left"):
		nav_agent.navigation_layers=1
		print("Nav agent now on layer 1 (Tilemap navigation)")
	elif event.is_action_pressed("ui_right"):
		nav_agent.navigation_layers=2
		print("Nav agent now on layer 2 (Generated NavMesh)")
	elif event.is_action_pressed("ui_accept"):
		show_polys = 0
		($Timer as Timer).start()
		print("Repeating show polys")
	else: return

func _on_timer_timeout():
	if show_polys == 0 : print("Showing generated polys")
	if show_polys >= nav_region.navpoly.get_polygon_count():
		($Timer as Timer).stop()
		$Polygon2d.visible = false
	else:
		var vertices : Array = []
		for vertex in nav_region.navpoly.get_polygon(show_polys):
			vertices.append(nav_region.navpoly.get_vertices()[vertex])
		($Polygon2d as Polygon2D).polygon = vertices
		$Polygon2d.visible = true
		show_polys += 1
