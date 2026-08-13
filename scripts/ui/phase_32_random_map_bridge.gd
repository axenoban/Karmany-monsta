class_name KarmanyPhase32RandomMapBridge
extends Node3D

const DEFAULT_MATCH_SEED: int = 32001

@onready var phase_31: KarmanyPhase31Map41Bridge = $Phase31Map41Prototype
@onready var seed_input: LineEdit = $Phase32Overlay/MainMargin/Panel/InnerMargin/VBox/SeedRow/SeedInput
@onready var regenerate_button: Button = $Phase32Overlay/MainMargin/Panel/InnerMargin/VBox/SeedRow/RegenerateButton
@onready var next_seed_button: Button = $Phase32Overlay/MainMargin/Panel/InnerMargin/VBox/SeedRow/NextSeedButton
@onready var reveal_button: Button = $Phase32Overlay/MainMargin/Panel/InnerMargin/VBox/SeedRow/RevealButton
@onready var status_label: Label = $Phase32Overlay/MainMargin/Panel/InnerMargin/VBox/StatusLabel
@onready var selection_label: Label = $Phase32Overlay/MainMargin/Panel/InnerMargin/VBox/SelectionLabel
@onready var fallback_label: Label = $Phase32Overlay/MainMargin/Panel/InnerMargin/VBox/FallbackLabel

var pools: KarmanyMap41TilePools = KarmanyMap41TilePools.new()
var content_session: KarmanyMap41ContentSession = null
var match_seed: int = DEFAULT_MATCH_SEED
var setup_ok: bool = false
var selected_coord: Vector2i = Vector2i.ZERO
var has_selected_coord: bool = false

func _ready() -> void:
	if phase_31 == null or not phase_31.setup_ok:
		push_error("FASE 32 ERROR: Fase 31 no esta disponible.")
		return

	var phase_31_overlay := phase_31.get_node_or_null("Phase31Overlay") as CanvasLayer
	if phase_31_overlay != null:
		phase_31_overlay.visible = false

	if not pools.load_from_project():
		push_error("FASE 32 ERROR: No se pudieron cargar los pools por nivel.")
		return

	_connect_controls()
	_connect_tiles()
	seed_input.text = str(DEFAULT_MATCH_SEED)
	setup_ok = set_seed_and_regenerate(DEFAULT_MATCH_SEED)
	if setup_ok:
		print("FASE 32 VISUAL OK - seed determinista, pools por nivel y revelado seguro activos.")
	else:
		push_error("FASE 32 ERROR: No se pudo generar el mapa inicial.")

func set_seed_and_regenerate(seed_value: int) -> bool:
	var generated := KarmanyMap41ContentGenerator.generate(seed_value, pools)
	if generated == null:
		return false
	if not generated.apply_public_state(phase_31.board_state):
		return false

	content_session = generated
	match_seed = seed_value
	seed_input.text = str(match_seed)
	_clear_selection()
	_refresh_all_tile_views()
	_update_status()
	return true

func reveal_coord(coord: Vector2i) -> bool:
	if content_session == null:
		return false
	if not content_session.reveal_into_board_state(phase_31.board_state, coord):
		return false
	_refresh_tile_view(coord)
	_show_coord(coord)
	return true

func get_assignment_fingerprint() -> String:
	if content_session == null:
		return ""
	return content_session.get_assignment_fingerprint()

func _connect_controls() -> void:
	if not regenerate_button.pressed.is_connected(_on_regenerate_pressed):
		regenerate_button.pressed.connect(_on_regenerate_pressed)
	if not next_seed_button.pressed.is_connected(_on_next_seed_pressed):
		next_seed_button.pressed.connect(_on_next_seed_pressed)
	if not reveal_button.pressed.is_connected(_on_reveal_pressed):
		reveal_button.pressed.connect(_on_reveal_pressed)

func _connect_tiles() -> void:
	for coord_value in phase_31.get_level_map().keys():
		var coord: Vector2i = coord_value
		var tile := phase_31.get_tile_view(coord)
		if tile == null:
			continue
		if not tile.tile_clicked.is_connected(_on_tile_clicked):
			tile.tile_clicked.connect(_on_tile_clicked)

func _on_regenerate_pressed() -> void:
	var text_value: String = seed_input.text.strip_edges()
	if not text_value.is_valid_int():
		status_label.text = "Seed invalida. Usa un numero entero."
		return
	if not set_seed_and_regenerate(text_value.to_int()):
		status_label.text = "No se pudo generar el mapa para esa seed."

func _on_next_seed_pressed() -> void:
	set_seed_and_regenerate(match_seed + 1)

func _on_reveal_pressed() -> void:
	if not has_selected_coord:
		selection_label.text = "Selecciona primero una posicion N1/N2/N3."
		return
	if phase_31.board_state.is_revealed(selected_coord):
		_show_coord(selected_coord)
		return
	if not reveal_coord(selected_coord):
		selection_label.text = "Solo las posiciones N1/N2/N3 ocultas pueden explorarse en este probe."

func _on_tile_clicked(tile: KarmanyHexTile3D) -> void:
	if tile == null:
		return
	selected_coord = tile.coord
	has_selected_coord = true
	_show_coord(selected_coord)

func _show_coord(coord: Vector2i) -> void:
	var level_map := phase_31.get_level_map()
	var level: int = int(level_map.get(coord, -1))
	var level_name: String = KarmanyCanonicalMap41Layout.get_level_short_name(level)
	var public_tile := content_session.get_public_tile_data(phase_31.board_state, coord) if content_session != null else null
	if public_tile == null:
		selection_label.text = "%s %s | OCULTA | identidad no expuesta." % [level_name, coord]
	else:
		selection_label.text = "%s %s | %s — %s" % [level_name, coord, public_tile.tile_id, public_tile.display_name]

func _clear_selection() -> void:
	if phase_31.selected_tile != null:
		phase_31.selected_tile.set_selected(false)
	phase_31.selected_tile = null
	has_selected_coord = false
	selected_coord = Vector2i.ZERO
	selection_label.text = "Selecciona una loseta. N1/N2/N3 no muestran identidad hasta Explorar seleccionada."

func _refresh_all_tile_views() -> void:
	for coord_value in phase_31.get_level_map().keys():
		_refresh_tile_view(coord_value as Vector2i)

func _refresh_tile_view(coord: Vector2i) -> void:
	var tile := phase_31.get_tile_view(coord)
	var cell := phase_31.board_state.get_cell(coord)
	if tile == null or cell == null:
		return
	tile.tile_data = cell.tile_data if cell.revealed else null

func _update_status() -> void:
	status_label.text = "match_seed=%d | misma seed = mismo mapa | geometria F31 intacta" % match_seed
	var counts := pools.get_pool_counts()
	fallback_label.text = "ALPHA TILE POOL FALLBACK | N1 %d→18 | N2 %d→12 | N3 %d→6 | repeticiones registradas en Salida" % [
		int(counts.get(KarmanyTileData.TileLevel.N1, 0)),
		int(counts.get(KarmanyTileData.TileLevel.N2, 0)),
		int(counts.get(KarmanyTileData.TileLevel.N3, 0))
	]
