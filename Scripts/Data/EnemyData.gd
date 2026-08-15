class_name EnemyData
extends Resource

# Typed definition for a single enemy. One .tres file per enemy lives under
# Data/Enemies/{Tier1,Tier2,Tier3,Boss}/ and is loaded by Consts at startup.
# See Consts._loadEnemyDir for how the tiers are assembled.
#
# Consumers (Main.setStage, PrepareScene, GameoverPanel)
# read these as plain properties (enemy.health, enemy.name, ...), so this stays
# a drop-in replacement for the old dictionaries in Consts.gd.

@export var id: int = 0
# The floor this enemy owns as a mandatory boss; 0 for a normal enemy. Boss
# scheduling lives here rather than in the sort order of Data/Enemies/Boss/, so
# renaming, renumbering or reordering those files can't reshuffle the run.
@export var bossFloor: int = 0
@export var name: String = ""
@export var health: int = 0
@export var reward: int = 0
@export var frame: int = 0          # icon frame in the enemy spritesheet
@export_multiline var description: String = ""
@export var attackSteps: int = 0    # piece drops between enemy attacks
@export var attackDamage: int = 0
@export var attackAddsGarbage: bool = false

# --- Debuffs applied while this enemy is the active stage (Main.setStage) ---
@export var damageReduction: float = 1.0    # multiplier on the player's damage (0.5 = halved)
@export var disablesHold: bool = false      # locks the player out of holding pieces
