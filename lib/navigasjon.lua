-- Felles skjermbytte (lagt til 2026-10-28).
--
-- gaaTil( scene ) bytter scene med samme sikkerhetsnett som resten av
-- spillet: feil fanges og vises som en rød boks i stedet for at siden dør.
--
-- forlatBane( maal ) brukes av pause- og dødsmenyen når spilleren går ut
-- av en bane (retry, banevalg, hjem). Rekkefølgen er den samme som før
-- (se pausemenu1.lua sin historikk): avbryt ventende overganger og
-- knekk-timeren, trekk ett forsøk, lagre, og gå til reklame-for-liv hvis
-- forsøkene er brukt opp.

local composer = require( "composer" )

local M = {}

function M.gaaTil( scene, effekt, tid )
	local ok, err = pcall( composer.gotoScene, scene, { effect = effekt or "fade", time = tid or 400 } )
	if not ok then
		local msg = "Checkpoint: " .. tostring( _G.LAST_CHECKPOINT ) .. "\n" .. tostring( err )
		print( "CRASH going to " .. tostring( scene ) .. ": " .. msg )
		local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth - 20, display.contentHeight - 20 )
		bg:setFillColor( 0, 0, 0, 0.85 )
		local t = display.newText( { text = msg, x = display.contentCenterX, y = display.contentCenterY,
			width = display.contentWidth - 40, font = native.systemFont, fontSize = 14, align = "left" } )
		t:setFillColor( 1, 0.3, 0.3 )
	end
end

-- Avbryter knekk-timeren i banen. timer.cancel( nil ) stopper ALLE timere
-- i Solar2D, så den kalles bare når det faktisk finnes en.
function M.stoppKnekkTimer()
	if _G.eventTimer ~= nil then
		pcall( timer.cancel, _G.eventTimer )
		_G.eventTimer = nil
	end
end

function M.forlatBane( maal )
	local liv = require( "lib.liv" )
	transition.cancel()
	M.stoppKnekkTimer()
	liv.endreliv( 1 )
	liv.lagreliv()
	if liv.erTom() then
		maal = "scenes.adoffer"
	end
	M.gaaTil( maal, "fade", 400 )
end

return M
