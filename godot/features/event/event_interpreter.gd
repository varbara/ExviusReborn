class_name EventInterpreter
extends RefCounted

## Runs one page's script against an EventStage, a frame at a time (CUTSCENE-PLAN.md
## sections 4.2 and 5).
##
## A script is a run of frames, <u8 op> <u16 length> <payload>. Commands run at once
## until one blocks: `wait N` for N frames, `advance` until nothing on the stage is
## moving or waiting on the player. Moves, pans, fades and text start and keep going on
## their own, which is how several things happen at the same time.
##
## Opcodes not handled yet are skipped and counted in `skipped_ops`.

const OP_ADVANCE: int = 0x01
const OP_WAIT: int = 0x02
const OP_GOTO: int = 0x04
const OP_WARP: int = 0x05
const OP_CAMERA: int = 0x06
const OP_MOVE: int = 0x07
const OP_TEXT: int = 0x08
const OP_SET_SWITCH: int = 0x0a
const OP_FACE: int = 0x0b
const OP_VISIBLE: int = 0x0c
const OP_FADE: int = 0x0e
const OP_BGM: int = 0x0f
const OP_FLASH: int = 0x12
const OP_START: int = 0x2e
const OP_BUBBLE: int = 0x46
const OP_PLAY_SSBP: int = 0x55
const OP_STOP_BGM: int = 0x57
const OP_NEXT_LOCATION: int = 0x59
const OP_END: int = 0x5c
const OP_PLAY_VFX: int = 0x5f
const OP_STOP_VFX: int = 0x66
const OP_PANEL: int = 0x67
const OP_PLAY_SE: int = 0x69
const OP_STOP_SE: int = 0x6a
const OP_BANNER: int = 0x6e
const OP_STOP_SSBP: int = 0x6f
const OP_MOVIE: int = 0x74
## Commands one frame may run before the script is taken to be looping.
const MAX_COMMANDS_PER_FRAME: int = 10000

var bin: EventBin
var stage: EventStage
## Shared with EventPlayer: page conditions read it, op 0x0a writes it.
var switches: Dictionary
var code: PackedByteArray
var labels: PackedInt32Array
## Byte offset of the next command.
var pc: int = 0
## Frames stepped so far.
var frame: int = 0
var done: bool = false
## "end" (op 0x5c or the end of the script), "warp" or "error".
var end_reason: String = ""
## Set by op 0x05: {"layer": id, "x": tile x, "y": tile y}.
var warp: Dictionary = {}
## Set by op 0x59, where the game goes once the cutscene is over: {"type": 0 mission
## or 1 town, "id": id}. The prologue names mission 1110101, Mitra the Farplane (9001).
var next_location: Dictionary = {}
var skipped_ops: Dictionary = {}  # op -> count

var _wait: int = 0
var _blocked: bool = false
var _ref_size: int = 5
var _stopped_vfx_ids: Dictionary = {}


func _init(event_bin: EventBin, page: EventBin.Page, event_stage: EventStage, shared_switches: Dictionary) -> void:
	bin = event_bin
	stage = event_stage
	switches = shared_switches
	code = page.code
	labels = page.labels
	_ref_size = bin.actor_ref_size()
	_collect_stopped_vfx_ids()
	if _opens_with_fade_in():
		stage.set_black()


## One frame: counts down a wait, rechecks an `advance`, then runs commands until one
## blocks or the script ends. The stage is ticked by the caller, before this.
func step() -> void:
	if done:
		return
	frame += 1
	if _wait > 0:
		_wait -= 1
		if _wait > 0:
			return
	if _blocked:
		if stage.is_busy():
			return
		_blocked = false
	var budget: int = MAX_COMMANDS_PER_FRAME
	while not done and _wait == 0 and not _blocked:
		budget -= 1
		if budget < 0:
			_finish("error")
			push_error("EventInterpreter: %s runs more than %d commands in one frame" % [bin.path.get_file(), MAX_COMMANDS_PER_FRAME])
			return
		if pc + 3 > code.size():
			_finish("end")
			return
		var op: int = code[pc]
		var length: int = EventBin.u16(code, pc + 1)
		var at: int = pc + 3
		if at + length > code.size():
			_finish("error")
			push_error("EventInterpreter: frame at %d overruns the script" % pc)
			return
		pc = at + length
		_execute(op, at, length)


