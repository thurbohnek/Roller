-- Skjermbildet under spill (lagt til 2026-10-28, ny stil).
--
-- Banene legger alt i sceneGroup (grp), som skaleres til 0,6 sent i
-- scene:create. Denne gruppa ligger i grp, men regner seg tilbake hvert
-- bilde, så alt i den kan plasseres i vanlige skjermkoordinater:
--
--   øverst til venstre:  banenavn og nummer (+ plass til ungene)
--   øverst til høyre:    forsøk (lib/liv.lua) og pauseknappen
--
-- Brukes fra banefilene og lib/liv.lua:
--     hud.gruppe()          -- lager/finner gruppa for gjeldende bane
--     hud.pauseKnapp( k )   -- flytter pauseknappen (knapp1) inn hit
--     hud.bane( n )         -- banepillen, og legger HUD-en øverst

local ui = require( "lib.ui" )

local M = {}

local NAVN = { "Meadow", "Molehill", "Root Tunnel", "Wet Clay", "Crystal Drip", "Pillar Hall",
	"Frozen Vein", "Deep Dark", "The Bottom" }
M.NAVN = NAVN

local hud, eier

function M.gruppe()
	local g = _G.grp
	if hud and hud.parent and eier == g then return hud end
	if not ( g and g.parent and g.insert ) then
		-- Banen er allerede revet ned (f.eks. liv.hent sin 3-sekunders
		-- timer etter at spilleren gikk ut). Gi en usynlig gruppe som
		-- fjernes neste bilde, så kallet ikke krasjer.
		local tom = display.newGroup()
		tom.isVisible = false
		timer.performWithDelay( 1, function() display.remove( tom ) end )
		return tom
	end
	hud = display.newGroup()
	eier = g
	g:insert( hud )
	local h, e = hud, g
	local function folg()
		if not h.parent or not e.contentToLocal then
			Runtime:removeEventListener( "enterFrame", folg )
			return
		end
		-- motsatt skala og forskyvning av banegruppa
		local x0, y0 = e:contentToLocal( 0, 0 )
		local x1 = e:contentToLocal( 1000, 0 )
		local s = ( x1 - x0 ) / 1000
		h.xScale, h.yScale = s, s
		h.x, h.y = x0, y0
	end
	Runtime:addEventListener( "enterFrame", folg )
	folg()
	return hud
end

-- Pauseknappen fra banefila (knapp1, pauseknapp.png) får ny plass og ny
-- størrelse; bildet er tegnet om i ny stil.
function M.pauseKnapp( k )
	local h = M.gruppe()
	h:insert( k )
	k.width, k.height = 58, 58
	k.x, k.y = ui.HOYRE - 44, ui.TOPP + 40
end

function M.bane( n )
	local h = M.gruppe()
	local g = display.newGroup()
	h:insert( g )
	local x, y = ui.VENSTRE + 132, ui.TOPP + 40
	local flate = display.newRoundedRect( g, x, y, 236, 52, 26 )
	flate:setFillColor( ui.F.jord[1], ui.F.jord[2], ui.F.jord[3], 0.88 )
	flate.strokeWidth = 3
	flate:setStrokeColor( unpack( ui.F.kant ) )
	local merke = display.newCircle( g, x - 92, y, 20 )
	merke.fill = ui.gradient( ui.KNAPP.oransje[1], ui.KNAPP.oransje[2] )
	ui.tekst( g, tostring( n ), x - 92, y - 1, 22, { farge = ui.F.hvit } )
	ui.tekst( g, NAVN[n] or ( "Level " .. n ), x + 18, y - 1, 21 )
	h:toFront()

	-- stor introtekst som glir bort
	local intro = display.newGroup()
	h:insert( intro )
	ui.tittel( intro, "Level " .. n, ui.CX, ui.CY - 70, 56, ui.F.krem, ui.F.jordMork )
	ui.tekst( intro, NAVN[n] or "", ui.CX, ui.CY - 18, 26, { skygge = true } )
	transition.to( intro, { delay = 1300, time = 500, alpha = 0, y = -30,
		onComplete = function() display.remove( intro ) end } )
end

return M
