-- "Level complete" (lagt til 2026-10-28). Vises som overlay når marken
-- når målet (goto2 i banefilene). Viser banen, ungene som er reddet
-- totalt i banen og dråpene, og går videre til neste bane, banevalget
-- eller hjemmet. Å forlate en fullført bane koster ikke forsøk.

local composer = require( "composer" )
local ui = require( "lib.ui" )
local framgang = require( "lib.framgang" )
local nav = require( "lib.navigasjon" )
local lm = require( "lib.ogt_levelmanager" )
local samling = require( "lib.samling" )

-- dråper i bonus første gang en bane klares
local BONUS_FORSTE = 25

local scene = composer.newScene()

local function rydd()
	transition.cancel()
	nav.stoppKnekkTimer()
end

function scene:create( event )
	local grp = self.view
	local bane = lm.currentLevel or 1
	ui.hinne( grp, 0.55 )

	local p = ui.panel( grp, ui.CX, ui.CY + 14, 560, 400 )
	ui.tittel( grp, "Level " .. bane .. " complete!", ui.CX, ui.CY - 140, 40, ui.F.gull, ui.F.jordMork )

	-- dråpene fra runden, og bonus første gang banen klares
	-- (ogt_levelmanager.unlockNextLevel har allerede kalt framgang.fullfor,
	-- så første gang kjennes på at bonusen ikke er gitt for banen før)
	local runde = samling.siste()
	local fikk = runde.bane == bane and runde.draaper or 0
	local bonus = 0
	if framgang.taBonus( bane ) then
		bonus = BONUS_FORSTE
		framgang.leggTilDraaper( bonus )
	end
	framgang.lagre()
	require( "lib.oppdrag" ).hendelse( "bane", 1 )
	require( "lib.lyd" ).spill( "mal" )

	-- ungene i banen: tre plasser som spretter inn én etter én
	local u = framgang.unger( bane )
	local nye = runde.bane == bane and runde.unger or {}
	for i = 1, 3 do
		local x = ui.CX - 90 + ( i - 1 ) * 90
		local plass = display.newCircle( grp, x, ui.CY - 50, 38 )
		plass:setFillColor( ui.F.jordMork[1], ui.F.jordMork[2], ui.F.jordMork[3], 0.8 )
		local ik = ui.ikon( grp, u[i] and "unge" or "ungeTom", x, ui.CY - 50, 62 )
		ui.sprett( ik, 250 + i * 220 )
		if nye[i] then
			ui.tekst( grp, "Saved!", x, ui.CY - 4, 15, { farge = ui.F.gull } )
		end
	end
	local n = framgang.antallUnger( bane )
	ui.tekst( grp, n == 3 and "The whole family from this cave is safe!" or
		( n .. " of 3 children found in this cave" ), ui.CX, ui.CY + 20, 20, { farge = ui.F.kremDempet, fet = false } )
	local linje = "+" .. fikk .. " leaves"
	if bonus > 0 then linje = linje .. "   +" .. bonus .. " first-time bonus" end
	ui.tekst( grp, linje, ui.CX, ui.CY + 46, 19, { farge = ui.F.blad } )
	ui.pille( grp, "blad", ui.CX, ui.CY + 88, 160, tostring( framgang.draaper() ) )

	local siste = not lm.anotherLevel()
	ui.knapp( grp, { tekst = siste and "All levels" or "Next level", ikon = "spill", x = ui.CX, y = ui.CY + 150,
		bredde = 260, hoyde = 64, trykk = function()
			rydd()
			if siste then nav.gaaTil( "scenes.gotochooselevel" ) else nav.gaaTil( "scenes.gotonextlevel" ) end
		end } )
	ui.rundKnapp( grp, "liste", ui.CX - 200, ui.CY + 150, 60, function()
		rydd()
		nav.gaaTil( "scenes.gotochooselevel" )
	end )
	ui.rundKnapp( grp, "hjem", ui.CX + 200, ui.CY + 150, 60, function()
		rydd()
		nav.gaaTil( "scenes.gotomenu" )
	end )
end

function scene:hide( event )
	if event.phase == "did" then
		composer.removeScene( "scenes.fullfort" )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "hide", scene )

return scene