func _execute(op: int, at: int, length: int) -> void:
	match op:
		OP_ADVANCE:
			_blocked = stage.is_busy()
		OP_WAIT:
			_wait = EventBin.u16(code, at)
		OP_GOTO:
			var label: int = EventBin.u16(code, at)
			if label >= 1 and label <= labels.size():
				pc = labels[label - 1]
			else:
				push_warning("EventInterpreter: goto label %d of %d" % [label, labels.size()])
		OP_WARP:
			warp = {
				"layer": EventBin.u32(code, at),
				"x": EventBin.u32(code, at + 4),
				"y": EventBin.u32(code, at + 8),
			}
			_finish("warp")
		OP_CAMERA:
			var camera_target := Vector2(EventBin.s16(code, at + 1), EventBin.s16(code, at + 3))
			if code[at] != 0:
				camera_target += stage.camera_position()
			stage.camera_to(camera_target, code[at + 6] / 10.0)
		OP_MOVE:
			var actor: EventActor = _actor(at)
			var rest: int = at + _ref_size
			var target := Vector2(EventBin.s16(code, rest + 2), EventBin.s16(code, rest + 4))
			if code[rest + 1] == 1:
				target += actor.position
			actor.move_to(target, code[rest + 6] / 10.0)
		OP_TEXT:
			stage.show_text(EventBin.u32(code, at))
		OP_SET_SWITCH:
			switches[EventBin.u32(code, at)] = code[at + 4]
		OP_FACE:
			_actor(at).face(code[at + _ref_size])
		OP_VISIBLE:
			_actor(at).visible = code[at + _ref_size] != 0
		OP_FADE:
			var color := Color8(code[at + 1], code[at + 2], code[at + 3])
			var frames: int = EventBin.u32(code, at + 6) if length >= 10 else 40
			if code[at] == 0 and _has_upcoming_movie(at + 3 + length):
				pass # Keep screen black until movie begins to avoid flashing staging actors
			else:
				stage.fade(code[at] == 1, color, frames)
		OP_BGM:
			var bgm_length: int = EventBin.u16(code, at)
			var bgm_name: String = code.slice(at + 2, at + 2 + bgm_length).get_string_from_ascii()
			var fade_in_sec: float = 0.0
			var extra_off: int = at + 2 + bgm_length
			if length >= (2 + bgm_length + 4):
				var fade_frames: int = EventBin.u32(code, extra_off)
				if fade_frames > 0:
					fade_in_sec = float(fade_frames) / 60.0
			stage.play_bgm(bgm_name, fade_in_sec)
		OP_FLASH:
			stage.flash(Color8(code[at], code[at + 1], code[at + 2]), code[at + 3], code[at + 4])
		OP_PLAY_SSBP:
			var ssbp: Dictionary = decode_ssbp(code, at, length)
			if not ssbp.is_empty():
				stage.play_ssbp(
					int(ssbp["eff_id"]),
					str(ssbp["file_name"]),
					str(ssbp["anim_ref"]),
					ssbp["pos"] as Vector2,
					int(ssbp["z"]),
					bool(ssbp["screen_space"])
				)
		OP_STOP_BGM:
			var fade_frames: int = EventBin.u32(code, at) if length >= 4 else (code[at] if length >= 1 else 0)
			var fade_sec: float = float(fade_frames) / 60.0 if fade_frames > 0 else 0.0
			stage.stop_bgm(fade_sec)
		OP_PLAY_VFX:
			var vfx: Dictionary = decode_vfx(code, at, length)
			if not vfx.is_empty():
				var vfx_id: int = int(vfx["vfx_id"])
				var file_name: String = str(vfx["file_name"])
				var loop: bool = int(vfx["end_flag"]) != 0 or _stopped_vfx_ids.has(vfx_id) or is_persistent_crystal(file_name)
				stage.play_vfx(
					vfx_id,
					file_name,
					vfx["pos"] as Vector2,
					int(vfx["z"]),
					int(vfx["scale_pct"]),
					loop
				)
		OP_STOP_VFX:
			if length >= 4:
				stage.stop_vfx(EventBin.u32(code, at))
		OP_BANNER:
			var name_length: int = EventBin.u16(code, at)
			var file_name: String = code.slice(at + 2, at + 2 + name_length).get_string_from_ascii()
			stage.show_banner(file_name, EventBin.u32(code, at + 2 + name_length))
		OP_STOP_SSBP:
			if length >= 4:
				stage.stop_ssbp(EventBin.u32(code, at))
			else:
				stage.stop_ssbp(0)
		OP_MOVIE:
			var movie_length: int = EventBin.u16(code, at)
			var movie_name: String = code.slice(at + 2, at + 2 + movie_length).get_string_from_ascii()
			stage.play_movie(movie_name)
			_blocked = stage.is_busy()
		OP_NEXT_LOCATION:
			next_location = {"type": code[at], "id": EventBin.u32(code, at + 1)}
		OP_BUBBLE:
			var rest: int = at + _ref_size
			_actor(at).show_bubble(
				EventBin.u32(code, rest), EventBin.u32(code, rest + 4), EventBin.s32(code, rest + 12))
		OP_PANEL:
			stage.set_panel_visible(code[at] == 1)
		OP_PLAY_SE:
			var se_id: int = EventBin.u32(code, at) if length >= 4 else (code[at] if length >= 1 else 0)
			stage.play_se(se_id)
		OP_STOP_SE:
			var fade_frames: int = EventBin.u32(code, at) if length >= 4 else (code[at] if length >= 1 else 0)
			var fade_sec: float = float(fade_frames) / 60.0 if fade_frames > 0 else 0.0
			stage.stop_se(fade_sec)
		OP_START:
			pass
		OP_END:
			_finish("end")
		_:
			skipped_ops[op] = int(skipped_ops.get(op, 0)) + 1


