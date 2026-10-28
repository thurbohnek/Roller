-- Markens hjem: hovedmenyen (lagt til 2026-10-28, ny stil).
--
-- Et snitt av jorda under en eng. Rommene er knapper:
--   Play (midten)      -> banevalget (scenes/banevalg.lua)
--   Family             -> de reddede markeungene, bane for bane
--   Worm athletics     -> minispillene (scenes/minispill.lua)
--   Shop / Quests      -> kommer i neste runde, vises som "Soon"
-- Øverst: dråper, daglig gave, innstillinger og Controls.
--
-- Bakgrunnen (ui/hjem_bg.jpg) og romplasseringene i HJEM_ROM i
-- Util/grafikk/lag_ui.py hører sammen med ROM under.

local composer = require( "composer" )
local ui = require( "lib.ui" )
local framgang = require( "lib.framgang" )
local nav = require( "lib.navigasjon" )

local scene = composer.newScene()

-- x, y, bredde, høyde i skjermenheter (som HJEM_ROM i lag_ui.py)
local ROM = {
	spill = { 480, 330, 300, 150 },
	familie = { 175, 290, 230, 124 },
	athletics = { 205, 455, 250, 104 },
	butikk = { 785, 290, 230, 124 },
	oppdrag = { 755, 455, 250, 104 },
}

local draapePille, gaveKnapp

local function oppdaterDraaper()
	if draapePille then draapePille:sett( tostring( framgang.draaper() ) ) end
end

-- Usynlig trykkflate over et rom.
local function romKnapp( forelder, navn, trykk )
	local r = ROM[navn]
	local flate = display.newRoundedRect( forelder, r[1], r[2], r[3], r[4], r[4] / 2 )
	flate:setFillColor( 1, 1, 1, 0.01 )
	ui.trykkbar( flate, trykk )
	return flate
end

local function romTittel( forelder, navn, tekst )
	local r = ROM[navn]
	return ui.tekst( forelder, tekst, r[1], r[2] + r[4] / 2 - 28, 22, { skygge = true } )
end

-- ------------------------------------------------------------ dialoger

local function lukk( g ) display.remove( g ) end

local function visFamilie( forelder )
	local g = display.newGroup()
	forelder:insert( g )
	ui.hinne( g )
	local p = ui.panel( g, ui.CX, ui.CY, 720, 440 )
	ui.tittel( g, "Family", ui.CX, ui.CY - 178, 40 )
	ui.tekst( g, string.format( "%d of %d children found", framgang.totaltUnger(), framgang.BANER * 3 ),
		ui.CX, ui.CY - 128, 22, { farge = ui.F.kremDempet, fet = false } )
	for b = 1, framgang.BANER do
		local kol = ( b - 1 ) % 3
		local rad = math.floor( ( b - 1 ) / 3 )
		local x = ui.CX - 220 + kol * 220
		local y = ui.CY - 60 + rad * 86
		local felt = display.newRoundedRect( g, x, y, 200, 72, 18 )
		felt:setFillColor( ui.F.jordMork[1], ui.F.jordMork[2], ui.F.jordMork[3], 0.7 )
		ui.tekst( g, "Level " .. b, x, y - 18, 18, { farge = ui.F.kremDempet } )
		local u = framgang.unger( b )
		for i = 1, 3 do
			ui.ikon( g, u[i] and "unge" or "ungeTom", x - 44 + ( i - 1 ) * 44, y + 14, 38 )
		end
	end
	ui.knapp( g, { tekst = "OK", x = ui.CX, y = ui.CY + 190, bredde = 160, hoyde = 56, trykk = function() lukk( g ) end } )
	ui.inn( g )
end

local function visSnart( forelder, tittel, tekst )
	local g = display.newGroup()
	forelder:insert( g )
	ui.hinne( g )
	local p = ui.panel( g, ui.CX, ui.CY, 520, 270 )
	ui.tittel( g, tittel, ui.CX, ui.CY - 88, 38 )
	ui.tekst( g, tekst, ui.CX, ui.CY - 6, 21, { bredde = 440, fet = false } )
	ui.knapp( g, { tekst = "OK", x = ui.CX, y = ui.CY + 86, bredde = 160, hoyde = 56, trykk = function() lukk( g ) end } )
	ui.inn( g )
end

local function visGave( forelder, gave )
	local g = display.newGroup()
	forelder:insert( g )
	ui.hinne( g )
	local p = ui.panel( g, ui.CX, ui.CY, 600, 360 )
	ui.tittel( g, "Daily gift", ui.CX, ui.CY - 132, 40 )
	ui.tekst( g, gave.dag == 1 and "Come back every day for bigger gifts!" or ( "Day " .. gave.dag .. " in a row!" ),
		ui.CX, ui.CY - 84, 22, { farge = ui.F.kremDempet, fet = false } )
	-- de sju dagene, dagens uthevet
	for d = 1, 7 do
		local x = ui.CX - 231 + ( d - 1 ) * 77
		local erIDag = d == math.min( gave.dag, 7 )
		local f = display.newRoundedRect( g, x, ui.CY - 6, 66, 86, 14 )
		if erIDag then
			f.fill = ui.gradient( ui.KNAPP.oransje[1], ui.KNAPP.oransje[2] )
			f.strokeWidth = 3
			f:setStrokeColor( unpack( ui.F.gull ) )
		else
			f:setFillColor( ui.F.jordMork[1], ui.F.jordMork[2], ui.F.jordMork[3], d < gave.dag and 0.35 or 0.75 )
		end
		ui.tekst( g, "Day " .. d, x, ui.CY - 36, 14, { farge = ui.F.kremDempet } )
		ui.ikon( g, "blad", x, ui.CY - 6, 30 )
		ui.tekst( g, tostring( framgang.GAVER[d] ), x, ui.CY + 24, 16 )
	end
	local hent = ui.knapp( g, { tekst = "Collect " .. gave.draaper, ikon = "blad", x = ui.CX, y = ui.CY + 112,
		bredde = 260, hoyde = 62, trykk = function()
			framgang.hentGave()
			require( "lib.oppdrag" ).hendelse( "gave", 1 )
			require( "lib.lyd" ).spill( "gave" )
			oppdaterDraaper()
			if gaveKnapp then
				transition.cancel( gaveKnapp )
				gaveKnapp.xScale, gaveKnapp.yScale = 1, 1
			end
			if draapePille then
				transition.to( draapePille, { time = 120, xScale = 1.2, yScale = 1.2, onComplete = function()
					transition.to( draapePille, { time = 160, xScale = 1, yScale = 1 } )
				end } )
			end
			lukk( g )
		end } )
	ui.inn( g )
