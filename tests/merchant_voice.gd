extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(4): await physics_frame
	var s=w.player.character; var shops=w.shops
	check(not s.persist and not w.atlas.persist,"QA persistence disabled")
	for shop in s.shop_data.shops:
		s.story_completed=[]; shops.greeting_visits.clear()
		var one: String=shops.next_greeting(shop.id); var two: String=shops.next_greeting(shop.id)
		check(one!=two and shops.next_greeting(shop.id)==one,"Ordinary greetings rotate: "+shop.id)
		check(shop.greetings[2].text not in one and shop.greetings[3].text not in two,"Future chapters are not mentioned: "+shop.id)
		s.story_completed.append(shop.greetings[2].requires)
		check(shop.greetings[2].text in shops.next_greeting(shop.id),"Chapter completion unlocks callback: "+shop.id)
		s.story_completed.append(shop.greetings[3].requires)
		check(shop.greetings[3].text in shops.next_greeting(shop.id),"Later completed chapter unlocks callback: "+shop.id)
		var pos: Array=shop.position; w.player.position=Vector3(pos[0],pos[1],pos[2]); shops.open(shop.id)
		check(shops.status.text.begins_with(shop.merchant+":"),"Real shop opening uses merchant voice: "+shop.id)
		shops.close()
	w.player.position=Vector3(400,0,400); w.player.shop_open=true; shops.transact()
	check(shops.status.text=="Return to the merchant to trade.","Trade failure replaces banter with clear instructions")
	w.queue_free(); await process_frame
	print("MERCHANT_VOICE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
