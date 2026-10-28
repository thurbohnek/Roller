display.setStatusBar( display.HiddenStatusBar )

-- Temporary debugging aid: records the last reached checkpoint so a crash
-- overlay can show roughly where things broke, since Solar2D's HTML5
-- command-line builder doesn't support keeping real file/line info in
-- error messages. Safe no-op call, remove once debugging is done.
_G.LAST_CHECKPOINT = "app_start"
function checkpoint( name )
	_G.LAST_CHECKPOINT = name
end

local composer = require( "composer" )

 
require "ssk2.loadSSK"
_G.ssk.init( { html5 = true } )
if system.getInfo( "platformName" ) ~= "HTML5" then
	aaa = ssk.meters.create_fps(  true )
	bbb = ssk.meters.create_mem( true )
end

-- Går via hovedmenyen igjen fra 2026-09-15, matcher Ørjans nyere
-- versjon av spillet. Gikk tidligere rett til bane 1
-- (composer.gotoScene("scenes.gotolevel1")), som hoppet over
-- menu.lua helt. menu.lua sin "storyknapp" leder videre til
-- scenes.chooselevel (banevalg) når den trykkes.
-- Lyd av/på fra Settings-skjermen, lagret mellom hver gang spillet startes.
require( "lib.innstillinger" ).brukLyd()

composer.gotoScene( "scenes.gotomenu" )
-- Varsel nede i hjørnet når en ny versjon er publisert (lib/oppdatering.lua).
require( "lib.oppdatering" ).start()

 


local function myUnhandledErrorListener( event )

    local iHandledTheError = true

    if iHandledTheError then
        print( "Handling the unhandled error", event.errorMessage )
    else
        print( "Not handling the unhandled error", event.errorMessage )
    end
    
    return iHandledTheError
end

Runtime:addEventListener("unhandledError", myUnhandledErrorListener)


local function touched(event)
	
	if event.phase == "began"  then
		

		collectgarbage()
		
		print( "MemUsage (in KB): " .. collectgarbage("count") )
		
		system.getInfo( "textureMemoryUsed" )
		
		print( "textureMemoryUsed is " .. system.getInfo( "textureMemoryUsed" )/1000  )
		
	end
end



Runtime : addEventListener( "touch", touched )


