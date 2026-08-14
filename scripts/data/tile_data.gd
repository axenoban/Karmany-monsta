class_name KarmanyTileData
extends Resource


enum TileLevel {
	START,
	N1,
	N2,
	N3,
	SANCTUARY
}

@export_group("Identity")

@export var tile_id: String = ""
@export var display_name: String = ""
@export var level: TileLevel = TileLevel.START
@export var function_tags: PackedStringArray = PackedStringArray()
@export var icon_tags: PackedStringArray = PackedStringArray()


@export_group("Rules v0.74")

@export_multiline var on_explore_text: String = ""
@export_multiline var entry_bonus_text: String = ""
@export_multiline var later_use_text: String = ""
@export_multiline var limit_text: String = ""

@export_group("Universal Interaction F39")

# Canonical gameplay profile for Uso posterior == Interactuar.
# The profile is content metadata: presentation, legality, AI and execution all
# resolve it through KarmanyUniversalTileInteractionService. An empty profile
# is an invalid Phase 39 content definition even when later_use_text exists.
@export var interaction_profile_id: StringName = &""

@export_group("Executable Effects")

@export var on_explore_effects: Array[KarmanyEffectData] = []
@export var entry_effects: Array[KarmanyEffectData] = []
@export var later_use_effects: Array[KarmanyEffectData] = []

@export_group("Board State")

@export var starts_revealed: bool = false
@export var can_rotate_visual: bool = true


func has_universal_interaction_definition() -> bool:
	return (
		not later_use_text.strip_edges().is_empty()
		and interaction_profile_id != &""
	)
