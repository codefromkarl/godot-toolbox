extends Resource
class_name PartyState

const WalletScript := preload("res://addons/godot_toolbox_architecture/rpg_core/party/wallet.gd")

@export var members: Array[Resource] = []
@export var active_member_ids: Array[StringName] = []
@export var reserve_member_ids: Array[StringName] = []
@export var max_active_members: int = 4
@export var wallet: Resource = WalletScript.new()


func add_member(member: Resource) -> Error:
	if member == null or String(member.character_id).is_empty():
		return ERR_INVALID_PARAMETER
	if has_member(member.character_id):
		return ERR_ALREADY_EXISTS
	members.append(member)
	if active_member_ids.size() < max(1, max_active_members):
		active_member_ids.append(member.character_id)
	else:
		reserve_member_ids.append(member.character_id)
	return OK


func remove_member(character_id: StringName) -> Error:
	var index := _member_index(character_id)
	if index < 0:
		return ERR_DOES_NOT_EXIST
	members.remove_at(index)
	active_member_ids.erase(character_id)
	reserve_member_ids.erase(character_id)
	_promote_reserve_members()
	return OK


func has_member(character_id: StringName) -> bool:
	return _member_index(character_id) >= 0


func member(character_id: StringName) -> Resource:
	var index := _member_index(character_id)
	if index < 0:
		return null
	return members[index]


func active_members() -> Array[Resource]:
	var result: Array[Resource] = []
	for id in active_member_ids:
		var next_member := member(id)
		if next_member != null:
			result.append(next_member)
	return result


func reserve_members() -> Array[Resource]:
	var result: Array[Resource] = []
	for id in reserve_member_ids:
		var next_member := member(id)
		if next_member != null:
			result.append(next_member)
	return result


func _member_index(character_id: StringName) -> int:
	for index in range(members.size()):
		if members[index] != null and members[index].character_id == character_id:
			return index
	return -1


func _promote_reserve_members() -> void:
	while active_member_ids.size() < max(1, max_active_members) and not reserve_member_ids.is_empty():
		active_member_ids.append(reserve_member_ids.pop_front())
