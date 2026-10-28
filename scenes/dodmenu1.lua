-- Dødsmenyen (ny stil 2026-10-28). Vises som overlay når marken knekker
-- eller faller ut av banen. Retry, Levels og Home koster ett forsøk, som
-- før (lib/navigasjon.lua forlatBane, som også sender til
-- reklame-for-liv når forsøkene er brukt opp).

local composer = require( "composer" )
local ui = require( "lib.ui" )
local nav = require( "lib.navigasjon" )
local liv = require( "lib.liv" )

local scene = composer.newScene()

local TIPS = {
	"Hold the screen to stretch the worm across gaps.",
	"Let go to curl up and roll faster downhill.",
	"Double tap to go limp and slide through narrow icy cracks.",
	"Tap once to make a limp worm firm again.",
	"Stretch out just before an edge to jump further.",
}

function scene:create( event )
	local grp = self.view
	require( "lib.lyd" ).spill( "dod" )
	ui.hinne( grp, 0.6 )
	local p = ui.panel( grp, ui.CX, ui.CY - 10, 520, 300 )
	ui.tittel( grp, "Ouch!", ui.CX, ui.CY - 122, 50, ui.F.hjerte, ui.F.jordMork )

	-- forsøk igjen etter dette (samme tall som telleren i banen)
	local igjen = math.max( 0, liv.returnScore() - 1 )
	ui.pille( grp, "hjerte", ui.CX, ui.CY - 62, 190, igjen .. ( igjen == 1 and " try left" or " tries left" ) )
	ui.tekst( grp, TIPS[math.random( #TIPS )], ui.CX, ui.CY - 10, 19,
		{ farge = ui.F.kremDempet, fet = false, bredde = 440 } )

	ui.knapp( grp, { tekst = "Try again", ikon = "igjen", x = ui.CX, y = ui.CY + 66, bredde = 280, hoyde = 70,
		trykk = function() nav.forlatBane( "scenes.gotoretry" ) end } )
	ui.rundKnapp( grp, "liste", ui.CX - 205, ui.CY + 66, 60, function()
		nav.forlatBane( "scenes.gotochooselevel" )
	end, "oransje" )
	ui.rundKnapp( grp, "hjem", ui.CX + 205, ui.CY + 66, 60, function()
		nav.forlatBane( "scenes.gotomenu" )
	end, "oransje" )
end

function scene:hide( event )
	if event.phase == "did" then
		composer.removeScene( "scenes.dodmenu1" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
