-- "What's new": kort oppsummering for spillerne etter en oppdatering
-- (lagt til 2026-09-29).
--
-- Vises én gang på startskjermen når det finnes en oppføring spilleren
-- ikke har sett (lagret med GGData "nyheter"). Første gang noen spiller
-- vises bare den nyeste. Kalles fra scenes/hjem.lua.
--
-- NY OPPDATERING: legg en ny oppføring ØVERST i NYHETER med neste
-- nummer. Kort og for spillerne, 1-4 linjer, på engelsk som resten av
-- spillet.

local GGData = require( "lib.GGData" )

local M = {}

M.NYHETER = {
	{ nr = 7, dato = "2026-10-29", linjer = {
		"Checkpoints! Pass a flag before a hard part, and Try again starts you there.",
		"Lost children you find now roll after you in a line, copying every move.",
		"A real soundtrack: cosy tunes on the meadow, crystal bells in the caves.",
		"Flowers, mushrooms and glowing crystals along the way.",
	} },
	{ nr = 6, dato = "2026-10-28", linjer = {
		"Leaves instead of dew drops! Worms really drag leaves home to eat.",
		"Leaves now trace the jumps in arcs, and golden leaves hide high above the big gaps.",
		"Calm nature sounds instead of music: birds on the meadow, dripping caves below.",
		"Lost children you find follow you to the end of the level.",
	} },
	{ nr = 5, dato = "2026-10-28", linjer = {
		"Music and sound effects! Drops chime higher the more you grab in a row.",
		"Worm athletics moved into a new underground arena with a cheering crowd.",
		"Sparkles when you grab drops and find lost children.",
	} },
	{ nr = 4, dato = "2026-10-28", linjer = {
		"All 9 levels are repainted: a sunny meadow on top, deeper and darker caves below.",
		"Collect dew drops and find 3 lost baby worms hidden in every level.",
		"The Shop is open: new worm colours, hats and helpful abilities.",
		"Weekly quests give extra dew drops.",
	} },
	{ nr = 3, dato = "2026-10-28", linjer = {
		"A brand new look! Your worm's underground home is the new menu.",
		"A new map from the meadow down into the deep caves.",
		"Daily gift: come back every day for dew drops. More days in a row, bigger gifts.",
		"Out of tries? Trade dew drops for more.",
	} },
	{ nr = 2, dato = "2026-09-29", linjer = {
		"Worm athletics is now on flat ground. Find the technique to move and jump!",
		"100 m: a short tap when the head is at the back of the ring keeps the worm going.",
		"Long jump: a flat run-up and a line. High jump: the bar really falls if you hit it.",
	} },
	{ nr = 1, dato = "2026-09-29", linjer = {
		"Levels 5-9 are brand new caves, harder the deeper you go: ice, big jumps and narrow icy cracks.",
		"The stone in the top left corner shows which level you are on.",
		"Controls: learn how to move the worm from the start screen or the pause menu.",
		"Games: Worm athletics with high jump, long jump and 100 m, with the real worm.",
	} },
}

local data = GGData:new( "nyheter" )
local vistDenneGangen = false

-- Viser det som er nytt siden sist (én gang per økt). etterpaa kalles
-- når panelet lukkes, eller med en gang hvis det ikke er noe nytt.
function M.visHvisNy( forelder, etterpaa )
	local ferdig = etterpaa or function() end
	if vistDenneGangen then ferdig() return false end
	vistDenneGangen = true
	local sett = data.sett or ( M.NYHETER[1].nr - 1 )
	local nye = {}
	for _, n in ipairs( M.NYHETER ) do
		if n.nr > sett then nye[#nye + 1] = n end
	end
	if #nye == 0 then ferdig() return false end
	data.sett = M.NYHETER[1].nr
	data:save()

	local ui = require( "lib.ui" )
	local g = display.newGroup()
	forelder:insert( g )
	ui.hinne( g )
	local panel = ui.panel( g, ui.CX, ui.CY, 760, 440 )
	ui.tittel( g, "What's new", ui.CX, ui.CY - 172, 40 )
	local y = ui.CY - 118
	local vist = 0
	for _, n in ipairs( nye ) do
		for _, l in ipairs( n.linjer ) do
			if vist < 6 then
				local prikk = display.newCircle( g, ui.CX - 318, y + 13, 6 )
				prikk:setFillColor( unpack( ui.F.gull ) )
				local t = ui.tekst( g, l, ui.CX - 300, y, 20, { bredde = 610, juster = "left", fet = false, ankerX = 0 } )
				t.tekstObjekt.anchorY = 0
				y = y + t.tekstObjekt.height + 12
				vist = vist + 1
			end
		end
	end
	ui.knapp( g, { tekst = "Let's go!", x = ui.CX, y = ui.CY + 172, bredde = 220, hoyde = 58, trykk = function()
		display.remove( g )
		ferdig()
	end } )
	ui.inn( g )
	return true
end

return M
