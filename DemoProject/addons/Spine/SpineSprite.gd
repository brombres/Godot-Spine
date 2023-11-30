@tool
class_name SpineSprite
extends Node2D

const SpineSpriteDefinition = preload("SpineSpriteDefinition.gd")
@export var definition:SpineSpriteDefinition

var data:SpineSpriteData
var mesh_builder:SurfaceTool = SurfaceTool.new()
var mesh:ArrayMesh


func _ready():
	_configure_resources()
	data = SpineSpriteData.new()
	data.configure( self )

func _enter_tree():
	renamed.connect( _configure_resources )

func _exit_tree():
	if renamed.is_connected( _configure_resources ):
		renamed.disconnect( _configure_resources )

func _process( _dt:float ):
	if data: data.update( _dt )
	queue_redraw()

func _draw():
	if prepare_to_draw():
		mesh_builder.clear()
		mesh_builder.begin( Mesh.PRIMITIVE_TRIANGLES )

		data.draw( mesh_builder, _handle_draw )

func _handle_draw( texture_index:int ):
	var atlas = definition.atlas
	if texture_index >= atlas.textures.size(): return

	var texture = atlas.textures[texture_index]
	var normal_map = atlas.normal_maps[texture_index] if texture_index < atlas.normal_maps.size() else null

	if mesh:
		mesh.clear_surfaces()
		mesh_builder.commit( mesh )
	else:
		mesh = mesh_builder.commit()

	_on_draw( mesh, texture, normal_map )

	mesh_builder.clear()
	mesh_builder.begin( Mesh.PRIMITIVE_TRIANGLES )

func _on_draw( mesh:ArrayMesh, texture:Texture2D, normal_map ):
	# Typically called multiple times during the _draw() phase. Override to handle the normal map if desired.
	# 'normal_map' is either "null" or a Texture2D.
	draw_mesh( mesh, texture )

func prepare_to_draw()->bool:
	if not definition or not definition.prepare_to_draw(): return false
	if not data or not data.prepare_to_draw(): return false
	return true

func _configure_resources():
	if definition or not Engine.is_editor_hint(): return

	var viewport = get_viewport()
	if not viewport: return

	var child_count = viewport.get_child_count()
	var scene = viewport.get_child( child_count - 1 )

	if not _configure_resources_with_folder( scene.scene_file_path.get_base_dir() ):  # Try scene folder first
		_configure_resources_with_folder( "res://" )  # Then root resource folder

func _configure_resources_with_folder( folder:String )->bool:
	var def_name = name + ".tres"
	var res = _find_resource( folder, func(filepath):return filepath.get_file()==def_name )
	if res is SpineSpriteDefinition:
		prints( "Auto-configuring SpineSprite %s with SpineSpriteDefinition %s" % [name,res.resource_path] )
		definition = res
		return true

	var skeleton_name = name + ".skel"
	var skeleton = _find_resource( folder, func(filepath):return filepath.get_file()==skeleton_name )
	if not skeleton:
		skeleton_name = name + ".spine-json"
		skeleton = _find_resource( folder, func(filepath):return filepath.get_file()==skeleton_name )
	if not skeleton: return false

	var atlas_name = name + ".atlas"
	var atlas = _find_resource( folder, func(filepath):return filepath.get_file()==atlas_name )
	if not atlas:
		# If there's only one .atlas, use that
		if _count_files( folder, func(filepath):return filepath.ends_with(".atlas") ) == 1:
			atlas = _find_resource( folder, func(filepath):return filepath.ends_with(".atlas") )

	if not atlas: return false

	prints( "Auto-configuring SpineSprite %s with %s and %s" % [name,skeleton.resource_path,atlas.resource_path] )

	definition = SpineSpriteDefinition.new()
	definition.skeleton = skeleton
	definition.atlas = atlas

	return true


func _count_files( folder:String, match_fn:Callable )->int:
	if folder == "res://bin": return 0

	var n = 0

	var dir = DirAccess.open( folder )
	if dir:
		dir.list_dir_begin()

		var filepath = dir.get_next()
		while filepath != "":
			if not filepath.ends_with(".import"):
				if folder == "res://": filepath = folder + filepath
				else:                  filepath = "%s/%s" % [folder,filepath]
				if dir.current_is_dir():
					n += _count_files( filepath, match_fn )
				elif match_fn.call( filepath ):
					n += 1

			filepath = dir.get_next()

		dir.list_dir_end()

	return n

func _find_resource( folder:String, match_fn:Callable ):
	if folder == "res://bin": return null

	var dir = DirAccess.open( folder )
	if dir:
		dir.list_dir_begin()

		var filepath = dir.get_next()
		while filepath != "":
			if not filepath.ends_with(".import"):
				if folder == "res://": filepath = folder + filepath
				else:                  filepath = "%s/%s" % [folder,filepath]
				if dir.current_is_dir():
					var result = _find_resource( filepath, match_fn )
					if result:
						dir.list_dir_end()
						return result
				elif match_fn.call( filepath ):
					dir.list_dir_end()
					return load( filepath )

			filepath = dir.get_next()

		dir.list_dir_end()

	return null

