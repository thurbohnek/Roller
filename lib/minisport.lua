-- Felles deler for idrettsminispillene (lagt til 2026-09-28):
-- scenes/mini_100m.lua, scenes/mini_lengdehopp.lua og
-- scenes/mini_hoydehopp.lua.
--
-- Marken er den ekte marken fra banene med samme fysikk
-- (lib/markfysikk.lua), og styres likt: slipp = ring som ruller, hold =
-- strekker seg ut, dobbelttrykk = slapp, ett trykk = stram igjen.
-- Øvelsene er bygget rundt det marken faktisk kan (målt i en kopi av
-- fysikken, se KODEBASE.md): den ruller bare nedover av seg selv, strekk
-- før en kant gir lengre og høyere hopp, og slapp glir gjennom trange
-- sprekker med is.
--
-- Banene er i "verdenspiksler" som i Box2D-oppsettet i banene, og
-- kameraet er det samme som i banene (M.kamera).

local composer = require( "composer" )
local physics = require( "physics" )
local perspective = require( "lib.perspective" )
local GGData = require( "lib.GGData" )
local ui = require( "lib.ui" )

local M = {}

M.B = display.contentWidth
M.H = display.contentHeight
M.STEIN = 3.0                  -- friksjon på stein, som i banene
M.IS = 0.05                    -- friksjon på is, som i banene

-- Rekorder, lagret mellom hver gang spillet startes.
local data = GGData:new( "minispill" )

function M.rekord( navn )
	return data[navn]
end

-- Lagrer verdien hvis den er bedre. storreErBedre: true for hopp, false
-- for tid. Returnerer true hvis det er ny rekord.
function M.nyRekord( navn, verdi, storreErBedre )
	local gammel = data[navn]
	local bedre = gammel == nil or ( storreErBedre and verdi > gammel ) or ( not storreErBedre and verdi < gammel )
	if bedre then
		data[navn] = verdi
		data:save()
	end
	return bedre
end

-- Bakgrunn: arenaen under jorda (ui/arena_bg.jpg, laget av
-- Util/grafikk/lag_ui.py), tre bilder etter hverandre som ruller sakte
-- bak banen: kall bg:rull( kameraX ) hvert bilde.
function M.bakgrunn( forelder )
	local g = display.newGroup()
	forelder:insert( g )
	-- dekker hele skjermhøyden, også på skjermer som er høyere enn 16:9
	local hoyde = display.actualContentHeight + 20
	local BB = 1200 * hoyde / 540
	for i = 0, 2 do
		local bg = display.newImageRect( g, "ui/arena_bg.jpg", BB, hoyde )
		bg.anchorX = 0
		bg.x, bg.y = display.screenOriginX + ( i - 1 ) * BB, display.contentCenterY
	end
	function g:rull( kx )
		g.x = -( ( kx * 0.3 ) % BB )
	end
	return g
end

-- Løpebane i ny stil (2026-10-28): rødbrun bane med lys kant oppå jord.
local KANT = ui.rgb( "C9563A" )
local KANT_LYS = { 1, 0.75, 0.6 }
local ISFARGE = { 0.47, 0.8, 0.98 }

