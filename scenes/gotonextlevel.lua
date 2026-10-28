local composer = require( "composer" )

local scene = composer.newScene()

local widget = require ("widget")

widget.setTheme ( "widget_theme_ios")
local physicsData = (require "lib.shapedefs").physicsData(scaleFactor)
local physics = require( "physics" )
--physics.setDrawMode( "hybrid" )
local perspective = require ("lib.perspective")
local scaleFactor = 1.0
local bredde = display.contentWidth
local hoyde = display.contentHeight
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenLeft = display.screenOriginX
local screenWidth = display.viewableContentWidth - screenLeft * 2
local screenRight = screenLeft + screenWidth
local screenTop = display.screenOriginY
local screenHeight = display.viewableContentHeight - screenTop * 2
local screenBottom = screenTop + screenHeight
local gameUI =require("lib.gameUI")
local lm = require("lib.ogt_levelmanager")

-- -----------------------------------------------------------------------------------
-- Ny fil, 2026-09-15. Samme mønster som gotoretry.lua (splash-scene som
-- venter litt og bytter videre trygt), men for "banen er fullført, gå
-- videre til neste bane automatisk" i stedet for "start denne banen på
-- nytt". Mathias ba om at man ikke lenger skal måtte gå via banevalget
-- selv når man klarer en bane.
--
-- Alle ni goto2()-funksjonene (én per level-fil, kalt fra
-- onCollision1 sitt "mal2 vs del4" mål-treff) viste før alltid
-- "scenes.gotochooselevel" (rett til banevalget). De viser nå denne
-- splashen i stedet. lm.currentLevel er allerede satt til gjeldende
-- bane av level-fila sin egen scene:create, se der.
-- -----------------------------------------------------------------------------------
local function goto( event )
	local destination = "scenes.gotochooselevel"
	if lm.anotherLevel() then
		lm.currentLevel = lm.currentLevel + 1
		destination = "scenes.level" .. tostring(lm.currentLevel)
	end
	-- Trygt her: destination er ikke lenger den aktive scenen (denne
	-- splashen er), og har ingen overlay oppå seg. Samme
	-- removeScene()-forsiktighet som gotoretry.lua, selv om neste bane som
	-- oftest aldri har vært lastet før (removeScene på en scene som ikke
	-- finnes er en no-op i Composer).
	composer.removeScene( destination )
	local ok, err = pcall( composer.gotoScene, destination, {effect = "fade" , time = 500} )
	if not ok then
		local msg = "Checkpoint: " .. tostring(_G.LAST_CHECKPOINT) .. "\n" .. tostring(err)
		print( "CRASH going to " .. tostring(destination) .. " (gotonextlevel): " .. msg )
		local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth - 20, display.contentHeight - 20 )
		bg:setFillColor( 0, 0, 0, 0.85 )
		local t = display.newText( { text = msg, x = display.contentCenterX, y = display.contentCenterY, width = display.contentWidth - 40, font = native.systemFont, fontSize = 14, align = "left" } )
		t:setFillColor( 1, 0.3, 0.3 )
	end
end

function scene:create( event )

    local sceneGroup = self.view
   print ("gotonextlevel scene:create did")

grp=sceneGroup



    -- Lasteskjerm i ny stil (2026-10-28, lib/lasting.lua).
    require( "lib.lasting" ).vis( sceneGroup )



end


-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        print ("gotonextlevel scene:show will")
    elseif ( phase == "did" ) then
        print ("gotonextlevel scene:show did")

timer.performWithDelay( 800, goto)

    end
end


-- "scene:hide()"
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    -- Samme grunn som i gotoretry.lua: composer.removeScene() på seg
    -- selv må skje i "did", ikke "will", ellers korrumperes Composer sin
    -- interne overgangstilstand.
    if ( phase == "will" ) then
print ("gotonextlevel scene:hide will")
    elseif ( phase == "did" ) then
       composer.removeScene( "scenes.gotonextlevel" )
print ("gotonextlevel scene:hide did")


    end
end


-- "scene:destroy()"
function scene:destroy( event )

    local sceneGroup = self.view
    print ("gotonextlevel scene:destroy did")

end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene
