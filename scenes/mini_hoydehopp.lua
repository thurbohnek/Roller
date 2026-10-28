-- Minispill: høydehopp (lagt til 2026-09-28, ekte markfysikk fra samme
-- dag, flat bane og fysisk liste fra 2026-09-29 etter ønske fra Mathias).
-- En liten bakke gir litt fart, så er det flatt fram til lista. Marken
-- må selv hoppe over: hold inne på riktig tidspunkt, så strekker den seg
-- og spretter opp. Lista stilles med "Bar up" / "Bar down" (5 cm om
-- gangen) og ligger løst på en knagg, så den faller ned hvis marken
-- treffer den. Hele marken må over. Tre forsøk per høyde.
--
-- Målt i en kopi av fysikken (se KODEBASE.md): uten å trykke ruller
-- marken rett inn i lista. Holder man inne når hodet er oppe foran i
-- ringen, et stykke før lista, kan den komme opptil ca. 145 px over
-- bakken der lista står, men det er følsomt for tidspunktet.
-- 50 px = 1 m.

local composer = require( "composer" )
local physics = require( "physics" )
local sport = require( "lib.minisport" )
local markfysikk = require( "lib.markfysikk" )

local scene = composer.newScene()

local GRADER, BAKKE = 22, 400
local TAN = math.tan( math.rad( GRADER ) )
local GULVY = BAKKE * TAN + 230
local LISTEX = BAKKE + 900
local PX_PER_M = 50
local MIN, MAKS, STEG = 0.10, 3.00, 0.05

-- lista sett fra siden (enden av en liste som går inn i skjermen) og
-- knaggen den ligger på. Knaggen kolliderer bare med lista.
local LISTE_B, LISTE_H = 34, 12
local KNAGG = { kategori = 2, maske = 4 }
local LISTEKAT = 4

local tilstand, mark, hoyde, bom, beste, lavest, stilleTid, etterTid
local kamera, verden, bakgrunn, liste, knagg, listeStart, info, status, opp, ned
local lytter

local function listeBunnY()
	return GULVY - hoyde * PX_PER_M
end

local function lagListe()
	display.remove( liste )
	display.remove( knagg )
	local by = listeBunnY()
	knagg = display.newRect( verden, LISTEX + 5, by + 4, 22, 8 )  -- tyngdepunktet til lista er over knaggen
	knagg:setFillColor( 0.45, 0.36, 0.28 )
	physics.addBody( knagg, "static", { friction = 0.3,
		filter = { categoryBits = KNAGG.kategori, maskBits = KNAGG.maske } } )
	liste = display.newRect( verden, LISTEX, by - LISTE_H / 2, LISTE_B, LISTE_H )
	liste:setFillColor( 0.95, 0.9, 0.8 )
	liste.strokeWidth = 3
	liste:setStrokeColor( 0.6, 0.25, 0.1 )
	physics.addBody( liste, "dynamic", { density = 0.3, friction = 0.4, bounce = 0.1,
		filter = { categoryBits = LISTEKAT, maskBits = 65535 } } )
	listeStart = { x = liste.x, y = liste.y }
end

local function listeRevet()
	if not liste or not liste.x then return true end
	return math.abs( liste.y - listeStart.y ) > 6 or math.abs( liste.x - listeStart.x ) > 10
		or math.abs( liste.rotation ) > 12
end

local function visStatus()
	local merke = ""
	for i = 1, bom do merke = merke .. " X" end
	status.text = string.format( "Bar: %.2f m", hoyde ) .. "   Misses:" .. ( merke == "" and " -" or merke ) ..
		( beste and string.format( "   Best: %.2f m", beste ) or "" )
end

local function nyttForsok()
	tilstand = "klar"
	physics.pause()
	if mark then mark:fjern() end
	mark = markfysikk.lag( verden, 0, 0 )
	lagListe()
	-- mens lista stilles, står kameraet slik at lista synes
	-- (fokus vises øverst til venstre, som i banene)
	kamera:setFocus( { x = LISTEX - 900, y = GULVY - 450 } )
	lavest, stilleTid, etterTid = nil, 0, 0
	opp.isVisible, ned.isVisible = true, true
	info.text = "Set the bar, then tap to start. Hold when the head is at the top front to jump."
	visStatus()
end

local function endreHoyde( d )
	if tilstand ~= "klar" then return end
	hoyde = math.max( MIN, math.min( MAKS, math.floor( ( hoyde + d ) * 100 + 0.5 ) / 100 ) )
	bom = 0
	lagListe()
	visStatus()
end

