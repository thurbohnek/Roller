-- Lasteskjerm i ny stil (lagt til 2026-10-28). Brukes av de små
-- mellomscenene (gotomenu, gotoretry, gotolevel1, gotochooselevel,
-- gotonextlevel) i stedet for det gamle last.png-arket.
--
--     require( "lib.lasting" ).vis( sceneGroup, "Level 4" )

local ui = require( "lib.ui" )

local M = {}

function M.vis( forelder, undertekst )
	local g = display.newGroup()
	forelder:insert( g )
	local bg = display.newRect( g, ui.CX, ui.CY, ui.FULL_B + 4, ui.FULL_H + 4 )
	bg.fill = ui.gradient( ui.F.jordLys, ui.F.jordMork )

	local mark = ui.ikon( g, "unge", ui.CX, ui.CY - 30, 110 )
	transition.to( mark, { time = 1400, rotation = 360, iterations = 0 } )

	ui.tekst( g, "Loading", ui.CX, ui.CY + 62, 30, { farge = ui.F.krem } )
	if undertekst then
		ui.tekst( g, undertekst, ui.CX, ui.CY + 98, 20, { farge = ui.F.kremDempet, fet = false } )
	end
	return g
end

return M
