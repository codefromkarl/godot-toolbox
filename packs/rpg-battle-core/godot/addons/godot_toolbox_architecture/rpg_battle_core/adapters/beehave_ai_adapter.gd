extends Resource
class_name RPGBeehaveAIAdapter


func adapter_id() -> StringName:
	return &"beehave"


func is_optional() -> bool:
	return true


func can_use_runtime() -> bool:
	return ClassDB.class_exists("BeehaveTree") or ClassDB.class_exists("BeehaveNode")
