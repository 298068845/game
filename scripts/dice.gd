class_name Dice
extends RefCounted

static func d20(modifier: int = 0) -> Dictionary:
	var raw := randi_range(1, 20)
	return {"raw": raw, "modifier": modifier, "total": raw + modifier, "critical": raw == 20, "fumble": raw == 1}

static func roll_stat() -> int:
	# 育成掷骰：2d6+3，稳定落在5~15。
	return randi_range(1, 6) + randi_range(1, 6) + 3

static func damage(sides: int, modifier: int = 0) -> int:
	return max(1, randi_range(1, sides) + modifier)

