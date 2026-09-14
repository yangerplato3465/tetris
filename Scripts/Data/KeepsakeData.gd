class_name KeepsakeData
extends Resource

# Typed definition for a keepsake (permanent trinket). One .tres per keepsake
# lives under Data/Keepsakes/ and is loaded into Keepsakes.keepsakes at startup.
#
# A keepsake is a list of effects, each of which runs on a trigger:
#   {"trigger": String, "type": String, "amount": ..., ...}
#
#   acquire       once, on purchase. Changes run state, so it uses its own small
#                 vocabulary (ACQUIRE_EFFECTS below), applied by
#                 PlayerManager.applyAcquireEffect.
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

# Effect types valid on the "acquire" trigger, mapped to the keys each one reads
# (a trailing "?" marks a key as optional). The boolean unlocks read nothing.
const ACQUIRE_EFFECTS := {
	"combo_mult": ["amount"],
	"max_hp": ["amount"],
	"heal": ["amount"],
	"max_magic": ["amount"],
	"next_piece": ["amount?"],
	"fire_blocks": [],
	"ice_blocks": [],
	"gold_blocks": [],
}

@export var id: String = ""
@export var name: String = ""
# Descriptive only, same tiers as AbilityData.rarity: nothing rolls or prices off
# it yet — the shop picks uniformly from Keepsakes.pool.
@export_enum("common", "uncommon", "rare") var rarity: String = "common"
@export_multiline var description: String = ""   # shown as the shop tooltip
@export var price: int = 0
@export var frame: int = 0                        # icon frame in Sprite/Cards/Icons.png
@export var effects: Array = []                   # Array of effect descriptors

# The descriptors that run on `trigger`, in authored order.
func effectsFor(trigger: String) -> Array:
	return effects.filter(func(desc): return desc.get("trigger", "") == trigger)
