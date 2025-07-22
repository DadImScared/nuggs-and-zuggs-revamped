extends CharacterBody2D
signal enemy_died_with_sources(xp_amount: int, damage_sources: Dictionary)

var speed = 50.0
func _physics_process(delta: float) -> void:
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * PlayerStats.speed
	##print("Player global_position: ", global_position, " velocity: ", velocity)
	move_and_slide()
	#if sauce_holder:
		#sauce_holder.global_position = global_position

func _on_mob_died(xp_amount: int, damage_sources):
	PlayerStats.gain_xp(xp_amount)

	enemy_died_with_sources.emit(xp_amount, damage_sources)

#func _on_sauce_selected(sauce):
	#sauce_holder.add_sauce(sauce)
