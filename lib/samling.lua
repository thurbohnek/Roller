-- Blader og markeunger i banene (lagt til 2026-10-28; bladene var
-- dråper i første versjon, derfor heter mye i koden fortsatt "draape").
--
-- Posisjonene står i lib/samleN.lua (lages av Util/grafikk/lag_samling.py),
-- i enheter fra sentrum av flis 1, så de følger banen også med teststart.
--
-- Tingene har ingen fysikk: hvert bilde sjekkes avstanden fra marken sine
-- ledd til tingene i nærheten. Da kan de ikke påvirke hvordan marken
-- beveger seg, og de gamle kollisjonslytterne i banefilene ser dem ikke.
--
--   Dråpe: +1 dråpe (lagres med en gang, men skrives til disk høyst
--          én gang i sekundet).
--   Unge:  lagres som reddet i banen med en gang (lib/framgang.lua).
--          Unger som er reddet fra før, vises som skygger.
--
-- Evner fra butikken (lib/oppgradering.lua): magnet (lengre fangavstand
-- for dråper), flaks (noen dråper teller dobbelt) og radar (pil ved
-- marken mot nærmeste unge som mangler).
--
-- Fra banefila, etter at fliser og mark er lagt i kameraet:
--     require( "lib.samling" ).lag( N, camera, firkant1,
--         { del1, del2, del3, del4, del5, del6, del7, del8, del9 } )

local ui = require( "lib.ui" )
local hud = require( "lib.hud" )
local framgang = require( "lib.framgang" )
local oppgradering = require( "lib.oppgradering" )
local oppdrag = require( "lib.oppdrag" )
local lyd = require( "lib.lyd" )
local sjekkpunkt = require( "lib.sjekkpunkt" )

local M = {}

local R_DRAAPE = 50      -- fangavstand fra sentrum av et ledd, i enheter
local R_UNGE = 56
local NAER = 700         -- bare ting nærmere enn dette sjekkes nøye

local siste = { bane = nil, draaper = 0, unger = { false, false, false } }

-- Resultatet fra sist spilte runde (brukes av scenes/fullfort.lua).
function M.siste()
	return siste
end

local function hudRad( bane, tidligere )
	local h = hud.gruppe()
	local g = display.newGroup()
	h:insert( g )
	local x, y = ui.VENSTRE + 96, ui.TOPP + 98
	local flate = display.newRoundedRect( g, x + 34, y, 232, 44, 22 )
	flate:setFillColor( ui.F.jord[1], ui.F.jord[2], ui.F.jord[3], 0.8 )
	flate.strokeWidth = 3
	flate:setStrokeColor( unpack( ui.F.kant ) )
	ui.ikon( g, "blad", x - 60, y, 30 )
	local tall = ui.tekst( g, "0", x - 38, y - 1, 20, { ankerX = 0 } )
	local plasser = {}
	for i = 1, 3 do
		local px = x + 40 + ( i - 1 ) * 38
		plasser[i] = ui.ikon( g, tidligere[i] and "unge" or "ungeTom", px, y, 32 )
		if tidligere[i] then plasser[i].alpha = 0.55 end
	end
	return g, tall, plasser
end

