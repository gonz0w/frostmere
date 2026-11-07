extends ColorRect
var world: Node3D
var state: RefCounted
var points: Label
var rows: VBoxContainer
var selected:="melee"
func _ready() -> void:
	state=world.player.character; color=Color("15252c"); set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(center)
	var column:=VBoxContainer.new(); column.custom_minimum_size.x=800; column.add_theme_constant_override("separation",18); center.add_child(column)
	var title:=Label.new(); title.text="SKILLS & PERKS"; title.add_theme_font_size_override("font_size",28); column.add_child(title)
	points=Label.new(); column.add_child(points)
	var note:=Label.new(); note.text="Learn through successful combat and crafting. Each skill level earns one perk point.\nSkills start at 1 and cap at 10. Every 100 XP earns a level.\nRefund learned perks freely to try another build. XP and existing equipment stay yours."; column.add_child(note)
	var tabs:=HBoxContainer.new(); column.add_child(tabs)
	for skill: String in state.Skills.NAMES:
		var button:=Button.new(); button.text=state.Skills.NAMES[skill]; button.custom_minimum_size=Vector2(180,42); button.pressed.connect(func(): selected=skill; refresh()); tabs.add_child(button)
	rows=VBoxContainer.new(); rows.add_theme_constant_override("separation",16); rows.custom_minimum_size.y=260; column.add_child(rows)
	var close:=Button.new(); close.text="Return to exploration [ Esc ]"; close.custom_minimum_size.y=44; close.pressed.connect(close_menu); column.add_child(close)
	state.skills_changed.connect(refresh); state.skill_advanced.connect(func(skill: String,level: int): world.hud.announce(state.Skills.NAMES[skill]+" increased", "Level %d · %d unspent perk points · %s opens skills" % [level,state.perk_points(),world.controls.label("skills")]))
	refresh(); hide()
func refresh() -> void:
	points.text="Unspent perk points: %d" % state.perk_points()
	for child in rows.get_children(): rows.remove_child(child); child.queue_free()
	var progress:=Label.new(); progress.add_theme_font_size_override("font_size",21)
	var level: int=state.skill_level(selected)
	progress.text="%s · Level %d / 10 · %s" % [state.Skills.NAMES[selected],level,"Mastered" if level==10 else "%d / 100 XP to next level" % (int(state.skills.xp[selected])%100)]; rows.add_child(progress)
	for id: String in state.Skills.PERKS:
		var perk: Dictionary=state.Skills.PERKS[id]
		if perk.skill!=selected: continue
		var desc:=Label.new(); desc.text=perk.name+" — "+perk.detail; rows.add_child(desc)
		var button:=Button.new(); button.custom_minimum_size.y=42; button.text="Refund %s · %d point%s" % [perk.name,perk.cost,"s" if perk.cost!=1 else ""] if state.has_perk(id) else "Learn · level %d required · %d point%s" % [perk.level,perk.cost,"s" if perk.cost!=1 else ""]
		button.disabled=not state.has_perk(id) and not state.can_learn_perk(id)
		button.pressed.connect(func():
			if state.has_perk(id): state.refund_perk(id)
			else: state.learn_perk(id)
		)
		rows.add_child(button)
func open_menu() -> void:
	var p: CharacterBody3D=world.player
	if p.dialog_open or p.shop_open:
		var escape:=InputEventKey.new(); escape.physical_keycode=KEY_ESCAPE; escape.pressed=true; p._unhandled_input(escape)
	p.workshop_open=false; p.map_open=false; p.character_menu_open=false; p.dialog_open=true; p.set_paused(true); show(); refresh()
func close_menu() -> void:
	hide(); world.player.dialog_open=false; world.player.set_paused(false)
