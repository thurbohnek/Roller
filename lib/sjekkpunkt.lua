-- Sjekkpunkter (lagt til 2026-10-28).
--
-- Før de vanskelige partiene i hver bane står et flagg. Når marken passerer
-- det, er sjekkpunktet nådd, og "Try again" (og Retry i pausemenyen)
-- starter banen derfra. Hvor de står, står i lib/samleN.lua (sjekkpunkter),
-- laget av Util/grafikk/lag_samling.py.
--
-- Marken må alltid starte i del1 = (0, 0) (se lib/teststart.lua). Derfor
-- flyttes hele banen i stedet: forskyvning( N ) gir hvor mye alt skal
-- flyttes (halens startpunkt ved sjekkpunktet), og banefilene trekker det
-- fra flisene, målet og dødslinja. For bane 5-9 gjør lib/teststart.lua det.
--
-- Bare i minnet: sjekkpunktet glemmes når banen klares, når spilleren går
-- til banevalget eller hjem, og når spillet startes på nytt.

local M = {}

local aktiv = {}       -- aktiv[bane] = nummer på sjekkpunktet som er nådd

local function liste( bane )
	local ok, data = pcall( require, "lib.samle" .. bane )
	return ok and type( data ) == "table" and data.sjekkpunkter or {}
end

M.liste = liste

function M.aktiv( bane )
	return aktiv[bane]
end

function M.sett( bane, i )
	if not aktiv[bane] or i > aktiv[bane] then aktiv[bane] = i end
end

-- Når banen sist ble startet fra et sjekkpunkt (system.getTimer()).
-- Dør marken rett etterpå, er sjekkpunktet ikke trygt, og det glemmes
-- (se M.vedDod), så spilleren aldri blir fanget i en dødsløkke.
local startTid = {}

function M.startet( bane )
	startTid[bane] = aktiv[bane] and system.getTimer() or nil
end

function M.vedDod( bane )
	if startTid[bane] and system.getTimer() - startTid[bane] < 3500 then
		aktiv[bane] = nil
	end
end

function M.nullstill( bane )
	if bane then aktiv[bane] = nil else aktiv = {} end
end

-- Hvor mye banen skal flyttes: { x, y } (0, 0 uten sjekkpunkt).
function M.forskyvning( bane )
	local i = aktiv[bane]
	local s = i and liste( bane )[i]
	if not s then return { x = 0, y = 0 } end
	return { x = s.x, y = s.y }
end

return M
