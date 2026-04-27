extends RefCounted
class_name ShellFlowBridge

var forwarded_commands: Array[StringName] = []


func forward_pause_request(root: Node) -> bool:
	forwarded_commands.append(&"pause")
	var flow := root.get_node_or_null("FlowCore") if root != null else null
	return flow != null


func forward_resume_request(root: Node) -> bool:
	forwarded_commands.append(&"resume")
	var flow := root.get_node_or_null("FlowCore") if root != null else null
	return flow != null
