extends Resource
class_name RewardGrant

@export var experience: int = 0
@export var gold: int = 0
@export var item_ids: Array[StringName] = []


func apply_to_party(party: Resource) -> Error:
	if party == null:
		return ERR_INVALID_PARAMETER
	if gold > 0:
		var err: int = party.wallet.add(&"gold", gold)
		if err != OK:
			return err
	for member in party.members:
		if member != null:
			member.grant_experience(experience)
	return OK


func to_dictionary() -> Dictionary:
	var items: Array[String] = []
	for item_id in item_ids:
		items.append(String(item_id))
	return {
		"experience": experience,
		"gold": gold,
		"items": items,
	}
