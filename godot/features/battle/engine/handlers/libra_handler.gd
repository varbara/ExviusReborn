class_name LibraHandler
extends EffectHandler

## Opcode 47 (LIBRA / Analyze): scans the target when its hit lands and emits a
## LIBRA_SCANNED event so the battle UI opens the target's detailed info popup.


func handled_types() -> PackedStringArray:
	return PackedStringArray(["LIBRA"])


func schedule(engine: BattleEngine, action: BattleAction, effect: SkillEffect, targets: Array[Combatant]) -> void:
	for target in targets:
		engine.schedule_hit(new_hit(action, effect, target), effect.hit_frames[0])


func resolve(engine: BattleEngine, hit: ScheduledHit) -> void:
	var target: Combatant = engine.combatant(hit.target_id)
	if target == null or not target.is_alive():
		return
	engine.events.append(BattleEventLog.LIBRA_SCANNED, engine.frame, {
		"action": hit.action.id,
		"actor": hit.actor_id,
		"target": target.id,
	})

