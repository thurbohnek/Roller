-- Butikken (lagt til 2026-10-28). Evner, drakter og hatter for dråper.
-- Data og priser: lib/oppgradering.lua. Bilder: Util/grafikk/lag_mark.py.
--
-- Til venstre står marken slik den ser ut nå. Til høyre er tre faner:
-- Abilities, Worms (drakter) og Hats. Et kort som eies, kan tas på; et
-- som ikke eies, har en kjøpeknapp med prisen.

local composer = require( "composer" )
local ui = require( "lib.ui" )
local framgang = require( "lib.framgang" )
local opp = require( "lib.oppgradering" )
local nav = require( "lib.navigasjon" )

local scene = composer.newScene()

local grp, innhold, forhandsvisning, draapePille, fane, sveveMark
local visFane

-- Marken som i banene: hale til høyre, hodet til venstre, hatten på.
-- ledd = antall kroppsledd (7 i spillet; færre gir en kortere mark til kortene)
local function lagMark( forelder, x, y, skala, drakt, hatt, ledd )
	ledd = ledd or 7
	local g = display.newGroup()
	forelder:insert( g )
	local hale = display.newImageRect( g, opp.drakt( "hale.png", drakt ), 27, 17 )
	hale.x = 108 - 27 * ( 7 - ledd )
	for i = 7 - ledd + 1, 7 do
		local d = display.newImageRect( g, opp.drakt( "del1.png", drakt ), 34, 17 )
		d.x = 108 - 27 * i
	end
	local hode = display.newImageRect( g, opp.drakt( "hode.png", drakt ), 30, 25 )
	hode.x, hode.y = 108 - 217, 2
	local fil = opp.hattFil( hatt )
	if fil then
		local h = display.newImageRect( g, fil, 27, 22 )
		h.x, h.y = hode.x - 2, hode.y - 19
	end
	g.x, g.y = x, y
	g.xScale, g.yScale = skala, skala
	return g
end

local function melding( tekst )
	local g = display.newGroup()
	grp:insert( g )
	local f = display.newRoundedRect( g, ui.CX, ui.BUNN - 60, 420, 50, 25 )
	f:setFillColor( ui.F.jordMork[1], ui.F.jordMork[2], ui.F.jordMork[3], 0.95 )
	f.strokeWidth = 3
	f:setStrokeColor( unpack( ui.F.kant ) )
	ui.tekst( g, tekst, ui.CX, ui.BUNN - 61, 20 )
	transition.to( g, { delay = 1400, time = 300, alpha = 0, onComplete = function() display.remove( g ) end } )
end

local function oppdater()
	draapePille:sett( tostring( framgang.draaper() ) )
	if sveveMark then transition.cancel( sveveMark ) end
	display.remove( forhandsvisning )
	forhandsvisning = display.newGroup()
	grp:insert( forhandsvisning )
	local m = lagMark( forhandsvisning, 222, 300, 1.25, nil, nil )
	sveveMark = m
	transition.to( m, { time = 1100, y = m.y - 6, iterations = 0, transition = easing.continuousLoop } )
	local navn = ""
	for _, d in ipairs( opp.DRAKTER ) do if d.id == opp.valgt( "drakt" ) then navn = d.navn end end
	ui.tekst( forhandsvisning, navn, 222, 372, 22, { farge = ui.F.krem } )
end

local function kjopt()
	oppdater()
	visFane( fane )
end

local function kjopKnapp( forelder, x, y, b, pris, kjop )
	return ui.knapp( forelder, { tekst = tostring( pris ), ikon = "blad", x = x, y = y, bredde = b, hoyde = 44,
		farge = "oransje", storrelse = 20, trykk = function()
			if framgang.draaper() < pris then
				melding( "Not enough leaves yet" )
				return
			end
			if kjop() then
				require( "lib.lyd" ).spill( "kjop" )
				kjopt()
			end
		end } )
end

-- ---------------------------------------------------------- fanene

