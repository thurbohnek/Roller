-- Minispill: 100 m (lagt til 2026-09-28, ekte markfysikk fra samme dag,
-- flat bane fra 2026-09-29 etter ønske fra Mathias).
-- En liten bakke i starten gir litt fart, så er resten flatt. Marken
-- ruller ikke langt av seg selv på flat bakke; man må finne teknikken
-- for å komme seg bortover. Nedtelling først; trykker man før "GO!" er
-- det tyvstart.
--
-- Målt i en kopi av fysikken (se KODEBASE.md): uten å trykke ruller
-- marken ca. 1300 px (37 m) og stopper. Et kort trykk per omdreining,
-- når hodet er bak i ringen, holder den gående i ca. 110 px/s. Andre
-- rytmer hjelper lite eller bremser. 35 px = 1 m.

local composer = require( "composer" )
local physics = require( "physics" )
local sport = require( "lib.minisport" )
local markfysikk = require( "lib.markfysikk" )

local scene = composer.newScene()

local GRADER = 22
local TAN = math.tan( math.rad( GRADER ) )
local BAKKE = 200                     -- startbakken, px bortover
local PX_PER_M = 35
local START = -108                    -- midten av marken ved start
local MAAL = START + 100 * PX_PER_M
local FLATY = BAKKE * TAN + 230

local function bakkeY( x )
	if x < BAKKE then return x * TAN + 230 end
	return FLATY
end

local tilstand, mark, tid, fastTid
local kamera, verden, bakgrunn, tidtekst, info, status
local lytter

local function nyMark()
	if mark then mark:fjern() end
	mark = markfysikk.lag( verden, 0, 0 )
	kamera:setFocus( mark.punkt )
end

local function visStatus()
	local r = sport.rekord( "100m_fysikk" )
	status.text = r and string.format( "Record: %.2f s", r ) or "Record: -"
end

local function klar()
	tilstand = "klar"
	physics.pause()
	nyMark()
	tid, fastTid = 0, 0
	tidtekst.text = "0.00 s"
	info.text = "Tap to start. Then find the rhythm: a short tap when the head is at the back of the ring."
	visStatus()
end

local function tyvstart()
	tilstand = "tyvstart"
	info.text = "False start! Wait for GO."
	timer.performWithDelay( 1400, function()
		if tilstand == "tyvstart" then klar() end
	end )
end

local function nedtelling()
	tilstand = "nedtelling"
	local ord = { "Ready...", "Set...", "GO!" }
	for i, o in ipairs( ord ) do
		timer.performWithDelay( ( i - 1 ) * 700 + 1, function()
			if tilstand ~= "nedtelling" then return end
			info.text = o
			if i == #ord then
				tilstand = "lop"
				physics.start()
				timer.performWithDelay( 900, function()
					if tilstand == "lop" and info.text == "GO!" then info.text = "" end
				end )
			end
		end )
	end
end

local function ferdig( fullfort, tekst )
	tilstand = "ferdig"
	local linjer = { { "100 m", 30 } }
	if fullfort then
		local ny = sport.nyRekord( "100m_fysikk", tid, false )
		linjer[2] = { string.format( "Time: %.2f s", tid ), 28, { 0.92, 0.9, 0.86 } }
		linjer[3] = { ny and "New record!" or string.format( "Record: %.2f s", sport.rekord( "100m_fysikk" ) ), 24 }
	else
		linjer[2] = { tekst, 26, { 0.92, 0.9, 0.86 } }
	end
	info.text = ""
	sport.resultat( scene.view, linjer, klar )
end

function scene:create( event )
	local grp = self.view
	physics.start()
	bakgrunn = sport.bakgrunn( grp )

	kamera, verden = sport.kamera( grp, bakgrunn )

	-- liten startbakke og så flatt
	sport.terreng( verden, { { -300, bakkeY( -300 ) }, { BAKKE, FLATY }, { MAAL + 3000, FLATY } } )
	for m = 0, 100, 10 do
		local x = START + m * PX_PER_M
		sport.merke( verden, x, bakkeY( x ), m .. " m", 34 )
	end
	-- mål
	local linje = display.newRect( verden, MAAL, bakkeY( MAAL ) + 10, 20, 40 )
	linje:setFillColor( 0.92, 0.9, 0.84 )
	local skilt = display.newRoundedRect( verden, MAAL, bakkeY( MAAL ) - 260, 300, 120, 24 )
	skilt:setFillColor( unpack( require( "lib.ui" ).F.jord ) )
	skilt.strokeWidth = 6
	skilt:setStrokeColor( unpack( require( "lib.ui" ).F.gull ) )
	sport.tekst( verden, "Finish", MAAL, bakkeY( MAAL ) - 260, 48 )

	sport.tekst( grp, "100 m", sport.B / 2, 30, 30 )
	tidtekst = sport.tekst( grp, "0.00 s", sport.B / 2, 66, 26, { 0.92, 0.9, 0.86 } )
	status = sport.tekst( grp, "", sport.B - 110, 30, 18, { 0.85, 0.85, 0.85 } )
	info = sport.tekst( grp, "", sport.B / 2, 108, 19 )

	sport.trykkflate( grp, function() return mark end, function()
		if tilstand == "klar" then
			nedtelling()
			return false
		elseif tilstand == "nedtelling" then
			tyvstart()
			return false
		end
		return tilstand == "lop"
	end )
	sport.tilbake( grp )
	klar()

	local sist = system.getTimer()
	lytter = function()
		local naa = system.getTimer()
		local dt = math.min( 0.05, ( naa - sist ) / 1000 )
		sist = naa
		if not mark then return end
		-- sentrum av hele marken, ikke én del: den går rundt i ringen
		local mx, my = mark:senter()
		if not mx then return end
		if tilstand == "lop" then
			tid = tid + dt
			tidtekst.text = string.format( "%.2f s", tid )
			if mark:fart() < 8 then fastTid = fastTid + dt else fastTid = 0 end
			if fastTid > 2 then
				info.text = "Tap when the head is at the back of the ring."
			elseif info.text ~= "GO!" and fastTid == 0 and tid > 6 then
				info.text = ""
			end
			if fastTid > 12 then
				ferdig( false, "The worm stopped." )
			elseif mx >= MAAL then
				ferdig( true )
			end
		end
	end
	Runtime:addEventListener( "enterFrame", lytter )
end

function scene:hide( event )
	if event.phase == "will" then
		Runtime:removeEventListener( "enterFrame", lytter )
		kamera:stopp()
		tilstand = "borte"
	elseif event.phase == "did" then
		mark = nil
		physics.start()
		composer.removeScene( "scenes.mini_100m" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