local function flat( pkt )
	local ut = {}
	for _, p in ipairs( pkt ) do
		ut[#ut + 1] = p[1]
		ut[#ut + 1] = p[2]
	end
	return ut
end

-- Stein langs pkt (liste med {x, y}, fra venstre mot høyre). opp = true
-- gir tak (steinen fylles oppover i stedet for nedover). Tegnes i
-- fargene fra banene, med en fysisk kjede langs overflata.
function M.terreng( verden, pkt, valg )
	valg = valg or {}
	local dybde = valg.dybde or ( valg.opp and 260 or 1400 )
	-- steinen følger overflata dybde px nedover (eller oppover for tak),
	-- så den ser ut som en masse og ikke en kloss
	local fyll = {}
	for _, p in ipairs( pkt ) do fyll[#fyll + 1] = { p[1], p[2] } end
	local retning = valg.opp and -1 or 1
	for i = #pkt, 1, -1 do
		fyll[#fyll + 1] = { pkt[i][1], pkt[i][2] + retning * dybde }
	end
	local minx, maxx, miny, maxy = math.huge, -math.huge, math.huge, -math.huge
	for _, p in ipairs( fyll ) do
		minx, maxx = math.min( minx, p[1] ), math.max( maxx, p[1] )
		miny, maxy = math.min( miny, p[2] ), math.max( maxy, p[2] )
	end
	local poly = display.newPolygon( verden, ( minx + maxx ) / 2, ( miny + maxy ) / 2, flat( fyll ) )
	if valg.opp then
		poly.fill = ui.gradient( ui.F.jordMork, ui.F.jord )
	else
		poly.fill = ui.gradient( ui.F.jord, ui.F.jordMork )
	end
	local linje = display.newLine( verden, pkt[1][1], pkt[1][2], pkt[2][1], pkt[2][2] )
	for i = 3, #pkt do linje:append( pkt[i][1], pkt[i][2] ) end
	linje:setStrokeColor( unpack( valg.farge or ( valg.is and ISFARGE ) or KANT ) )
	linje.strokeWidth = valg.is and 22 or 30
	-- lys stripe langs toppen av banen
	if not valg.opp then
		local glans = display.newLine( verden, pkt[1][1], pkt[1][2] - 11, pkt[2][1], pkt[2][2] - 11 )
		for i = 3, #pkt do glans:append( pkt[i][1], pkt[i][2] - 11 ) end
		glans:setStrokeColor( KANT_LYS[1], KANT_LYS[2], KANT_LYS[3], 0.45 )
		glans.strokeWidth = 5
	end
	-- fysikken: en kjede langs overflata, fra et usynlig ankerpunkt i (0, 0)
	local anker = display.newRect( verden, 0, 0, 1, 1 )
	anker.isVisible = false
	physics.addBody( anker, "static", { chain = flat( pkt ), connectFirstAndLast = false,
		friction = valg.is and M.IS or M.STEIN } )
	return anker
end

-- Merke i verden (en liten stolpe med tekst over bakken i x, y).
function M.merke( verden, x, y, tekst, storrelse )
	local p = display.newRoundedRect( verden, x, y - 34, 10, 68, 5 )
	p:setFillColor( unpack( ui.F.krem ) )
	local skilt = display.newRoundedRect( verden, x, y - 96, ( storrelse or 40 ) * ( #tekst * 0.62 + 0.9 ),
		( storrelse or 40 ) * 1.35, 14 )
	skilt:setFillColor( ui.F.jordMork[1], ui.F.jordMork[2], ui.F.jordMork[3], 0.85 )
	skilt.strokeWidth = 4
	skilt:setStrokeColor( unpack( ui.F.kant ) )
	local t = display.newText( { parent = verden, text = tekst, x = x, y = y - 98,
		font = ui.SKRIFT_FET, fontSize = storrelse or 40 } )
	t:setFillColor( unpack( ui.F.krem ) )
	return t
end

-- Tekst som øvelsene endrer med o.text = "...". Samme skrift som resten
-- av spillet.
function M.tekst( forelder, t, x, y, storrelse, farge )
	local o = display.newText( { parent = forelder, text = t, x = x, y = y,
		font = ui.SKRIFT_FET, fontSize = storrelse or 22 } )
	o:setFillColor( unpack( farge or ui.F.krem ) )
	return o
end

-- Knappene reagerer på "touch", ikke "tap": da tar knappen hele trykket,
-- så det ikke også går videre til trykkflata under og starter løpet.
local function paaTrykk( o, trykk )
	o:addEventListener( "touch", function( e )
		if e.phase == "began" then
			display.getCurrentStage():setFocus( o )
		elseif e.phase == "ended" or e.phase == "cancelled" then
			display.getCurrentStage():setFocus( nil )
			if e.phase == "ended" then
				require( "lib.lyd" ).spill( "klikk" )
				trykk()
			end
		end
		return true
	end )
end
M.paaTrykk = paaTrykk

-- Knapper i ny stil. Øvelsene oppgir fortsatt de gamle bildenavnene;
-- de gjøres om til tekst og farge her.
local KNAPPER = {
	["knapp_opp.png"] = { "Bar up", "bla" },
	["knapp_ned.png"] = { "Bar down", "bla" },
	["knapp_igjen.png"] = { "Again", "gronn", "igjen" },
	["knapp_games.png"] = { "Events", "oransje", "liste" },
}

function M.knapp( forelder, bilde, x, y, trykk )
	local v = KNAPPER[bilde] or { bilde, "jord" }
	local k = ui.knapp( forelder, { tekst = v[1], ikon = v[3], x = x, y = y, bredde = v[3] and 160 or 140,
		hoyde = 50, farge = v[2], storrelse = 19 } )
	paaTrykk( k, trykk )
	return k
end

local function tilMeny()
	local ok, err = pcall( composer.gotoScene, "scenes.minispill", { effect = "fade", time = 400 } )
	if not ok then
		print( "CRASH going to minispill: " .. tostring( err ) )
	end
end

-- Tilbake til minispillmenyen, samme runde knapp som ellers i spillet.
function M.tilbake( forelder )
	-- ui.trykkbar tar hele trykket, så det ikke også starter løpet
	return ui.rundKnapp( forelder, "tilbake", ui.VENSTRE + 40, 36, 56, tilMeny )
end

-- Hele skjermen tar imot trykk og sender dem til marken, som i banene
-- (began = trykk, ended = slipp). vedTrykk kalles i tillegg ved hvert
-- trykk, så scenen kan starte løpet.
function M.trykkflate( forelder, hentMark, vedTrykk )
	local flate = display.newRect( forelder, M.B / 2, M.H / 2, M.B * 3, M.H * 3 )
	flate.isVisible = false
	flate.isHitTestable = true
	flate:addEventListener( "touch", function( e )
		local mark = hentMark()
		if e.phase == "began" then
			if vedTrykk and vedTrykk() == false then return true end
			if mark then mark:trykk() end
		elseif e.phase == "ended" or e.phase == "cancelled" then
			if mark then mark:slipp() end
		end
		return true
	end )
	return flate
end

-- Kamera, på samme måte som i banene: lib/perspective.lua med demping
-- 10, kameraet skalert 0,6 inni en gruppe som også er skalert 0,6, og
-- fokus på "punkt" (sveiset til marken, mark.punkt). Returnerer kameraet
-- og verdensgruppa (i lag 1) som alt i øvelsen legges i.
-- Kall kamera:setFocus( mark.punkt ) når marken er laget.
function M.kamera( forelder, bakgrunn )
	local ytre = display.newGroup()
	forelder:insert( ytre )
	local kamera = perspective.createView()
	ytre:insert( kamera )
	-- Zoom: banene viser verden i 0,6. Øvelsene var 0,36 (marken ble
	-- veldig liten); 0,48 fra 2026-10-28 viser marken tydeligere og nok
	-- av løypa foran.
	local ZOOM_YTRE = 0.8
	local z = 0.6 * ZOOM_YTRE
	kamera.xScale, kamera.yScale = 0.6, 0.6
	ytre.xScale, ytre.yScale = ZOOM_YTRE, ZOOM_YTRE
	-- I banene havner fokuset øverst til venstre (0,36 x midten av
	-- skjermen), fordi bakken der går nedover mot høyre. Øvelsene er
	-- flate, så hele kameraet flyttes til marken står litt til venstre
	-- for midten og litt under, med bakken synlig foran.
	ytre.x = M.B * 0.33 - display.contentCenterX * z
	ytre.y = M.H * 0.6 - display.contentCenterY * z
	local verden = display.newGroup()
	kamera:add( verden, 1, false )
	-- mørkt felt bak tekstene øverst, så de kan leses mot arenaen
	local felt = display.newRoundedRect( forelder, ui.CX, 66, 700, 116, 26 )
	felt:setFillColor( ui.F.jordMork[1], ui.F.jordMork[2], ui.F.jordMork[3], 0.72 )
	-- banene setter grenser rundt hele banen; her er løypene i
	-- negative koordinater også, så ingen grenser
	kamera:setBounds( -1e7, 1e7, -1e7, 1e7 )
	kamera.damping = 10
	kamera:track()
	if bakgrunn then
		local lag1 = kamera:layer( 1 )
		kamera.bakgrunnLytter = function()
			if lag1.x then bakgrunn:rull( -lag1.x * z ) end
		end
		Runtime:addEventListener( "enterFrame", kamera.bakgrunnLytter )
	end
	function kamera:stopp()
		kamera:cancel()
		if kamera.bakgrunnLytter then
			Runtime:removeEventListener( "enterFrame", kamera.bakgrunnLytter )
		end
	end
	return kamera, verden
end

-- Resultatpanel med knapper (ny stil).
function M.resultat( forelder, linjer, igjen )
	local g = display.newGroup()
	forelder:insert( g )
	local px, py = M.B / 2, M.H / 2 - 10
	ui.hinne( g, 0.4 )
	ui.panel( g, px, py, 540, 290 )
	require( "lib.lyd" ).spill( "mal" )
	for i, l in ipairs( linjer ) do
		local f = l[3]
		if i == 1 then f = f or ui.F.gull end
		M.tekst( g, l[1], px, py - 96 + ( i - 1 ) * 40, l[2] or 24, f )
	end
	M.knapp( g, "knapp_igjen.png", px - 95, py + 92, function()
		display.remove( g )
		igjen()
	end )
	M.knapp( g, "knapp_games.png", px + 95, py + 92, tilMeny )
	ui.sprett( g, 0 )
	return g
end

return M
