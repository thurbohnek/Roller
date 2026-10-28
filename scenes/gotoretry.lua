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
-- Ny fil, 2026-09-10. Samme mønster som gotolevel1.lua (splash-scene som
-- venter litt og bytter videre), men for "retry på gjeldende bane" i
-- stedet for "ingen liv igjen, start på nytt fra bane 1".
--
-- Retry kalte tidligere composer.removeScene() rett fra pausemeny/
-- dødsmeny sin egen resume(), altså mens den banen som skulle rives ned
-- FORTSATT var den aktive scenen med akkurat den menyen som overlay oppå
-- seg. Det krasjet fortsatt (uhåndtert "attempt to compare nil with
-- number" fra selve motoren), selv etter at hideOverlay() ble lagt inn
-- rett før removeScene() som forsøk på å rekkefølge dette riktig.
--
-- Denne scenen unngår hele problemet ved å gjøre det samme trikset som
-- gotolevel1.lua allerede gjorde trygt: pausemeny/dødsmeny sin resume()
-- gjør nå bare en vanlig gotoScene() hit (som Composer selv skjuler
-- overlayen for, dokumentert trygt), og FØRST når denne splashen faktisk
-- er den aktive scenen (ingen overlay oppå, banen som skal restartes er
-- nå bare skjult i minnet, ikke aktiv), rives den ned og lastes på nytt.
-- -----------------------------------------------------------------------------------
local function goto( event )
	local destination = "scenes.level" .. tostring(lm.currentLevel)
	-- Trygt her: destination er ikke lenger den aktive scenen (denne
	-- splashen er), og har ingen overlay oppå seg. Fortsatt nødvendig for
	-- at gotoScene til samme scenenavn faktisk skal kjøre scene:create på
	-- nytt, se samme forklaring i dodmenu1.lua/pausemenu1.lua sin resume().
	composer.removeScene( destination )
	local ok, err = pcall( composer.gotoScene, destination, {effect = "fade" , time = 500} )
	if not ok then
		local msg = "Checkpoint: " .. tostring(_G.LAST_CHECKPOINT) .. "\n" .. tostring(err)
		print( "CRASH going to " .. tostring(destination) .. " (gotoretry): " .. msg )
		local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth - 20, display.contentHeight - 20 )
		bg:setFillColor( 0, 0, 0, 0.85 )
		local t = display.newText( { text = msg, x = display.contentCenterX, y = display.contentCenterY, width = display.contentWidth - 40, font = native.systemFont, fontSize = 14, align = "left" } )
		t:setFillColor( 1, 0.3, 0.3 )
	end
end

function scene:create( event )

    local sceneGroup = self.view
   print ("gotoretry scene:create did")

grp=sceneGroup



    -- Lasteskjerm i ny stil (2026-10-28, lib/lasting.lua).
    require( "lib.lasting" ).vis( sceneGroup )



end


-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        print ("gotoretry scene:show will")
    elseif ( phase == "did" ) then
        print ("gotoretry scene:show did")

timer.performWithDelay( 800, goto)

    end
end


-- "scene:hide()"
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    -- Samme grunn som i gotolevel1.lua: composer.removeScene() på seg
    -- selv må skje i "did", ikke "will", ellers korrumperes Composer sin
    -- interne overgangstilstand.
    if ( phase == "will" ) then
print ("gotoretry scene:hide will")
    elseif ( phase == "did" ) then
       composer.removeScene( "scenes.gotoretry" )
print ("gotoretry scene:hide did")


    end
end


-- "scene:destroy()"
function scene:destroy( event )

    local sceneGroup = self.view
    print ("gotoretry scene:destroy did")

end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene
