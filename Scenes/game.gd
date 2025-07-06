extends Node2D

@onready var player = $Player

func spawn_mob():
	var new_mob = preload("res://Scenes/enemy.tscn").instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_mob.global_position = %PathFollow2D.global_position
	#var level_multiplier = 1.0 + (PlayerStats.level - 1) * 0.2 # 20% more HP per level
	#new_mob.health = new_mob.health * level_multiplier
	add_child(new_mob)
	#new_mob.add_to_group("enemies")
	#new_mob.connect("died", Callable(player, "_on_mob_died"))
	new_mob.died.connect(Callable(player, "_on_mob_died"))

func _on_timer_timeout() -> void:
	spawn_mob()
