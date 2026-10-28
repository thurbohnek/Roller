-- Tom for forsøk (lagt til 2026-09-15, ny stil 2026-10-28).
--
-- Vises når spilleren har brukt opp forsøkene. Valgene:
--   Watch a short ad  -> +1 forsøk  (reklamen er en plassholder til et
--   Watch a long ad   -> +3 forsøk   reklame-SDK kobles på med egen konto)
--   Use dew drops     -> +3 forsøk for DRAAPE_PRIS dråper
--   Start over        -> fulle forsøk, fra bane 1 (som før)
-- Kjøp for ekte penger er tatt ut: spillet er gratis med reklame for liv
-- (Mathias 2026-10-28).

local composer = require( "composer" )
local ui = require( "lib.ui" )
local nav = require( "lib.navigasjon" )
local liv = require( "lib.liv" )
local framgang = require( "lib.framgang" )

local scene = composer.newScene()

local KORT = { sekunder = 3, forsok = 1 }
local LANG = { sekunder = 6, forsok = 3 }
local DRAAPE_PRIS = 60
local DRAAPE_FORSOK = 3

local function giForsok( n )
	liv.addToScore( n )
	liv.lagreliv()
	nav.gaaTil( "scenes.gotoretry", "fade", 500 )
end

local function visReklame( forelder, valg )
	local g = display.newGroup()
	forelder:insert( g )
	local h = ui.hinne( g, 1 )
	h:setFillColor( 0, 0, 0, 1 )
	ui.tekst( g, "Ad", ui.CX, ui.CY - 60, 26, { farge = ui.F.kremDempet } )
	local t = ui.tittel( g, tostring( valg.sekunder ), ui.CX, ui.CY + 10, 72 )
	local igjen = valg.sekunder
	-- timer.performWithDelay er trygt her: ingen bane er aktiv
	timer.performWithDelay( 1000, function()
		igjen = igjen - 1
		if igjen <= 0 then
			giForsok( valg.forsok )
		else
			display.remove( t )
			t = ui.tittel( g, tostring( igjen ), ui.CX, ui.CY + 10, 72 )
		end
	end, valg.sekunder )
end

function scene:create( event )
	local grp = self.view
	local bg = display.newImageRect( grp, "ui/hjem_bg.jpg", 1200, 540 )
	bg.x, bg.y = ui.CX, ui.CY
	ui.hinne( grp, 0.55 )

	local p = ui.panel( grp, ui.CX, ui.CY + 8, 620, 440 )
	ui.tittel( grp, "Out of tries", ui.CX, ui.CY - 170, 42, ui.F.hjerte, ui.F.jordMork )
	ui.tekst( grp, "Get more tries and keep looking for your family.", ui.CX, ui.CY - 122, 19,
		{ farge = ui.F.kremDempet, fet = false } )

	ui.knapp( grp, { tekst = "Short ad: +" .. KORT.forsok .. " try", ikon = "spill", x = ui.CX, y = ui.CY - 60,
		bredde = 380, hoyde = 62, farge = "gronn", trykk = function() visReklame( grp, KORT ) end } )
	ui.knapp( grp, { tekst = "Long ad: +" .. LANG.forsok .. " tries", ikon = "spill", x = ui.CX, y = ui.CY + 14,
		bredde = 380, hoyde = 62, farge = "bla", trykk = function() visReklame( grp, LANG ) end } )

	local har = framgang.draaper() >= DRAAPE_PRIS
	ui.knapp( grp, { tekst = DRAAPE_PRIS .. " drops: +" .. DRAAPE_FORSOK .. " tries", ikon = "draape",
		x = ui.CX, y = ui.CY + 88, bredde = 380, hoyde = 62, farge = har and "oransje" or "gra",
		trykk = function()
			if framgang.bruk( DRAAPE_PRIS ) then giForsok( DRAAPE_FORSOK ) end
		end } )
	if not har then
		ui.tekst( grp, "You have " .. framgang.draaper() .. " drops", ui.CX, ui.CY + 128, 14,
			{ farge = ui.F.kremDempet, fet = false } )
	end

	ui.knapp( grp, { tekst = "Start over from level 1", x = ui.CX, y = ui.CY + 182, bredde = 300, hoyde = 46,
		storrelse = 18, farge = "jord", trykk = function()
			liv.new()
			liv.lagreliv()
			nav.gaaTil( "scenes.gotolevel1", "fade", 500 )
		end } )
end

function scene:hide( event )
	if event.phase == "did" then
		composer.removeScene( "scenes.adoffer" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
