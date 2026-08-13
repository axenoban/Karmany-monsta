class_name KarmanyVisualDirectionController
extends Node


signal visual_direction_applied()


const COLOR_BACKGROUND: Color = Color(0.025, 0.045, 0.060, 1.0)
const COLOR_AMBIENT: Color = Color(0.38, 0.52, 0.56, 1.0)
const COLOR_GROUND: Color = Color(0.045, 0.075, 0.080, 1.0)
const COLOR_HIDDEN: Color = Color(0.075, 0.115, 0.145, 1.0)
const COLOR_START: Color = Color(0.20, 0.39, 0.29, 1.0)
const COLOR_N1: Color = Color(0.30, 0.39, 0.20, 1.0)
const COLOR_N2: Color = Color(0.20, 0.35, 0.37, 1.0)
const COLOR_N3: Color = Color(0.29, 0.25, 0.39, 1.0)
const COLOR_SANCTUARY: Color = Color(0.43, 0.31, 0.16, 1.0)
const COLOR_GOLD: Color = Color(0.88, 0.68, 0.28, 1.0)
const COLOR_JADE: Color = Color(0.27, 0.72, 0.57, 1.0)
const COLOR_MOVE: Color = Color(0.28, 0.76, 0.42, 1.0)
const COLOR_EXPLORE: Color = Color(0.25, 0.59, 0.88, 1.0)
const COLOR_BLOCKED: Color = Color(0.78, 0.25, 0.22, 1.0)
const COLOR_TEXT: Color = Color(0.91, 0.94, 0.91, 1.0)
const COLOR_TEXT_MUTED: Color = Color(0.62, 0.70, 0.68, 1.0)
const COLOR_PANEL: Color = Color(0.035, 0.065, 0.075, 0.94)
const COLOR_PANEL_ALT: Color = Color(0.055, 0.095, 0.100, 0.96)


var board_ux: KarmanyPhase20BoardUXBridge = null
var hud: KarmanyGameHUD = null
var world_environment: WorldEnvironment = null
var key_light: DirectionalLight3D = null
var fill_light: OmniLight3D = null
var rim_light: DirectionalLight3D = null

var _hud_theme: Theme = null
var _configured: bool = false
var _applied: bool = false


func configure(
	p_board_ux: KarmanyPhase20BoardUXBridge,
	p_hud: KarmanyGameHUD,
	p_world_environment: WorldEnvironment,
	p_key_light: DirectionalLight3D,
	p_fill_light: OmniLight3D,
	p_rim_light: DirectionalLight3D
) -> bool:
	if p_board_ux == null or p_hud == null:
		return false
	if p_world_environment == null:
		return false
	if p_key_light == null or p_fill_light == null or p_rim_light == null:
		return false

	board_ux = p_board_ux
	hud = p_hud
	world_environment = p_world_environment
	key_light = p_key_light
	fill_light = p_fill_light
	rim_light = p_rim_light
	_configured = true

	_bind_refresh_signals()
	refresh_visual_direction()
	return true


func is_configured() -> bool:
	return _configured


func is_applied() -> bool:
	return _applied


func get_palette_color(key: StringName) -> Color:
	match key:
		&"background":
			return COLOR_BACKGROUND
		&"ground":
			return COLOR_GROUND
		&"hidden":
			return COLOR_HIDDEN
		&"start":
			return COLOR_START
		&"n1":
			return COLOR_N1
		&"n2":
			return COLOR_N2
		&"n3":
			return COLOR_N3
		&"sanctuary":
			return COLOR_SANCTUARY
		&"gold":
			return COLOR_GOLD
		&"jade":
			return COLOR_JADE
		&"move":
			return COLOR_MOVE
		&"explore":
			return COLOR_EXPLORE
		&"blocked":
			return COLOR_BLOCKED
	return Color.WHITE


func refresh_visual_direction() -> void:
	if not _configured:
		return

	_style_environment()
	_style_board_ground()
	_style_tiles()
	_style_trainer()
	_style_hud()
	_applied = true
	visual_direction_applied.emit()


