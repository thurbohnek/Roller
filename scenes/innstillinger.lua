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
	local bg = display.newImageRect( grp, "ui/hjem_bg.jpg", 1200, 540 )
	bg.x, bg.y = ui.CX, ui.CY
	ui.hinne( grp, 0.45 )

	local p = ui.panel( grp, ui.CX, ui.CY + 10, 560, 400 )
	ui.tittel( grp, "Settings", ui.CX, ui.CY - 150, 42 )

	-- lyd
	local lydKnapp
	local function tegnLyd()
		if lydKnapp then display.remove( lydKnapp ) end
		local paa = innstillinger.lydPaa()
		lydKnapp = ui.knapp( grp, { tekst = paa and "Sound: On" or "Sound: Off", ikon = paa and "lyd" or "lydAv",
			x = ui.CX, y = ui.CY - 68, bredde = 300, hoyde = 62, farge = paa and "gronn" or "gra",
			trykk = function()
				innstillinger.byttLyd()
				tegnLyd()
			end } )
	end
	tegnLyd()

	ui.knapp( grp, { tekst = "How to move", ikon = "hjelp", x = ui.CX, y = ui.CY + 10, bredde = 300, hoyde = 62,
		farge = "bla", trykk = function() require( "lib.kontroller" ).vis( grp ) end } )

	ui.tekst( grp, "Font: Fredoka (SIL Open Font License)", ui.CX, ui.CY + 92, 14,
		{ farge = ui.F.kremDempet, fet = false } )

	ui.knapp( grp, { tekst = "Back", ikon = "tilbake", x = ui.CX, y = ui.CY + 166, bredde = 200, hoyde = 56,
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
