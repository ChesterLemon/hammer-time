extends Area2D

var on_screen = true #track whether the nail is on screen or not (used for mjolnir ability)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("hammer") and not area.is_retreating:
		var travel = area.get_swing_power()
		global_position.x -= travel
		
	if area.is_in_group("planks"):
		global_position.x = -218
		%GameManager.nail_ready = false
		area.move_up()
		
		if $AnimatedSprite2D.animation == "default": %GameManager.update_money(1)
		elif $AnimatedSprite2D.animation == "gold": 
			%GameManager.update_money(20)
			$GoldSound.play()
		elif $AnimatedSprite2D.animation == "rainbow": %Hammer.dk_ability()
		else: #lightning nail, sink all visible nails
			var nails = get_tree().get_nodes_in_group("nails")
			for nail in nails:
				if nail.on_screen:
					nail.global_position.x = -218
			%EffectAnimation.play("mjolnir")
			$LightningSound.play()
			var planks = get_tree().get_nodes_in_group("planks")
			for plank in planks: 
				plank.plank_move_speed = 400
				plank.move_up()
	

func set_default():
	$AnimatedSprite2D.play("default")

func set_gold():
	$AnimatedSprite2D.play("gold")
	
func set_rainbow():
	$AnimatedSprite2D.play("rainbow")

func set_lightning():
	$AnimatedSprite2D.play("lightning")

func _on_visible_on_screen_notifier_2d_screen_entered() -> void: on_screen = true

func _on_visible_on_screen_notifier_2d_screen_exited() -> void: on_screen = false
