-- Pausemenyen (ny stil 2026-10-28). Vises som overlay fra pauseknappen i
-- banene. Reglene er de samme som før: Resume fortsetter, mens Retry,
-- Levels og Home avslutter forsøket og koster ett liv (lib/navigasjon.lua
-- forlatBane, som også sender til reklame-for-liv når livene er brukt
-- opp). Quit-knappen er fjernet: apper skal ikke avslutte seg selv på iOS.
-- Historikken for de gamle feilrettingene står i TIL-ORJAN.md.

local composer = require( "composer" )
local ui = require( "lib.ui" )
local nav = require( "lib.navigasjon" )
local innstillinger = require( "lib.innstillinger" )
local lm = require( "lib.ogt_levelmanager" )
local physics = require( "physics" )

local scene = composer.newScene()

function scene:create( event )
	local grp = self.view
	ui.hinne( grp, 0.55 )
	local p = ui.panel( grp, ui.CX, ui.CY, 520, 360 )
	ui.tittel( grp, "Paused", ui.CX, ui.CY - 130, 44 )
	ui.tekst( grp, "Level " .. tostring( lm.currentLevel or "" ), ui.CX, ui.CY - 86, 20,
		{ farge = ui.F.kremDempet, fet = false } )

	ui.knapp( grp, { tekst = "Resume", ikon = "spill", x = ui.CX, y = ui.CY - 18, bredde = 280, hoyde = 70,
		trykk = function()
			composer.hideOverlay( "fade", 250 )
			physics.start()
		end } )

	local rad = ui.CY + 80
	local knapper = {
		{ "igjen", "Retry", "scenes.gotoretry" },
		{ "liste", "Levels", "scenes.gotochooselevel" },
		{ "hjem", "Home", "scenes.gotomenu" },
	}
	for i, k in ipairs( knapper ) do
		local x = ui.CX - 150 + ( i - 1 ) * 100
		ui.rundKnapp( grp, k[1], x, rad, 64, function() nav.forlatBane( k[3] ) end, "oransje" )
		ui.tekst( grp, k[2], x, rad + 46, 16, { farge = ui.F.kremDempet } )
	end
	local lyd
	lyd = ui.rundKnapp( grp, innstillinger.lydPaa() and "lyd" or "lydAv", ui.CX + 150, rad, 64, function()
		local paa = innstillinger.byttLyd()
		display.remove( lyd.ikonObj )
		lyd.ikonObj = ui.ikon( lyd, paa and "lyd" or "lydAv", 0, 0, 64 * 0.52 )
	end, "bla" )
	ui.tekst( grp, "Sound", ui.CX + 150, rad + 46, 16, { farge = ui.F.kremDempet } )

	-- styringen (Controls)
	ui.rundKnapp( grp, "hjelp", ui.CX + 220, ui.CY - 142, 50, function()
		require( "lib.kontroller" ).vis( grp )
	end, "bla" )
end

function scene:hide( event )
	if event.phase == "did" then
		composer.removeScene( "scenes.pausemenu1" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
