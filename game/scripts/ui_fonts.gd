extends RefCounted
class_name UIFonts

const UI_FONT_PATH := "res://assets/fonts/SourceHanSansCN-Medium.ttf"

static var _ui_font: FontFile

static func get_ui_font() -> FontFile:
	if _ui_font == null:
		_ui_font = load(UI_FONT_PATH) as FontFile
		if _ui_font == null:
			push_warning("Failed to load UI font %s" % UI_FONT_PATH)
			return null
		_ui_font.allow_system_fallback = true
	return _ui_font

static func apply_to_control_tree(root: Node) -> void:
	if root == null:
		return
	var ui_font := get_ui_font()
	if ui_font == null:
		push_warning("UI font missing at %s" % UI_FONT_PATH)
		return
	_apply_recursive(root, ui_font)

static func _apply_recursive(node: Node, ui_font: Font) -> void:
	if node is Control:
		(node as Control).add_theme_font_override("font", ui_font)
	for child in node.get_children():
		_apply_recursive(child, ui_font)
