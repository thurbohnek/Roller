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
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
-- local function reload( )
    
--    composer.gotoScene( "scenes.chooselevel",{effect = "fade" , time = 3000}) 
-- end
 
 
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
local function goto( event )
    --last:play()
	local ok, err = pcall( composer.gotoScene, "scenes.banevalg", {effect = "fade" , time = 500} )
	if not ok then
		local msg = "Checkpoint: " .. tostring(_G.LAST_CHECKPOINT) .. "\n" .. tostring(err)
		print( "CRASH going to chooselevel: " .. msg )
		local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth - 20, display.contentHeight - 20 )
		bg:setFillColor( 0, 0, 0, 0.85 )
		local t = display.newText( { text = msg, x = display.contentCenterX, y = display.contentCenterY, width = display.contentWidth - 40, font = native.systemFont, fontSize = 14, align = "left" } )
		t:setFillColor( 1, 0.3, 0.3 )
	end
end

function scene:create( event )

    local sceneGroup = self.view
   print ("gotochooselevel scene:create did")

 --local abc display.newImage( "loading.png",1920,1080 )


grp=sceneGroup



    -- Lasteskjerm i ny stil (2026-10-28, lib/lasting.lua).
    require( "lib.lasting" ).vis( sceneGroup )



end


-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        print ("gotochooselevel scene:show will")
    elseif ( phase == "did" ) then
        print ("gotochooselevel scene:show did")
--composer.removeScene( "scenes.level1" )
timer.performWithDelay( 1500, goto)

    end
end


-- "scene:hide()"
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    -- VIKTIG: composer.removeScene() på seg selv må skje i "did"-fasen,
    -- ikke "will", se samme forklaring i gotolevel1.lua sin scene:hide.
    if ( phase == "will" ) then
print ("gotochooselevel scene:hide will")
    elseif ( phase == "did" ) then
       composer.removeScene( "scenes.gotochooselevel" )
print ("gotochooselevel scene:hide did")


    end
end


-- "scene:destroy()"
function scene:destroy( event )

    local sceneGroup = self.view
    print ("gotochooselevel scene:destroy did")
 
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene