extends CharacterBody2D

var speed = 50.0
func _physics_process(delta: float) -> void:
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	move_and_slide()
	#if sauce_holder:
		#sauce_holder.global_position = global_position
	
func _on_mob_died(xp_amount: int):
	PlayerStats.gain_xp(xp_amount)

#func _on_sauce_selected(sauce):
	#sauce_holder.add_sauce(sauce)
