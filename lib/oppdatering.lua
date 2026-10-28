-- Varsel når en ny versjon av spillet er publisert (lagt til 2026-09-29).
--
-- Byggingen legger commit-ID-en både inn i spillet (lib/byggversjon.lua)
-- og i versjon.txt på nettsiden. Mens spillet kjører, henter vi
-- versjon.txt hvert SJEKK sekund. Er den en annen enn den som kjører,
-- ligger det en oppdatering klar, og en liten steinlapp vises nede i
-- venstre hjørne, der den ikke er i veien for banen. Trykk på lappen
-- skjuler den. Den nye versjonen lastes når siden lastes på nytt.
--
-- Startes én gang fra main.lua: require( "lib.oppdatering" ).start()

local M = {}

local URL = "https://thurbohnek.github.io/Roller/versjon.txt"
local SJEKK = 120 -- sekunder mellom hver sjekk

local denne = require( "lib.byggversjon" )
local lapp = nil
local skjult = false

local function visLapp()
	if lapp or skjult then
		if lapp then lapp:toFront() end
		return
	end
	lapp = display.newGroup()
	local ui = require( "lib.ui" )
	local x = ui.VENSTRE + 170
	local y = ui.BUNN - 40
	local flate = display.newRoundedRect( lapp, x, y, 316, 58, 29 )
	flate:setFillColor( ui.F.jord[1], ui.F.jord[2], ui.F.jord[3], 0.92 )
	flate.strokeWidth = 3
	flate:setStrokeColor( unpack( ui.F.gull ) )
	ui.ikon( lapp, "gave", x - 128, y, 34 )
	ui.tekst( lapp, "Update ready!", x + 14, y - 11, 17, { farge = ui.F.gull } )
	ui.tekst( lapp, "Reload the page to play it.", x + 14, y + 11, 14, { farge = ui.F.krem, fet = false } )
	-- "touch" og ikke "tap": da tar lappen hele trykket, så det ikke også
	-- styrer marken (banene lytter på touch for hele skjermen)
	lapp:addEventListener( "touch", function( e )
		if e.phase == "ended" then
			skjult = true
			display.remove( lapp )
			lapp = nil
		end
		return true
	end )
end

local function sjekk()
	network.request( URL .. "?t=" .. os.time(), "GET", function( e )
		if e.isError or not e.response then return end
		local ny = tostring( e.response ):match( "^%s*(%x+)%s*$" )
		if ny and #ny >= 7 and ny ~= denne then
			visLapp()
		end
	end )
end

-- Ikke timer.performWithDelay: flere scener (gotomenu, pausemenu1,
-- dodmenu1) kaller timer.cancel( eventTimer ) med eventTimer = nil, og da
-- stopper Solar2D ALLE timere. En enterFrame-lytter som måler tiden selv
-- blir ikke stoppet av det.
function M.start()
	if denne == "lokal" then
		return
	end
	local neste = system.getTimer() + 20000
	Runtime:addEventListener( "enterFrame", function()
		local naa = system.getTimer()
		if naa >= neste then
			neste = naa + SJEKK * 1000
			sjekk()
		end
	end )
end

return M
