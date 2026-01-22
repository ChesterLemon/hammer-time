extends Area2D

#uprgadeable values
var power_min = 10
var swing_speed = 600
var move_speed = 600
var crit_min = 0

#used for temporary buffs such as in dk_ability
var dking = false
var temp_crit_min
var temp_swing_speed
var temp_move_speed
var temp_anim_speed

#amounts to increment variables per upgrade
var swing_speed_increment = 25
var move_speed_increment = 50

var swing_power = 10 #minimum possible power for current swing, updated by update_swing_power()
var can_swing = true #used to prevent swinging unless hammer is fully back in starting position

#tracking hammer's current state
var is_moving = false #moving forward toward a nail
var is_retreating = false #moving away from nail to home position
@onready var hit_box: CollisionShape2D = $CollisionShape2D

func _process(delta: float) -> void:
	if Input.is_action_just_released("left_click") and can_swing and not %ShopMenu.visible:
		$AnimationPlayer.play("swing")
		hit_box.disabled = false #re-enable collisions
		can_swing = false
		set_swing_power() #set the power of the current swing
	if is_moving:
		global_position.x -= swing_speed * delta #move toward the current nail
	if is_retreating:
		if position.x < 32:
			global_position.x += move_speed * delta #move away from the nail until home
		else: 
			is_retreating = false
			can_swing = true

#### UPGRADES ####
func update_swing_speed(): #update swing animation speed, called by upgrade menu
	$AnimationPlayer.speed_scale += .2
	move_speed += move_speed_increment
	swing_speed += swing_speed_increment

func update_swing_power():
		power_min += 5
	
func update_crit_chance():
	crit_min += 1

func set_swing_power(): #check for crit swing, or set siwng power within power range
	var crit = randi_range(crit_min, 10)
	if crit == 10: swing_power = 120
	else:
		swing_power = randf_range(power_min, power_min * 2)
		if swing_power >= 100: #anything over 100 qualifies as a crit, adjust accordingly
			swing_power = 120

func get_swing_power():
	return swing_power


#### ABILITIES ####
func dk_ability():
	if not dking:
		dking = true
		temp_crit_min = crit_min
		temp_swing_speed = swing_speed
		temp_move_speed = move_speed
		temp_anim_speed = $AnimationPlayer.speed_scale
		crit_min = 10
		swing_speed = 600 + (10 * swing_speed_increment)
		move_speed = 900 + (10 * move_speed_increment)
		$AnimationPlayer.speed_scale = 3.0
	$DkTimer.start()
	%EffectAnimation.play("dk")
	%DkMusic.play()


#### SIGNALS ####
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	is_moving = true #once hammer is done swinging forward, move toward nail

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("nails") and not is_retreating:
		is_moving = false
		set_deferred("is_retreating", true)
		if swing_power == 120: #play crit sound and show damage
			$CritSound.pitch_scale = randf_range(0.85, 1.15) #randomize crit sound pitch
			GameManager.display_damage(100, hit_box.global_position - Vector2(70, 50), 50, true)
			$CritSound.play()
			%Camera2D.screen_shake(5, 0.5)
			
		else:
			GameManager.display_damage(int(swing_power), hit_box.global_position - Vector2(30, 40), 25, false)
			%Camera2D.screen_shake(2, 0.25)
		
		$HitSound.pitch_scale = randf_range(0.85, 1.15) #randomize hit sound pitch
		$HitSound.play() #play only when hitting a nail while swinging
		set_deferred("hit_box.disabled", true) #disable collisions while hammer is retreating
	elif area.is_in_group("planks"): 
		area.move_up() #in the event a nail hitting the plank doesn't register, allow hammer to trigger the effect instead
		is_moving = false
		set_deferred("is_retreating", true)

func _on_dk_timer_timeout() -> void:
	dking = false
	crit_min = temp_crit_min
	swing_speed = temp_swing_speed
	move_speed = temp_move_speed
	$AnimationPlayer.speed_scale = temp_anim_speed
	%EffectAnimation.play("default")
	%DkMusic.stop()
