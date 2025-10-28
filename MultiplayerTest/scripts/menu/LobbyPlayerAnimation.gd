@tool
extends TextureRect

@export var spriteframes: SpriteFrames
@export var animation_name: String = "default"
@export var do_animation: bool = false

func _ready():
	if not spriteframes or not spriteframes.has_animation(animation_name):
		return

	if Engine.is_editor_hint():
		texture = spriteframes.get_frame_texture(animation_name, 0)
	else:
		if do_animation:
			texture = _spriteframes_to_animated_texture()
		else:
			texture = spriteframes.get_frame_texture(animation_name, 0)

func set_frames(_spriteframes: SpriteFrames):
	spriteframes = _spriteframes
	var current_frame = texture.current_frame
	texture = _spriteframes_to_animated_texture()
	if current_frame < _spriteframes.get_frame_count(animation_name):
		texture.current_frame = current_frame

func _spriteframes_to_animated_texture() -> AnimatedTexture:
	var anim = AnimatedTexture.new()
	anim.speed_scale = spriteframes.get_animation_speed(animation_name)
	anim.frames = spriteframes.get_frame_count(animation_name)
	
	for i in range(anim.frames):
		var tex = spriteframes.get_frame_texture(animation_name, i)
		var new_texture: ImageTexture = ImageTexture.create_from_image(tex.get_image())
		anim.set_frame_texture(i, new_texture)
	
	return anim