func _bind_refresh_signals() -> void:
	var manager: KarmanyTurnManager = board_ux.board_prototype.turn_manager
	if manager == null:
		return
	if not manager.action_spent.is_connected(_on_action_spent):
		manager.action_spent.connect(_on_action_spent)
	if not manager.turn_started.is_connected(_on_turn_started):
		manager.turn_started.connect(_on_turn_started)


func _on_action_spent(
	_player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	call_deferred("refresh_visual_direction")


func _on_turn_started(
	_player: KarmanyPlayerState,
	_round_number: int,
	_actions_available: int
) -> void:
	call_deferred("refresh_visual_direction")


func _style_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = COLOR_BACKGROUND
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = COLOR_AMBIENT
	environment.ambient_light_energy = 0.72
	world_environment.environment = environment

	key_light.light_color = Color(1.0, 0.82, 0.62, 1.0)
	key_light.light_energy = 1.35
	key_light.shadow_enabled = true
	key_light.rotation_degrees = Vector3(-58.0, -32.0, 0.0)

	fill_light.light_color = Color(0.28, 0.62, 0.67, 1.0)
	fill_light.light_energy = 2.0
	fill_light.omni_range = 10.0
	fill_light.position = Vector3(-3.0, 4.5, 2.5)

	rim_light.light_color = Color(0.45, 0.34, 0.78, 1.0)
	rim_light.light_energy = 0.55
	rim_light.shadow_enabled = false
	rim_light.rotation_degrees = Vector3(-42.0, 150.0, 0.0)

	var original_light_value: Variant = board_ux.board_prototype.get_node_or_null("DirectionalLight3D")
	var original_light := original_light_value as DirectionalLight3D
	if original_light != null:
		original_light.light_energy = 0.12
		original_light.shadow_enabled = false


func _style_board_ground() -> void:
	var ground_value: Variant = board_ux.board_prototype.get_node_or_null("Ground")
	var ground := ground_value as MeshInstance3D
	if ground == null:
		return

	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_GROUND
	material.roughness = 0.94
	material.metallic = 0.08
	material.emission_enabled = true
	material.emission = Color(0.015, 0.035, 0.035, 1.0)
	material.emission_energy_multiplier = 0.35
	ground.material_override = material


func _style_tiles() -> void:
	var board_state: KarmanyBoardState = board_ux.board_prototype.board_state
	if board_state == null:
		return

	for coord in board_state.get_coords():
		var tile_value: Variant = board_ux.board_prototype.call("get_tile_view", coord)
		var tile := tile_value as KarmanyHexTile3D
		var cell: KarmanyBoardCellState = board_state.get_cell(coord)
		if tile == null or cell == null:
			continue

		tile.hover_color = Color(0.43, 0.77, 0.78, 1.0)
		tile.selected_color = COLOR_GOLD
		tile.move_hint_color = COLOR_MOVE
		tile.explore_hint_color = COLOR_EXPLORE
		tile.blocked_hint_color = COLOR_BLOCKED
		tile.set_base_color(_get_cell_direction_color(cell))

		var material_value: Variant = tile.mesh_instance.material_override
		var material := material_value as StandardMaterial3D
		if material != null:
			material.roughness = 0.67
			material.metallic = 0.09
			material.emission_enabled = true
			material.emission = _get_cell_direction_color(cell) * 0.11
			material.emission_energy_multiplier = 0.32


func _get_cell_direction_color(cell: KarmanyBoardCellState) -> Color:
	if cell == null:
		return COLOR_HIDDEN
	if not cell.revealed:
		return COLOR_HIDDEN
	if cell.tile_data == null:
		return Color(0.17, 0.22, 0.23, 1.0)

	match cell.tile_data.level:
		KarmanyTileData.TileLevel.START:
			return COLOR_START
		KarmanyTileData.TileLevel.N1:
			return COLOR_N1
		KarmanyTileData.TileLevel.N2:
			return COLOR_N2
		KarmanyTileData.TileLevel.N3:
			return COLOR_N3
		KarmanyTileData.TileLevel.SANCTUARY:
			return COLOR_SANCTUARY
	return COLOR_N1


func _style_trainer() -> void:
	var trainer_value: Variant = board_ux.board_prototype.get("trainer_unit")
	var trainer := trainer_value as KarmanyTrainerUnit3D
	if trainer == null:
		return

	var body := trainer.get_node_or_null("Body") as MeshInstance3D
	var head := trainer.get_node_or_null("Head") as MeshInstance3D
	if body != null:
		body.material_override = _make_trainer_material(
			Color(0.08, 0.30, 0.34, 1.0),
			Color(0.04, 0.13, 0.15, 1.0),
			0.25
		)
	if head != null:
		head.material_override = _make_trainer_material(
			Color(0.20, 0.48, 0.46, 1.0),
			Color(0.05, 0.18, 0.17, 1.0),
			0.22
		)

	if trainer.get_node_or_null("KarmicBase") == null:
		var base := MeshInstance3D.new()
		base.name = "KarmicBase"
		var base_mesh := CylinderMesh.new()
		base_mesh.top_radius = 0.38
		base_mesh.bottom_radius = 0.38
		base_mesh.height = 0.035
		base_mesh.radial_segments = 32
		base.mesh = base_mesh
		base.position = Vector3(0.0, 0.025, 0.0)

		var base_material := StandardMaterial3D.new()
		base_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		base_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		base_material.albedo_color = Color(0.20, 0.82, 0.66, 0.48)
		base_material.emission_enabled = true
		base_material.emission = COLOR_JADE
		base_material.emission_energy_multiplier = 1.7
		base.material_override = base_material
		trainer.add_child(base)


func _make_trainer_material(
	albedo: Color,
	emission: Color,
	emission_energy: float
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.62
	material.metallic = 0.07
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = emission_energy
	return material


func _style_hud() -> void:
	var main_margin := hud.get_node_or_null("MainMargin") as Control
	if main_margin == null:
		return

	if _hud_theme == null:
		_hud_theme = _build_hud_theme()
	main_margin.theme = _hud_theme

	var title := hud.get_node_or_null("MainMargin/Panel/Margin/VBox/TitleLabel") as Label
	if title != null:
		title.text = "KARMANY MONSTA · FORJA DE RESONANCIA"
		title.add_theme_color_override("font_color", COLOR_GOLD)
		title.add_theme_font_size_override("font_size", 20)

	var context := hud.get_node_or_null("MainMargin/Panel/Margin/VBox/ActionContextLabel") as Label
	if context != null:
		context.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

	var legacy := hud.get_node_or_null("MainMargin/Panel/Margin/VBox/LegacyPointsLabel") as Label
	if legacy != null:
		legacy.add_theme_color_override("font_color", COLOR_GOLD)
		legacy.add_theme_font_size_override("font_size", 18)


func _build_hud_theme() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0.0, 0.0, 0.0, 0.55))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_font_size("font_size", "Label", 15)

	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_GOLD)
	theme.set_color("font_pressed_color", "Button", COLOR_JADE)
	theme.set_color("font_disabled_color", "Button", Color(0.42, 0.49, 0.48, 0.72))
	theme.set_font_size("font_size", "Button", 14)

	theme.set_stylebox("panel", "PanelContainer", _make_panel_style())
	theme.set_stylebox("normal", "Button", _make_button_style(COLOR_PANEL_ALT, Color(0.16, 0.31, 0.30, 1.0)))
	theme.set_stylebox("hover", "Button", _make_button_style(Color(0.09, 0.17, 0.17, 0.98), COLOR_GOLD))
	theme.set_stylebox("pressed", "Button", _make_button_style(Color(0.04, 0.13, 0.12, 1.0), COLOR_JADE))
	theme.set_stylebox("disabled", "Button", _make_button_style(Color(0.04, 0.065, 0.07, 0.82), Color(0.12, 0.16, 0.16, 0.8)))
	return theme


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = Color(0.22, 0.52, 0.45, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 10
	return style


func _make_button_style(
	background: Color,
	border: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style
