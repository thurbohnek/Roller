-- Felles grafisk system for Roller (lagt til 2026-10-28, ny stil).
--
-- Stilen er en blanding av "lys overflate" (bane 1-2, himmel og gress) og
-- "varm jordhule" (bane 3-9 og menyene, som ligger i markens hjem under
-- bakken). Alt grensesnitt bygges herfra, så farger, skrift, knapper og
-- paneler er like overalt:
--
--     local ui = require( "lib.ui" )
--     ui.tekst( forelder, "Hello", x, y, 28 )
--     ui.knapp( forelder, { tekst = "Play", x = 480, y = 400, farge = "gronn", trykk = fn } )
--     ui.panel( forelder, x, y, bredde, hoyde )
--
-- Ikonene (dråpe, hjerte, unge, pause, lås ...) er bilder i ui/, tegnet av
-- Util/grafikk/lag_ui.py i dobbel oppløsning.

local M = {}

M.B = display.contentWidth
M.H = display.contentHeight
M.CX = display.contentCenterX
M.CY = display.contentCenterY
-- hele skjermen, også utenfor 16:9-feltet på brede/høye telefoner
M.VENSTRE = display.screenOriginX
M.TOPP = display.screenOriginY
M.HOYRE = display.screenOriginX + display.actualContentWidth
M.BUNN = display.screenOriginY + display.actualContentHeight
M.FULL_B = display.actualContentWidth
M.FULL_H = display.actualContentHeight

local function rgb( hex, a )
	local r = tonumber( hex:sub( 1, 2 ), 16 ) / 255
	local g = tonumber( hex:sub( 3, 4 ), 16 ) / 255
	local b = tonumber( hex:sub( 5, 6 ), 16 ) / 255
	return { r, g, b, a or 1 }
end
M.rgb = rgb

-- Fargene. Navnene brukes i resten av koden, aldri tallene direkte.
M.F = {
	jordMork = rgb( "2A1408" ),     -- dypeste jord
	jord = rgb( "3E1F0C" ),         -- paneler
	jordLys = rgb( "5A3014" ),
	kant = rgb( "C47A3A" ),         -- oransje kant rundt paneler
	kantLys = rgb( "E9A060" ),
	krem = rgb( "FFF0DC" ),         -- tekst på mørkt
	kremDempet = rgb( "D9C2A6" ),
	himmel = rgb( "82CDFF" ),
	himmelLys = rgb( "D2ECFF" ),
	gress = rgb( "5BC46A" ),
	gressMork = rgb( "3C9A4B" ),
	oransje = rgb( "F09A3E" ),
	oransjeMork = rgb( "C46E1E" ),
	draape = rgb( "78CDFA" ),
	hjerte = rgb( "F05A6E" ),
	gull = rgb( "FFD054" ),
	lilla = rgb( "46287A" ),        -- tekst på lyst
	hvit = rgb( "FFFFFF" ),
	skygge = rgb( "000000", 0.35 ),
	gra = rgb( "8A7A6A" ),
}

-- Knappefarger: { topp, bunn, kant, tekst }
M.KNAPP = {
	gronn = { rgb( "73D982" ), rgb( "3C9A4B" ), rgb( "2A6E35" ), M.F.hvit },
	oransje = { rgb( "FFB25E" ), rgb( "D9781E" ), rgb( "9A4F10" ), M.F.hvit },
	bla = { rgb( "8FD8FF" ), rgb( "3E9BD6" ), rgb( "236A9A" ), M.F.hvit },
	jord = { rgb( "6A3A1A" ), rgb( "4A2410" ), rgb( "C47A3A" ), M.F.krem },
	rod = { rgb( "FF8090" ), rgb( "D83A52" ), rgb( "9A1E33" ), M.F.hvit },
	gra = { rgb( "A89A8A" ), rgb( "7A6C5E" ), rgb( "54483C" ), M.F.krem },
}

-- Skrift: Fredoka (SIL Open Font License, OFL-Fredoka.txt). Faller
-- tilbake til systemskrift hvis fila ikke kan lastes.
local function lastSkrift( navn )
	local ok, f = pcall( native.newFont, navn )
	if ok and f then return f end
	return native.systemFontBold
