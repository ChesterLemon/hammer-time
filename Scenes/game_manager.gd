extends Node2D

var money = 0
var speed_upgrade_count = 0
var speed_upgrade_cost = 1
var strength_upgrade_count = 0
var strength_upgrade_cost = 1
var crit_upgrade_count = 0
var crit_upgrade_cost = 1

var dk_cost = 25
var gold_cost = 50
var mjolnir_cost = 99

var dk_bought = false
var gold_bought = false
var mjolnir_bought = false

var current_hammer = 0 #0: base 1: dk 2: gold 3: mjolnir

var nail_ready = true

var swing_speed_number = 100
var global_font = preload("uid://g4w01g2r5g72")

#update money tracker
func update_money(coins):
	if %Hammer/AnimatedSprite2D.animation == "blue": money += 2 * coins #blue hammer provides double money
	else: money += coins
	%MoneyLabel.text = "$" + str(money)

#animate damage numbers
#create a label singleton for each swing's damage, animate it in a random direction then shrink to zero
func display_damage(damage: int, pos: Vector2, text_font_size: int = 25, is_critical: bool = false):
	var number = Label.new()
	number.text = str(damage)
	number.global_position = pos
	number.z_index = 7
	number.label_settings = LabelSettings.new()
	
	var text_color = "#FFF" #white text for normal hit
	if is_critical: text_color = "#E12300" #red text for crit
	
	#font settings for the label
	number.label_settings.font_color = text_color
	number.label_settings.font = global_font
	number.label_settings.font_size = text_font_size
	number.label_settings.outline_color = "#000"
	number.label_settings.outline_size = 3
	
	call_deferred("add_child", number) #create instance of the label for given swing's damage
	
	await number.resized
	number.pivot_offset = Vector2(number.size / 2) #set pivot point
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true) #set animated properties to play simultaneously (not really needed i don't think)
	tween.tween_property( #animate position to a random point above the starting y position
		number, "position", number.position - Vector2(randf_range(-30, 30), randf_range(20, 40)), 0.5
	).set_ease(Tween.EASE_OUT)
	tween.tween_property( #animate the scale of the number down to zero after a delay of .25 seconds
		number, "scale", Vector2.ZERO, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.25)
	
	await tween.finished
	number.queue_free() #delete the label instance
	


### MENU HANDLING ###

func cant_afford_upgrade():
	%Camera2D.screen_shake(5, 0.5)
	%MoneyLabelAnim.play("cant_afford")
	%BadSelect.play()
	
func cant_afford_hammer(hammer: int):
	%Camera2D.screen_shake(5, 0.5)
	%BadSelect.play()

func update_stats_text(hammer: int):
	match hammer:
		0: %StatsLabel.text = "Increased money per nail"
		1: %StatsLabel.text = "Chance to spawn Rainbow Nails"
		2: %StatsLabel.text = "Chance to spawn Golden Nails"
		3: %StatsLabel.text = "Chance to spawn Lightning Nails"

#switch hammers when a hammer's "USE" button is clicked
func update_hammer(hammer: int):
	match hammer:
		0: 
			%BaseHammerIcon.frame = 0
			%DkHammerIcon.frame = 0
			%GoldHammerIcon.frame = 0
			%MjolnirHammerIcon.frame = 0
			
			%BaseUseButton.disabled = true
			%DkUseButton.disabled = false
			%GoldUseButton.disabled = false
			%MjolnirUseButton.disabled = false
			
			%BaseHammerButton.disabled = true
			%DkHammerButton.disabled = false
			%GoldHammerButton.disabled = false
			%MjolnirHammerButton.disabled = false
			
			update_stats_text(0)
			current_hammer = 0
			
			%Hammer/AnimatedSprite2D.play("blue")
		1: 
			if dk_bought:
				%BaseHammerIcon.frame = 1
				%DkHammerIcon.frame = 1
				%GoldHammerIcon.frame = 0
				%MjolnirHammerIcon.frame = 0
				
				%BaseUseButton.disabled = false
				%DkUseButton.disabled = true
				%GoldUseButton.disabled = false
				%MjolnirUseButton.disabled = false
				
				%BaseHammerButton.disabled = false
				%DkHammerButton.disabled = true
				%GoldHammerButton.disabled = false
				%MjolnirHammerButton.disabled = false
				
				update_stats_text(1)
				current_hammer = 1
				
				%Hammer/AnimatedSprite2D.play("dk")
			else: cant_afford_hammer(1)
		2:
			if gold_bought:
				%BaseHammerIcon.frame = 1
				%DkHammerIcon.frame = 0
				%GoldHammerIcon.frame = 1
				%MjolnirHammerIcon.frame = 0
				
				%BaseUseButton.disabled = false
				%DkUseButton.disabled = false
				%GoldUseButton.disabled = true
				%MjolnirUseButton.disabled = false
				
				%BaseHammerButton.disabled = false
				%DkHammerButton.disabled = false
				%GoldHammerButton.disabled = true
				%MjolnirHammerButton.disabled = false
				
				update_stats_text(2)
				current_hammer = 2
				
				%Hammer/AnimatedSprite2D.play("gold")
			else: cant_afford_hammer(2)
		3:
			if mjolnir_bought:
				%BaseHammerIcon.frame = 1
				%DkHammerIcon.frame = 0
				%GoldHammerIcon.frame = 0
				%MjolnirHammerIcon.frame = 1
				
				%BaseUseButton.disabled = false
				%DkUseButton.disabled = false
				%GoldUseButton.disabled = false
				%MjolnirUseButton.disabled = true
				
				%BaseHammerButton.disabled = false
				%DkHammerButton.disabled = false
				%GoldHammerButton.disabled = false
				%MjolnirHammerButton.disabled = true
				
				update_stats_text(3)
				current_hammer = 3
				
				%Hammer/AnimatedSprite2D.play("mjolnir")
			else: cant_afford_hammer(3)


