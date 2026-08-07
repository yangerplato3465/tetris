class_name CharacterData
extends Resource

# Typed definition for a playable character class. One .tres per character lives
# under Data/Characters/ and is loaded into Consts.characters at startup.
#
# abilityPool is every ability id the class may equip; startingAbilities are the
# ids the run begins with (mapped to skill_1, skill_2, ... in slot order). Both
# reference ability ids defined by the .tres files under Data/Abilities/.
#
# passive is the class trait id, checked by name in the systems that implement it
# (see PlayerManager.hasPassive). Known ids:
#   "overload"      — orbs collected past the energy cap burn HP (Main.onEnergyOverflow)
#   "combo_mastery" — combos scale damage; without it comboMult stays flat
#                     (PlayerManager.selectCharacter)
# An empty passive means the class has none.

@export var id: String = ""
@export var name: String = ""
@export var frame: int = 0           # icon frame in the character spritesheet
@export var tagline: String = ""
@export var maxEnergy: int = 5       # energy (magic orb) cap
@export var passive: String = ""     # passive trait id, "" for none
@export var passiveName: String = ""
@export var passiveDescription: String = ""
@export var abilityPool: Array[String] = []
@export var startingAbilities: Array[String] = []
