class_name KarmanyEquipmentCraftResult
extends RefCounted


enum Status {
	SUCCESS,
	INVALID_REQUEST,
	NOT_ACTIVE_PLAYER,
	NO_ACTIONS,
	RARITY_NOT_ALLOWED,
	DUPLICATE,
	INSUFFICIENT_RESOURCES,
	REQUIRES_DISCARD,
	INVALID_DISCARD,
	INVENTORY_ERROR,
	MARKET_ERROR
}


var status: Status = Status.INVALID_REQUEST
var message: String = ""
var equipment: KarmanyEquipmentData = null
var discarded_equipment: KarmanyEquipmentData = null
var paid_cost: Dictionary = {}
var action_consumed: bool = false


func is_success() -> bool:
	return status == Status.SUCCESS
