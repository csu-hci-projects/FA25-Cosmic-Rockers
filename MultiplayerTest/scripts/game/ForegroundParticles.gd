extends GPUParticles2D

var dust_particles = preload("res://resources/dust_particles.tres")
var ash_particles = preload("res://resources/ash_particles.tres")
var leaf_particles = preload("res://resources/leaf_particles.tres")
var glow_particles = preload("res://resources/glow_particles.tres")

var dust_texture = preload("res://sprites/particles/dust_2.png")
var glow_texture = preload("res://sprites/particles/glow.png")
var leaf_texture = preload("res://sprites/particles/leaf.png")

var particle_settings = {
	LevelData.LEVEL_EFFECT.DUST_PARTICLE: {
		"particle": dust_particles,
		"amount": 32,
		"texture": dust_texture,
		"lifetime": 2.5
	},
	LevelData.LEVEL_EFFECT.ASH_PARTICLE: {
		"particle": ash_particles,
		"amount": 48,
		"texture": glow_texture,
		"lifetime": 2.5
	},
	LevelData.LEVEL_EFFECT.LEAF_PARTICLE: {
		"particle": leaf_particles,
		"amount": 80,
		"texture": leaf_texture,
		"lifetime": 4
	},
	LevelData.LEVEL_EFFECT.GLOW_PARTICLE: {
		"particle": glow_particles,
		"amount": 32,
		"texture": glow_texture,
		"lifetime": 2.5
	}
}

func create_level_effects():
	var effects: Array[LevelData.LEVEL_EFFECT] = WorldState.get_level_effects()
	for effect in effects:
		set_data(effect)

func set_data(type: LevelData.LEVEL_EFFECT):
	if !particle_settings.has(type):
		return
	
	var data: Dictionary = particle_settings[type]
	process_material = data["particle"]
	amount = data["amount"]
	lifetime = data["lifetime"]
	texture = data["texture"]
	