end

-- ------------------------------------------------------------ scenen

function scene:create( event )
	local grp = self.view

	ui.bakgrunn( grp, "ui/hjem_bg.jpg" )
	require( "lib.lyd" ).bakgrunn( "eng" )

	-- tittel på himmelen
	ui.tittel( grp, "Roller", ui.CX, 62, 64, ui.F.krem, ui.F.jord )
	local mark = ui.ikon( grp, "unge", ui.CX + 132, 50, 46 )
	transition.to( mark, { time = 3000, rotation = 360, iterations = 0 } )

	-- rommene
	romKnapp( grp, "spill", function() nav.gaaTil( "scenes.gotochooselevel" ) end )
	local spillTekst = ui.tittel( grp, "PLAY", ROM.spill[1], ROM.spill[2] + 8, 46, ui.F.krem, ui.F.jordMork )
	local spillIkon = ui.ikon( grp, "spill", ROM.spill[1], ROM.spill[2] - 38, 50 )
	transition.to( spillIkon, { time = 700, xScale = 1.12, yScale = 1.12, iterations = 0,
		transition = easing.continuousLoop } )

	romKnapp( grp, "familie", function() visFamilie( grp ) end )
	romTittel( grp, "familie", "Family" )
	local ant = framgang.totaltUnger()
	local fr = ROM.familie
	if ant == 0 then
		ui.ikon( grp, "ungeTom", fr[1], fr[2] - 12, 44 )
	else
		for i = 1, math.min( ant, 5 ) do
			ui.ikon( grp, "unge", fr[1] - 72 + ( i - 1 ) * 36, fr[2] - 12, 38 )
		end
	end

	romKnapp( grp, "athletics", function() nav.gaaTil( "scenes.minispill" ) end )
	romTittel( grp, "athletics", "Worm athletics" )
	local ar = ROM.athletics
	ui.ikon( grp, "stjerne", ar[1], ar[2] - 14, 40 )

	romKnapp( grp, "butikk", function() nav.gaaTil( "scenes.butikk" ) end )
	romTittel( grp, "butikk", "Shop" )
	ui.ikon( grp, "pose", ROM.butikk[1], ROM.butikk[2] - 14, 46 )

	romKnapp( grp, "oppdrag", function() nav.gaaTil( "scenes.oppdrag" ) end )
	romTittel( grp, "oppdrag", "Quests" )
	ui.ikon( grp, "flagg", ROM.oppdrag[1], ROM.oppdrag[2] - 14, 42 )
	-- merke når et oppdrag er klart til å hentes
	local klare = require( "lib.oppdrag" ).klare()
	if klare > 0 then
		local r = ROM.oppdrag
		local merke = display.newCircle( grp, r[1] + r[3] / 2 - 18, r[2] - r[4] / 2 + 14, 17 )
		merke:setFillColor( unpack( ui.F.hjerte ) )
		merke.strokeWidth = 3
		merke:setStrokeColor( 1, 1, 1 )
		ui.tekst( grp, tostring( klare ), merke.x, merke.y - 1, 18, { farge = ui.F.hvit } )
		transition.to( merke, { time = 600, xScale = 1.15, yScale = 1.15, iterations = 0,
			transition = easing.continuousLoop } )
	end

	-- topplinje
	draapePille = ui.pille( grp, "blad", ui.VENSTRE + 92, 36, 150, tostring( framgang.draaper() ), true )
	ui.rundKnapp( grp, "tannhjul", ui.HOYRE - 40, 36, 56, function() nav.gaaTil( "scenes.innstillinger" ) end )
	ui.rundKnapp( grp, "hjelp", ui.HOYRE - 108, 36, 56, function()
		require( "lib.kontroller" ).vis( grp )
	end )
	gaveKnapp = ui.rundKnapp( grp, "gave", ui.HOYRE - 176, 36, 56, function()
		local gave = framgang.gaveIDag()
		if gave then
			visGave( grp, gave )
		else
			visSnart( grp, "Daily gift", "You got today's gift. Come back tomorrow for a bigger one!" )
		end
	end, "oransje" )
end

function scene:show( event )
	if event.phase == "did" then
		oppdaterDraaper()
		local grp = self.view
		-- What's new først (én gang per oppdatering), så dagens gave
		local gave = framgang.gaveIDag()
		if gave and gaveKnapp then
			transition.to( gaveKnapp, { time = 500, xScale = 1.15, yScale = 1.15, iterations = 0,
				transition = easing.continuousLoop } )
		end
		require( "lib.nyheter" ).visHvisNy( grp, function()
			if gave and framgang.gaveIDag() then visGave( grp, gave ) end
		end )
	end
end

function scene:hide( event )
	if event.phase == "did" then
		composer.removeScene( "scenes.hjem" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

return scene
