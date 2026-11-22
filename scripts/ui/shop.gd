extends Control
## 상점: [구매] 상점 물건을 코인으로 산다 / [판매] 가방의 물건을 절반 값에 판다

signal closed

var _mode: String = "buy"
var _list: VBoxContainer
var _coins: Label
var _buy_tab: Button
var _sell_tab: Button


func _ready() -> void:
	hide()
	var root := UIKit.window(self, Vector2(380, 250), "자갈 마을 잡화점", close_shop)
	var tabs := HBoxContainer.new()
	root.add_child(tabs)
	_buy_tab = UIKit.button("구매")
	_buy_tab.pressed.connect(func(): _mode = "buy"; _refresh())
	_sell_tab = UIKit.button("판매")
	_sell_tab.pressed.connect(func(): _mode = "sell"; _refresh())
	tabs.add_child(_buy_tab)
	tabs.add_child(_sell_tab)
	var sp := Control.new()
	sp.size_flags_horizontal = SIZE_EXPAND_FILL
	tabs.add_child(sp)
	_coins = UIKit.label("", 12, Color(1, 0.9, 0.5))
	tabs.add_child(_coins)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 170)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	GameState.inventory_changed.connect(func(): if visible: _refresh())


func open_shop() -> void:
	_mode = "buy"
	_refresh()
	show()


func close_shop() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_shop()


static func sell_price(id: String) -> int:
	return maxi(1, GameState.ITEMS[id].get("price", 2) / 2)


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	_coins.text = "코인 %d" % GameState.coins
	_buy_tab.modulate = Color(1.3, 1.2, 0.8) if _mode == "buy" else Color.WHITE
	_sell_tab.modulate = Color(1.3, 1.2, 0.8) if _mode == "sell" else Color.WHITE
	if _mode == "buy":
		for id in GameState.SHOP_STOCK:
			var price: int = GameState.SHOP_STOCK[id]
			_row(id, "%d 코인" % price, "구매", GameState.coins >= price, _buy.bind(id, price))
	else:
		var any := false
		for id in GameState.inventory:
			var item: Dictionary = GameState.ITEMS[id]
			if item.type == "key" or not item.has("price"):
				continue
			any = true
			_row(id, "%d 코인 (보유 %d)" % [sell_price(id), GameState.inventory[id]], "판매", true, _sell.bind(id))
		if not any:
			_list.add_child(UIKit.label("팔 수 있는 물건이 없어요. (장착 중인 장비와 중요한 물건은 팔 수 없어요)", 10))


func _row(id: String, price_text: String, action: String, enabled: bool, cb: Callable) -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UIKit.box(Color(0.18, 0.14, 0.1), Color(0.4, 0.32, 0.22), 4))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	row.add_child(h)
	h.add_child(UIKit.icon_rect(GameState.get_icon(id), 24))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = SIZE_EXPAND_FILL
	v.add_child(UIKit.label(GameState.ITEMS[id].name, 12, Color(1, 0.92, 0.7)))
	var d := UIKit.label(GameState.ITEMS[id].desc.split("\n")[0], 9, Color(0.75, 0.75, 0.75))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	h.add_child(v)
	h.add_child(UIKit.label(price_text, 10, Color(1, 0.85, 0.5)))
	var b := UIKit.button(action)
	b.disabled = not enabled
	b.pressed.connect(cb)
	h.add_child(b)
	_list.add_child(row)


func _buy(id: String, price: int) -> void:
	if GameState.coins < price:
		return
	_set_coins(GameState.coins - price)
	GameState.add_item(id)
	_refresh()


func _sell(id: String) -> void:
	if GameState.inventory.get(id, 0) <= 0:
		return
	GameState.remove_item(id)
	_set_coins(GameState.coins + sell_price(id))
	_refresh()


func _set_coins(n: int) -> void:
	GameState.coins = n
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.coins = n
		player.coins_changed.emit(n)
