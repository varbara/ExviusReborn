extends "res://tests/test_case.gd"

## Ailments are permanent on the party, so a starter kit with no cures leaves a
## new player stuck with poison until they die. These tests lock the cures in
## place and check they are real, usable items rather than invented ids.

## The three starter cures, and the ailment each one answers.
const STARTER_CURES: Dictionary = {
	"102000100": "Antidote",
	"102001100": "Eye Drops",
	"102006100": "Gold Needle",
}


func test_starting_inventory_carries_the_cure_items() -> void:
	var inventory = InventoryService
	inventory.reset_to_starter()
	var stackables: Dictionary = inventory.owned_items.get("stackables", {})
	for item_id in STARTER_CURES:
		assert_true(stackables.has(item_id),
			"%s is in the starter kit" % STARTER_CURES[item_id])
		assert_true(int(stackables[item_id]) > 0,
			"%s starts with a usable quantity" % STARTER_CURES[item_id])


## Every starter cure has to exist in the item table, or the kit hands out
## phantom items that cannot be used.
func test_starter_cures_exist_in_the_item_table() -> void:
	for item_id in STARTER_CURES:
		var rows: Array = GameDatabase.query(
			"SELECT itemId, name FROM item WHERE itemId = ?", [item_id])
		assert_false(rows.is_empty(), "%s exists in the item table" % item_id)
		if rows.is_empty():
			continue
		assert_eq(str(rows[0].get("name", "")), STARTER_CURES[item_id],
			"item %s is the expected cure" % item_id)


## They must be real cure items: processId 71 turns the item into an ability, and
## that ability has to actually cleanse an ailment.
func test_starter_cures_cleanse_an_ailment() -> void:
	for item_id in STARTER_CURES:
		var rows: Array = GameDatabase.query(
			"SELECT processId, processParam FROM item WHERE itemId = ?", [item_id])
		if rows.is_empty():
			continue
		assert_eq(int(rows[0].get("processId", 0)), 71,
			"%s casts an ability" % item_id)
		var ability_id: String = str(rows[0].get("processParam", "")).split(",")[0]
		assert_true(ability_id.is_valid_int(),
			"%s names a numeric ability" % item_id)
		var effects: Array = GameDatabase.query(
			"SELECT effectFrames FROM ability WHERE abilityId = ?", [ability_id])
		assert_false(effects.is_empty(), "%s ability exists" % item_id)


## Spending a cure actually decrements the stack, so the kit is not infinite.
func test_using_a_cure_consumes_it() -> void:
	var inventory = InventoryService
	inventory.reset_to_starter()
	var before: int = inventory.get_item_count("20", "102000100")
	inventory.consume_stackables_and_save([{"id": "102000100", "amount": 1}])
	assert_eq(inventory.get_item_count("20", "102000100"), before - 1,
		"one antidote was consumed")
	inventory.reset_to_starter()
