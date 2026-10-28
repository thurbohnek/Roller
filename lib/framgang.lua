-- Spillerens fremgang (lagt til 2026-10-28): dråper, reddede markeunger,
-- daglig gave og fullførte baner. Lagres med GGData ("framgang"), samme
-- lagring som innstillingene.
--
--   Dråper (draaper)  - pengene. Samles i banene, brukes i butikken.
--   Unger (unger[N])  - tre gjemte markeunger per bane, { true, false, true }.
--                       Lagres per bane, så det beste resultatet teller.
--   Gave              - daglig gave; større jo flere dager på rad.
--
-- Banene låses fortsatt opp av lib/ogt_levelmanager.lua (unlockNextLevel).

local GGData = require( "lib.GGData" )

local M = {}

M.BANER = 9
M.UNGER_PER_BANE = 3

local data = GGData:new( "framgang" )
if data.draaper == nil then data.draaper = 0 end
if data.unger == nil then data.unger = {} end
if data.fullfort == nil then data.fullfort = {} end
if data.beste == nil then data.beste = {} end

local function lagre()
	data:save()
end
M.lagre = lagre

-- ---------------------------------------------------------- dråper

function M.draaper()
	return data.draaper or 0
end

-- utsett = true: lagres ikke til disk nå (samling i banen lagrer selv
-- høyst én gang i sekundet med M.lagre()).
function M.leggTilDraaper( n, utsett )
	data.draaper = math.max( 0, M.draaper() + n )
	if not utsett then lagre() end
	return data.draaper
end

-- Trekker n dråper hvis spilleren har nok. Returnerer true ved kjøp.
function M.bruk( n )
	if M.draaper() < n then return false end
	data.draaper = M.draaper() - n
	lagre()
	return true
end

-- ---------------------------------------------------------- unger

-- unger reddet i bane N: liste med tre true/false
function M.unger( bane )
	local u = data.unger[tostring( bane )]
	if not u then return { false, false, false } end
	return { u[1] == true, u[2] == true, u[3] == true }
end

function M.antallUnger( bane )
	local n = 0
	for _, v in ipairs( M.unger( bane ) ) do if v then n = n + 1 end end
	return n
end

function M.totaltUnger()
	local n = 0
	for b = 1, M.BANER do n = n + M.antallUnger( b ) end
	return n
end

-- Lagrer ungene fra en runde; beholder de som var reddet fra før.
function M.lagreUnger( bane, reddet )
	local gamle = M.unger( bane )
	local ny = {}
	for i = 1, M.UNGER_PER_BANE do ny[i] = gamle[i] or reddet[i] == true end
	data.unger[tostring( bane )] = ny
	lagre()
end

-- ---------------------------------------------------------- baner

function M.fullfort( bane )
	return data.fullfort[tostring( bane )] == true
end

-- Kalles når målet nås. Returnerer true første gang banen klares.
function M.fullfor( bane )
	local forste = not M.fullfort( bane )
	data.fullfort[tostring( bane )] = true
	lagre()
	return forste
end

-- Bonus første gang banen klares. Returnerer true bare én gang per bane.
function M.taBonus( bane )
	data.bonus = data.bonus or {}
	if data.bonus[tostring( bane )] then return false end
	data.bonus[tostring( bane )] = true
	lagre()
	return true
end

-- ---------------------------------------------------------- daglig gave

local GAVER = { 20, 30, 40, 60, 80, 100, 150 }   -- dag 1..7, så 150 hver dag

local function dagnummer()
	return math.floor( os.time() / 86400 )
end

-- Returnerer { dag = rekkedag, draaper = n } hvis det er en gave å hente
-- i dag, ellers nil.
function M.gaveIDag()
	local i_dag = dagnummer()
	if data.gaveDag == i_dag then return nil end
	local rekke = 1
	if data.gaveDag == i_dag - 1 then rekke = ( data.gaveRekke or 0 ) + 1 end
	return { dag = rekke, draaper = GAVER[math.min( rekke, #GAVER )] }
end

function M.hentGave()
	local g = M.gaveIDag()
	if not g then return nil end
	data.gaveDag = dagnummer()
	data.gaveRekke = g.dag
	data.draaper = M.draaper() + g.draaper
	lagre()
	return g
end

M.GAVER = GAVER

return M
