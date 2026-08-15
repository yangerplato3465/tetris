class_name KeepsakeData
extends Resource

# Typed definition for a keepsake (permanent trinket). One .tres per keepsake
# lives under Data/Keepsakes/ and is loaded into Keepsakes.keepsakes at startup.
#
# "effects" is an ordered list of effect descriptors applied on purchase, each a
# Dictionary {"type": String, "amount": int/float}. They are interpreted by
# PlayerManager.applyKeepsakeEffect — add new effect types there. Types in use:
# combo_mult, max_hp, heal, max_magic, unlock_hold, next_piece, treasure_box,
# fire_blocks, poison_blocks, gold_blocks (boolean/unlock types ignore "amount").

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""   # shown as the shop tooltip
@export var price: int = 0
@export var frame: int = 0                        # icon frame in Sprite/Cards/Icons.png
@export var effects: Array = []                   # Array of effect descriptors
