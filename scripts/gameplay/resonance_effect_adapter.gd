class_name KarmanyResonanceEffectAdapter
extends RefCounted


const CARD_SOURCE_ID: StringName = &"resonance"


var deck: KarmanyResonanceDeck = null


func setup(p_deck: KarmanyResonanceDeck) -> bool:
	if p_deck == null:
		return false
	deck = p_deck
	return true


func configure_context(context: KarmanyEffectContext) -> bool:
	if context == null or deck == null:
		return false

	context.draw_cards_handler = Callable(
		self,
		"_draw_cards"
	)
	context.discard_cards_handler = Callable(
		self,
		"_discard_cards"
	)
	return true


func _draw_cards(
	card_source_id: StringName,
	amount: int,
	player: KarmanyPlayerState
) -> bool:
	if card_source_id != CARD_SOURCE_ID:
		return false
	if amount <= 0 or player == null or deck == null:
		return false

	return deck.draw_to_hand(
		player.resonance_hand,
		amount
	) == amount


func _discard_cards(
	card_source_id: StringName,
	amount: int,
	player: KarmanyPlayerState
) -> bool:
	if card_source_id != CARD_SOURCE_ID:
		return false
	if amount <= 0 or player == null:
		return false

	return player.resonance_hand.request_discard(amount)
