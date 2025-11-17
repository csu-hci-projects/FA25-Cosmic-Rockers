@tool
extends EditorScript
"""
SpriteFrames Atlas Swapper Tool
Clones a SpriteFrames resource, replaces all AtlasTextures with a new atlas,
and saves the result to a .tres file.
"""

func _run():
	# --- CONFIG ---
	var source_path = "res://sprites/sprite_sheets/player/player_animation.tres"
	var new_atlas_path = "res://sprites/sprite_sheets/player/player_green.png"
	var output_path = "res://sprites/sprite_sheets/player/player_green_animation.tres"
	# ---------------

	var original := load(source_path) as SpriteFrames
	if original == null:
		push_error("❌ Could not load source SpriteFrames at " + source_path)
		return

	var new_atlas := load(new_atlas_path) as Texture2D
	if new_atlas == null:
		push_error("❌ Could not load new atlas texture at " + new_atlas_path)
		return

	var new_frames := clone_spriteframes_with_new_atlas(original, new_atlas)
	if new_frames == null:
		push_error("❌ Failed to create new SpriteFrames resource.")
		return

	var err := ResourceSaver.save(new_frames, output_path)
	if err == OK:
		print("✅ Saved swapped SpriteFrames to: ", output_path)
	else:
		push_error("❌ Failed to save SpriteFrames (error code: %s)" % err)


func clone_spriteframes_with_new_atlas(original: SpriteFrames, new_atlas: Texture2D) -> SpriteFrames:
	var new_frames := SpriteFrames.new()

	for anim_name in original.get_animation_names():
		new_frames.add_animation(anim_name)
		new_frames.set_animation_loop(anim_name, original.get_animation_loop(anim_name))
		new_frames.set_animation_speed(anim_name, original.get_animation_speed(anim_name))

		var frame_count := original.get_frame_count(anim_name)
		for i in range(frame_count):
			var old_tex := original.get_frame_texture(anim_name, i)
			var tex_to_set: Texture2D

			if old_tex is AtlasTexture:
				var old_atlas := old_tex as AtlasTexture
				var new_atlas_tex := AtlasTexture.new()
				new_atlas_tex.atlas = new_atlas
				new_atlas_tex.region = old_atlas.region
				new_atlas_tex.margin = old_atlas.margin
				new_atlas_tex.filter_clip = old_atlas.filter_clip
				tex_to_set = new_atlas_tex
			else:
				tex_to_set = old_tex

			new_frames.add_frame(anim_name, tex_to_set)
			# Frame duration is automatically derived from animation speed

	return new_frames