## The actor an actor-scoped command names: kind 0 is a party member by cast index,
## kind 1 a record by id.
func _actor(at: int) -> EventActor:
	var ref: int = EventBin.u32(code, at + 1) if _ref_size == 5 else EventBin.u16(code, at + 1)
	if code[at] == 0:
		return stage.party_actor(ref)
	return stage.record_actor(bin.slot_of_rid(ref), switches)


func _finish(reason: String) -> void:
	done = true
	end_reason = reason


## Scenes that open on a fade-in start from a black screen.
func _opens_with_fade_in() -> bool:
	var at: int = 0
	while at + 3 <= code.size():
		var op: int = code[at]
		var length: int = EventBin.u16(code, at + 1)
		if op == OP_FADE and length >= 1 and at + 3 < code.size():
			return code[at + 3] == 0
		at += 3 + length
	return false


func _has_upcoming_movie(from: int) -> bool:
	var at: int = from
	while at + 3 <= code.size():
		var op: int = code[at]
		var length: int = EventBin.u16(code, at + 1)
		if op == OP_MOVIE:
			return true
		if op in [0x01, 0x02]:
			at += 3 + length
			continue
		break
	return false


func _collect_stopped_vfx_ids() -> void:
	_stopped_vfx_ids.clear()
	var at: int = 0
	while at + 3 <= code.size():
		var op: int = code[at]
		var length: int = EventBin.u16(code, at + 1)
		if op == OP_STOP_VFX and length >= 4 and at + 7 <= code.size():
			_stopped_vfx_ids[EventBin.u32(code, at + 3)] = true
		at += 3 + length


static func is_persistent_crystal(file_name: String) -> bool:
	var stem: String = file_name.get_file().get_basename()
	if not stem.begins_with("map_crystal_"):
		return false
	for suffix in ["_fadein", "_fadeout", "_escape", "_break"]:
		if stem.ends_with(suffix) or stem.contains(suffix + "_"):
			return false
	return true