func _on_swing_speed_button_pressed() -> void:
	if speed_upgrade_count >= 10: #only allow 10 upgrades per skill
		pass
	else:
		if money >= speed_upgrade_cost: #if player can afford the upgrade:
			money -= speed_upgrade_cost 
			%MoneyLabel.text = "$" + str(money) #update current money
			speed_upgrade_count += 1 
			%SpeedCount.text = str(speed_upgrade_count) + "/10" #track number of upgrades per skill
			speed_upgrade_cost *= 2 
			if speed_upgrade_count == 10: %SpeedPrice.text = ""
			else: %SpeedPrice.text = "$" + str(speed_upgrade_cost) #increment cost of next upgrade
			%Hammer.update_swing_speed() #upgrade skill
		else: cant_afford_upgrade() #if can't afford, shake camera and highlight insufficient funds

func _on_swing_power_button_pressed() -> void:
	if strength_upgrade_count >= 10:
		pass
	else:
		if money >= strength_upgrade_cost:
			money -= strength_upgrade_cost
			%MoneyLabel.text = "$" + str(money)
			strength_upgrade_count += 1
			%StrengthCount.text = str(strength_upgrade_count) + "/10"
			strength_upgrade_cost *= 2 
			if strength_upgrade_count == 10: %PowerPrice.text = ""
			else: %PowerPrice.text = "$" + str(strength_upgrade_cost)
			%Hammer.update_swing_power()
		else: cant_afford_upgrade()

func _on_crit_chance_button_pressed() -> void:
	if crit_upgrade_count >= 10:
		pass
	else:
		if money >= crit_upgrade_cost:
			money -= crit_upgrade_cost
			%MoneyLabel.text = "$" + str(money)
			crit_upgrade_count += 1
			%CritChanceCount.text = str(crit_upgrade_count) + "/10"
			crit_upgrade_cost *= 2 
			if crit_upgrade_count == 10: %CritPrice.text = ""
			else: %CritPrice.text = "$" + str(crit_upgrade_cost)
			%Hammer.update_crit_chance()
		else: cant_afford_upgrade()

func _on_shop_button_pressed() -> void:
	%HammerMenu.hide()
	%ShopMenu.visible = !%ShopMenu.visible

func _on_hammers_button_pressed() -> void:
	%HammerMenu.show()

func _on_upgrades_button_pressed() -> void:
	%HammerMenu.hide()


#swap hammers with respective "USE" buttons in Hammer Menu
func _on_base_use_button_pressed() -> void: update_hammer(0)

func _on_dk_use_button_pressed() -> void: update_hammer(1)

func _on_gold_use_button_pressed() -> void: update_hammer(2)

func _on_mjolnir_use_button_pressed() -> void: update_hammer(3)


func _on_dk_buy_button_pressed() -> void:
	if not dk_bought and money >= dk_cost:
		%DkBuyText.hide()
		%DkBuyButton.disabled = true
		dk_bought = true
		money -= dk_cost 
		%MoneyLabel.text = "$" + str(money)
		%HammerBuy.play()
	else: cant_afford_hammer(1)

func _on_gold_buy_button_pressed() -> void:
	if not gold_bought and money >= gold_cost:
		%GoldBuyText.hide()
		%GoldBuyButton.disabled = true
		gold_bought = true
		money -= gold_cost 
		%MoneyLabel.text = "$" + str(money)
		%HammerBuy.play()
	else: cant_afford_hammer(2)

func _on_mjolnir_buy_button_pressed() -> void:
	if not mjolnir_bought and money >= mjolnir_cost:
		%MjolnirBuyText.hide()
		%MjolnirBuyButton.disabled = true
		mjolnir_bought = true
		money -= mjolnir_cost 
		%MoneyLabel.text = "$" + str(money)
		%HammerBuy.play()
	else: cant_afford_hammer(3)

func _on_base_hammer_button_mouse_entered() -> void: update_stats_text(0)

func _on_dk_hammer_button_mouse_entered() -> void: update_stats_text(1)

func _on_gold_hammer_button_mouse_entered() -> void: update_stats_text(2)

func _on_mjolnir_hammer_button_mouse_entered() -> void: update_stats_text(3)


func _on_nail_stop_area_entered(area: Area2D) -> void:
	if area.is_in_group("nails") and area.global_position.x > -210:
		area.global_position.y = -124.0
		nail_ready = true
