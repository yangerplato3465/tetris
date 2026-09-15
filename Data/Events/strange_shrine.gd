extends RefCounted

# Reference event exercising every schema feature — a cost, weighted random
# outcomes, a follow-up page with its own title, a keepsake grant, a custom
# function, a hidden option gated on a flag another event sets, a locked option
# gated on the floor, and spoken dialogue lines. Use it as an authoring template.

const EVENT := {
	"id": "strange_shrine",
	"title": "Strange Shrine",
	"start": "intro",
	"pages": {
		"intro": {
			"body": "A crumbling shrine hums with unstable magic. Something glitters in the offering bowl.",
			"options": [
				{
					"text": "Make an offering (pay 25 coins)",
					"cost": [{"type": "coins", "amount": 25}],
					"result": "The shrine flares with warm light. You feel sturdier.",
					"effects": [{"type": "max_hp", "amount": 10}],
				},
				{
					"text": "Grab the glittering thing",
					"outcomes": [
						{
							"weight": 2,
							"result": "A pouch of coins! The shrine doesn't seem to mind.",
							"effects": [{"type": "coins", "amount": 40}],
						},
						{
							"weight": 1,
							"result": "The shrine's magic lashes out and something stirs behind you...",
							"effects": [{"type": "lose_hp", "amount": 10}],
							"next": "guardian",
						},
					],
				},
				# Hidden unless you looted the Abandoned Cart earlier this run.
				{
					"text": "Confess to robbing the cart (pay 30 coins)",
					"requires": [{"flag": "robbed_merchant"}],
					"cost": [{"type": "coins", "amount": 30}],
					"result": "You leave the coins in the bowl. The weight on your chest lifts.",
					"effects": [{"type": "clear_flag", "flag": "robbed_merchant"}, {"type": "max_hp", "amount": 15}],
				},
				{
					"text": "Back away slowly",
					"result": "Some things are best left alone.",
				},
			],
		},
		"guardian": {
			"title": "The Guardian Wakes",
			"body": "A stone sentinel unfolds from the shrine's shadow, grinding to life. It blocks the path forward.",
			"lines": [
				{"speaker": "Guardian", "text": "WHO DISTURBS THE SHRINE?"},
				{"speaker": "Guardian", "text": "TAKE NOTHING. OR BE TAKEN."},
			],
			"options": [
				{
					"text": "Stand your ground (+15 shield)",
					"result": "You brace yourself as the guardian sizes you up... then slowly settles back into stillness.",
					"effects": [{"type": "shield", "amount": 15}],
				},
				{
					"text": "Sprint past it",
					"result": "You bolt. A stone fist grazes you as you escape.",
					"effects": [{"type": "lose_hp", "amount": 5}],
				},
				{
					"text": "Pry the gem from its chest (lose 10 HP)",
					# Shown but disabled before floor 4, so the player sees what they're missing.
					"requires": [{"min_floor": 4}],
					"locked_text": "The gem is sealed tight (floor 4+)",
					"cost": [{"type": "hp", "amount": 10}],
					"result": "The gem comes loose with a crack, and the guardian crumbles.",
					"effects": [
						{"type": "gain_random_keepsake", "rarity": "uncommon"},
						{"type": "call", "method": "crumble"},
					],
				},
			],
		},
	},
}

# Custom logic for {"type": "call", "method": "crumble"} — an effect that scales
# off run state, which no descriptor covers. The returned text is appended to the
# option's result.
func crumble() -> String:
	var shield := floori(PlayerManager.coin / 5.0)
	RunEffects.apply({"type": "shield", "amount": shield})
	return "Stone dust hardens on your skin: +%d shield, one per 5 coins you carry." % shield
