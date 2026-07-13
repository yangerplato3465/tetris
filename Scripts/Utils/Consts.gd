extends Node

# All static game data is authored as typed Resource .tres files under Data/ and
# loaded here at startup. To add/tune content, edit or add a .tres in the Godot
# Inspector — no code change. See EnemyData / AbilityData / CharacterData.
#
# Loading happens in _init() (not _ready) because PlayerManager reads
# Consts.abilities/characters from its own _ready, and _init runs at
# instantiation — before any autoload's _ready — so the data is guaranteed
# populated regardless of autoload ordering.

# Enemy rosters. Files are read in sorted filename order, so the numeric
# prefixes (01_, 02_, ...) on the Boss files preserve the level order that
# MapScene/GameplayScene index into (BossEnemy[0] = level 3 boss, [1] = level 6).
var tier1Enemy: Array = []
var tier2Enemy: Array = []
var tier3Enemy: Array = []
var BossEnemy: Array = []

# Ability templates keyed by id (Dictionary[String] -> AbilityData). PlayerManager
# keeps mutable per-run dictionary copies (abilityState) so upgrades/swaps don't
# touch these; see PlayerManager._initAbilities.
var abilities: Dictionary = {}

# Playable classes (Array[CharacterData]). abilityPool/startingAbilities on each
# reference ids in `abilities`.
var characters: Array = []

func _init():
	tier1Enemy = _loadResourceDir("res://Data/Enemies/Tier1")
	tier2Enemy = _loadResourceDir("res://Data/Enemies/Tier2")
	tier3Enemy = _loadResourceDir("res://Data/Enemies/Tier3")
	BossEnemy = _loadResourceDir("res://Data/Enemies/Boss")
	characters = _loadResourceDir("res://Data/Characters")
	for ability in _loadResourceDir("res://Data/Abilities"):
		abilities[ability.id] = ability

# Load every .tres in a directory, sorted by filename. Handles the ".remap"
# suffix that Godot gives resources in exported builds.
func _loadResourceDir(path: String) -> Array:
	var out: Array = []
	var dir = DirAccess.open(path)
	if dir == null:
		push_error("Consts: could not open data directory " + path)
		return out
	for file in dir.get_files():
		var res_name = file
		if res_name.ends_with(".remap"):
			res_name = res_name.trim_suffix(".remap")
		if res_name.ends_with(".tres"):
			out.append(load(path + "/" + res_name))
	return out

var howToPlay = "-Deal damage by clearing lines on a tetris board
-consecutively clearing lines deals more damage
-you lose a run when the tetrimino reaches the top
-you start with 50 coins, item shop shows up when you
defeat an enemy,gather coins to spend at the shop
-hover on shop items to see what it does
-you can rebind control in the settings menu
-different enemies have certain debuff on you
-There are a total of 15 levels, good luck!"
