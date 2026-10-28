-- Ukentlige oppdrag (lagt til 2026-10-28).
--
-- Hver uke (mandag 00:00 UTC) trekkes tre oppdrag fra lista under, likt
-- for alle spillere samme uke. Fremdriften lagres med GGData ("oppdrag")
-- og nullstilles når uka skifter. Belønningen er dråper og hentes i
-- scenes/oppdrag.lua.
--
-- Hendelser meldes fra spillet med oppdrag.hendelse( art, antall ):
--   "draape"   en dråpe samlet           (lib/samling.lua)
--   "unge"     en ny unge reddet         (lib/samling.lua)
--   "bane"     en bane fullført          (scenes/fullfort.lua)
--   "sport"    en øvelse i Worm athletics (scenes/minispill.lua)
--   "gave"     daglig gave hentet         (scenes/hjem.lua)

local GGData = require( "lib.GGData" )
local framgang = require( "lib.framgang" )

local M = {}

local MULIGE = {
	{ art = "draape", maal = 150, lonn = 40, tekst = "Collect %d dew drops" },
	{ art = "draape", maal = 400, lonn = 90, tekst = "Collect %d dew drops" },
	{ art = "bane", maal = 3, lonn = 40, tekst = "Finish %d levels" },
	{ art = "bane", maal = 8, lonn = 100, tekst = "Finish %d levels" },
	{ art = "unge", maal = 2, lonn = 60, tekst = "Find %d lost children" },
	{ art = "sport", maal = 3, lonn = 40, tekst = "Play Worm athletics %d times" },
	{ art = "gave", maal = 4, lonn = 60, tekst = "Collect the daily gift %d days" },
}

local data = GGData:new( "oppdrag" )

local function ukenummer()
	-- 1. januar 1970 var en torsdag; +3 gjør at uka starter mandag
	return math.floor( ( os.time() / 86400 + 3 ) / 7 )
end

-- Sekunder til neste uke starter.
function M.sekunderIgjen()
	local neste = ( ukenummer() + 1 ) * 7 - 3
	return math.max( 0, math.floor( neste * 86400 - os.time() ) )
end

-- Trekker tre forskjellige oppdrag for uka, med høyst ett av hver art.
-- "Finn unger" tas bare med hvis spilleren har unger igjen å finne.
local function trekk( uke )
	local ungerIgjen = framgang.BANER * framgang.UNGER_PER_BANE - framgang.totaltUnger()
	local fro = uke % 100000 + 1
	local valgt, arter = {}, {}
	local i = 0
	while #valgt < 3 and i < 60 do
		i = i + 1
		fro = ( fro * 16807 ) % 2147483647      -- Park-Miller, holder seg innen doble tall
		local o = MULIGE[fro % #MULIGE + 1]
		local greit = not arter[o.art] and ( o.art ~= "unge" or ungerIgjen >= o.maal )
		if greit then
			arter[o.art] = true
			valgt[#valgt + 1] = o
		end
	end
	return valgt
end

local function sjekkUke()
	local uke = ukenummer()
	if data.uke ~= uke or not data.liste then
		data.uke = uke
		data.liste = {}
		for _, o in ipairs( trekk( uke ) ) do
			data.liste[#data.liste + 1] = { art = o.art, maal = o.maal, lonn = o.lonn,
				tekst = string.format( o.tekst, o.maal ), har = 0, hentet = false }
		end
		data:save()
	end
end

-- Ukas oppdrag: liste med { tekst, art, maal, har, lonn, hentet }.
function M.liste()
	sjekkUke()
	return data.liste
end

function M.hendelse( art, antall )
	sjekkUke()
	local endret = false
	for _, o in ipairs( data.liste ) do
		if o.art == art and o.har < o.maal then
			o.har = math.min( o.maal, o.har + ( antall or 1 ) )
			endret = true
		end
	end
	if endret then data:save() end
end

-- Antall oppdrag som er klare til å hentes (til merket på hjemskjermen).
function M.klare()
	local n = 0
	for _, o in ipairs( M.liste() ) do
		if o.har >= o.maal and not o.hentet then n = n + 1 end
	end
	return n
end

-- Henter belønningen. Returnerer antall dråper, eller nil.
function M.hent( i )
	local o = M.liste()[i]
	if not o or o.hentet or o.har < o.maal then return nil end
	o.hentet = true
	data:save()
	framgang.leggTilDraaper( o.lonn )
	return o.lonn
end

return M
