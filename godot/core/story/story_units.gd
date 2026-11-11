extends RefCounted

## The units the main story hands over, and the switch that marks the point they
## join. The datamine has no column for this -- `unit.joinParty` is 1 for almost
## every unit and no switch type means "unit acquired" -- so each join point is
## recorded here, checked against the story data it comes from.
##
## Fina is the story unit of Season 1: the wiki records her as obtained after
## clearing Lechios Hills in Lanzelt (dungeon 11207), joining at level 20 as her
## 2* entry (unit 100000302).
##
## Loaded by StoryUnitService with preload, so no global class registration is
## involved: the join points must be readable in a headless run too.
## `switch` is the one the stage named by the wiki opens when it is cleared: that is
## the moment the story hands the unit over. `level` is the level the wiki records;
## where it records none the unit joins at 1, at the base rarity it is listed as.
##
## Not listed: Runda. Its wiki page carries no acquisition sentence at all, so there
## is nothing to hang the join on; add it here once that is known.
const GRANTS: Array[Dictionary] = [
	{
		# "obtained after clearing Lechios Hills in Lanzelt", joining at Lv 20 (2*).
		# Lechios Hills - Bandit's Hideout, the dungeon's last stage.
		"switch": "10024400",
		"unit_id": "100000302",
		"level": 20,
		"name": "Fina",
	},
	{
		# "obtained after you clear Galebreak in Dirnado" -- Beast in the Storm.
		"switch": "10057500",
		"unit_id": "100000503",
		"level": 1,
		"name": "Lid",
	},
	{
		# "in Aquapolis Olderion after you clear Water Shrine in Olderion" -- the boss.
		"switch": "10077500",
		"unit_id": "100000403",
		"level": 1,
		"name": "Nichol",
	},
	{
		# "in Magi Nation Mysidia after you clear Magic Library - Showdown of Destiny".
		"switch": "10102600",
		"unit_id": "100000603",
		"level": 1,
		"name": "Sakura",
	},
	{
		# "in Downtown Zoldaad after you clear Invincible Interior in Zoldaad" -- the end.
		"switch": "10095600",
		"unit_id": "100000703",
		"level": 1,
		"name": "Jake",
	},
	{
		# Gifted to every player on starting the Season 3 story: the switch that opens
		# its first land, Wohlstok, once the Season 2 finale has played.
		"switch": "10376002",
		"unit_id": "100025705",
		"level": 1,
		"name": "Blue Mage Fina",
	},
]
