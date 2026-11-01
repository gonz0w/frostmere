extends RefCounted
## Explicit identities; chapter positions remain owned by their gameplay scenes.
const DESIGNS = {
	"outfitter":["The Copper Stag","nordic","store",.82,"dormer"],
	"runesmith":["The Runesmith's House","nordic","runes",1.0,"lantern"],
	"weaver":["Thread & Thistle","nordic","weaver",.68,"hip"],
	"cottage":["The Crofter's Rest","nordic","home",.9,"hip"],
	"ember_hall":["Ember Hall Stores","nordic","provisions",.82,"clerestory"],
	"apothecary":["Juniper & Rune","grove","herbs",1.05,"dormer"],
	"stoneguard":["Stoneguard Hall","mountain","armory",.65,"battlement"],
	"stormweaver":["Stormweaver Hall","mountain","runes",1.05,"lantern"],
	"council":["The Divided Council","mountain","council",.75,"clerestory"],
	"summit_smith":["Summit Smithy","mountain","smith",.55,"vent"],
	"high_road":["The High Road","mountain","store",.72,"dormer"],
	"watch_hut":["The Last Warm Shelter","winter","shelter",.9,"hip"],
	"lantern_house":["Lantern Chapter House","woodland","library",.95,"lantern"],
	"coven_house":["The Veiled Coven","woodland","runes",1.15,"dormer"],
	"cartographer":["The Mapmaker's Lodge","woodland","maps",.62,"hip"],
	"harbormaster":["Saltbreak Harbour House","coast","maps",.65,"lantern"],
	"net_loft":["The Net & Needle","coast","nets",.48,"dormer"],
	"salt_store":["The Salt Granary","coast","provisions",.58,"hip"],
	"lens_lodge":["Lenswarden Observatory Lodge","sun","astronomy",.55,"observatory"],
	"grove_keeper":["Amberbough Keeper's Lodge","grove","herbs",.85,"lantern"],
	"grove_hunter":["The Pactkeeper's Hearth","grove","hunter",.65,"hip"],
	"choir_lodge":["The Cantor's Hospice","ash","music",1.15,"bell"],
	"convergence_lodge":["The Witness House","sun","library",.78,"clerestory"],
	"winter_hostel":["Passkeeper's Rest","winter","shelter",.9,"dormer"],
	"winter_store":["The White Road Stores","winter","provisions",.7,"vent"]
}
static func get_design(id: String) -> Dictionary:
	assert(DESIGNS.has(id),"Unknown building identity: "+id)
	var row: Array=DESIGNS[id]
	return {"id":id,"name":row[0],"region":row[1],"use":row[2],"pitch":row[3],"roofline":row[4]}
