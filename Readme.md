This simple project demonstrates Godot 4 navigation


Small_Tiles and Big_Tiles are two sample scenes that both contain a similar structure.
The main difference being that Small_Tiles uses a much smaller tile size.


Clicking will set the mouse position as the target for pathing,
and start the navigation agent heading towards it.


Left and right arrow keys will change the Navigation Mesh that the navigation agent uses,
beteeen the built in TileMap's and the script generated ones.


Using the TileMap's built in navigation on the Small_Tiles scene reveals some of it's weaknesses;
Notably excessive numbers of waypoints and, by extension, poor pathing optimisation.


TileMapHelper contains several scripts that dynamically build a slightly simplified
NavigationPolygon, with the assumption that each tile is either fully navigable or not at all.

Using this NavigationPolygon we can see paths containing fewer waypoints
and better pathing optimisation.


If you intend to use this script it may be wise to save the resulting polygon,
to avoid having to recalculate it.
This optimisation assumes most edges are Horizonntal or vertical;
while it will work for other shapes, performance in generation of the mesh
and improvements seen will suffer.

