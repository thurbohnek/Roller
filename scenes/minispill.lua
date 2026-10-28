-- Worm athletics: menyen for minispillene (lagt til 2026-09-27, ny stil
-- 2026-10-28). Nås fra rommet "Worm athletics" i hjemmet. Hver øvelse har
-- sin egen scene og rekord (lib/minisport.lua):
--   High jump -> scenes/mini_hoydehopp.lua
--   Long jump -> scenes/mini_lengdehopp.lua
--   100 m     -> scenes/mini_100m.lua

local composer = require( "composer" )
local ui = require( "lib.ui" )
local nav = require( "lib.navigasjon" )
local sport = require( "lib.minisport" )

local scene = composer.newScene()

local function rekord( navn, format )
	local r = sport.rekord( navn )
	if r == nil then return "No record yet" end
	return "Record: " .. string.format( format, r )
end

function scene:create( event )
	local grp = self.view
	ui.bakgrunn( grp, "ui/hjem_bg.jpg" )
	ui.hinne( grp, 0.4 )

	ui.rundKnapp( grp, "tilbake", ui.VENSTRE + 40, 36, 56, function() nav.gaaTil( "scenes.gotomenu" ) end )
	ui.tittel( grp, "Worm athletics", ui.CX, 64, 48, ui.F.gull, ui.F.jordMork )
	ui.tekst( grp, "Use the real worm moves. Find the technique and beat your record!", ui.CX, 112, 19,
		{ fet = false, skygge = true } )

	local ovelser = {
		{ "High jump", "Clear the bar. Set it higher each time.", "scenes.mini_hoydehopp",
			rekord( "hoydehopp_fysikk", "%.2f m" ), "oransje" },
		{ "Long jump", "Full speed, then jump from the line.", "scenes.mini_lengdehopp",
			rekord( "lengdehopp_fysikk", "%.2f m" ), "gronn" },
		{ "100 m", "Keep the worm rolling on flat ground.", "scenes.mini_100m",
			rekord( "100m_fysikk", "%.2f s" ), "bla" },
	}
	for i, o in ipairs( ovelser ) do
		local x = ui.CX - 290 + ( i - 1 ) * 290
		local y = ui.CY + 70
		local kort = ui.panel( grp, x, y, 260, 300 )
		ui.tekst( grp, o[1], x, y - 112, 28, { farge = ui.F.gull } )
		ui.ikon( grp, i == 3 and "spill" or "stjerne", x, y - 52, 56 )
		ui.tekst( grp, o[2], x, y + 8, 17, { bredde = 220, fet = false } )
		ui.tekst( grp, o[4], x, y + 58, 16, { farge = ui.F.kremDempet } )
		ui.knapp( grp, { tekst = "Play", ikon = "spill", x = x, y = y + 110, bredde = 180, hoyde = 54, farge = o[5],
			trykk = function()
				require( "lib.oppdrag" ).hendelse( "sport", 1 )
				nav.gaaTil( o[3] )
			end } )
	end
end

function scene:hide( event )
	if event.phase == "did" then
		composer.removeScene( "scenes.minispill" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
