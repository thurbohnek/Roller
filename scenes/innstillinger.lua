-- Innstillinger (lagt til 2026-09-27, ny stil 2026-10-28). Nås fra
-- tannhjulet i hjemmet. Lyd av/på (lib/innstillinger.lua), styringen og
-- lisensen til skrifta.

local composer = require( "composer" )
local ui = require( "lib.ui" )
local nav = require( "lib.navigasjon" )
local innstillinger = require( "lib.innstillinger" )

local scene = composer.newScene()

function scene:create( event )
	local grp = self.view
	ui.bakgrunn( grp, "ui/hjem_bg.jpg" )
	ui.hinne( grp, 0.45 )

	local p = ui.panel( grp, ui.CX, ui.CY + 14, 600, 470 )
	ui.tittel( grp, "Settings", ui.CX, ui.CY - 178, 42 )

	-- tre lydknapper: all lyd, musikken, naturlydene
	local knapper = {}
	local tegn
	local function bryter( nr, y, tekstPaa, tekstAv, erPaa, bytt )
		if knapper[nr] then display.remove( knapper[nr] ) end
		local paa = erPaa()
		local alt = nr == 1 or innstillinger.lydPaa()
		knapper[nr] = ui.knapp( grp, { tekst = paa and tekstPaa or tekstAv, ikon = paa and "lyd" or "lydAv",
			x = ui.CX, y = y, bredde = 340, hoyde = 54, farge = ( paa and alt ) and "gronn" or "gra",
			storrelse = 22, trykk = function()
				bytt()
				tegn()
			end } )
	end
	tegn = function()
		bryter( 1, ui.CY - 114, "Sound: On", "Sound: Off", innstillinger.lydPaa, innstillinger.byttLyd )
		bryter( 2, ui.CY - 52, "Music: On", "Music: Off", innstillinger.musikkPaa, innstillinger.byttMusikk )
		bryter( 3, ui.CY + 10, "Nature sounds: On", "Nature sounds: Off", innstillinger.naturPaa,
			innstillinger.byttNatur )
	end
	tegn()

	ui.knapp( grp, { tekst = "How to move", ikon = "hjelp", x = ui.CX, y = ui.CY + 76, bredde = 340, hoyde = 54,
		farge = "bla", storrelse = 22, trykk = function() require( "lib.kontroller" ).vis( grp ) end } )

	ui.tekst( grp, "Music: MintoDog, Zane Little and cynicmusic (CC0, OpenGameArt)", ui.CX, ui.CY + 126, 14,
		{ farge = ui.F.kremDempet, fet = false } )
	ui.tekst( grp, "Font: Fredoka (SIL Open Font License)", ui.CX, ui.CY + 146, 14,
		{ farge = ui.F.kremDempet, fet = false } )

	ui.knapp( grp, { tekst = "Back", ikon = "tilbake", x = ui.CX, y = ui.CY + 196, bredde = 200, hoyde = 54,
		farge = "oransje", trykk = function() nav.gaaTil( "scenes.gotomenu" ) end } )
end

function scene:hide( event )
	if event.phase == "did" then
		composer.removeScene( "scenes.innstillinger" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