function M.lag( bane, camera, firkant1, deler )
	local ok, data = pcall( require, "lib.samle" .. bane )
	if not ok or type( data ) ~= "table" then return end

	siste = { bane = bane, draaper = 0, unger = { false, false, false } }
	local tidligere = framgang.unger( bane )
	local rad, tall, plasser = hudRad( bane, tidligere )

	-- Pynt langs bakken (blomster, gress, sopp, krystaller). Legges bakerst
	-- i kameralaget, bak flisene, så foten forsvinner ned i bakken.
	for _, pn in ipairs( data.pynt or {} ) do
		local ok, bilde = pcall( display.newImageRect, "ui/pynt/" .. pn[1] .. ".png", pn[4], pn[4] )
		if ok and bilde then
			bilde.anchorY = 1
			bilde.x, bilde.y = firkant1.x + pn[2], firkant1.y + pn[3]
			bilde.rotation = pn[5]
			if math.random() < 0.5 then bilde.xScale = -1 end
			camera:add( bilde, 1, false )
			bilde:toBack()
		end
	end

	local ting = {}
	local holder = display.newGroup()      -- for å vite når banen rives
	camera:add( holder, 1, false )

	local function legg( x, y, art, i, verdi )
		local g = display.newGroup()
		g.x, g.y = firkant1.x + x, firkant1.y + y
		if art == "draape" and ( verdi or 1 ) > 1 then
			-- gyllent blad: større, med glød
			local glod = display.newCircle( g, 0, 0, 52 )
			glod:setFillColor( 1, 0.85, 0.3, 0.3 )
			ui.ikon( g, "bladGull", 0, 0, 84 )
		elseif art == "draape" then
			ui.ikon( g, "blad", 0, 0, 58 )
			g.rotation = math.random( -25, 25 )
		else
			local glod = display.newCircle( g, 0, 0, 56 )
			glod:setFillColor( 1, 0.85, 0.55, 0.28 )
			ui.ikon( g, "unge", 0, 0, 92 )
			if tidligere[i] then g.alpha = 0.35 end
		end
		camera:add( g, 1, false )
		ting[#ting + 1] = { obj = g, art = art, i = i, x = g.x, y = g.y, verdi = verdi or 1,
			rot = g.rotation, fase = math.random() * 6.28 }
	end
	-- bladene: { x, y, verdi } (verdi 5 = gyllent blad)
	for _, p in ipairs( data.blader or data.draaper or {} ) do legg( p[1], p[2], "draape", nil, p[3] ) end
	for i, p in ipairs( data.unger or {} ) do legg( p[1], p[2], "unge", i ) end

	local rDraape = R_DRAAPE * oppgradering.magnetFaktor()
	local flaks = oppgradering.flaksSjanse()

	-- radarpil: kretser rundt marken og peker mot nærmeste unge som mangler
	local pil
	if oppgradering.harRadar() then
		pil = display.newGroup()
		local trekant = display.newPolygon( pil, 0, 0, { 0, -14, 26, 0, 0, 14, 6, 0 } )
		trekant:setFillColor( unpack( ui.F.blad ) )
		trekant.strokeWidth = 3
		trekant:setStrokeColor( 1, 1, 1, 0.9 )
		camera:add( pil, 1, false )
		pil.isVisible = false
	end

	-- Sjekkpunktene: et flagg på bakken midt under der marken startes.
	-- Passerer marken det, er sjekkpunktet nådd (lib/sjekkpunkt.lua).
	local flagg = {}
	for i, sp in ipairs( data.sjekkpunkter or {} ) do
		local g = display.newGroup()
		camera:add( g, 1, false )
		g.x, g.y = firkant1.x + sp.lx - 100, firkant1.y + sp.ly + 46
		local stang = display.newRoundedRect( g, 0, -60, 8, 120, 4 )
		stang:setFillColor( unpack( ui.F.jordLys ) )
		local duk = display.newPolygon( g, 34, -100, { 0, -26, 60, 0, 0, 26 } )
		local glod = display.newCircle( g, 30, -100, 56 )
		glod:setFillColor( 1, 0.85, 0.4, 0.25 )
		glod.isVisible = false
		duk:toFront()
		local nadd = ( sjekkpunkt.aktiv( bane ) or 0 ) >= i
		local function farg( paa )
			if paa then duk:setFillColor( unpack( ui.F.gull ) ) else duk:setFillColor( 0.55, 0.5, 0.45 ) end
			duk.strokeWidth = 4
			duk:setStrokeColor( unpack( paa and ui.F.kant or { 0.3, 0.25, 0.2 } ) )
			glod.isVisible = paa
		end
		farg( nadd )
		flagg[i] = { g = g, x = firkant1.x + sp.lx, nadd = nadd, farg = farg }
	end

	local function nadd( i )
		local f = flagg[i]
		f.nadd = true
		f.farg( true )
		sjekkpunkt.sett( bane, i )
		lyd.spill( "gave" )
		local h = hud.gruppe()
		local t = ui.tittel( h, "Checkpoint!", ui.CX, ui.TOPP + 120, 40, ui.F.gull, ui.F.jordMork )
		t.alpha = 0
		transition.to( t, { time = 250, alpha = 1, y = t.y - 10 } )
		transition.to( t, { delay = 1300, time = 400, alpha = 0, onComplete = function() display.remove( t ) end } )
	end

	local skitten = false
	local sistLagret = system.getTimer()

	-- Ungene som er funnet i runden, følger etter marken på rekke: små
	-- kopier av marken (alle ni ledd) som spiller av nøyaktig det marken
	-- gjorde litt tidligere, samme vei, samme rulling og strekking. Bare
	-- grafikk, ingen fysikk.
	local folgere = {}
	local spor = {}            -- marken sin positur de siste bildene (nyeste først)
	local AVSTAND = 26         -- bilder mellom hver i rekka
	local SKALA = 0.55         -- ungene er litt over halvparten så store
	local BILDER = { { "hale.png", 27, 17 } }
	for i = 2, 8 do BILDER[i] = { "del1.png", 34, 17 } end
	BILDER[9] = { "hode.png", 30, 25 }

	local function nyFolger()
		local g = display.newGroup()
		camera:add( g, 1, false )
		g.deler = {}
		for i = 1, 9 do
			local b = BILDER[i]
			local d = display.newImageRect( g, "mark/rosa/" .. b[1], b[2] * SKALA, b[3] * SKALA )
			d.isVisible = false
			g.deler[i] = d
		end
		g.alpha = 0
		transition.to( g, { time = 400, alpha = 1 } )
		folgere[#folgere + 1] = g
	end

	-- Tegner ungen g i marken sin positur fra n bilder siden: leddene samles
	-- rundt midten (ledd 5) og flyttes litt ned, så den lille marken står på
	-- bakken der den store sto.
	local function tegnFolger( g, positur )
		local mx, my = positur[5][1], positur[5][2] + ( 1 - SKALA ) * 32
		for i = 1, 9 do
			local p, d = positur[i], g.deler[i]
			d.x = mx + ( p[1] - positur[5][1] ) * SKALA
			d.y = my + ( p[2] - positur[5][2] ) * SKALA
			d.rotation = p[3]
			d.isVisible = true
		end
	end

	-- små gnister som spruter ut fra (x, y) i verden
	local function gnister( x, y, farge, antall, avstand )
		for i = 1, antall do
			local v = ( i / antall ) * math.pi * 2 + math.random() * 0.5
			local p = display.newCircle( 0, 0, math.random( 5, 9 ) )
			camera:add( p, 1, false )
			p.x, p.y = x, y
			p:setFillColor( farge[1], farge[2], farge[3] )
			transition.to( p, { time = 380, x = x + math.cos( v ) * avstand, y = y + math.sin( v ) * avstand,
				alpha = 0, xScale = 0.3, yScale = 0.3, transition = easing.outQuad,
				onComplete = function() display.remove( p ) end } )
		end
	end

	local function ta( t )
		t.tatt = true
		local o = t.obj
		if t.art == "draape" then
			local dobbel = math.random() < flaks
			local verdi = t.verdi * ( dobbel and 2 or 1 )
			siste.draaper = siste.draaper + verdi
			framgang.leggTilDraaper( verdi, true )
			oppdrag.hendelse( "draape", verdi )
			skitten = true
			if t.verdi > 1 then
				lyd.spill( "gave" )
				gnister( t.x, t.y, ui.F.gull, 12, 110 )
			else
				lyd.spill( "draape" )
				gnister( t.x, t.y, ui.F.blad, 6, 60 )
			end
			if ( verdi > 1 ) and o.parent then
				ui.tekst( o, "+" .. verdi, 0, -44, 24, { farge = ui.F.gull } )
			end
			tall:settTekst( tostring( siste.draaper ) )
			transition.to( o, { time = 220, xScale = 1.8, yScale = 1.8, alpha = 0,
				onComplete = function() display.remove( o ) end } )
		else
			siste.unger[t.i] = true
			lyd.spill( "unge" )
			nyFolger()
			gnister( t.x, t.y, ui.F.gull, 12, 110 )
			if not tidligere[t.i] then
				local u = { false, false, false }
				u[t.i] = true
				framgang.lagreUnger( bane, u )
				oppdrag.hendelse( "unge", 1 )
			end
			local p = plasser[t.i]
			if p and p.parent then
				local ny = ui.ikon( p.parent, "unge", p.x, p.y, 32 )
				display.remove( p )
				plasser[t.i] = ny
				ui.sprett( ny, 0 )
			end
			transition.to( o, { time = 450, xScale = 2.2, yScale = 2.2, alpha = 0,
				transition = easing.outQuad, onComplete = function() display.remove( o ) end } )
		end
	end

	local function hvertBilde()
		if not holder.parent or not deler[5] or not deler[5].x then
			Runtime:removeEventListener( "enterFrame", hvertBilde )
			if skitten then framgang.lagre() end
			return
		end
		local tid = system.getTimer()
		local mx, my = deler[5].x, deler[5].y
		for i, f in ipairs( flagg ) do
			if not f.nadd and mx > f.x + 40 then nadd( i ) end
		end
		-- følgerne
		if deler[1].x and deler[9].x then
			local positur = {}
			for i = 1, 9 do positur[i] = { deler[i].x, deler[i].y, deler[i].rotation } end
			table.insert( spor, 1, positur )
			if #spor > AVSTAND * 3 + 1 then spor[#spor] = nil end
			for k, g in ipairs( folgere ) do
				local positur = spor[math.min( #spor, k * AVSTAND )]
				if positur and g.parent then tegnFolger( g, positur ) end
			end
		end
		for _, t in ipairs( ting ) do
			if not t.tatt and t.obj.parent then
				local dx, dy = t.x - mx, t.y - my
				if dx > -NAER and dx < NAER and dy > -NAER and dy < NAER then
					-- svev opp og ned (og bladene vipper litt) bare når de er i nærheten
					t.obj.y = t.y + math.sin( tid * 0.004 + t.fase ) * 5
					if t.art == "draape" and t.verdi == 1 then
						t.obj.rotation = t.rot + math.sin( tid * 0.003 + t.fase ) * 10
					end
					local r = t.art == "draape" and rDraape or R_UNGE
					local r2 = r * r
					for _, d in ipairs( deler ) do
						if d.x then
							local ex, ey = t.x - d.x, t.y - d.y
							if ex * ex + ey * ey < r2 then
								ta( t )
								break
							end
						end
					end
				end
			end
		end
		if pil then
			-- nærmeste unge som ikke er reddet
			local best, bd
			for _, t in ipairs( ting ) do
				if t.art == "unge" and not t.tatt and not tidligere[t.i] then
					local dx, dy = t.x - mx, t.y - my
					local d2 = dx * dx + dy * dy
					if not bd or d2 < bd then best, bd = t, d2 end
				end
			end
			if best and bd > 260 * 260 then
				local v = math.atan2( best.y - my, best.x - mx )
				pil.x, pil.y = mx + math.cos( v ) * 120, my + math.sin( v ) * 120
				pil.rotation = math.deg( v )
				pil.isVisible = true
				pil:toFront()
			else
				pil.isVisible = false
			end
		end
		if skitten and tid - sistLagret > 1000 then
			framgang.lagre()
			skitten = false
			sistLagret = tid
		end
	end
	Runtime:addEventListener( "enterFrame", hvertBilde )
	hud.gruppe():toFront()
end

return M