## Decodes an OP_PLAY_SSBP (0x55) payload at `at` of `length` bytes.
static func decode_ssbp(bytes: PackedByteArray, at: int, length: int) -> Dictionary:
	var end: int = at + length
	if end > bytes.size() or at + 6 > end:
		return {}
	var eff_id: int = EventBin.u32(bytes, at)
	var pos: int = at + 4
	var file_len: int = EventBin.u16(bytes, pos)
	pos += 2
	if pos + file_len + 2 > end:
		return {}
	var file_name: String = bytes.slice(pos, pos + file_len).get_string_from_ascii()
	pos += file_len
	var pack_len: int = EventBin.u16(bytes, pos)
	pos += 2
	if pos + pack_len + 2 > end:
		return {}
	var pack_name: String = bytes.slice(pos, pos + pack_len).get_string_from_ascii()
	pos += pack_len
	var anim_len: int = EventBin.u16(bytes, pos)
	pos += 2
	if pos + anim_len + 13 > end:
		return {}
	var anim_ref: String = bytes.slice(pos, pos + anim_len).get_string_from_ascii()
	pos += anim_len
	var x: int = EventBin.s32(bytes, pos)
	var y: int = EventBin.s32(bytes, pos + 4)
	var z: int = EventBin.s32(bytes, pos + 8)
	var screen_space: bool = bytes[pos + 12] != 0
	var loop_flag: int = bytes[pos + 13] if pos + 14 <= end else 0
	return {
		"op": OP_PLAY_SSBP,
		"eff_id": eff_id,
		"file_name": file_name,
		"pack_name": pack_name,
		"anim_ref": anim_ref,
		"pos": Vector2(x, y),
		"z": z,
		"screen_space": screen_space,
		"loop_flag": loop_flag,
	}


## Decodes an OP_PLAY_VFX (0x5f) payload at `at` of `length` bytes.
static func decode_vfx(bytes: PackedByteArray, at: int, length: int) -> Dictionary:
	var end: int = at + length
	if end > bytes.size() or at + 2 > end:
		return {}
	var id_str_len: int = EventBin.u16(bytes, at)
	var pos: int = at + 2 + id_str_len
	if pos + 6 > end:
		return {}
	var vfx_id: int = EventBin.u32(bytes, pos)
	var file_len: int = EventBin.u16(bytes, pos + 4)
	pos += 6
	if pos + file_len + 18 > end:
		return {}
	var file_name: String = bytes.slice(pos, pos + file_len).get_string_from_ascii()
	var tail: int = pos + file_len
	var x: int = EventBin.s32(bytes, tail)
	var y: int = EventBin.s32(bytes, tail + 4)
	var z: int = EventBin.s32(bytes, tail + 8)
	var scale_pct: int = bytes[tail + 16]
	var end_flag: int = bytes[tail + 17]
	return {
		"op": OP_PLAY_VFX,
		"vfx_id": vfx_id,
		"file_name": file_name,
		"pos": Vector2(x, y),
		"z": z,
		"scale_pct": scale_pct,
		"end_flag": end_flag,
	}


## Extracts OP_PLAY_SSBP (0x55) and OP_PLAY_VFX (0x5f) commands from a map_blueprint's
## effect_spawner payload_hex bytes.
static func extract_spawner_effects(raw: PackedByteArray) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var idx: int = 0
	while idx + 3 < raw.size():
		var op: int = raw[idx]
		var length: int = EventBin.u16(raw, idx + 1)
		if (op == OP_PLAY_SSBP or op == OP_PLAY_VFX) and length >= 20 and idx + 3 + length <= raw.size():
			var decoded: Dictionary = decode_ssbp(raw, idx + 3, length) if op == OP_PLAY_SSBP else decode_vfx(raw, idx + 3, length)
			var file_name: String = str(decoded.get("file_name", ""))
			if (op == OP_PLAY_SSBP and file_name.ends_with(".ssbp")) or (op == OP_PLAY_VFX and file_name.ends_with(".bmb")):
				out.append(decoded)
				idx += 3 + length
				continue
		idx += 1
	return out