local function ferdigForsok( klart, tekst )
	tilstand = "vent"
	if klart then
		bom = 0
		if beste == nil or hoyde > beste then beste = hoyde end
		if sport.nyRekord( "hoydehopp_fysikk", hoyde, true ) then
			tekst = tekst .. "  New record!"
		end
	else
		bom = bom + 1
		if bom >= 3 then
			tekst = tekst .. "  Three misses: lower the bar or try again."
			bom = 0
		end
	end
	info.text = tekst
	visStatus()
	timer.performWithDelay( 2500, function()
		if tilstand == "vent" then nyttForsok() end
	end )
end

function scene:create( event )
	local grp = self.view
	physics.start()
	hoyde, bom = 0.30, 0
	bakgrunn = sport.bakgrunn( grp )

	kamera, verden = sport.kamera( grp, bakgrunn )

	-- stativet bak lista: stolpe med høydemerker (bare til pynt)
	local topp = GULVY - MAKS * PX_PER_M - 40
	local stolpe = display.newRect( verden, LISTEX + 24, ( GULVY + topp ) / 2, 12, GULVY - topp )
	stolpe:setFillColor( 0.55, 0.45, 0.35 )
	for m = 0.5, MAKS, 0.5 do
		local y = GULVY - m * PX_PER_M
		local s = display.newRect( verden, LISTEX + 24, y, 28, 4 )
		s:setFillColor( 0.9, 0.82, 0.7 )
		local t = display.newText( { parent = verden, text = string.format( "%.1f", m ), x = LISTEX + 70, y = y,
			font = require( "lib.ui" ).SKRIFT_FET, fontSize = 26 } )
		t:setFillColor( 0.9, 0.82, 0.7 )
	end
	-- liten bakke, flatt, og matta bak lista
	sport.terreng( verden, { { -300, -300 * TAN + 230 }, { BAKKE, GULVY }, { LISTEX + 60, GULVY } } )
	sport.terreng( verden, { { LISTEX + 60, GULVY }, { LISTEX + 700, GULVY } }, { farge = { 0.36, 0.66, 0.92 } } )  -- blå matte
	sport.terreng( verden, { { LISTEX + 700, GULVY }, { LISTEX + 3000, GULVY } } )

	sport.tekst( grp, "High jump", sport.B / 2, 30, 30 )
	status = sport.tekst( grp, "", sport.B / 2, 68, 21, { 0.92, 0.9, 0.86 } )
	info = sport.tekst( grp, "", sport.B / 2, 110, 19 )

	sport.trykkflate( grp, function() return mark end, function()
		if tilstand == "klar" then
			tilstand = "tillop"
			kamera:setFocus( mark.punkt )
			opp.isVisible, ned.isVisible = false, false
			info.text = ""
			physics.start()
			return false
		end
		return tilstand == "tillop"
	end )
	opp = sport.knapp( grp, "knapp_opp.png", display.screenOriginX + 90, sport.H / 2 - 40, function() endreHoyde( STEG ) end )
	ned = sport.knapp( grp, "knapp_ned.png", display.screenOriginX + 90, sport.H / 2 + 22, function() endreHoyde( -STEG ) end )
	sport.tilbake( grp )
	nyttForsok()

	local sist = system.getTimer()
	lytter = function()
		local naa = system.getTimer()
		local dt = math.min( 0.05, ( naa - sist ) / 1000 )
		sist = naa
		if not mark or tilstand ~= "tillop" then return end
		local mx, my = mark:senter()
		if not mx then return end
		-- laveste del som passerer lista (bunnen av delen, over bakken)
		for _, d in ipairs( mark.deler ) do
			if math.abs( d.x - LISTEX ) < 14 then
				local h = GULVY - ( d.y + 9 )
				if lavest == nil or h < lavest then lavest = h end
			end
		end
		if mark:fart() < 8 then stilleTid = stilleTid + dt else stilleTid = 0 end
		if listeRevet() then
			etterTid = etterTid + dt
			if etterTid > 1 then ferdigForsok( false, "The bar fell." ) end
		elseif mx > LISTEX + 250 then
			if lavest ~= nil and lavest >= hoyde * PX_PER_M then
				ferdigForsok( true, string.format( "Cleared %.2f m!", hoyde ) )
			else
				ferdigForsok( false, "Under the bar. Jump over it!" )
			end
		elseif stilleTid > 2.5 then
			ferdigForsok( false, "The worm stopped before the bar." )
		end
	end
	Runtime:addEventListener( "enterFrame", lytter )
end

function scene:hide( event )
	if event.phase == "will" then
		Runtime:removeEventListener( "enterFrame", lytter )
		kamera:stopp()
		tilstand = "borte"
	elseif event.phase == "did" then
		mark = nil
		physics.start()
		composer.removeScene( "scenes.mini_hoydehopp" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
