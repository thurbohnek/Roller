-- Ukentlige oppdrag (lagt til 2026-10-28). Data: lib/oppdrag.lua.
-- Tre kort med fremdrift, og en knapp for å hente dråpene når et
-- oppdrag er klart. Nye oppdrag hver mandag.

local composer = require( "composer" )
local ui = require( "lib.ui" )
local framgang = require( "lib.framgang" )
local oppdrag = require( "lib.oppdrag" )
local nav = require( "lib.navigasjon" )

local scene = composer.newScene()

local grp, innhold, draapePille
local tegn

local function tidIgjen()
	local s = oppdrag.sekunderIgjen()
	local d = math.floor( s / 86400 )
	local t = math.floor( ( s % 86400 ) / 3600 )
	if d > 0 then return "New quests in " .. d .. "d " .. t .. "h" end
	local m = math.floor( ( s % 3600 ) / 60 )
	return "New quests in " .. t .. "h " .. m .. "m"
end

tegn = function()
	transition.cancel( "oppdrag" )
	display.remove( innhold )
	innhold = display.newGroup()
	grp:insert( innhold )
	draapePille:sett( tostring( framgang.draaper() ) )

	for i, o in ipairs( oppdrag.liste() ) do
		local y = 168 + ( i - 1 ) * 122
		local x = ui.CX
		local ferdig = o.har >= o.maal
		ui.panel( innhold, x, y, 700, 108, { radius = 22, lys = o.hentet } )
		ui.ikon( innhold, o.hentet and "hake" or "flagg", x - 300, y, 60 )
		ui.tekst( innhold, o.tekst, x - 256, y - 22, 22, { ankerX = 0,
			farge = o.hentet and ui.F.lilla or ui.F.krem } )
		-- fremdriftslinje
		local bx, bb = x - 256, 300
		local spor = display.newRoundedRect( innhold, bx + bb / 2, y + 18, bb, 18, 9 )
		spor:setFillColor( 0, 0, 0, 0.35 )
		local andel = math.min( 1, o.har / o.maal )
		if andel > 0 then
			local fyll = display.newRoundedRect( innhold, bx, y + 18, math.max( 18, bb * andel ), 18, 9 )
			fyll.anchorX = 0
			fyll.fill = ui.gradient( ui.KNAPP.gronn[1], ui.KNAPP.gronn[2] )
		end
		ui.tekst( innhold, o.har .. " / " .. o.maal, bx + bb + 14, y + 17, 16, { ankerX = 0,
			farge = o.hentet and ui.F.lilla or ui.F.kremDempet, fet = false } )
		if o.hentet then
			ui.tekst( innhold, "Done", x + 270, y, 22, { farge = ui.F.lilla } )
		elseif ferdig then
			local k = ui.knapp( innhold, { tekst = "+" .. o.lonn, ikon = "blad", x = x + 262, y = y, bredde = 130,
				hoyde = 52, storrelse = 22, trykk = function()
					if oppdrag.hent( i ) then
						require( "lib.lyd" ).spill( "kjop" )
						tegn()
					end
				end } )
			transition.to( k, { tag = "oppdrag", time = 600, xScale = 1.07, yScale = 1.07, iterations = 0,
				transition = easing.continuousLoop } )
		else
			ui.ikon( innhold, "blad", x + 236, y, 34 )
			ui.tekst( innhold, "+" .. o.lonn, x + 256, y - 1, 22, { ankerX = 0, farge = ui.F.blad } )
		end
	end
	ui.tekst( innhold, tidIgjen(), ui.CX, 520, 18, { farge = ui.F.kremDempet, fet = false } )
end

function scene:create( event )
	grp = self.view
	local bg = display.newRect( grp, ui.CX, ui.CY, ui.FULL_B + 4, ui.FULL_H + 4 )
	bg.fill = ui.gradient( ui.F.jordLys, ui.F.jordMork )
	ui.rundKnapp( grp, "tilbake", ui.VENSTRE + 40, 36, 56, function() nav.gaaTil( "scenes.gotomenu" ) end )
	ui.tittel( grp, "Weekly quests", ui.CX, 40, 40, ui.F.krem, ui.F.jord )
	draapePille = ui.pille( grp, "blad", ui.HOYRE - 92, 36, 150, tostring( framgang.draaper() ), true )
	ui.tekst( grp, "Finish quests to earn leaves.", ui.CX, 92, 18, { farge = ui.F.kremDempet, fet = false } )
	tegn()
end

function scene:hide( event )
	if event.phase == "will" then
		transition.cancel( "oppdrag" )
	elseif event.phase == "did" then
		composer.removeScene( "scenes.oppdrag" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
