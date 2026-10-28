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

	local p = ui.panel( grp, ui.CX, ui.CY + 10, 560, 400 )
	ui.tittel( grp, "Settings", ui.CX, ui.CY - 150, 42 )

	-- lyd
	local lydKnapp, tegnNatur
	local function tegnLyd()
		if lydKnapp then display.remove( lydKnapp ) end
		local paa = innstillinger.lydPaa()
		lydKnapp = ui.knapp( grp, { tekst = paa and "Sound: On" or "Sound: Off", ikon = paa and "lyd" or "lydAv",
			x = ui.CX, y = ui.CY - 92, bredde = 320, hoyde = 58, farge = paa and "gronn" or "gra",
			trykk = function()
				innstillinger.byttLyd()
				tegnLyd()
				tegnNatur()
			end } )
	end

	-- naturlydene i bakgrunnen (vind, fugler, drypp), av/på for seg
	local naturKnapp
	function tegnNatur()
		if naturKnapp then display.remove( naturKnapp ) end
		local paa = innstillinger.naturPaa()
		naturKnapp = ui.knapp( grp, { tekst = paa and "Nature sounds: On" or "Nature sounds: Off",
			ikon = paa and "lyd" or "lydAv", x = ui.CX, y = ui.CY - 24, bredde = 320, hoyde = 58,
			farge = ( paa and innstillinger.lydPaa() ) and "gronn" or "gra", storrelse = 22,
			trykk = function()
				innstillinger.byttNatur()
				tegnNatur()
			end } )
	end
	tegnLyd()
	tegnNatur()

	ui.knapp( grp, { tekst = "How to move", ikon = "hjelp", x = ui.CX, y = ui.CY + 44, bredde = 320, hoyde = 58,
		farge = "bla", trykk = function() require( "lib.kontroller" ).vis( grp ) end } )

	ui.tekst( grp, "Font: Fredoka (SIL Open Font License)", ui.CX, ui.CY + 104, 14,
		{ farge = ui.F.kremDempet, fet = false } )

	ui.knapp( grp, { tekst = "Back", ikon = "tilbake", x = ui.CX, y = ui.CY + 162, bredde = 200, hoyde = 56,
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
