-- Banevalget i ny stil (lagt til 2026-10-28). Erstatter scenes/chooselevel.lua
-- (rutenettet fra ogt_levelmanager).
--
-- En sti fra enga og ned i jorda: bane 1-2 på gresset, så et hull og en
-- tunnel nedover til bane 9, mørkere jo dypere. Under hvert stopp vises
-- markeungene som er reddet i banen.
--
-- Valget gjør det samme som ogt_levelmanager sin selectLevel: setter
-- lm.currentLevel (brukt av retry og "neste bane"), sjekker forsøk
-- (reklame-for-liv hvis tomt) og starter banen.
--
-- Stoppene står samme sted som BANEVALG i Util/grafikk/lag_ui.py.

local composer = require( "composer" )
local ui = require( "lib.ui" )
local framgang = require( "lib.framgang" )
local nav = require( "lib.navigasjon" )
local lm = require( "lib.ogt_levelmanager" )
local liv = require( "lib.liv" )

local scene = composer.newScene()

local STOPP = { { 105, 226 }, { 235, 226 }, { 450, 300 }, { 610, 300 }, { 770, 330 }, { 850, 410 },
	{ 710, 455 }, { 545, 470 }, { 380, 490 } }
local NAVN = require( "lib.hud" ).NAVN

-- Alle baner er åpne mens spillet testes (samme beslutning som
-- "TEMP for debugging" i ogt_levelmanager.lua, se TIL-ORJAN.md). Sett til
-- false for å kreve at forrige bane er fullført.
local ALLE_APNE = true

local function erApen( b )
	if ALLE_APNE or b == 1 then return true end
	return framgang.fullfort( b - 1 )
end

local function startBane( b )
	lm.currentLevel = b
	liv.lastliv()
	if liv.erTom() then
		nav.gaaTil( "scenes.adoffer" )
		return
	end
	composer.removeScene( "scenes.level" .. b )
	nav.gaaTil( "scenes.level" .. b, "fade", 500 )
end

local function stopp( forelder, b, x, y )
	local g = display.newGroup()
	forelder:insert( g )
	g.x, g.y = x, y
	local apen = erApen( b )
	local klart = framgang.fullfort( b )
	local d = 64
	local farge = not apen and "gra" or ( klart and "gronn" or "oransje" )
	local f = ui.KNAPP[farge]
	local skygge = display.newCircle( g, 0, 5, d / 2 )
	skygge:setFillColor( f[3][1], f[3][2], f[3][3] )
	local flate = display.newCircle( g, 0, 0, d / 2 )
	flate.fill = ui.gradient( f[1], f[2] )
	flate.strokeWidth = 4
	flate:setStrokeColor( 1, 1, 1, 0.85 )
	if apen then
		ui.tekst( g, tostring( b ), 0, -2, 30, { farge = ui.F.hvit } )
	else
		ui.ikon( g, "laas", 0, -2, 34 )
	end
	-- unger under stoppet
	local u = framgang.unger( b )
	local ry = d / 2 + 16
	local bakgrunn = display.newRoundedRect( g, 0, ry, 84, 26, 13 )
	bakgrunn:setFillColor( 0.1, 0.05, 0.02, 0.6 )
	for i = 1, 3 do
		ui.ikon( g, u[i] and "unge" or "ungeTom", -26 + ( i - 1 ) * 26, ry, 22 )
	end
	if apen then
		ui.trykkbar( g, function() startBane( b ) end )
	end
	return g
end

function scene:create( event )
	local grp = self.view
	ui.bakgrunn( grp, "ui/banevalg_bg.jpg" )
	require( "lib.lyd" ).bakgrunn( "eng" )

	-- en liten mark ved neste bane som venter
	local neste = 1
	for b = 1, framgang.BANER do
		if not framgang.fullfort( b ) then neste = b break end
		neste = b
	end

	for b, p in ipairs( STOPP ) do
		local s = stopp( grp, b, p[1], p[2] )
		ui.sprett( s, 40 * b )
		if b == neste then
			local m = ui.ikon( grp, "unge", p[1] + 44, p[2] - 30, 40 )
			transition.to( m, { time = 900, y = m.y - 8, iterations = 0, transition = easing.continuousLoop } )
		end
	end

	-- topplinje
	ui.rundKnapp( grp, "tilbake", ui.VENSTRE + 40, 36, 56, function() nav.gaaTil( "scenes.gotomenu" ) end )
	ui.tittel( grp, "Choose a level", ui.CX, 40, 34, ui.F.krem, ui.F.jord )
	ui.pille( grp, "blad", ui.HOYRE - 92, 36, 150, tostring( framgang.draaper() ), true )
	local t = ui.pille( grp, "unge", ui.HOYRE - 92, 96, 150,
		framgang.totaltUnger() .. "/" .. ( framgang.BANER * 3 ), true )

	-- navnet på banen ved hvert stopp, bare for de som er åpne
	for b, p in ipairs( STOPP ) do
		if erApen( b ) then
			ui.tekst( grp, NAVN[b], p[1], p[2] - 48, 15, { skygge = true } )
		end
	end
end

function scene:hide( event )
	if event.phase == "did" then
		composer.removeScene( "scenes.banevalg" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
