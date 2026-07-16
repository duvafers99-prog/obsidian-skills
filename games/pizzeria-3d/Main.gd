extends Node3D
# =============================================================================
#  PIZZERÍA 3D — idle tycoon prototype for Godot 4.3+
#
#  Everything (scene + logic) is built from code so there are no fragile .tscn
#  files to hand-edit. Characters are simple placeholder figures made from
#  primitives — see README.md for how to swap in real rigged models (Mixamo /
#  Kenney) and animate them. Press F5 in the Godot editor to play.
# =============================================================================

# ---- economy state ----------------------------------------------------------
var money: float = 0.0
var lifetime: float = 0.0
var cooks: int = 1
var oven: int = 1
var auto: bool = false
var scooters: int = 0
var combo: int = 1

const AUTO_COST := 100.0
const PATIENCE := 6.0          # seconds a front customer will wait
const DELIVERY_MULT := 3.0
const MAX_QUEUE := 4

# a waiting customer (using a class, not a Dictionary, so dot-access works)
class Customer:
	var node: Node3D
	var bar_fill: MeshInstance3D
	var patience: float = 6.0
	var active: bool = false
	var served: bool = false

func cook_cost() -> float:   return 15.0 * pow(1.18, cooks - 1)
func oven_cost() -> float:   return 50.0 * pow(1.65, oven - 1)
func deli_cost() -> float:   return 150.0 * pow(1.5, scooters)
func pizza_value() -> float: return pow(2.0, oven - 1)
func counter_rate() -> float: return (cooks * 0.85) if auto else 0.0   # pizzas/sec auto
func delivery_rate() -> float: return scooters * 0.5
func auto_income() -> float:
	return counter_rate() * pizza_value() + delivery_rate() * pizza_value() * DELIVERY_MULT

# ---- world anchors ----------------------------------------------------------
var chef_pos := Vector3(-3.2, 0, 1.0)
var counter_pos := Vector3(1.6, 0, 1.0)
var house_pos := Vector3(5.0, 0, -3.2)
var pickup_pos := Vector3(-4.0, 0, -3.2)

# ---- runtime refs -----------------------------------------------------------
var chef_node: Node3D
var queue: Array = []          # each item: { node, bar_fill, patience, active, served }
var scooter_nodes: Array = []
var face_i: int = 0

# ui
var lbl_money: Label
var lbl_per: Label
var lbl_combo: Label
var btn_cook: Button
var btn_oven: Button
var btn_auto: Button
var btn_deli: Button

# timers / accumulators
var spawn_acc: float = 0.0
var visual_acc: float = 0.0
var ui_acc: float = 0.0
var bob_t: float = 0.0

# =============================================================================
func _ready() -> void:
	_build_environment()
	_build_ui()
	chef_node = _make_person(Color(0.95, 0.95, 0.95), true)   # white = chef
	chef_node.position = chef_pos
	add_child(chef_node)
	# seed a couple of customers
	_spawn_customer()
	_spawn_customer()
	_refresh_ui()

# ---- scene building ---------------------------------------------------------
func _build_environment() -> void:
	# camera
	var cam := Camera3D.new()
	cam.position = Vector3(0, 6.5, 9.5)
	add_child(cam)
	cam.look_at(Vector3(0.5, 1.0, 0.0), Vector3.UP)
	cam.fov = 55

	# sun
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.1
	add_child(sun)

	# ambient environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.18, 0.10, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.48, 0.42)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# floor (restaurant)
	_make_box(Vector3(14, 0.4, 6), Color(0.55, 0.34, 0.18), Vector3(0, -0.2, 1.2))
	# road strip
	_make_box(Vector3(16, 0.42, 3.2), Color(0.22, 0.22, 0.26), Vector3(0, -0.2, -3.2))
	# counter
	_make_box(Vector3(1.2, 1.0, 1.4), Color(0.72, 0.47, 0.24), counter_pos + Vector3(0, 0.5, 0))
	# belt
	_make_box(Vector3(3.6, 0.25, 0.5), Color(0.16, 0.10, 0.07), Vector3(-0.9, 0.6, 1.0))
	# house
	var house := _make_box(Vector3(1.4, 1.4, 1.4), Color(0.86, 0.78, 0.66), house_pos + Vector3(0, 0.7, 0))
	_make_box(Vector3(1.5, 0.1, 1.5), Color(0.7, 0.25, 0.2), house_pos + Vector3(0, 1.55, 0))  # roof slab

