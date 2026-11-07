extends Node
## Scale UI text from recorded baselines; keep oversized authored pages reachable.
var world: Node3D
var rich_labels: Array[WeakRef]=[]
var heading_pattern=RegEx.new()
const SIZES=["font_size","normal_font_size","bold_font_size","italics_font_size","bold_italics_font_size","mono_font_size"]
func _ready() -> void:
	heading_pattern.compile("\\[font_size=([0-9]+)\\]")
	world.accessibility.changed.connect(apply)
	get_tree().node_added.connect(_added)
	apply.call_deferred()
func _added(node: Node) -> void:
	if node is Control: _style.call_deferred(weakref(node))
func apply() -> void:
	walk(world)
	world.hud.reflow_accessible()
func walk(node: Node) -> void:
	if node is Control: _style(weakref(node))
	for child in node.get_children(): walk(child)
func _style(reference: WeakRef) -> void:
	var node=reference.get_ref()
	if not is_instance_valid(node) or not world.is_ancestor_of(node): return
	# The prelude has independently-sized subtitles.
	if is_instance_valid(world.intro) and node==world.intro.subtitle: return
	if not node.has_meta("accessibility_fonts"):
		var sizes={}
		if node is RichTextLabel:
			rich_labels.append(weakref(node))
			for key in SIZES.slice(1): sizes[key]=node.get_theme_font_size(key)
		elif node is Label or node is BaseButton or node is LineEdit or node is ItemList or node is TabContainer:
			sizes.font_size=node.get_theme_font_size("font_size")
		node.set_meta("accessibility_fonts",sizes)
	var base: Dictionary=node.get_meta("accessibility_fonts")
	for key in base: node.add_theme_font_size_override(key,maxi(1,roundi(base[key]*world.accessibility.ui_scale)))
	if node is ScrollContainer: node.follow_focus=true
	if node is OptionButton:
		var popup=node.get_popup()
		if not popup.has_meta("base_font_size"): popup.set_meta("base_font_size",popup.get_theme_font_size("font_size"))
		popup.add_theme_font_size_override("font_size",roundi(popup.get_meta("base_font_size")*world.accessibility.ui_scale))
	if node is RichTextLabel: _rich_text(node)
	if node is ColorRect and node.anchor_right==1 and node.anchor_bottom==1:
		_wrap_page(node)
func _wrap_page(page: Control) -> void:
	if page.has_node("AccessibleScroll"): return
	var content: Control
	for child in page.get_children():
		if child is MarginContainer or child is CenterContainer: content=child; break
	if content==null: return
	var scroll=ScrollContainer.new(); scroll.name="AccessibleScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.follow_focus=true
	page.add_child(scroll)
	content.reparent(scroll)
	content.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var resize=func(): content.custom_minimum_size=Vector2(maxf(1,page.size.x-20),maxf(1,page.size.y-20))
	page.resized.connect(resize); resize.call()

func _process(_delta: float) -> void:
	for index in range(rich_labels.size()-1,-1,-1):
		var label=rich_labels[index].get_ref()
		if not is_instance_valid(label):
			rich_labels.remove_at(index); continue
		if is_instance_valid(label) and label.is_visible_in_tree() and label.text!=label.get_meta("scaled_text",""): _rich_text(label)
func _rich_text(label: RichTextLabel) -> void:
	if label.text!=label.get_meta("scaled_text",""): label.set_meta("source_text",label.text)
	var text: String=label.get_meta("source_text",label.text)
	var matches=heading_pattern.search_all(text)
	matches.reverse()
	for match in matches:
		var size=roundi(int(match.get_string(1))*world.accessibility.ui_scale)
		text=text.substr(0,match.get_start())+"[font_size="+str(size)+"]"+text.substr(match.get_end())
	label.set_meta("scaled_text",text); label.text=text