end
M.SKRIFT = lastSkrift( "Fredoka-SemiBold" )
M.SKRIFT_FET = lastSkrift( "Fredoka-Bold" )

local function farg( obj, f )
	obj:setFillColor( f[1], f[2], f[3], f[4] or 1 )
end
M.farg = farg

local function gradient( topp, bunn )
	return { type = "gradient", color1 = topp, color2 = bunn, direction = "down" }
end
M.gradient = gradient

-- Tekst. valg: { farge, fet, bredde, juster ("left"/"center"/"right"),
-- skygge (true for mørk skygge under, til tekst rett på bilder) }
function M.tekst( forelder, t, x, y, storrelse, valg )
	valg = valg or {}
	local g = display.newGroup()
	forelder:insert( g )
	local font = valg.fet == false and M.SKRIFT or M.SKRIFT_FET
	local par = { parent = g, text = t, x = 0, y = 0, font = font, fontSize = storrelse or 24,
		width = valg.bredde, align = valg.juster or "center" }
	if valg.skygge then
		local s = display.newText( par )
		s:setFillColor( 0, 0, 0, 0.45 )
		s.x, s.y = 0, math.max( 2, ( storrelse or 24 ) * 0.08 )
	end
	local o = display.newText( par )
	farg( o, valg.farge or M.F.krem )
	g.x, g.y = x, y
	g.tekstObjekt = o
	function g:settTekst( ny )
		for i = 1, g.numChildren do g[i].text = ny end
	end
	if valg.ankerX then
		for i = 1, g.numChildren do g[i].anchorX = valg.ankerX end
	end
	return g
end

-- Panel med myk skygge, mørk jord og oransje kant. valg: { lys = true for
-- hvitt panel (brukes over himmel), radius }
function M.panel( forelder, x, y, b, h, valg )
	valg = valg or {}
	local g = display.newGroup()
	forelder:insert( g )
	local r = valg.radius or 26
	local skygge = display.newRoundedRect( g, 0, 8, b, h, r )
	skygge:setFillColor( 0, 0, 0, 0.35 )
	local bunn = display.newRoundedRect( g, 0, 0, b, h, r )
	if valg.lys then
		bunn.fill = gradient( rgb( "FFFFFF" ), rgb( "EAF4FF" ) )
		bunn.strokeWidth = 4
		bunn:setStrokeColor( unpack( rgb( "B9DDF7" ) ) )
	else
		bunn.fill = gradient( M.F.jordLys, M.F.jord )
		bunn.strokeWidth = 5
		bunn:setStrokeColor( unpack( M.F.kant ) )
	end
	local glans = display.newRoundedRect( g, 0, -h / 2 + 10, b - 24, 6, 3 )
	glans:setFillColor( 1, 1, 1, valg.lys and 0.9 or 0.12 )
	g.x, g.y = x, y
	g.bredde, g.hoyde = b, h
	return g
end

-- Bakgrunnsbilde fra Util/grafikk/lag_ui.py: 1200 x 720 enheter, med
-- innholdet (960 x 540) i midten. Det dekker skjermer fra 4:3 (iPad) til
-- 20:9 uten skalering, så ting som er tegnet inn i bildet (rommene i
-- hjemmet, stien i banevalget) står der knappene er.
function M.bakgrunn( forelder, fil )
	local bg = display.newImageRect( forelder, fil, 1200, 720 )
	bg.x, bg.y = M.CX, M.CY
	return bg
end

-- Mørk hinne over hele skjermen som tar imot alle trykk (bak dialoger).
function M.hinne( forelder, alfa )
	local h = display.newRect( forelder, M.CX, M.CY, M.FULL_B + 40, M.FULL_H + 40 )
	h:setFillColor( 0.05, 0.02, 0, alfa or 0.6 )
	h:addEventListener( "touch", function() return true end )
	h:addEventListener( "tap", function() return true end )
	return h
end

