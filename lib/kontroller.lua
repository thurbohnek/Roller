-- Forklaring av styringen (lagt til 2026-09-28, ny stil 2026-10-28).
--
-- Vises fra "?"-knappen i hjemmet (scenes/hjem.lua) og i pausemenyen
-- (scenes/pausemenu1.lua). Pausemenyen er selv en overlay, og Composer
-- tillater bare én overlay om gangen, så forklaringen er en vanlig gruppe
-- som legges oppå det som allerede vises.
--
-- Styringen, slik den er i banefilene (trykk_knapp):
--   slipp skjermen     -> motorene går til +30, marken ruller seg til en ring
--   hold inne          -> motorene snur, marken strekker seg ut
--   dobbelttrykk       -> motorene slås av, marken blir slapp
--   ett trykk (slapp)  -> stram igjen
--
--     require( "lib.kontroller" ).vis( gruppe, function() ... end )   -- kalles ved OK

local ui = require( "lib.ui" )

local M = {}

local ROSA = ui.rgb( "F49AA8" )
local ROSA_M = ui.rgb( "D9667A" )

-- Marken tegnet av ledd langs en kurve: f(t) gir (x, y) for t = 0..1,
-- fra halen til hodet.
local function markLangs( forelder, f )
	local g = display.newGroup()
	forelder:insert( g )
	local n = 11
	for kant = 1, 2 do
		for i = 0, n do
			local t = i / n
			local x, y = f( t )
			local r = ( 8 + 4 * math.min( 1, t * 3 ) ) * ( kant == 1 and 1 or 0.78 )
			local c = display.newCircle( g, x, y, r )
			ui.farg( c, kant == 1 and ROSA_M or ROSA )
		end
	end
	local hx, hy = f( 1 )
	local hode = display.newCircle( g, hx, hy, 13 )
	ui.farg( hode, ROSA )
	hode.strokeWidth = 2.5
	hode:setStrokeColor( ROSA_M[1], ROSA_M[2], ROSA_M[3] )
	local oye = display.newCircle( g, hx + 3, hy - 3, 4.5 )
	oye:setFillColor( 1, 1, 1 )
	local pupill = display.newCircle( g, hx + 4, hy - 3, 2.4 )
	pupill:setFillColor( 0.15, 0.08, 0.1 )
	return g
end

local function ring( forelder, x, y )
	return markLangs( forelder, function( t )
		local a = math.rad( -60 + 300 * t )
		return x + 34 * math.cos( a ), y + 34 * math.sin( a )
	end )
end

local function rett( forelder, x, y )
	return markLangs( forelder, function( t ) return x - 62 + 124 * t, y + 18 end )
end

local function slapp( forelder, x, y )
	return markLangs( forelder, function( t )
		return x - 64 + 128 * t, y - 8 + 44 * math.sin( math.pi * t )
	end )
end

-- En finger som viser bevegelsen
local function finger( forelder, x, y, tekst )
	local c = display.newCircle( forelder, x, y, 15 )
	c:setFillColor( 1, 1, 1, 0.9 )
	c.strokeWidth = 3
	c:setStrokeColor( ui.F.kant[1], ui.F.kant[2], ui.F.kant[3] )
	return c
end

function M.vis( forelder, vedLukk )
	local g = display.newGroup()
	forelder:insert( g )
	ui.hinne( g )
	local panel = ui.panel( g, ui.CX, ui.CY, 880, 470 )
	ui.tittel( g, "How to move", ui.CX, ui.CY - 190, 40 )

	local kort = {
		{ "Let go", "The worm curls into a ring and rolls downhill.", ring, nil },
		{ "Hold", "The worm stretches out. Reach across gaps and push off edges.", rett, "hold" },
		{ "Double tap", "The worm goes limp and slides through narrow icy cracks. Tap once to firm up.", slapp, "dobbel" },
	}
	for i, k in ipairs( kort ) do
		local x = ui.CX - 280 + ( i - 1 ) * 280
		local y = ui.CY + 10
		local f = display.newRoundedRect( g, x, y, 256, 290, 22 )
		f:setFillColor( ui.F.jordMork[1], ui.F.jordMork[2], ui.F.jordMork[3], 0.8 )
		f.strokeWidth = 2
		f:setStrokeColor( ui.F.kant[1], ui.F.kant[2], ui.F.kant[3], 0.6 )
		k[3]( g, x, y - 78 )
		-- fingeren: tom = slipp, fylt = hold, to ringer = dobbelttrykk
		local fy = y + 6
		if k[4] == nil then
			local c = finger( g, x, fy )
			c:setFillColor( 1, 1, 1, 0.15 )
			ui.tekst( g, "release", x + 44, fy, 14, { farge = ui.F.kremDempet, fet = false } )
		elseif k[4] == "hold" then
			finger( g, x, fy )
			ui.tekst( g, "hold", x + 38, fy, 14, { farge = ui.F.kremDempet, fet = false } )
		else
			finger( g, x - 12, fy )
			finger( g, x + 12, fy )
			ui.tekst( g, "x2", x + 50, fy, 14, { farge = ui.F.kremDempet, fet = false } )
		end
		ui.tekst( g, k[1], x, y + 46, 26, { farge = ui.F.gull } )
		ui.tekst( g, k[2], x, y + 100, 17, { bredde = 226, fet = false } )
	end
	ui.knapp( g, { tekst = "Got it", ikon = "hake", x = ui.CX, y = ui.CY + 196, bredde = 200, hoyde = 56,
		trykk = function()
			display.remove( g )
			if vedLukk then vedLukk() end
		end } )
	ui.inn( g )
	return g
end

return M