func _make_box(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.material_override = _mat(color)
	m.position = pos
	add_child(m)
	return m

func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	return mat

# a placeholder "person": body + head + optional chef hat, grouped in a Node3D
func _make_person(shirt: Color, is_chef: bool = false) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var bmesh := CapsuleMesh.new()
	bmesh.radius = 0.32
	bmesh.height = 1.1
	body.mesh = bmesh
	body.material_override = _mat(shirt)
	body.position = Vector3(0, 0.75, 0)
	root.add_child(body)
	var head := MeshInstance3D.new()
	var hmesh := SphereMesh.new()
	hmesh.radius = 0.26
	hmesh.height = 0.52
	head.mesh = hmesh
	head.material_override = _mat(Color(1.0, 0.82, 0.63))
	head.position = Vector3(0, 1.5, 0)
	head.name = "Head"
	root.add_child(head)
	if is_chef:
		var hat := MeshInstance3D.new()
		var cmesh := CylinderMesh.new()
		cmesh.top_radius = 0.28
		cmesh.bottom_radius = 0.24
		cmesh.height = 0.34
		hat.mesh = cmesh
		hat.material_override = _mat(Color(1, 1, 1))
		hat.position = Vector3(0, 1.86, 0)
		root.add_child(hat)
	return root

# ---- UI (2D overlay) --------------------------------------------------------
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	lbl_money = Label.new()
	lbl_money.text = "$0"
	lbl_money.add_theme_font_size_override("font_size", 44)
	lbl_money.add_theme_color_override("font_color", Color(1.0, 0.81, 0.30))
	lbl_money.position = Vector2(24, 20)
	layer.add_child(lbl_money)

	lbl_per = Label.new()
	lbl_per.text = "Toca ¡Hacer pizza!"
	lbl_per.add_theme_font_size_override("font_size", 22)
	lbl_per.position = Vector2(26, 78)
	layer.add_child(lbl_per)

	lbl_combo = Label.new()
	lbl_combo.text = ""
	lbl_combo.add_theme_font_size_override("font_size", 26)
	lbl_combo.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
	lbl_combo.position = Vector2(470, 24)
	layer.add_child(lbl_combo)

	# big make button
	var make_btn := Button.new()
	make_btn.text = "🍕  ¡HACER PIZZA!"
	make_btn.add_theme_font_size_override("font_size", 34)
	make_btn.position = Vector2(40, 1000)
	make_btn.size = Vector2(640, 100)
	make_btn.pressed.connect(_on_make_manual)
	layer.add_child(make_btn)

	# upgrade row
	btn_cook = _make_shop_btn(layer, 20,  1130, _on_buy_cook)
	btn_oven = _make_shop_btn(layer, 195, 1130, _on_buy_oven)
	btn_auto = _make_shop_btn(layer, 370, 1130, _on_buy_auto)
	btn_deli = _make_shop_btn(layer, 545, 1130, _on_buy_deli)

func _make_shop_btn(layer: CanvasLayer, x: int, y: int, cb: Callable) -> Button:
	var b := Button.new()
	b.position = Vector2(x, y)
	b.size = Vector2(160, 110)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(cb)
	layer.add_child(b)
	return b

# ---- input handlers ---------------------------------------------------------
func _on_make_manual() -> void:
	var v := pizza_value()
	money += v
	lifetime += v
	_toss_pizza(v)

func _on_buy_cook() -> void:
	var c := cook_cost()
	if money < c: return
	money -= c; cooks += 1; _refresh_ui()

func _on_buy_oven() -> void:
	var c := oven_cost()
	if money < c: return
	money -= c; oven += 1; _refresh_ui()

func _on_buy_auto() -> void:
	if auto or money < AUTO_COST: return
	money -= AUTO_COST; auto = true; _refresh_ui()

func _on_buy_deli() -> void:
	var c := deli_cost()
	if money < c: return
	money -= c; scooters += 1; _add_scooter(); _refresh_ui()

# ---- pizzas -----------------------------------------------------------------
func _toss_pizza(coin_val: float) -> void:
	var pz := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.22
	mesh.bottom_radius = 0.22
	mesh.height = 0.06
	pz.mesh = mesh
	pz.material_override = _mat(Color(0.95, 0.75, 0.35))
	pz.position = chef_pos + Vector3(0, 1.1, 0)
	add_child(pz)
	var mid := (chef_pos + counter_pos) * 0.5 + Vector3(0, 1.9, 0)
	var end := counter_pos + Vector3(0, 1.1, 0)
	var tw := create_tween()
	tw.tween_property(pz, "position", mid, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(pz, "position", end, 0.6).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(func():
		pz.queue_free()
		_serve_counter(coin_val))

func _serve_counter(coin_val: float) -> void:
	if queue.size() > 0 and queue[0].active:
		_serve_front()
	else:
		_coin(counter_pos + Vector3(0, 1.6, 0), coin_val, Color(0.4, 0.9, 0.55))

# ---- customers --------------------------------------------------------------
var SHIRTS := [Color(0.9,0.3,0.3), Color(0.3,0.5,0.9), Color(0.4,0.8,0.4),
	Color(0.8,0.6,0.2), Color(0.7,0.4,0.8), Color(0.3,0.75,0.75)]

func _slot_pos(i: int) -> Vector3:
	return counter_pos + Vector3(1.4 + i * 0.95, 0, 0.2)

func _spawn_customer() -> void:
	if queue.size() >= MAX_QUEUE: return
	var node := _make_person(SHIRTS[face_i % SHIRTS.size()])
	face_i += 1
	var enter := _slot_pos(queue.size()) + Vector3(7, 0, 0)
	node.position = enter
	add_child(node)
	# patience bar (two thin boxes above the head)
	var bar_bg := _bar_box(Color(0,0,0,0.75), 0.9)
	bar_bg.position = Vector3(0, 2.15, 0)
	node.add_child(bar_bg)
	var bar_fill := _bar_box(Color(0.37,0.88,0.54), 0.86)
	bar_fill.position = Vector3(0, 2.15, 0.01)
	bar_fill.visible = false
	node.add_child(bar_fill)
	var c := Customer.new()
	c.node = node
	c.bar_fill = bar_fill
	c.patience = PATIENCE
	queue.append(c)
	_layout_queue()

func _bar_box(col: Color, w: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, 0.12, 0.05)
	m.mesh = mesh
	var mat := _mat(col)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	return m

func _layout_queue() -> void:
	for i in queue.size():
		var c: Customer = queue[i]
		var tw := create_tween()
		tw.tween_property(c.node, "position", _slot_pos(i), 0.5).set_trans(Tween.TRANS_SINE)

func _serve_front() -> void:
	var c = queue.pop_front()
	if c == null: return
	var tip: float = ceil(pizza_value() * 0.5 * combo)
	money += tip
	lifetime += tip
	combo = min(combo + 1, 99)
	_coin(c.node.position + Vector3(0, 2.2, 0), tip, Color(0.4, 0.9, 0.55))
	_leave(c.node, true)
	_layout_queue()

func _angry_front() -> void:
	var c = queue.pop_front()
	if c == null: return
	combo = 1
	_coin(c.node.position + Vector3(0, 2.2, 0), -1, Color(1.0, 0.4, 0.4), "😠")
	_leave(c.node, false)
	_layout_queue()

func _leave(node: Node3D, happy: bool) -> void:
	var tw := create_tween()
	if happy:
		tw.tween_property(node, "position", node.position + Vector3(0, 1.2, 0), 0.35)
		tw.parallel().tween_property(node, "scale", Vector3(1.15,1.15,1.15), 0.35)
		tw.tween_property(node, "position", node.position + Vector3(-2, 3, 0), 0.4)
	else:
		# angry shake, then storm off
		tw.tween_property(node, "rotation_degrees", Vector3(0,0,10), 0.08)
		tw.tween_property(node, "rotation_degrees", Vector3(0,0,-10), 0.08)
		tw.tween_property(node, "rotation_degrees", Vector3(0,0,10), 0.08)
		tw.tween_property(node, "position", node.position + Vector3(6, 0, 0), 0.5)
	tw.finished.connect(func(): node.queue_free())

# ---- delivery scooters ------------------------------------------------------
func _add_scooter() -> void:
	if scooter_nodes.size() >= 5: return  # visual cap; income still scales
	var s := _make_box(Vector3(0.7, 0.4, 0.35), Color(0.95, 0.75, 0.2), pickup_pos + Vector3(0, 0.4, 0))
	scooter_nodes.append(s)
	_run_scooter(s, true)

func _run_scooter(s: Node3D, going_out: bool) -> void:
	var target = (house_pos if going_out else pickup_pos) + Vector3(0, 0.4, 0)
	var dur := 2.6 if going_out else 2.1
	var tw := create_tween()
	tw.tween_property(s, "position", target, dur).set_trans(Tween.TRANS_LINEAR)
	tw.finished.connect(func():
		if not is_instance_valid(s): return
		if going_out:
			_coin(house_pos + Vector3(0, 1.4, 0), pizza_value() * DELIVERY_MULT, Color(0.4,0.9,0.55))
		_run_scooter(s, not going_out))

# ---- floating coin label ----------------------------------------------------
func _coin(pos: Vector3, val: float, col: Color, override_text: String = "") -> void:
	var lab := Label3D.new()
	lab.text = override_text if override_text != "" else "+" + _fmt(val)
	lab.modulate = col
	lab.font_size = 64
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.position = pos
	add_child(lab)
	var tw := create_tween()
	tw.tween_property(lab, "position", pos + Vector3(0, 1.2, 0), 0.85)
	tw.parallel().tween_property(lab, "modulate", Color(col.r, col.g, col.b, 0.0), 0.85)
	tw.finished.connect(func(): lab.queue_free())

# ---- main loop --------------------------------------------------------------
func _process(delta: float) -> void:
	bob_t += delta
	# gentle idle bob so placeholders feel alive
	if chef_node:
		chef_node.position.y = chef_pos.y + sin(bob_t * 3.0) * 0.06

	# passive income
	var inc := auto_income()
	if inc > 0.0:
		money += inc * delta
		lifetime += inc * delta

	# auto counter pizzas (each arrival serves a waiting customer)
	var cr := counter_rate()
	if cr > 0.0:
		visual_acc += min(cr, 6.0) * delta
		var guard := 0
		var pv := pizza_value()
		while visual_acc >= 1.0 and guard < 6:
			_toss_pizza(pv)
			visual_acc -= 1.0
			guard += 1

	# customers keep arriving
	spawn_acc += delta
	if spawn_acc >= 1.0:
		spawn_acc = 0.0
		_spawn_customer()

	# front customer's patience drains
	if queue.size() > 0:
		var f: Customer = queue[0]
		if not f.active:
			f.active = true
			f.patience = PATIENCE
			f.bar_fill.visible = true
		f.patience -= delta
		var p: float = clamp(f.patience / PATIENCE, 0.0, 1.0)
		f.bar_fill.scale.x = p
		var mat: StandardMaterial3D = f.bar_fill.material_override
		mat.albedo_color = Color(0.37,0.88,0.54) if p > 0.5 else (Color(1,0.82,0.25) if p > 0.22 else Color(1,0.42,0.42))
		if f.patience <= 0.0:
			_angry_front()

	# throttled UI refresh
	ui_acc += delta
	if ui_acc >= 0.15:
		ui_acc = 0.0
		_refresh_ui()

# ---- ui refresh -------------------------------------------------------------
func _refresh_ui() -> void:
	lbl_money.text = _fmt(money)
	var inc := auto_income()
	lbl_per.text = ("💰 " + _fmt(inc) + "/s automático") if inc > 0.0 else "Toca ¡Hacer pizza!"
	lbl_combo.text = ("🔥 x" + str(combo)) if combo > 1 else ""
	btn_cook.text = "👨‍🍳 Cocinero x%d\n%s" % [cooks, _fmt(cook_cost())]
	btn_oven.text = "🔥 Horno N%d\n%s" % [oven, _fmt(oven_cost())]
	btn_auto.text = ("🧑‍💼 Gestor\n✔ Auto") if auto else ("🧑‍💼 Gestor\n" + _fmt(AUTO_COST))
	btn_deli.text = "🛵 Reparto x%d\n%s" % [scooters, _fmt(deli_cost())]
	btn_cook.disabled = money < cook_cost()
	btn_oven.disabled = money < oven_cost()
	btn_auto.disabled = auto or money < AUTO_COST
	btn_deli.disabled = money < deli_cost()

# ---- number formatter -------------------------------------------------------
func _fmt(n: float) -> String:
	if n < 0: return ""
	if n < 1000:
		return "$" + (str(int(n)) if n >= 10 or n == floor(n) else "%.2f" % n)
	var suf := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp"]
	var i := int(floor(log(n) / log(1000.0)))
	i = min(i, suf.size() - 1)
	return "$" + ("%.2f" % (n / pow(1000.0, i))) + suf[i]