-- Ikon fra ui/. Størrelsene er tegnet i 2x, oppgis her i skjermenheter.
M.IKON = {
	draape = { "ui/draape.png", 1 },     -- forhold bredde/høyde
	hjerte = { "ui/hjerte.png", 1 },
	unge = { "ui/unge.png", 1 },
	ungeTom = { "ui/unge_tom.png", 1 },
	pause = { "ui/pause.png", 1 },
	laas = { "ui/laas.png", 1 },
	tilbake = { "ui/tilbake.png", 1 },
	lyd = { "ui/lyd.png", 1 },
	lydAv = { "ui/lyd_av.png", 1 },
	gave = { "ui/gave.png", 1 },
	stjerne = { "ui/stjerne.png", 1 },
	hjem = { "ui/hjem.png", 1 },
	igjen = { "ui/igjen.png", 1 },
	spill = { "ui/spill.png", 1 },
	liste = { "ui/liste.png", 1 },
	tannhjul = { "ui/tannhjul.png", 1 },
	hake = { "ui/hake.png", 1 },
	hjelp = { "ui/hjelp.png", 1 },
	magnet = { "ui/magnet.png", 1 },
	klover = { "ui/klover.png", 1 },
	radar = { "ui/radar.png", 1 },
	flagg = { "ui/flagg.png", 1 },
	pose = { "ui/pose.png", 1 },
}
function M.ikon( forelder, navn, x, y, storrelse )
	local i = M.IKON[navn]
	local o = display.newImageRect( forelder, i[1], storrelse * i[2], storrelse )
	o.x, o.y = x, y
	return o
end

-- Lite trykk-lyd (fins ikke ennå; plass til den her).
local function klikk() require( "lib.lyd" ).spill( "klikk" ) end

-- Knapp som reagerer på touch: krymper litt når den trykkes, og utløser
-- ved slipp over knappen. Tar hele trykket, så ingenting under reagerer.
function M.trykkbar( obj, trykk )
	obj.isHitTestable = true
	obj:addEventListener( "touch", function( e )
		if e.phase == "began" then
			display.getCurrentStage():setFocus( obj )
			obj.erTrykket = true
			transition.cancel( obj )
			transition.to( obj, { time = 70, xScale = 0.94, yScale = 0.94 } )
		elseif obj.erTrykket and ( e.phase == "ended" or e.phase == "cancelled" ) then
			display.getCurrentStage():setFocus( nil )
			obj.erTrykket = false
			transition.to( obj, { time = 110, xScale = 1, yScale = 1, transition = easing.outBack } )
			local b = obj.contentBounds
			if e.phase == "ended" and b and e.x >= b.xMin and e.x <= b.xMax and e.y >= b.yMin and e.y <= b.yMax then
				klikk()
				trykk( e )
			end
		end
		return true
	end )
	return obj
end

-- Knapp. valg: { tekst, ikon, x, y, bredde, hoyde, farge (navn i M.KNAPP),
-- storrelse (skrift), trykk }
function M.knapp( forelder, valg )
	local g = display.newGroup()
	forelder:insert( g )
	local b, h = valg.bredde or 200, valg.hoyde or 64
	local f = M.KNAPP[valg.farge or "gronn"]
	local r = math.min( h / 2, 26 )
	local skygge = display.newRoundedRect( g, 0, 6, b, h, r )
	skygge:setFillColor( f[3][1], f[3][2], f[3][3], 1 )
	local flate = display.newRoundedRect( g, 0, 0, b, h, r )
	flate.fill = gradient( f[1], f[2] )
	flate.strokeWidth = 3
	flate:setStrokeColor( f[3][1], f[3][2], f[3][3] )
	local glans = display.newRoundedRect( g, 0, -h / 2 + 8, b - 20, 5, 2.5 )
	glans:setFillColor( 1, 1, 1, 0.35 )
	local tx = 0
	if valg.ikon then
		local s = h * 0.56
		local ix = valg.tekst and ( -b / 2 + 14 + s / 2 ) or 0
		M.ikon( g, valg.ikon, ix, 0, s )
		if valg.tekst then tx = s / 2 + 6 end
	end
	if valg.tekst then
		local t = M.tekst( g, valg.tekst, tx, -2, valg.storrelse or math.floor( h * 0.42 ), { farge = f[4] } )
		g.etikett = t
	end
	g.x, g.y = valg.x or 0, valg.y or 0
	if valg.trykk then M.trykkbar( g, valg.trykk ) end
	function g:aktiv( paa )
		g.alpha = paa and 1 or 0.45
	end
	return g
