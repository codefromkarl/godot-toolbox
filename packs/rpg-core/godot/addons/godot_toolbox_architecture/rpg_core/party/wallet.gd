extends Resource
class_name Wallet

@export var currencies: Dictionary = {}


func amount(currency_id: StringName) -> int:
	return int(currencies.get(currency_id, 0))


func add(currency_id: StringName, value: int) -> Error:
	if String(currency_id).is_empty() or value < 0:
		return ERR_INVALID_PARAMETER
	currencies[currency_id] = amount(currency_id) + value
	return OK


func can_spend(currency_id: StringName, value: int) -> bool:
	return value >= 0 and amount(currency_id) >= value


func spend(currency_id: StringName, value: int) -> Error:
	if String(currency_id).is_empty() or value < 0:
		return ERR_INVALID_PARAMETER
	if not can_spend(currency_id, value):
		return ERR_UNAVAILABLE
	currencies[currency_id] = amount(currency_id) - value
	return OK


func to_dictionary() -> Dictionary:
	var result: Dictionary = {}
	for key in currencies.keys():
		result[String(key)] = int(currencies[key])
	return result
