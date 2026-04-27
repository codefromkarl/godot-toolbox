extends Resource
class_name FlowRequest

enum Kind {
	PUSH,
	REPLACE,
	POP,
	COMPLETE,
}

@export var kind: Kind = Kind.PUSH
@export var mode: GameMode
@export var result: FlowResult
@export var payload: Dictionary = {}


static func push(next_mode: GameMode, request_payload: Dictionary = {}) -> FlowRequest:
	var request := FlowRequest.new()
	request.kind = Kind.PUSH
	request.mode = next_mode
	request.payload = request_payload
	return request


static func replace(next_mode: GameMode, request_payload: Dictionary = {}) -> FlowRequest:
	var request := FlowRequest.new()
	request.kind = Kind.REPLACE
	request.mode = next_mode
	request.payload = request_payload
	return request


static func pop(request_payload: Dictionary = {}) -> FlowRequest:
	var request := FlowRequest.new()
	request.kind = Kind.POP
	request.payload = request_payload
	return request


static func complete(flow_result: FlowResult) -> FlowRequest:
	var request := FlowRequest.new()
	request.kind = Kind.COMPLETE
	request.result = flow_result
	return request
