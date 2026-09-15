class_name KeepsakeData
extends Resource

# Typed definition for a keepsake (permanent trinket). One .tres per keepsake
# lives under Data/Keepsakes/ and is loaded into Keepsakes.keepsakes at startup.
#
# A keepsake is a list of effects, each of which runs on a trigger:
#   {"trigger": String, "type": String, "amount": ..., ...}
#
#   acquire       once, when gained — bought, or granted by an event. Changes run
#                 state outside a battle, so it uses the out-of-battle vocabulary
#                 (RunEffects.EFFECT_KEYS, minus the event-only `call`).
#   battle_start  when a battle begins (Main.stageReady)
#   line_clear    after any line clear is billed (Main.attack). May carry
#                 "min_lines" to fire only on bigger clears — 4 means a Tetris.
#   victory       when the enemy dies (Main.victory)
#
# Every trigger except acquire runs its effects through Main._applyAbilityEffect,
# so they use the *ability* vocabulary (AbilityData.EFFECT_KEYS): a keepsake that
# heals on victory is {"trigger": "victory", "type": "heal", "amount": 3}. A new
# keepsake built from existing triggers and effect types needs no code.
# DataValidator checks every descriptor against these lists at boot.

const TRIGGERS := ["acquire", "battle_start", "line_clear", "victory"]

@export var id: String = ""
@export var name: String = ""
# Descriptive only, same tiers as AbilityData.rarity: nothing rolls or prices off
# it yet — the shop picks uniformly from Keepsakes.pool.
@export_enum("common", "uncommon", "rare") var rarity: String = "common"
@export_multiline var description: String = ""   # shown as the shop tooltip
@export var price: int = 0
@export var frame: int = 0                        # icon frame in Sprite/Cards/Icons.png
# False makes this an event-only keepsake: never rolled in the shop or by
# gain_random_keepsake, obtainable only from an event that grants it by id.
@export var inShop: bool = true
@export var effects: Array = []                   # Array of effect descriptors

# The descriptors that run on `trigger`, in authored order.
func effectsFor(trigger: String) -> Array:
	return effects.filter(func(desc): return desc.get("trigger", "") == trigger)