end

-- Rund ikonknapp (pause, tilbake, lyd ...).
function M.rundKnapp( forelder, ikon, x, y, d, trykk, farge )
	local g = display.newGroup()
	forelder:insert( g )
	local f = M.KNAPP[farge or "jord"]
	local skygge = display.newCircle( g, 0, 4, d / 2 )
	skygge:setFillColor( f[3][1], f[3][2], f[3][3], 1 )
	local flate = display.newCircle( g, 0, 0, d / 2 )
	flate.fill = gradient( f[1], f[2] )
	flate.strokeWidth = 3
	flate:setStrokeColor( f[3][1], f[3][2], f[3][3] )
	g.ikonObj = M.ikon( g, ikon, 0, 0, d * 0.52 )
	g.x, g.y = x, y
	if trykk then M.trykkbar( g, trykk ) end
	return g
end

-- Pille med ikon og tall (HUD og topplinjer). Returnerer gruppa; sett
-- tallet med g:sett( tekst ).
function M.pille( forelder, ikon, x, y, b, tekst, lys )
	local g = display.newGroup()
	forelder:insert( g )
	local h = 52
	local flate = display.newRoundedRect( g, 0, 0, b, h, h / 2 )
	if lys then
		flate:setFillColor( 1, 1, 1, 0.88 )
		flate:setStrokeColor( unpack( rgb( "B9DDF7" ) ) )
	else
		flate:setFillColor( M.F.jord[1], M.F.jord[2], M.F.jord[3], 0.88 )
		flate:setStrokeColor( unpack( M.F.kant ) )
	end
	flate.strokeWidth = 3
	if ikon then M.ikon( g, ikon, -b / 2 + 28, 0, 34 ) end
	local t = M.tekst( g, tekst or "", ikon and 14 or 0, -1, 26, { farge = lys and M.F.lilla or M.F.krem } )
	g.x, g.y = x, y
	function g:sett( ny ) t:settTekst( ny ) end
	return g
end

-- Stor tittel med kontur (spillnavn, overskrifter på dialoger).
function M.tittel( forelder, t, x, y, storrelse, farge, kantfarge )
	local g = display.newGroup()
	forelder:insert( g )
	local kf = kantfarge or M.F.jordMork
	local tykk = math.max( 2, math.floor( storrelse * 0.07 ) )
	local par = { parent = g, text = t, x = 0, y = 0, font = M.SKRIFT_FET, fontSize = storrelse }
	local sk = display.newText( par )
	sk:setFillColor( 0, 0, 0, 0.3 )
	sk.y = tykk * 2.2
	for i = 0, 15 do
		local a = i * math.pi / 8
		local o = display.newText( par )
		o:setFillColor( kf[1], kf[2], kf[3] )
		o.x, o.y = math.cos( a ) * tykk, math.sin( a ) * tykk
	end
	local o = display.newText( par )
	farg( o, farge or M.F.krem )
	g.x, g.y = x, y
	return g
end

-- Hele dialoger: toner inn og glir litt opp, alt samtidig.
function M.inn( gruppe )
	gruppe.alpha = 0
	local y = gruppe.y
	gruppe.y = y + 24
	transition.to( gruppe, { time = 240, alpha = 1, y = y, transition = easing.outQuad } )
end

-- Liten sprett når noe vises (knapper, ikoner, belønninger).
function M.sprett( obj, forsinkelse )
	obj.xScale, obj.yScale = 0.6, 0.6
	obj.alpha = 0
	transition.to( obj, { delay = forsinkelse or 0, time = 260, xScale = 1, yScale = 1, alpha = 1,
		transition = easing.outBack } )
end

return M