local function evner()
	for i, e in ipairs( opp.EVNER ) do
		local y = 184 + ( i - 1 ) * 118
		local x = 668
		local kort = ui.panel( innhold, x, y, 520, 104, { radius = 20 } )
		ui.ikon( innhold, e.ikon, x - 214, y, 70 )
		local niva = opp.niva( e.id )
		local maks = #e.pris
		ui.tekst( innhold, e.navn, x - 166, y - 26, 22, { ankerX = 0 } )
		local tekst = e.tekst[math.min( niva + 1, maks )]
		ui.tekst( innhold, tekst, x - 166, y + 4, 15, { ankerX = 0, fet = false, bredde = 230, juster = "left",
			farge = ui.F.kremDempet } )
		-- nivåprikker
		for n = 1, maks do
			local p = display.newCircle( innhold, x - 160 + ( n - 1 ) * 20, y + 34, 6 )
			if n <= niva then p:setFillColor( unpack( ui.F.gull ) ) else p:setFillColor( 0, 0, 0, 0.35 ) end
		end
		local pris = opp.nestePris( e.id )
		if pris then
			kjopKnapp( innhold, x + 180, y, 130, pris, function() return opp.kjopEvne( e.id ) end )
		else
			ui.ikon( innhold, "hake", x + 180, y, 44 )
			ui.tekst( innhold, "Max", x + 180, y + 32, 15, { farge = ui.F.gull } )
		end
	end
end

local function utseende( art )
	local liste = art == "drakt" and opp.DRAKTER or opp.HATTER
	for i, v in ipairs( liste ) do
		local kol, rad = ( i - 1 ) % 4, math.floor( ( i - 1 ) / 4 )
		local x, y = 478 + kol * 128, 218 + rad * 172
		local valgt = opp.valgt( art ) == v.id
		local eier = opp.eier( art, v.id )
		local kort = ui.panel( innhold, x, y, 118, 164, { radius = 18, lys = valgt } )
		if art == "drakt" then
			lagMark( innhold, x + 38, y - 34, 0.72, v.id, "ingen", 3 )
		else
			local hode = display.newImageRect( innhold, opp.drakt( "hode.png" ), 30, 25 )
			hode.x, hode.y = x, y - 30
			hode.xScale, hode.yScale = 1.8, 1.8
			local fil = opp.hattFil( v.id )
			if fil then
				local h = display.newImageRect( innhold, fil, 27, 22 )
				h.x, h.y = x - 3.6, y - 30 - 34
				h.xScale, h.yScale = 1.8, 1.8
			end
		end
		ui.tekst( innhold, v.navn, x, y + 18, 16, { farge = valgt and ui.F.lilla or ui.F.krem } )
		if valgt then
			ui.ikon( innhold, "hake", x, y + 54, 36 )
		elseif eier then
			ui.knapp( innhold, { tekst = "Wear", x = x, y = y + 54, bredde = 100, hoyde = 40, farge = "bla",
				storrelse = 18, trykk = function()
					opp.velg( art, v.id )
					kjopt()
				end } )
		else
			kjopKnapp( innhold, x, y + 54, 100, v.pris, function()
				if opp.kjop( art, v.id ) then
					opp.velg( art, v.id )
					return true
				end
			end )
		end
	end
end

local FANER = { { "evner", "Abilities" }, { "drakt", "Worms" }, { "hatt", "Hats" } }
local faneKnapper = {}

visFane = function( navn )
	fane = navn
	display.remove( innhold )
	innhold = display.newGroup()
	grp:insert( innhold )
	for _, k in ipairs( faneKnapper ) do display.remove( k ) end
	faneKnapper = {}
	for i, f in ipairs( FANER ) do
		local k = ui.knapp( grp, { tekst = f[2], x = 520 + ( i - 1 ) * 150, y = 98, bredde = 140, hoyde = 46,
			farge = f[1] == navn and "oransje" or "jord", storrelse = 19,
			trykk = function() visFane( f[1] ) end } )
		faneKnapper[#faneKnapper + 1] = k
	end
	if navn == "evner" then evner() else utseende( navn ) end
end

function scene:create( event )
	grp = self.view
	local bg = display.newRect( grp, ui.CX, ui.CY, ui.FULL_B + 4, ui.FULL_H + 4 )
	bg.fill = ui.gradient( ui.F.jordLys, ui.F.jordMork )

	ui.rundKnapp( grp, "tilbake", ui.VENSTRE + 40, 36, 56, function() nav.gaaTil( "scenes.gotomenu" ) end )
	ui.tittel( grp, "Shop", ui.CX, 40, 40, ui.F.krem, ui.F.jord )
	draapePille = ui.pille( grp, "blad", ui.HOYRE - 92, 36, 150, tostring( framgang.draaper() ), true )

	ui.panel( grp, 222, 300, 340, 300, { radius = 26 } )
	ui.tekst( grp, "Your worm", 222, 182, 22, { farge = ui.F.kremDempet } )
	oppdater()
	visFane( "evner" )
end

function scene:hide( event )
	if event.phase == "will" and sveveMark then
		transition.cancel( sveveMark )
		sveveMark = nil
	elseif event.phase == "did" then
		composer.removeScene( "scenes.butikk" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
