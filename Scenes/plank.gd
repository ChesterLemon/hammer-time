extends Area2D

var state = 0
var all_planks
var all_nails
var plank_move_speed = 150

func _ready() -> void:
	all_planks = get_tree().get_nodes_in_group("planks")
	all_nails = get_children()

func _process(delta: float) -> void:
	match state:
		0: pass
		1: 
			if position.y <= -532: #if plank is fully off top of screen, move to bottom of screen
				position.y = 552
				update_nails()
				reroll_nails()
			if not %GameManager.nail_ready: global_position.y -= plank_move_speed * delta #shift plank up once nail is sunk
			else: 
				plank_move_speed = 150
				state = 0

func move_up(): #set move target for all planks (called when nail is sunk)
	for plank in all_planks: plank.state = 1 #set state to 1 in _process()

func update_nails(): #reset x position of all nails in the plank, called when plank is ready to be recycled
	for nails in all_nails:
		if nails.is_in_group("nails"): nails.position.x = 6.75

func reroll_nails():
	for nails in all_nails:
		if nails.is_in_group("nails"):
			var x = randi_range(1, 15)
			if x == 10: #1 in 15 chance to spawn special nail based on current_hammer
				match %GameManager.current_hammer:
					0: pass
					1: nails.set_rainbow()
					2: nails.set_gold()
					3: nails.set_lightning()
			else: nails.set_default()
