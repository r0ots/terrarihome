class_name PlantIcons

const SIZE := 16

static var _icons: Dictionary = {}
static var _initialized := false


static func _ensure_init() -> void:
	if _initialized: return
	_initialized = true
	_generate_all()


static func get_icon(id: StringName) -> ImageTexture:
	_ensure_init()
	return _icons.get(id)


static func get_all() -> Dictionary:
	_ensure_init()
	return _icons


static func _img() -> Image:
	return Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)


static func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for dy in h:
		for dx in w:
			img.set_pixel(x + dx, y + dy, c)


static func _col(img: Image, x: int, y0: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		img.set_pixel(x, y, c)


static func _row(img: Image, y: int, x0: int, x1: int, c: Color) -> void:
	for x in range(x0, x1 + 1):
		img.set_pixel(x, y, c)


static func _px(img: Image, pixels: Array, c: Color) -> void:
	for p in pixels:
		img.set_pixel(p[0], p[1], c)


static func _generate_all() -> void:
	_gen_carotte()
	_gen_herberaude()
	_gen_boutomate()
	_gen_persil_piquant()
	_gen_cactus_epineux()
	_gen_basilic_royal()
	_gen_truffe()
	_gen_champi_mi_gnon()
	_gen_morille_doree()
	_gen_pleurote_cascade()
	_gen_mousse_lunaire()
	_gen_patate_douce()
	_gen_radis_rose()
	_gen_navet_tournoyant()
	_gen_gingembre_tourne_vent()
	_gen_ail_des_ours()
	_gen_fougere_dor()
	_gen_fraise_sauvage()


# 1. Carotte — orange tapered carrot pointing down, green leaves on top
static func _gen_carotte() -> void:
	var img := _img()
	var orange := Color("E67E22")
	var dark := Color("A04000")
	var green := Color("27AE60")
	# Green leaves (top, rows 1-4)
	_px(img, [[7,0],[8,0]], green)
	_px(img, [[6,1],[7,1],[8,1],[9,1]], green)
	_px(img, [[5,2],[7,2],[8,2],[10,2]], green)
	_px(img, [[6,3],[9,3]], green)
	# Carrot body — tapers from wide to narrow
	# Row 4: width 6 centered
	_row(img, 4, 5, 10, orange)
	_px(img, [[5,4],[10,4]], dark)
	_row(img, 5, 5, 10, orange)
	_px(img, [[5,5],[10,5]], dark)
	_row(img, 6, 6, 9, orange)
	_px(img, [[6,6],[9,6]], dark)
	_row(img, 7, 6, 9, orange)
	_px(img, [[6,7],[9,7]], dark)
	_row(img, 8, 6, 9, orange)
	_px(img, [[6,8],[9,8]], dark)
	_row(img, 9, 6, 9, orange)
	_px(img, [[6,9],[9,9]], dark)
	_row(img, 10, 7, 8, orange)
	_px(img, [[7,10],[8,10]], dark)
	_row(img, 11, 7, 8, orange)
	_px(img, [[7,11],[8,11]], dark)
	img.set_pixel(7, 12, orange)
	img.set_pixel(7, 12, dark)
	img.set_pixel(8, 12, orange)
	img.set_pixel(7, 13, orange)
	img.set_pixel(7, 14, dark)
	_icons[&"carotte"] = _tex(img)


# 2. Herberaude — 3 emerald grass blades with a sparkle
static func _gen_herberaude() -> void:
	var img := _img()
	var green := Color("2ECC71")
	var dark := Color("1A8A4A")
	var sparkle := Color("82E0AA")
	# Left blade
	_col(img, 4, 6, 14, green)
	_px(img, [[3,5],[4,5]], green)
	img.set_pixel(3, 4, dark)
	# Center blade (tallest)
	_col(img, 7, 3, 14, green)
	_col(img, 8, 3, 14, green)
	_px(img, [[7,2],[8,2]], dark)
	# Right blade
	_col(img, 11, 6, 14, green)
	_px(img, [[12,5],[11,5]], green)
	img.set_pixel(12, 4, dark)
	# Dark edges
	_px(img, [[3,7],[3,10],[12,7],[12,10]], dark)
	# Sparkle pixels
	_px(img, [[10,2],[9,1],[11,1],[10,0]], sparkle)
	_icons[&"herberaude"] = _tex(img)


# 3. Boutomate — round red tomato with green calyx star on top
static func _gen_boutomate() -> void:
	var img := _img()
	var red := Color("E74C3C")
	var dark := Color("922B21")
	var green := Color("27AE60")
	var hi := Color("F1948A")
	# Green stem + calyx
	img.set_pixel(7, 1, green)
	img.set_pixel(8, 1, green)
	_px(img, [[5,3],[6,2],[7,2],[8,2],[9,2],[10,3]], green)
	# Tomato body (rows 3-13, roughly circular)
	for y in range(3, 14):
		var half: int
		if y <= 4: half = 3
		elif y <= 5: half = 4
		elif y <= 11: half = 5
		elif y <= 12: half = 4
		else: half = 3
		var cx := 7
		_row(img, y, cx - half + 1, cx + half, red)
		img.set_pixel(cx - half + 1, y, dark)
		img.set_pixel(cx + half, y, dark)
	# Dark top/bottom edges
	_row(img, 3, 6, 9, dark)
	_row(img, 13, 5, 10, dark)
	# Highlight
	_px(img, [[5,5],[5,6],[6,5]], hi)
	_icons[&"boutomate"] = _tex(img)


# 4. Persil Piquant — teal parsley fan with 3 leaflets + red spicy dots
static func _gen_persil_piquant() -> void:
	var img := _img()
	var teal := Color("1ABC9C")
	var dark := Color("117A65")
	var red := Color("E74C3C")
	# Stem
	_col(img, 7, 10, 15, dark)
	_col(img, 8, 10, 15, dark)
	# Left leaflet
	_px(img, [[3,5],[4,4],[4,5],[4,6],[5,3],[5,4],[5,5],[5,6],[5,7],[6,4],[6,5],[6,6]], teal)
	_px(img, [[3,4],[3,6],[6,3],[6,7]], dark)
	# Center leaflet
	_px(img, [[7,1],[7,2],[7,3],[7,4],[8,1],[8,2],[8,3],[8,4],[6,2],[9,2],[7,5],[8,5]], teal)
	_px(img, [[6,1],[9,1],[7,0],[8,0]], dark)
	# Right leaflet
	_px(img, [[10,4],[10,5],[10,6],[11,3],[11,4],[11,5],[11,6],[11,7],[12,5]], teal)
	_px(img, [[12,4],[12,6],[9,7],[9,3]], dark)
	# Junction
	_px(img, [[6,8],[7,7],[7,8],[7,9],[8,7],[8,8],[8,9],[9,8]], teal)
	# Red spicy dots
	_px(img, [[4,5],[8,2],[11,5]], red)
	_icons[&"persil_piquant"] = _tex(img)


# 5. Cactus Epineux — green barrel cactus with yellow spines
static func _gen_cactus_epineux() -> void:
	var img := _img()
	var green := Color("27AE60")
	var dark := Color("1E8449")
	var yellow := Color("F4D03F")
	# Barrel body (rows 4-14)
	for y in range(4, 15):
		var half: int
		if y <= 5: half = 3
		elif y <= 12: half = 4
		elif y <= 13: half = 3
		else: half = 2
		_row(img, y, 8 - half, 7 + half, green)
	# Vertical ribs
	for y in range(5, 14):
		for x in [6, 9]:
			img.set_pixel(x, y, dark)
	# Top curve outline
	_row(img, 4, 6, 9, dark)
	# Bottom outline
	_row(img, 14, 6, 9, dark)
	# Side outlines
	for y in range(6, 13):
		img.set_pixel(4, y, dark)
		img.set_pixel(11, y, dark)
	# Yellow spines poking out
	_px(img, [
		[3,5],[3,8],[3,11],
		[12,5],[12,8],[12,11],
		[5,3],[7,3],[9,3],[10,3],
		[6,2],[9,2],
	], yellow)
	_icons[&"cactus_epineux"] = _tex(img)


# 6. Basilic Royal — purple leaves with golden crown on top
static func _gen_basilic_royal() -> void:
	var img := _img()
	var purple := Color("9B59B6")
	var dark := Color("6C3483")
	var gold := Color("F4D03F")
	# Golden crown (rows 0-3)
	_px(img, [[6,3],[7,3],[8,3],[9,3]], gold)  # crown base
	_px(img, [[5,2],[6,2],[7,2],[8,2],[9,2],[10,2]], gold)
	_px(img, [[6,1],[8,1],[10,1]], gold)  # crown points
	_px(img, [[6,0],[8,0],[10,0]], gold)  # tips
	# Stem
	_col(img, 7, 4, 7, dark)
	_col(img, 8, 4, 7, dark)
	# Leaf clusters
	# Left leaf pair
	_px(img, [[3,7],[4,6],[4,7],[4,8],[5,5],[5,6],[5,7],[5,8],[5,9],[6,6],[6,7],[6,8]], purple)
	_px(img, [[3,6],[3,8],[6,5],[6,9]], dark)
	# Right leaf pair
	_px(img, [[9,6],[9,7],[9,8],[10,5],[10,6],[10,7],[10,8],[10,9],[11,6],[11,7],[11,8],[12,7]], purple)
	_px(img, [[12,6],[12,8],[9,5],[9,9]], dark)
	# Lower leaves
	_px(img, [[4,10],[5,10],[5,11],[6,10],[6,11],[6,12],[7,10],[7,11],[7,12]], purple)
	_px(img, [[8,10],[8,11],[8,12],[9,10],[9,11],[10,10],[10,11],[11,10]], purple)
	_px(img, [[4,11],[11,11],[6,13],[7,13],[8,13],[9,13]], dark)
	_icons[&"basilic_royal"] = _tex(img)


# 7. Truffe — brown irregular lumpy truffle shape
static func _gen_truffe() -> void:
	var img := _img()
	var brown := Color("795548")
	var dark := Color("4E342E")
	var hi := Color("A1887F")
	# Lumpy oval body (rows 4-13)
	var widths := [2, 4, 5, 6, 6, 6, 6, 5, 4, 2]
	for i in widths.size():
		var y := 4 + i
		var w: int = widths[i]
		var x0 := 8 - (w + 1) / 2
		_row(img, y, x0, x0 + w - 1, brown)
	# Lumpy bumps
	_px(img, [[4,6],[11,8],[5,11],[10,5]], brown)
	# Dark outline (top/bottom + sides)
	_row(img, 4, 7, 8, dark)
	_row(img, 13, 7, 8, dark)
	for y in range(5, 13):
		var w: int = widths[y - 4]
		var x0 := 8 - (w + 1) / 2
		img.set_pixel(x0, y, dark)
		img.set_pixel(x0 + w - 1, y, dark)
	# Highlights — irregular surface texture
	_px(img, [[6,6],[8,7],[7,9],[9,8],[6,10],[10,7]], hi)
	# Dark texture spots
	_px(img, [[7,7],[9,10],[8,11],[6,8]], dark)
	_icons[&"truffe"] = _tex(img)


# 8. Champi-mi-gnon — cute toadstool: tan cap, white spots, white stem, tiny eyes
static func _gen_champi_mi_gnon() -> void:
	var img := _img()
	var cap := Color("D4A574")
	var white := Color("FFFFFF")
	var eyes := Color("4E342E")
	# Mushroom cap (rows 2-8)
	_row(img, 2, 6, 9, cap)
	_row(img, 3, 5, 10, cap)
	_row(img, 4, 4, 11, cap)
	_row(img, 5, 3, 12, cap)
	_row(img, 6, 3, 12, cap)
	_row(img, 7, 4, 11, cap)
	_row(img, 8, 5, 10, cap)
	# White spots on cap
	_px(img, [[5,4],[6,3],[10,5],[9,4],[7,6],[11,6]], white)
	# Stem (rows 9-14)
	_rect(img, 6, 9, 4, 6, white)
	# Tiny dot eyes on stem area / face
	img.set_pixel(7, 10, eyes)
	img.set_pixel(9, 10, eyes)
	# Cute mouth
	img.set_pixel(8, 12, eyes)
	_icons[&"champi_mi_gnon"] = _tex(img)


# 9. Morille Doree — tall golden honeycomb-patterned cone on pale stem
static func _gen_morille_doree() -> void:
	var img := _img()
	var gold := Color("F4D03F")
	var dark := Color("B7950B")
	var stem := Color("F5F5DC")
	# Pale stem (rows 11-15)
	_rect(img, 7, 11, 2, 5, stem)
	_px(img, [[6,11],[9,11]], stem)
	# Conical cap (rows 0-10)
	var widths := [2, 2, 4, 4, 6, 6, 6, 8, 8, 6, 4]
	for i in widths.size():
		var w: int = widths[i]
		var x0 := 8 - w / 2
		_row(img, i, x0, x0 + w - 1, gold)
	# Honeycomb pattern — dark grid lines
	for i in widths.size():
		var w: int = widths[i]
		var x0 := 8 - w / 2
		if i % 2 == 0:
			for x in range(x0 + 1, x0 + w, 2):
				img.set_pixel(x, i, dark)
		else:
			for x in range(x0, x0 + w, 2):
				img.set_pixel(x, i, dark)
	# Side outlines
	for i in widths.size():
		var w: int = widths[i]
		var x0 := 8 - w / 2
		img.set_pixel(x0, i, dark)
		img.set_pixel(x0 + w - 1, i, dark)
	_icons[&"morille_doree"] = _tex(img)


# 10. Pleurote Cascade — 3 overlapping purple fan-shaped shelves cascading
static func _gen_pleurote_cascade() -> void:
	var img := _img()
	var purple := Color("AF7AC5")
	var dark := Color("7D3C98")
	var light := Color("D7BDE2")
	# Top shelf (small, right-shifted)
	_row(img, 1, 8, 12, purple)
	_row(img, 2, 7, 13, purple)
	_row(img, 3, 7, 13, purple)
	_px(img, [[8,1],[13,2],[13,3]], dark)
	_px(img, [[9,1],[8,2]], light)
	# Middle shelf (medium, left-shifted)
	_row(img, 5, 3, 9, purple)
	_row(img, 6, 2, 10, purple)
	_row(img, 7, 2, 10, purple)
	_row(img, 8, 3, 9, purple)
	_px(img, [[2,6],[2,7],[10,6],[10,7]], dark)
	_px(img, [[4,5],[3,6]], light)
	# Bottom shelf (large, right-shifted)
	_row(img, 10, 5, 13, purple)
	_row(img, 11, 4, 14, purple)
	_row(img, 12, 4, 14, purple)
	_row(img, 13, 5, 13, purple)
	_px(img, [[4,11],[4,12],[14,11],[14,12]], dark)
	_px(img, [[6,10],[5,11]], light)
	# Connecting stem on right side
	_col(img, 11, 3, 10, dark)
	_icons[&"pleurote_cascade"] = _tex(img)


# 11. Mousse Lunaire — low blue-green moss mound with crescent moon above
static func _gen_mousse_lunaire() -> void:
	var img := _img()
	var blue := Color("5DADE2")
	var dark := Color("2E86C1")
	var moon := Color("F9E79F")
	# Crescent moon (upper area, rows 1-5)
	_px(img, [[9,0],[10,0],[11,0]], moon)
	_px(img, [[8,1],[12,1]], moon)
	_px(img, [[8,2],[11,2]], moon)
	_px(img, [[8,3],[11,3]], moon)
	_px(img, [[8,4],[10,4],[11,4]], moon)
	_px(img, [[9,5],[10,5]], moon)
	# Moss mound (rows 8-15)
	_row(img, 8, 6, 9, blue)
	_row(img, 9, 4, 11, blue)
	_row(img, 10, 3, 12, blue)
	_row(img, 11, 2, 13, blue)
	_row(img, 12, 2, 13, blue)
	_row(img, 13, 1, 14, blue)
	_row(img, 14, 1, 14, blue)
	_row(img, 15, 1, 14, blue)
	# Dark texture bumps
	_px(img, [[3,11],[5,10],[8,9],[11,10],[13,12]], dark)
	_px(img, [[2,13],[6,12],[9,11],[12,13],[4,14],[10,14]], dark)
	# Bottom outline
	_row(img, 15, 1, 14, dark)
	_px(img, [[1,13],[1,14],[14,13],[14,14]], dark)
	_icons[&"mousse_lunaire"] = _tex(img)


# 12. Patate Douce — rounded orange-brown tuber + small purple sprout
static func _gen_patate_douce() -> void:
	var img := _img()
	var orange := Color("DC7633")
	var dark := Color("A04000")
	var sprout := Color("9B59B6")
	# Purple sprout (top-right, rows 2-6)
	img.set_pixel(10, 2, sprout)
	_px(img, [[10,3],[11,3]], sprout)
	_px(img, [[9,4],[10,4]], sprout)
	img.set_pixel(9, 5, sprout)
	# Tuber body (rows 6-14)
	_row(img, 6, 5, 10, orange)
	_row(img, 7, 3, 12, orange)
	_row(img, 8, 2, 13, orange)
	_row(img, 9, 2, 13, orange)
	_row(img, 10, 2, 13, orange)
	_row(img, 11, 2, 13, orange)
	_row(img, 12, 3, 12, orange)
	_row(img, 13, 4, 11, orange)
	_row(img, 14, 6, 9, orange)
	# Dark outline
	_row(img, 6, 5, 10, dark)
	_row(img, 14, 6, 9, dark)
	for y in range(7, 14):
		var w: int
		match y:
			7, 12: w = 3
			13: w = 4
			_: w = 2
		img.set_pixel(8 - (14 - y + 3), y, dark)
	_px(img, [[2,8],[2,9],[2,10],[2,11],[13,8],[13,9],[13,10],[13,11]], dark)
	_px(img, [[3,7],[3,12],[12,7],[12,12],[4,13],[11,13]], dark)
	_icons[&"patate_douce"] = _tex(img)


# 13. Radis Rose — round pink bulb + green leaves on top + white root tip
static func _gen_radis_rose() -> void:
	var img := _img()
	var pink := Color("F1948A")
	var dark := Color("C0392B")
	var green := Color("27AE60")
	var white := Color("FFFFFF")
	# Green leaves (rows 0-4)
	_px(img, [[7,0],[8,0]], green)
	_px(img, [[5,1],[6,1],[7,1],[8,1],[9,1],[10,1]], green)
	_px(img, [[4,2],[6,2],[7,2],[8,2],[9,2],[11,2]], green)
	_px(img, [[5,3],[7,3],[8,3],[10,3]], green)
	_px(img, [[6,4],[7,4],[8,4],[9,4]], green)
	# Pink bulb (rows 5-12)
	_row(img, 5, 5, 10, pink)
	_row(img, 6, 4, 11, pink)
	_row(img, 7, 4, 11, pink)
	_row(img, 8, 4, 11, pink)
	_row(img, 9, 4, 11, pink)
	_row(img, 10, 5, 10, pink)
	_row(img, 11, 6, 9, pink)
	_row(img, 12, 7, 8, pink)
	# Dark outline
	_row(img, 5, 5, 10, dark)
	_row(img, 12, 7, 8, dark)
	_px(img, [[4,6],[4,7],[4,8],[4,9],[11,6],[11,7],[11,8],[11,9]], dark)
	_px(img, [[5,10],[10,10],[6,11],[9,11]], dark)
	# White root
	_px(img, [[7,13],[8,13]], white)
	img.set_pixel(8, 14, white)
	_icons[&"radis_rose"] = _tex(img)


# 14. Navet Tournoyant — cream turnip with purple top + motion line pixels
static func _gen_navet_tournoyant() -> void:
	var img := _img()
	var cream := Color("F5F5DC")
	var purple := Color("8E44AD")
	var motion := Color("BFC9CA")
	# Leaves
	_px(img, [[7,0],[8,0]], purple)
	_px(img, [[6,1],[7,1],[8,1],[9,1]], purple)
	# Purple top of turnip (rows 2-5)
	_row(img, 2, 6, 9, purple)
	_row(img, 3, 5, 10, purple)
	_row(img, 4, 4, 11, purple)
	_row(img, 5, 4, 11, purple)
	# Cream body (rows 6-12)
	_row(img, 6, 4, 11, cream)
	_row(img, 7, 4, 11, cream)
	_row(img, 8, 5, 10, cream)
	_row(img, 9, 5, 10, cream)
	_row(img, 10, 6, 9, cream)
	_row(img, 11, 7, 8, cream)
	_row(img, 12, 7, 8, cream)
	# Root tip
	img.set_pixel(7, 13, cream)
	# Motion lines (right side, suggesting spin)
	_px(img, [[13,4],[14,5]], motion)
	_px(img, [[13,7],[14,8]], motion)
	_px(img, [[13,10],[14,11]], motion)
	# Left motion lines
	_px(img, [[1,5],[2,4]], motion)
	_px(img, [[1,8],[2,7]], motion)
	_px(img, [[1,11],[2,10]], motion)
	_icons[&"navet_tournoyant"] = _tex(img)


# 15. Gingembre Tourne-Vent — gnarled golden root + small windmill on top
static func _gen_gingembre_tourne_vent() -> void:
	var img := _img()
	var gold := Color("F39C12")
	var dark := Color("B7950B")
	var red := Color("E74C3C")
	# Windmill on top (rows 0-4)
	img.set_pixel(8, 2, dark)  # center hub
	# 4 blades
	_px(img, [[8,0],[8,1]], red)   # top blade
	_px(img, [[8,3],[8,4]], red)   # bottom blade
	_px(img, [[6,2],[7,2]], red)   # left blade
	_px(img, [[9,2],[10,2]], red)  # right blade
	# Windmill stick
	_col(img, 8, 5, 6, dark)
	# Gnarled root body (rows 7-14)
	_row(img, 7, 5, 11, gold)
	_row(img, 8, 4, 12, gold)
	_row(img, 9, 3, 12, gold)
	_row(img, 10, 3, 13, gold)
	_row(img, 11, 4, 12, gold)
	_row(img, 12, 5, 11, gold)
	_row(img, 13, 6, 10, gold)
	# Knobby extensions
	_px(img, [[2,9],[2,10],[13,9],[14,10]], gold)
	_px(img, [[5,13],[5,14],[10,13],[11,14]], gold)
	# Dark outline/texture
	_px(img, [[3,9],[3,10],[13,10]], dark)
	_px(img, [[5,7],[11,7]], dark)
	_px(img, [[4,8],[12,8],[4,11],[12,11]], dark)
	_px(img, [[6,12],[10,12],[7,13],[9,13]], dark)
	_icons[&"gingembre_tourne_vent"] = _tex(img)


# 16. Ail des Ours — white garlic bulb bottom + broad green leaves fanning up
static func _gen_ail_des_ours() -> void:
	var img := _img()
	var white := Color("F5F5DC")
	var dark := Color("BFC9CA")
	var green := Color("27AE60")
	# Green leaves fanning up (rows 0-8)
	# Left leaf
	_col(img, 4, 2, 8, green)
	_col(img, 5, 1, 8, green)
	img.set_pixel(5, 0, green)
	# Center leaf
	_col(img, 7, 0, 8, green)
	_col(img, 8, 0, 8, green)
	# Right leaf
	_col(img, 10, 1, 8, green)
	_col(img, 11, 2, 8, green)
	# Garlic bulb (rows 9-14)
	_row(img, 9, 5, 10, white)
	_row(img, 10, 4, 11, white)
	_row(img, 11, 4, 11, white)
	_row(img, 12, 4, 11, white)
	_row(img, 13, 5, 10, white)
	_row(img, 14, 6, 9, white)
	# Clove lines on bulb
	_col(img, 6, 10, 13, dark)
	_col(img, 9, 10, 13, dark)
	# Outline
	_px(img, [[4,10],[4,11],[4,12],[11,10],[11,11],[11,12]], dark)
	_px(img, [[5,13],[10,13],[6,14],[9,14]], dark)
	_row(img, 9, 5, 10, dark)
	# Root tip
	_px(img, [[7,15],[8,15]], dark)
	_icons[&"ail_des_ours"] = _tex(img)


# 17. Fougere d'Or — golden fern frond: central stem with alternating leaflets
static func _gen_fougere_dor() -> void:
	var img := _img()
	var green := Color("229954")
	var gold := Color("F4D03F")
	var dark := Color("B7950B")
	# Central stem (curling at top)
	_col(img, 8, 2, 15, dark)
	_px(img, [[9,1],[10,1]], dark)  # curl tip
	img.set_pixel(10, 0, dark)
	# Alternating leaflets — left side (even rows), right side (odd rows)
	for i in range(6):
		var y := 3 + i * 2
		var length: int = 4 - i / 2
		# Left leaflet
		_row(img, y, 8 - length, 7, gold)
		img.set_pixel(8 - length, y, green)
	for i in range(6):
		var y := 4 + i * 2
		var length: int = 4 - i / 2
		# Right leaflet
		if y < 15:
			_row(img, y, 9, 8 + length, gold)
			img.set_pixel(8 + length, y, green)
	# Extra gold color near tip
	_px(img, [[9,2],[10,2]], gold)
	_icons[&"fougere_dor"] = _tex(img)


# 18. Fraise Sauvage — red strawberry (inverted triangle) + yellow seeds + green cap
static func _gen_fraise_sauvage() -> void:
	var img := _img()
	var red := Color("CB4335")
	var dark := Color("922B21")
	var seeds := Color("F4D03F")
	var green := Color("27AE60")
	# Green cap + stem (rows 0-3)
	img.set_pixel(7, 0, green)
	img.set_pixel(8, 0, green)
	_px(img, [[5,1],[6,1],[7,1],[8,1],[9,1],[10,1]], green)
	_px(img, [[4,2],[6,2],[7,2],[8,2],[9,2],[11,2]], green)
	_px(img, [[5,3],[10,3]], green)
	# Strawberry body — inverted triangle (rows 3-13)
	_row(img, 3, 3, 12, red)
	_row(img, 4, 3, 12, red)
	_row(img, 5, 3, 12, red)
	_row(img, 6, 3, 12, red)
	_row(img, 7, 4, 11, red)
	_row(img, 8, 4, 11, red)
	_row(img, 9, 5, 10, red)
	_row(img, 10, 5, 10, red)
	_row(img, 11, 6, 9, red)
	_row(img, 12, 7, 8, red)
	_row(img, 13, 7, 8, red)
	# Dark outline
	_px(img, [[3,3],[3,4],[3,5],[3,6]], dark)
	_px(img, [[12,3],[12,4],[12,5],[12,6]], dark)
	_px(img, [[4,7],[4,8],[11,7],[11,8]], dark)
	_px(img, [[5,9],[5,10],[10,9],[10,10]], dark)
	_px(img, [[6,11],[9,11]], dark)
	_px(img, [[7,12],[8,12],[7,13],[8,13]], dark)
	# Yellow seed dots
	_px(img, [[5,4],[9,4],[7,5],[11,5]], seeds)
	_px(img, [[5,7],[9,7],[7,8]], seeds)
	_px(img, [[6,10],[9,10]], seeds)
	_icons[&"fraise_sauvage"] = _tex(img)
