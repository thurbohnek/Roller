-- Innstillinger som skal huskes mellom hver gang spillet startes.
-- Lagt til 2026-09-27 sammen med "Settings"-steinen på startskjermen.
--
-- Foreløpig bare lyd av/på. Valget lagres med GGData (samme som
-- banefremgangen i ogt_levelmanager.lua) og settes med audio.setVolume,
-- som gjelder all lyd i spillet.

local GGData = require( "lib.GGData" )

local M = {}

local data = GGData:new( "innstillinger" )
if data.lyd == nil then
	data.lyd = true
end

function M.lydPaa()
	return data.lyd ~= false
end

-- Kalles fra main.lua ved oppstart, og hver gang valget endres.
function M.brukLyd()
	audio.setVolume( M.lydPaa() and 1 or 0 )
end

function M.byttLyd()
	data.lyd = not M.lydPaa()
	data:save()
	M.brukLyd()
	require( "lib.lyd" ).oppdaterBakgrunn()
	-- Musikken: "av", "mix" eller id-en til et spor (lib/lyd.lua M.SPOR).
-- Standard er "critters". (Fram til 2026-10-29 var det bare av/på i
-- data.musikk; false der betyr av.)
function M.musikkValg()
	if data.musikkValg then return data.musikkValg end
	if data.musikk == false then return "av" end
	return "critters"
end

function M.musikkPaa()
	return M.musikkValg() ~= "av"
end

function M.settMusikk( valg )
	data.musikkValg = valg
	data:save()
	require( "lib.lyd" ).oppdaterBakgrunn()
end

-- Naturlydene i bakgrunnen (vind, fugler, drypp), av/på for seg.
function M.naturPaa()
	return data.natur ~= false
end

function M.byttNatur()
	data.natur = not M.naturPaa()
	data:save()
	require( "lib.lyd" ).oppdaterBakgrunn()
	return M.naturPaa()
end

return M.lydPaa()
end

-- Musikken: "av", "mix" eller id-en til et spor (lib/lyd.lua M.SPOR).
-- Standard er "critters". (Fram til 2026-10-29 var det bare av/på i
-- data.musikk; false der betyr av.)
function M.musikkValg()
	if data.musikkValg then return data.musikkValg end
	if data.musikk == false then return "av" end
	return "critters"
end

function M.musikkPaa()
	return M.musikkValg() ~= "av"
end

function M.settMusikk( valg )
	data.musikkValg = valg
	data:save()
	require( "lib.lyd" ).oppdaterBakgrunn()
end

-- Naturlydene i bakgrunnen (vind, fugler, drypp), av/på for seg.
function M.naturPaa()
	return data.natur ~= false
end

function M.byttNatur()
	data.natur = not M.naturPaa()
	data:save()
	require( "lib.lyd" ).oppdaterBakgrunn()
	return M.naturPaa()
end

return M
