-- Butikken: evner, drakter og hatter (lagt til 2026-10-28).
--
-- Lagres med GGData ("oppgradering"). Betales med dråper (lib/framgang.lua).
--
-- Evnene endrer IKKE fysikken; marken beveger seg likt for alle. De
-- hjelper med det man samler:
--   magnet  - dråpene fanges lenger unna (lib/samling.lua)
--   flaks   - noen dråper teller dobbelt (lib/samling.lua)
--   radar   - en pil ved marken peker mot nærmeste unge som mangler
--
-- Drakt og hatt er bare utseende. Bildene lages av
-- Util/grafikk/lag_mark.py (mark/<drakt>/..., mark/hatt_<navn>.png).
--
-- Banefilene og lib/markfysikk.lua henter markbildene med
--     oppgradering.drakt( "hale.png" )   -- "mark/<valgt drakt>/hale.png"
-- og setter hatten på med
--     oppgradering.settPaaHatt( camera, del9 )

local GGData = require( "lib.GGData" )
local framgang = require( "lib.framgang" )

local M = {}

local data = GGData:new( "oppgradering" )
if data.eier == nil then data.eier = {} end
if data.drakt == nil then data.drakt = "rosa" end
if data.hatt == nil then data.hatt = "ingen" end

local function lagre() data:save() end

-- pris per nivå; tekst per nivå
M.EVNER = {
	{ id = "magnet", navn = "Leaf Magnet", ikon = "magnet", pris = { 120, 300 },
		tekst = { "Grab leaves from further away.", "Grab leaves from much further away." } },
	{ id = "flaks", navn = "Lucky Clover", ikon = "klover", pris = { 150, 350 },
		tekst = { "1 in 6 leaves counts double.", "1 in 3 leaves counts double." } },
	{ id = "radar", navn = "Family Radar", ikon = "radar", pris = { 250 },
		tekst = { "An arrow by your worm points to the nearest lost child." } },
}

M.DRAKTER = {
	{ id = "rosa", navn = "Classic", pris = 0 },
	{ id = "sol", navn = "Sunny", pris = 150 },
	{ id = "hav", navn = "Ocean", pris = 150 },
	{ id = "mynte", navn = "Mint", pris = 150 },
	{ id = "drue", navn = "Grape", pris = 200 },
	{ id = "tiger", navn = "Tiger", pris = 300 },
	{ id = "natt", navn = "Starry Night", pris = 350 },
	{ id = "regnbue", navn = "Rainbow", pris = 500 },
}

M.HATTER = {
	{ id = "ingen", navn = "No hat", pris = 0 },
	{ id = "fest", navn = "Party Hat", pris = 100 },
	{ id = "caps", navn = "Cap", pris = 120 },
	{ id = "lue", navn = "Beanie", pris = 120 },
	{ id = "blomst", navn = "Flower", pris = 150 },
	{ id = "flosshatt", navn = "Top Hat", pris = 250 },
	{ id = "krone", navn = "Crown", pris = 400 },
}

local function finn( liste, id )
	for _, v in ipairs( liste ) do if v.id == id then return v end end
end

-- ---------------------------------------------------------- evner

function M.niva( id )
	return data.eier["evne_" .. id] or 0
end

function M.evne( id ) return finn( M.EVNER, id ) end

-- Pris for neste nivå, eller nil hvis evnen er fullt oppgradert.
function M.nestePris( id )
	local e = finn( M.EVNER, id )
	return e and e.pris[M.niva( id ) + 1]
end

function M.kjopEvne( id )
	local pris = M.nestePris( id )
	if not pris or not framgang.bruk( pris ) then return false end
	data.eier["evne_" .. id] = M.niva( id ) + 1
	lagre()
	return true
end

-- Hvor mye lenger unna dråper fanges (ganges med vanlig avstand).
function M.magnetFaktor()
	return ( { 1, 1.6, 2.2 } )[M.niva( "magnet" ) + 1]
end

-- Sjansen for at en dråpe teller dobbelt.
function M.flaksSjanse()
	return ( { 0, 1 / 6, 1 / 3 } )[M.niva( "flaks" ) + 1]
end

function M.harRadar()
	return M.niva( "radar" ) > 0
end

-- ---------------------------------------------------------- utseende
-- art = "drakt" eller "hatt"

local function liste( art ) return art == "drakt" and M.DRAKTER or M.HATTER end

function M.eier( art, id )
	local v = finn( liste( art ), id )
	if not v then return false end
	return v.pris == 0 or data.eier[art .. "_" .. id] == true
end

function M.kjop( art, id )
	local v = finn( liste( art ), id )
	if not v or M.eier( art, id ) then return false end
	if not framgang.bruk( v.pris ) then return false end
	data.eier[art .. "_" .. id] = true
	lagre()
	return true
end

function M.valgt( art )
	return art == "drakt" and data.drakt or data.hatt
end

function M.velg( art, id )
	if not M.eier( art, id ) then return false end
	if art == "drakt" then data.drakt = id else data.hatt = id end
	lagre()
	return true
end

-- Bildefil for en del av marken i valgt drakt ("hale.png", "del1.png", "hode.png").
function M.drakt( fil, drakt )
	return "mark/" .. ( drakt or data.drakt ) .. "/" .. fil
end

function M.hattFil( id )
	id = id or data.hatt
	if not id or id == "ingen" then return nil end
	return "mark/hatt_" .. id .. ".png"
end

-- Hatten følger hodet (del9) hvert bilde. Ingen fysikk.
-- Hodet vises 30x25 og ser mot venstre; hatten sitter på toppen.
-- beholder er kameraet i banene (legges i lag 1) eller en vanlig gruppe.
function M.settPaaHatt( beholder, hode )
	local fil = M.hattFil()
	if not fil or not hode then return end
	local h = display.newImageRect( fil, 27, 22 )
	if beholder._PERSPECTIVE_PRIVATE_VALUES then
		beholder:add( h, 1, false )
	else
		beholder:insert( h )
	end
	local OX, OY = -2, -19
	local function folg()
		if not h.parent or not hode.x then
			Runtime:removeEventListener( "enterFrame", folg )
			display.remove( h )
			return
		end
		local r = math.rad( hode.rotation )
		local c, s = math.cos( r ), math.sin( r )
		h.x = hode.x + OX * c - OY * s
		h.y = hode.y + OX * s + OY * c
		h.rotation = hode.rotation
	end
	Runtime:addEventListener( "enterFrame", folg )
	folg()
	return h
end

return M
