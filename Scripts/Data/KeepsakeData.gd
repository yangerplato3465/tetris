class_name KeepsakeData
extends Resource

# Typed definition for a keepsake (permanent trinket). One .tres per keepsake
# lives under Data/Keepsakes/ and is loaded into Keepsakes.keepsakes at startup.
#
# "effects" is an ordered list of effect descriptors applied on purchase, each a
# Dictionary {"type": String, "amount": int/float}. They are interpreted by
# PlayerManager.applyKeepsakeEffect — add new effect types there. Types in use:
# combo_mult, max_hp, heal, max_magic, next_piece, treasure_box,
# fire_blocks, ice_blocks, gold_blocks (boolean/unlock types ignore "amount"),
# battle_orbs, battle_shield, first_clear_damage, first_attack_delay,
# victory_coins, victory_heal, tetris_orbs (per-battle bonuses applied by Main;
# amounts stack).

@export var id: String = ""
@export var name: String = ""
# Descriptive only, same tiers as AbilityData.rarity: nothing rolls or prices off
# it yet — the shop picks uniformly from Keepsakes.pool.
@export_enum("common", "uncommon", "rare") var rarity: String = "common"
@export_multiline var description: String = ""   # shown as the shop tooltip
@export var price: int = 0
@export var frame: int = 0                        # icon frame in Sprite/Cards/Icons.png
@export var effects: Array = []                   # Array of effect descriptors
