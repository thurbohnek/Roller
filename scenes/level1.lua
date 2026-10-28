local composer = require( "composer" )

local scene = composer.newScene()

local widget = require ("widget")

widget.setTheme ( "widget_theme_ios")

local physics = require( "physics" )
--physics.setDrawMode( "hybrid" )
local perspective = require ("lib.perspective")

local scaleFactor = 1.0
local physicsData = (require "lib.shapedefs").physicsData(scaleFactor)
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenLeft = display.screenOriginX
local screenWidth = display.viewableContentWidth - screenLeft * 2
local screenRight = screenLeft + screenWidth
local screenTop = display.screenOriginY
local screenHeight = display.viewableContentHeight - screenTop * 2
local screenBottom = screenTop + screenHeight

local bredde = display.contentWidth

local hoyde = display.contentHeight
local lm = require("lib.ogt_levelmanager")
local liv =require("lib.liv")
local mark =require("lib.mark")

-- Forhåndsdeklarert her (fil-scope) i stedet for utilsiktet global,
-- gjort 2026-09-10. Trengs synlig for BÅDE scene:create (der den
-- defineres) og scene:hide (der touch-lytteren fjernes igjen) siden de
-- er to separate funksjoner i denne fila, ikke nestet i hverandre.
local trykk_knapp
-- Samme grunn, funnet 2026-09-15: goSomewhere/goto/goto1/goto2 over
-- ligger på fil-nivå (kjøres kun én gang når modulen lastes), mens
-- onCollision/onCollision1 ble deklarert med "local function" inni
-- scene:create. De referansene til onCollision/onCollision1 i
-- goto/goto1/goto2 sine Runtime:removeEventListener()-kall pekte
-- dermed på en udefinert GLOBAL (alltid nil), ikke den faktiske
-- lytteren, så disse fjernet ingenting - lytterne lekket for hver
-- gang banen ble forlatt (pause/død/fullført), presis det Solar2D sin
-- egen dokumentasjon advarer mot (se "Kjente feil" i KODEBASE.md).
-- Forhåndsdeklarert her av samme grunn som trykk_knapp: begge stedene
-- refererer nå samme fil-scopede local.
-- knekk også (2026-09-28): den var "local function" inni scene:create,
-- så scene:hide og goto2 fjernet en udefinert global. Lytteren ble
-- stående etter at banen var ferdig og kjørte når den gamle marken
-- ble revet ned, og flyttet kameraet til neste bane over på den.
local onCollision, onCollision1, knekk
-- Lagt til 2026-09-15: forhåndsdeklarert av samme grunn som de over,
-- slik at både goto() og scene:hide kan fjerne enterFrame-lytteren
-- igjen. Se der den settes opp (nederst i scene:create) for hvorfor
-- den finnes.
local sjekkUtenforBanen


-- -----------------------------------------------------------------------------------------------------------------






        local function goSomewhere (event)
        camera:destroy()
        camera                               =nil
        Runtime:removeEventListener("collision", onCollision)
        Runtime:removeEventListener("collision", onCollision1)
        Runtime:removeEventListener( "touch", trykk_knapp)
        Runtime:removeEventListener( "tap", trykk_knapp)
        local goto                           = event.target.id
        local options                        = {effect = "fade" , time = 500}
        composer.gotoScene( goto, options )
        end
        
-- -----------------------------------------------------------------------------------------------------------------


        local function goto( event )
        print( "0" )
        physics.pause( )
        Runtime:removeEventListener("collision", onCollision)
        Runtime:removeEventListener("collision", onCollision1)
        -- Slår av utenfor-banen-sjekken her også, ellers kan den rekke å
        -- kalle goto() en gang til rett etter at dod-sonen allerede har
        -- gjort det (marken er som regel utenfor banen i begge tilfeller).
        Runtime:removeEventListener( "enterFrame", sjekkUtenforBanen )
        composer.showOverlay( "scenes.dodmenu1",{isModal = true,effect = "fade",time = 1500,})
        end



-- -----------------------------------------------------------------------------------------------------------------


        local function goto1( event )
        --grp:remove(camera)
        physics.pause( )
        Runtime:removeEventListener("collision", onCollision)
        Runtime:removeEventListener("collision", onCollision1)
        --Runtime:removeEventListener( "touch", trykk_knapp)
        --Runtime:removeEventListener( "tap", trykk_knapp)
        --knapp1.alpha = 0
        composer.showOverlay( "scenes.pausemenu1",{isModal = true,effect = "fade",time = 500,})
        end

-- -----------------------------------------------------------------------------------------------------------------

        local function goto2( event )
        --grp:remove(camera)
        physics.pause( )
        -- Lagt til 2026-09-16: maa fjernes her ogsaa. goto2 bruker
        -- showOverlay(), saa scene:hide kjorer aldri paa denne banen, og
        -- uten dette blir "falt ut av banen"-sjekken staaende og gaa
        -- etter at maalet er naadd. Den kunne da utlose doden midt i
        -- fullfort-overgangen.
        Runtime:removeEventListener( "enterFrame", sjekkUtenforBanen )
        Runtime:removeEventListener("collision", onCollision)
        Runtime:removeEventListener("collision", onCollision1)
        Runtime:removeEventListener("collision", knekk)
        --Runtime:removeEventListener( "touch", trykk_knapp)
        --Runtime:removeEventListener( "tap", trykk_knapp)
        --knapp1.alpha = 0
        -- Endret 2026-09-15: gikk før alltid til banevalget
        -- ("gotochooselevel"), går nå automatisk videre til neste bane
        -- via "gotonextlevel" (som selv faller tilbake til banevalget
        -- om dette var siste bane), se scenes/gotonextlevel.lua.
        composer.showOverlay( "scenes.fullfort",{isModal = true,effect = "fade",time = 500,})
        end

-- -----------------------------------------------------------------------------------------------------------------


      


        

-- Denne banens eget kamera. camera er global (_G.camera), og når
-- spillet går rett videre til neste bane, lager neste bane sitt kamera
-- FØR denne banens scene:hide kjører. Da ødela hide kameraet til den
-- nye banen, og den krasjet med "attempt to compare nil with number"
-- (funnet 2026-09-27, bane 8 -> 9).
local egetKamera

function scene:create( event )
checkpoint("level1:create_start")
lm.currentLevel = 1 -- så retry vet hvilken bane den skal restarte


    local sceneGroup = self.view
    print ("level1 scene:create did")
    
      ------aktiver for å kunne se hele brettet. Også aktiver local scaleFactor = 0.025-----
   -- grp = display.newGroup( )
    --
   -- local scaleFactor = 1
    
    -- Bevisst global (2026-09-10, markert eksplisitt per Solar2D sin
    -- egen anbefaling): lib/liv.lua sin liv.hent() skriver til denne
    -- gruppa direkte og har ingen annen måte å nå den på.
    _G.camera = perspective.createView()
    egetKamera = camera
    physics.start( )
    --physics.pause( )
    --physics.setGravity(0 , 9.81 )
    --physics.setGravity(0 , 0 )
    physics.setContinuous( true )
    liv.lastliv()
local mark = mark.hent 
    local justerside   = 1705
    local justeroppned = 1044


    --local scaleFactor = 0.025
    --local scaleFactor = 0.050
    --local scaleFactor = 0.1
    local scaleFactor = 0.6
     -- Bevisst global, se forklaring ved _G.camera over.
     _G.grp=sceneGroup
    camera.xScale = scaleFactor
    camera.yScale = scaleFactor




          local dod = display.newRect (0, 0, 70000, 50) 
          dod.x = bredde -bredde-bredde-900
          dod.y = hoyde
          dod:rotate( 31.48 ) 
          dod.myName = "dod"
          grp:insert( dod ) 
          dod.alpha = 1
          camera:add (dod,1,false)
          physics.addBody(dod, "kinematic", {isSensor = true})
          
          
         
          
          
          local mal2 = display.newRect( 0, 0, 10, 3000 )
          --mal2:setReferencePoint( display.BottomLeftReferencePoint )
          mal2.x = 31000
          mal2.y = 18000
          mal2.myName = "mal2"
          mal2:rotate(45)
          grp:insert ( mal2 )
          mal2.alpha = 0
          camera:add (mal2,1,false)
          physics.addBody(mal2, "kinematic", {isSensor = true})


 

    local knapp1 = display.newImageRect( "pauseknapp.png", 75, 75 )
    knapp1.x = bredde+bredde-((knapp1.width*2)*1.6)
    knapp1.y = hoyde - hoyde + (knapp1.height*2)
    knapp1.alpha = 1
    grp:insert(knapp1)
    -- Ny plass i skjermbildet under spill (2026-10-28, lib/hud.lua).
    require( "lib.hud" ).pauseKnapp( knapp1 )
   

    local hent = liv.hent 
liv.hent()
timer.performWithDelay(3000, hent, 1)

--game.load()
--print("Current Score: ", game.returnScore())






    local background = display.newImageRect( "background/1dirt1.png", 1920*40, 1080*5 )
    background.anchorX = 0.5
    background.anchorY = 0.5
    background.x = bredde-bredde-bredde
    background.y = background.height-background.height
    background:rotate( 31.48 )
    background.alpha = 1


    local background1 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background1.anchorX = 1
    background1.anchorY = 0.5
    background1.x = bredde-bredde
    background1.y = hoyde-hoyde-hoyde*0.67
    background1.rotation = 31.48 
    background1.alpha = 1

    local background2 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background2.anchorX = 1
    background2.anchorY = 0.5
    background2.x = background1.x+ justerside  
    background2.y = background1.y+   justeroppned
    background2:rotate( background1.rotation )
    background2.alpha = 1

    local background3 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background3.anchorX = 1
    background3.anchorY = 0.5
    background3.x = background2.x+ justerside
    background3.y = background2.y+   justeroppned
    background3:rotate( background1.rotation )
    background3.alpha = 1

    local background4 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background4.anchorX = 1
    background4.anchorY = 0.5
    background4.x = background3.x+ justerside
    background4.y = background3.y+   justeroppned
    background4:rotate( background1.rotation )
    background4.alpha = 1

    local background5 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background5.anchorX = 1
    background5.anchorY = 0.5
    background5.x = background4.x+ justerside
    background5.y = background4.y+   justeroppned
    background5:rotate( background1.rotation )
    background5.alpha = 1

    local background6 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background6.anchorX = 1
    background6.anchorY = 0.5
    background6.x = background5.x+ justerside
    background6.y = background5.y+   justeroppned
    background6:rotate( background1.rotation )
    background6.alpha = 1

    local background7 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background7.anchorX = 1
    background7.anchorY = 0.5
    background7.x = background6.x+ justerside
    background7.y = background6.y+   justeroppned
    background7:rotate( background1.rotation )
    background7.alpha = 1

    local background8 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background8.anchorX = 1
    background8.anchorY = 0.5
    background8.x = background7.x+ justerside
    background8.y = background7.y+   justeroppned
    background8:rotate( background1.rotation )
    background8.alpha = 1

    local background9 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background9.anchorX = 1
    background9.anchorY = 0.5
    background9.x = background8.x+ justerside
    background9.y = background8.y+   justeroppned
    background9:rotate( background1.rotation )
    background9.alpha = 1

    local background10 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background10.anchorX = 1
    background10.anchorY = 0.5
    background10.x = background9.x+ justerside
    background10.y = background9.y+   justeroppned
    background10:rotate( background1.rotation )
    background10.alpha = 1


    local background11 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background11.anchorX = 1
    background11.anchorY = 0.5
    background11.x = background10.x+ justerside
    background11.y = background10.y+   justeroppned
    background11:rotate( background1.rotation )
    background11.alpha = 1

    local background12 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background12.anchorX = 1
    background12.anchorY = 0.5
    background12.x = background11.x+ justerside
    background12.y = background11.y+   justeroppned
    background12:rotate( background1.rotation )
    background12.alpha = 1

    local background13 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background13.anchorX = 1
    background13.anchorY = 0.5
    background13.x = background12.x+ justerside
    background13.y = background12.y+   justeroppned
    background13:rotate( background1.rotation )
    background13.alpha = 1

    local background14 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background14.anchorX = 1
    background14.anchorY = 0.5
    background14.x = background13.x+ justerside
    background14.y = background13.y+   justeroppned
    background14:rotate( background1.rotation )
    background14.alpha = 1

    local background15 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background15.anchorX = 1
    background15.anchorY = 0.5
    background15.x = background14.x+ justerside
    background15.y = background14.y+   justeroppned
    background15:rotate( background1.rotation )
    background15.alpha = 1

    local background16 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background16.anchorX = 1
    background16.anchorY = 0.5
    background16.x = background15.x+ justerside
    background16.y = background15.y+   justeroppned
    background16:rotate( background1.rotation )
    background16.alpha = 1

    local background17 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background17.anchorX = 1
    background17.anchorY = 0.5
    background17.x = background16.x+ justerside
    background17.y = background16.y+   justeroppned
    background17:rotate( background1.rotation )
    background17.alpha = 1

    local background18 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background18.anchorX = 1
    background18.anchorY = 0.5
    background18.x = background17.x+ justerside
    background18.y = background17.y+   justeroppned
    background18:rotate( background1.rotation )
    background18.alpha = 1

    local background19 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background19.anchorX = 1
    background19.anchorY = 0.5
    background19.x = background18.x+ justerside
    background19.y = background18.y+   justeroppned
    background19:rotate( background1.rotation )
    background19.alpha = 1

    local background20 = display.newImageRect( "background/1back_cave.png", 2000, 6000 )
    background20.anchorX = 1
    background20.anchorY = 0.5
    background20.x = background19.x+ justerside
    background20.y = background19.y+   justeroppned
    background20:rotate( background1.rotation )
    background20.alpha = 1
   ------

    local background1a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background1a.anchorX = 1
    background1a.anchorY = 0.5
    background1a.x = bredde-bredde
    background1a.y = hoyde-hoyde-hoyde*0.67
    background1a.rotation = 31.48 
    background1a.alpha = 1

    local background2a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background2a.anchorX = 1
    background2a.anchorY = 0.5
    background2a.x = background1a.x+ justerside  
    background2a.y = background1a.y+   justeroppned
    background2a:rotate( background1.rotation )
    background2a.alpha = 1

    local background3a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background3a.anchorX = 1
    background3a.anchorY = 0.5
    background3a.x = background2a.x+ justerside
    background3a.y = background2a.y+   justeroppned
    background3a:rotate( background1.rotation )
    background3a.alpha = 1

    local background4a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background4a.anchorX = 1
    background4a.anchorY = 0.5
    background4a.x = background3a.x+ justerside
    background4a.y = background3a.y+   justeroppned
    background4a:rotate( background1.rotation )
    background4a.alpha = 1

    local background5a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background5a.anchorX = 1
    background5a.anchorY = 0.5
    background5a.x = background4a.x+ justerside
    background5a.y = background4a.y+   justeroppned
    background5a:rotate( background1.rotation )
    background5a.alpha = 1

    local background6a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background6a.anchorX = 1
    background6a.anchorY = 0.5
    background6a.x = background5a.x+ justerside
    background6a.y = background5a.y+   justeroppned
    background6a:rotate( background1.rotation )
    background6a.alpha = 1

    local background7a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background7a.anchorX = 1
    background7a.anchorY = 0.5
    background7a.x = background6a.x+ justerside
    background7a.y = background6a.y+   justeroppned
    background7a:rotate( background1.rotation )
    background7a.alpha = 1

    local background8a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background8a.anchorX = 1
    background8a.anchorY = 0.5
    background8a.x = background7a.x+ justerside
    background8a.y = background7a.y+   justeroppned
    background8a:rotate( background1.rotation )
    background8a.alpha = 1

    local background9a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background9a.anchorX = 1
    background9a.anchorY = 0.5
    background9a.x = background8a.x+ justerside
    background9a.y = background8a.y+   justeroppned
    background9a:rotate( background1.rotation )
    background9a.alpha = 1

    local background10a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background10a.anchorX = 1
    background10a.anchorY = 0.5
    background10a.x = background9a.x+ justerside
    background10a.y = background9a.y+   justeroppned
    background10a:rotate( background1.rotation )
    background10a.alpha = 1


    local background11a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background11a.anchorX = 1
    background11a.anchorY = 0.5
    background11a.x = background10a.x+ justerside
    background11a.y = background10a.y+   justeroppned
    background11a:rotate( background1.rotation )
    background11a.alpha = 1

    local background12a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background12a.anchorX = 1
    background12a.anchorY = 0.5
    background12a.x = background11a.x+ justerside
    background12a.y = background11a.y+   justeroppned
    background12a:rotate( background1.rotation )
    background12a.alpha = 1

    local background13a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background13a.anchorX = 1
    background13a.anchorY = 0.5
    background13a.x = background12a.x+ justerside
    background13a.y = background12a.y+   justeroppned
    background13a:rotate( background1.rotation )
    background13a.alpha = 1

    local background14a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background14a.anchorX = 1
    background14a.anchorY = 0.5
    background14a.x = background13a.x+ justerside
    background14a.y = background13a.y+   justeroppned
    background14a:rotate( background1.rotation )
    background14a.alpha = 1

    local background15a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background15a.anchorX = 1
    background15a.anchorY = 0.5
    background15a.x = background14a.x+ justerside
    background15a.y = background14a.y+   justeroppned
    background15a:rotate( background1.rotation )
    background15a.alpha = 1

    local background16a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background16a.anchorX = 1
    background16a.anchorY = 0.5
    background16a.x = background15a.x+ justerside
    background16a.y = background15a.y+   justeroppned
    background16a:rotate( background1.rotation )
    background16a.alpha = 1

    local background17a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background17a.anchorX = 1
    background17a.anchorY = 0.5
    background17a.x = background16a.x+ justerside
    background17a.y = background16a.y+   justeroppned
    background17a:rotate( background1.rotation )
    background17a.alpha = 1

    local background18a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background18a.anchorX = 1
    background18a.anchorY = 0.5
    background18a.x = background17a.x+ justerside
    background18a.y = background17a.y+   justeroppned
    background18a:rotate( background1.rotation )
    background18a.alpha = 1

    local background19a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background19a.anchorX = 1
    background19a.anchorY = 0.5
    background19a.x = background18a.x+ justerside
    background19a.y = background18a.y+   justeroppned
    background19a:rotate( background1.rotation )
    background19a.alpha = 1

    local background20a = display.newImageRect( "background/1back_cave1.png", 2000, 6000 )
    background20a.anchorX = 1
    background20a.anchorY = 0.5
    background20a.x = background19a.x+ justerside
    background20a.y = background19a.y+   justeroppned
    background20a:rotate( background1.rotation )
    background20a.alpha = 1

    -------

    local background1b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background1b.anchorX = 1
    background1b.anchorY = 0.5
    background1b.x = bredde-bredde
    background1b.y = hoyde-hoyde-hoyde*0.67
    background1b.rotation = 31.48 
    background1b.alpha = 1

    local background2b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background2b.anchorX = 1
    background2b.anchorY = 0.5
    background2b.x = background1b.x+ justerside  
    background2b.y = background1b.y+   justeroppned
    background2b:rotate( background1.rotation )
    background2b.alpha = 1

    local background3b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background3b.anchorX = 1
    background3b.anchorY = 0.5
    background3b.x = background2b.x+ justerside
    background3b.y = background2b.y+   justeroppned
    background3b:rotate( background1.rotation )
    background3b.alpha = 1

    local background4b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background4b.anchorX = 1
    background4b.anchorY = 0.5
    background4b.x = background3b.x+ justerside
    background4b.y = background3b.y+   justeroppned
    background4b:rotate( background1.rotation )
    background4b.alpha = 1

    local background5b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background5b.anchorX = 1
    background5b.anchorY = 0.5
    background5b.x = background4b.x+ justerside
    background5b.y = background4b.y+   justeroppned
    background5b:rotate( background1.rotation )
    background5b.alpha = 1

    local background6b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background6b.anchorX = 1
    background6b.anchorY = 0.5
    background6b.x = background5b.x+ justerside
    background6b.y = background5b.y+   justeroppned
    background6b:rotate( background1.rotation )
    background6b.alpha = 1

    local background7b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background7b.anchorX = 1
    background7b.anchorY = 0.5
    background7b.x = background6b.x+ justerside
    background7b.y = background6b.y+   justeroppned
    background7b:rotate( background1.rotation )
    background7b.alpha = 1

    local background8b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background8b.anchorX = 1
    background8b.anchorY = 0.5
    background8b.x = background7b.x+ justerside
    background8b.y = background7b.y+   justeroppned
    background8b:rotate( background1.rotation )
    background8b.alpha = 1

    local background9b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background9b.anchorX = 1
    background9b.anchorY = 0.5
    background9b.x = background8b.x+ justerside
    background9b.y = background8b.y+   justeroppned
    background9b:rotate( background1.rotation )
    background9b.alpha = 1

    local background10b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background10b.anchorX = 1
    background10b.anchorY = 0.5
    background10b.x = background9b.x+ justerside
    background10b.y = background9b.y+   justeroppned
    background10b:rotate( background1.rotation )
    background10b.alpha = 1


    local background11b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background11b.anchorX = 1
    background11b.anchorY = 0.5
    background11b.x = background10b.x+ justerside
    background11b.y = background10b.y+   justeroppned
    background11b:rotate( background1.rotation )
    background11b.alpha = 1

    local background12b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background12b.anchorX = 1
    background12b.anchorY = 0.5
    background12b.x = background11b.x+ justerside
    background12b.y = background11b.y+   justeroppned
    background12b:rotate( background1.rotation )
    background12b.alpha = 1

    local background13b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background13b.anchorX = 1
    background13b.anchorY = 0.5
    background13b.x = background12b.x+ justerside
    background13b.y = background12b.y+   justeroppned
    background13b:rotate( background1.rotation )
    background13b.alpha = 1

    local background14b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background14b.anchorX = 1
    background14b.anchorY = 0.5
    background14b.x = background13b.x+ justerside
    background14b.y = background13b.y+   justeroppned
    background14b:rotate( background1.rotation )
    background14b.alpha = 1

    local background15b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background15b.anchorX = 1
    background15b.anchorY = 0.5
    background15b.x = background14b.x+ justerside
    background15b.y = background14b.y+   justeroppned
    background15b:rotate( background1.rotation )
    background15b.alpha = 1

    local background16b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background16b.anchorX = 1
    background16b.anchorY = 0.5
    background16b.x = background15b.x+ justerside
    background16b.y = background15b.y+   justeroppned
    background16b:rotate( background1.rotation )
    background16b.alpha = 1

    local background17b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background17b.anchorX = 1
    background17b.anchorY = 0.5
    background17b.x = background16b.x+ justerside
    background17b.y = background16b.y+   justeroppned
    background17b:rotate( background1.rotation )
    background17b.alpha = 1

    local background18b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background18b.anchorX = 1
    background18b.anchorY = 0.5
    background18b.x = background17b.x+ justerside
    background18b.y = background17b.y+   justeroppned
    background18b:rotate( background1.rotation )
    background18b.alpha = 1

    local background19b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background19b.anchorX = 1
    background19b.anchorY = 0.5
    background19b.x = background18b.x+ justerside
    background19b.y = background18b.y+   justeroppned
    background19b:rotate( background1.rotation )
    background19b.alpha = 1

    local background20b = display.newImageRect( "background/1back_cave2.png", 2000, 6000 )
    background20b.anchorX = 1
    background20b.anchorY = 0.5
    background20b.x = background19b.x+ justerside
    background20b.y = background19b.y+   justeroppned
    background20b:rotate( background1.rotation )
    background20b.alpha = 1




 





------------------------------------------------------------------------
checkpoint("level1:cp_684_after_backgrounds")

    

    local del1 = display.newImageRect( "hale.png", 55, 35 )

    del1.x=0
    del1.y=0
    --del1.x=15200
    --del1.y=8500
    --del1.x=29600
    --del1.y=17000
    del1.width = 27
    del1.height = 17
    -- Bruker en egen, håndskrevet kollisjonsform i stedet for
    -- shapedefs.lua sin ferdige "hale"-form (sjekket 2026-09-10, spurt
    -- av Ørjan). Grunn: bildet krympes til 27x17 rett over, men
    -- shapedefs.lua sin "hale"-form er sporet fra bildet i original
    -- (ukrympet, ca 55x35) størrelse. Denne formen her stemmer med den
    -- krympede visningsstørrelsen, "hale"-formen ville vært dobbelt så
    -- stor. Ikke byttet ut, venter på om Ørjan finner en nyere versjon
    -- av marken (skal knekke i 3 biter, ikke de 9 leddene her).
    local del1Shape = {-13,8, -13,-8, 11,3, 14,0, 11,-3}
    physics.addBody(del1, "dynamic",  {density = 1.0, friction = 0.3, bounce = 0.2, shape=del1Shape})
      del1.alpha = 1
    grp:insert(del1)

     local del2 = display.newImageRect( "del1.png", 34, 17 )
    del2.x= del1.x-27
    del2.y=del1.y
    del2.rotation = (0)
    physics.addBody(del2,"dynamic", physicsData:get("del1") )
    grp:insert(del2)

     local del3 = display.newImageRect( "del1.png", 34, 17 )
    del3.x= del1.x-54
    del3.y=del1.y
    del3.rotation = (0)
    physics.addBody(del3,"dynamic", physicsData:get("del1") )
    grp:insert(del3)

     local del4 = display.newImageRect( "del1.png", 34, 17 )
    del4.x= del1.x-81
    del4.y=del1.y
    del4.rotation = (0)
    del4.isSensor = true
    del4.myName = "del4"
    

    physics.addBody(del4,"dynamic", physicsData:get("del1") )
    grp:insert(del4)

     local del5 = display.newImageRect( "del1.png", 34, 17 )
    del5.x= del1.x-108
    del5.y=del1.y
    del5.rotation = (0)
    physics.addBody(del5,"dynamic", physicsData:get("del1") )
    grp:insert(del5)

    local  del6 = display.newImageRect( "del1.png", 34, 17 )
    del6.x= del1.x-135
    del6.y=del1.y
    del6.rotation = (0)
    physics.addBody(del6,"dynamic", physicsData:get("del1") )
    grp:insert(del6)

     local del7 = display.newImageRect( "del1.png", 34, 17 )
    del7.x= del1.x-162
    del7.y=del1.y
    del7.rotation = (0)
    physics.addBody(del7,"dynamic", physicsData:get("del1") )
    grp:insert(del7)

     local del8 = display.newImageRect( "del1.png", 34, 17 )
    del8.x= del1.x-189
    del8.y=del1.y
    del8.rotation = (0)
    physics.addBody(del8,"dynamic", physicsData:get("del1") )
    grp:insert(del8)

     local del9 = display.newImageRect( "hode.png", 30,25)
    del9.x=del1.x-217
    del9.y=del1.y+2
    del9.rotation = (0)
    local del9Shape = {-15,-5, -12,-10, -10,-10, 0,-9, 14,-11 ,0,-11, 14,6, -12,4}
    physics.addBody(del9, "dynamic",  {density = 1.0, friction = 1.3, bounce = 0.2,shape=del9Shape})
    del9.myName = "del9"
    grp:insert(del9)

    local punkt = display.newRect( 200, 200, 10, 10 )
    punkt.x = del5.x
    punkt.y = del5.y-40
    punkt.alpha = 0
    punktsant   = true
    physics.addBody( punkt,"dynamic")
    punkt.isSensor = true
    grp:insert(punkt)


    local pivot_joint  = physics.newJoint( "pivot", del1, del2, del1.x-14, del1.y )
    local pivot_joint1 = physics.newJoint( "pivot", del2, del3, del2.x-14, del2.y )
    local pivot_joint2 = physics.newJoint( "pivot", del3, del4, del3.x-14, del3.y )
    local pivot_joint3 = physics.newJoint( "pivot", del4, del5, del4.x-14, del4.y )
    local pivot_joint4 = physics.newJoint( "pivot", del5, del6, del5.x-14, del5.y )
    local pivot_joint5 = physics.newJoint( "pivot", del6, del7, del6.x-14, del6.y )
    local pivot_joint6 = physics.newJoint( "pivot", del7, del8, del7.x-14, del7.y )
    local pivot_joint7 = physics.newJoint( "pivot", del8, del9, del8.x-14, del8.y )
    local pivot_joint8 = physics.newJoint( "weld", punkt, del5, punkt.x+108, del4.y+10 )



    pivot_joint.isMotorEnabled = true
    pivot_joint.motorSpeed =30
    pivot_joint.maxMotorTorque = 500
    pivot_joint.isLimitEnabled=true
    pivot_joint:setRotationLimits( 0, 38 )
    pivot_joint.isCollideConnected = true

    pivot_joint1.isMotorEnabled = true
    pivot_joint1.motorSpeed =pivot_joint.motorSpeed
    pivot_joint1.maxMotorTorque = pivot_joint.maxMotorTorque
    pivot_joint1.isLimitEnabled=true
    pivot_joint1:setRotationLimits( 0, 38 )
    pivot_joint1.isCollideConnected = pivot_joint.isCollideConnected

    pivot_joint2.isMotorEnabled = true
    pivot_joint2.motorSpeed =pivot_joint.motorSpeed
    pivot_joint2.maxMotorTorque = pivot_joint.maxMotorTorque
    pivot_joint2.isLimitEnabled=true
    pivot_joint2:setRotationLimits( 0, 38 )
    pivot_joint2.isCollideConnected = pivot_joint.isCollideConnected

    pivot_joint3.isMotorEnabled = true
    pivot_joint3.motorSpeed =pivot_joint.motorSpeed
    pivot_joint3.maxMotorTorque = pivot_joint.maxMotorTorque
    pivot_joint3.isLimitEnabled=true
    pivot_joint3:setRotationLimits( 0, 38 )
    pivot_joint3.isCollideConnected = pivot_joint.isCollideConnected

    pivot_joint4.isMotorEnabled = true
    pivot_joint4.motorSpeed =pivot_joint.motorSpeed
    pivot_joint4.maxMotorTorque = pivot_joint.maxMotorTorque
    pivot_joint4.isLimitEnabled=true
    pivot_joint4:setRotationLimits( 0, 38 )
    pivot_joint4.isCollideConnected = pivot_joint.isCollideConnected

    pivot_joint5.isMotorEnabled = true
    pivot_joint5.motorSpeed =pivot_joint.motorSpeed
    pivot_joint5.maxMotorTorque = pivot_joint.maxMotorTorque
    pivot_joint5.isLimitEnabled=true
    pivot_joint5:setRotationLimits( 0, 38 )
    pivot_joint5.isCollideConnected = pivot_joint.isCollideConnected

    pivot_joint6.isMotorEnabled = true
    pivot_joint6.motorSpeed =pivot_joint.motorSpeed
    pivot_joint6.maxMotorTorque = pivot_joint.maxMotorTorque
    pivot_joint6.isLimitEnabled=true
    pivot_joint6:setRotationLimits( 0, 38 )
    pivot_joint6.isCollideConnected = pivot_joint.isCollideConnected

    pivot_joint7.isMotorEnabled = true
    pivot_joint7.motorSpeed =pivot_joint.motorSpeed
    pivot_joint7.maxMotorTorque = pivot_joint.maxMotorTorque
    pivot_joint7.isLimitEnabled=true
    pivot_joint7:setRotationLimits( 0, 38 )
    pivot_joint7.isCollideConnected = pivot_joint.isCollideConnected


    pivot_joint8.isMotorEnabled = false
    pivot_joint8.motorSpeed = 0
    pivot_joint8.maxMotorTorque = 0
    pivot_joint8.isLimitEnabled=false
    --pivot_joint8:setRotationLimits( 0, 38 )
    pivot_joint8.isCollideConnected = true

-- Lagt til 2026-09-10: level1.lua manglet hele knott/weldJoint-blokken
-- som level2.lua-level9.lua har (verifisert identisk der, kopiert
-- derfra uendret). Uten disse fantes det ingen fysikkobjekter som
-- faktisk kunne utløse knekk(event) sin kollisjonssjekk, uansett om
-- Runtime-lytteren var skrudd på eller ikke. Se TIL-ORJAN.md.
local knott1 = display.newRect( 10,10,10,10 )
knott1.x = del1.x
knott1.y = del1.y+5
camera:add(knott1,1,false)
physics.addBody( knott1, "dynamic",{density = 0.0, friction = 0.0, bounce = 0.0})
knott1.isSensor = true
knott1.alpha = 0

local knott2 = display.newRect( 10,10,10,10 )
knott2.x = del2.x
knott2.y = del2.y+10
camera:add(knott2,1,false)
physics.addBody( knott2, "dynamic",{density = 0.0, friction = 0.0, bounce = 0.0})
knott2.isSensor = true
knott2.alpha = 0

local knott3 = display.newRect( 10,10,10,10 )
knott3.x = del3.x
knott3.y = del3.y+10
camera:add(knott3,1,false)
physics.addBody( knott3, "dynamic",{density = 0.0, friction = 0.0, bounce = 0.0})
knott3.isSensor = true
knott3.alpha = 0

local knott4 = display.newRect( 10,10,10,10 )
knott4.x = del4.x
knott4.y = del4.y+10
camera:add(knott4,1,false)
physics.addBody( knott4, "dynamic",{density = 0.0, friction = 0.0, bounce = 0.0})
knott4.isSensor = true
knott4.alpha = 0

local knott5 = display.newRect( 10,10,10,10 )
knott5.x = del5.x
knott5.y = del5.y+10
camera:add(knott5,1,false)
physics.addBody( knott5, "dynamic",{density = 0.0, friction = 0.0, bounce = 0.0})
knott5.isSensor = true
knott5.alpha = 0

local knott6 = display.newRect( 10,10,10,10 )
knott6.x = del6.x
knott6.y = del6.y+10
camera:add(knott6,1,false)
physics.addBody( knott6, "dynamic",{density = 0.0, friction = 0.0, bounce = 0.0})
knott6.isSensor = true
knott6.alpha = 0

local knott7 = display.newRect( 10,10,10,10 )
knott7.x = del7.x
knott7.y = del7.y+10
camera:add(knott7,1,false)
physics.addBody( knott7, "dynamic",{density = 0.0, friction = 0.0, bounce = 0.0})
knott7.isSensor = true
knott7.alpha = 0

local knott8 = display.newRect( 10,10,10,10 )
knott8.x = del8.x
knott8.y = del8.y+10
camera:add(knott8,1,false)
physics.addBody( knott8, "dynamic",{density = 0.0, friction = 0.0, bounce = 0.0})
knott8.isSensor = true
knott8.alpha = 0

local knott9 = display.newRect( 10,10,10,10 )
knott9.x = del9.x
knott9.y = del9.y+10
camera:add(knott9,1,false)
physics.addBody( knott9, "dynamic",{density = 0.0, friction = 0.0, bounce = 0.0})
knott9.isSensor = true
knott9.alpha = 0


local weldJoint1 = physics.newJoint( "weld", knott1, del1, knott1.x, knott1.x )
local weldJoint2 = physics.newJoint( "weld", knott2, del2, knott2.x, knott2.x )
local weldJoint3 = physics.newJoint( "weld", knott3, del3, knott3.x, knott3.x )
local weldJoint4 = physics.newJoint( "weld", knott4, del4, knott4.x, knott4.x )
local weldJoint5 = physics.newJoint( "weld", knott5, del5, knott5.x, knott5.x )
local weldJoint6 = physics.newJoint( "weld", knott6, del6, knott6.x, knott6.x )
local weldJoint7 = physics.newJoint( "weld", knott7, del7, knott7.x, knott7.x )
local weldJoint8 = physics.newJoint( "weld", knott8, del8, knott8.x, knott8.x )
local weldJoint9 = physics.newJoint( "weld", knott9, del9, knott9.x, knott9.x )










   

                                     
                                      local     firkant1 = display.newImageRect("level1/1.png", 7680,4702)
                                                firkant1.x = 3500
                                                --firkant1.x = 3850
                                                firkant1.y = 2300
                                                physics.addBody(firkant1,"static", physicsData:get("1") )
                                                firkant1.alpha = 1  
                                                firkant1.myName = "firkant1"                                
                                                
                                      local     firkant2 = display.newImageRect("level1/2.png", 7680,4702)
                                                firkant2.x = firkant1.x+firkant2.width
                                                firkant2.y = firkant1.y+firkant2.height
                                                physics.addBody(firkant2,"static", physicsData:get("2") )
                                                firkant2.myName = "firkant2"   
                                                
                                                 
                                      local     firkant3 = display.newImageRect("level1/3.png", 7680,4702)
                                                firkant3.x = firkant2.x+firkant3.width
                                                firkant3.y = firkant2.y+firkant3.height
                                                physics.addBody(firkant3,"static", physicsData:get("3") )
                                                firkant3.myName = "firkant3"   
                                                
                                                
                                      local     firkant4 = display.newImageRect("level1/4.png", 7680,4702)
                                                firkant4.x = firkant3.x+firkant4.width
                                                firkant4.y = firkant3.y+firkant4.height
                                                physics.addBody(firkant4,"static", physicsData:get("4") )
                                                firkant4.myName = "firkant4"   
                                                
                                                



 







mal2.type     = "mal2"
dod.type      = "dod"
del1.type     = "del1"
del2.type     = "del2"
del3.type     = "del3"
del4.type     = "del4"
del5.type     = "del5"
del6.type     = "del6"
del7.type     = "del7"
del8.type     = "del8"
del9.type     = "del9"

knott1.type   = "knott1"
knott2.type   = "knott2"
knott3.type   = "knott3"
knott4.type   = "knott4"
knott5.type   = "knott5"
knott6.type   = "knott6"
knott7.type   = "knott7"
knott8.type   = "knott8"
knott9.type   = "knott9"

firkant1.type = "firkant1"
firkant2.type = "firkant2"
firkant3.type = "firkant3"
firkant4.type = "firkant4"


------------------------------------------------------------------
checkpoint("level1:cp_1062_before_onCollision_def")
onCollision = function(event)
if event.phase == "began" then

if      event.object1 == dod and event.object2 == del1 then
    knapp1.alpha = 0
    --print( "dod og del1" )
elseif  event.object1 == dod and event.object2 == del2 then
    knapp1.alpha = 0
    --print( "dod og del2" )
elseif  event.object1 == dod and event.object2 == del3 then
    knapp1.alpha = 0
    --print( "dod og del3" )
elseif  event.object1 == dod and event.object2 == del4 then
    knapp1.alpha = 0
    --print( "dod og del4" )
elseif  event.object1 == dod and event.object2 == del5 then
    knapp1.alpha = 0
    --print( "dod og del5" )
elseif  event.object1 == dod and event.object2 == del6 then
    knapp1.alpha = 0
    --print( "dod og del6" )
elseif  event.object1 == dod and event.object2 == del7 then
    knapp1.alpha = 0
    --print( "dod og del7" )
elseif  event.object1 == dod and event.object2 == del8 then
    knapp1.alpha = 0
    --print( "dod og del8" )
elseif  event.object1 == dod and event.object2 == del9 then
    knapp1.alpha = 0
    --print( "dod og del9" )



      


            -- lm.resetLevels(dataFile)
goto()


end
end
end
Runtime:addEventListener("collision", onCollision)
------------------------------------------------------------------
checkpoint("level1:cp_1107_after_onCollision_listener")

onCollision1 = function(event)
if event.phase == "began" then
local agro = event.object1
local hit = event.object2
-- Rettet 2026-09-27: sammenlign med denne banens egne objekter, ikke
-- bare .type. Mens neste bane starter, ligger marken fra forrige bane
-- fortsatt i fysikkverdenen og faller gjennom sitt eget mål, og det
-- utløste målet i den nye banen med en gang (bane 8 -> 9 hoppet rett
-- videre og krasjet med "attempt to compare nil with number").
if agro == mal2 and hit == del4 then
    -- Rettet 2026-09-15: "collision1" var en udefinert global (skulle
    -- vært selve funksjonsnavnet onCollision1), så dette kallet kastet
    -- en feil hver gang målet ble nådd og stoppet resten av
    -- onCollision1 (lm.unlockNextLevel()/goto2() ble aldri kjørt) -
    -- banen "klikket bare" og gikk aldri videre til neste bane.
    Runtime:removeEventListener("collision", onCollision1)
    print( "mal2vsdel4" )
    del4.isSensor = false
  
           lm.unlockNextLevel()
 

 goto2()
end
end
end
Runtime:addEventListener("collision", onCollision1)
------------------------------------------------------------------
checkpoint("level1:cp_1126_after_onCollision1_listener")


stovteller1=0
stovteller2=0
stovteller3=0
stovteller4=0
stovteller5=0
stovteller6=0
stovteller7=0
stovteller8=0
stovteller9=0




local function onLocalCollision1( self, event )
 
    if ( event.phase == "began" ) then
        
     if  (self.type == "del1" and event.other.type == "firkant1") or
         (self.type == "del1" and event.other.type == "firkant2") or
         (self.type == "del1" and event.other.type == "firkant3") or
         (self.type == "del1" and event.other.type == "firkant4") then
       
        del1:removeEventListener( "collision" )

 
 local  stov1       = display.newImageRect("stov.png", 20,20)
        stov1.width  = 10+(math.random(10, 50)) 
        stov1.height = stov1.width
        stov1.x      = self.x+(math.random(1, 10)) 
        stov1.y      = self.y-(math.random(1, 10))
        rot         = (math.random(1,360)) 
        stov1.alpha  = 1.0
        stov1:rotate( rot )
        grp:insert(stov1)
        camera:add (stov1,1,false)
 


local tran= transition.to (stov1, {

                                    x          = stov1.x      - (math.random(-50, 50)),
                                    y          = stov1.y      - (math.random( 1, 50)),
                                    width      = stov1.width  + (math.random(1, 50)),
                                    height     = stov1.height + (math.random(1, 50)),
                                    alpha      = 0,
                                    time       = 1000,
                                    onComplete = function ()
                                        display.remove( stov1 )
                                        stov1 = nil
                                        -- Vaktet 2026-09-10: del1 kan allerede ha blitt
                                        -- revet ned (retry) mens denne transitionen ventet.
                                        -- .stage er nil på et fjernet visningsobjekt, se
                                        -- forklaring i TIL-ORJAN.md/KODEBASE.md.
                                        if del1.stage then del1:addEventListener( "collision" ) end
             end} ) 
                                    return stov1
         end
    --return true
    end
end
 
local function onLocalCollision2( self, event )
 
    if ( event.phase == "began" ) then
        
     if  (self.type == "del2" and event.other.type == "firkant1") or
         (self.type == "del2" and event.other.type == "firkant2") or
         (self.type == "del2" and event.other.type == "firkant3") or
         (self.type == "del2" and event.other.type == "firkant4") then

        del2:removeEventListener( "collision" )

       
 local  stov2        = display.newImageRect("stov.png", 20,20)
        stov2.width  = 10+(math.random(10, 50)) 
        stov2.height = stov2.width
        stov2.x      = self.x+(math.random(1, 10)) 
        stov2.y      = self.y-(math.random(1, 10))
        rot         = (math.random(1,360)) 
        stov2.alpha  = 1.0
        stov2:rotate( rot )
        grp:insert(stov2)
        camera:add (stov2,1,false)
 


local tran= transition.to (stov2, {

                                    x          = stov2.x      - (math.random(-50, 50)),
                                    y          = stov2.y      - (math.random( 1, 50)),
                                    width      = stov2.width  + (math.random(1, 50)),
                                    height     = stov2.height + (math.random(1, 50)),
                                    alpha      = 0,
                                    time       = 1000,
                                    onComplete = function ()
                                        display.remove( stov2 )
                                        stov2 = nil
                                        -- Vaktet 2026-09-10: del2 kan allerede ha blitt
                                        -- revet ned (retry) mens denne transitionen ventet.
                                        -- .stage er nil på et fjernet visningsobjekt, se
                                        -- forklaring i TIL-ORJAN.md/KODEBASE.md.
                                        if del2.stage then del2:addEventListener( "collision" ) end
             end} ) 
                                    return stov2
         end
    --return true
    end
end

local function onLocalCollision3( self, event )
 
    if ( event.phase == "began" ) then
        
     if  (self.type == "del3" and event.other.type == "firkant1") or
         (self.type == "del3" and event.other.type == "firkant2") or
         (self.type == "del3" and event.other.type == "firkant3") or
         (self.type == "del3" and event.other.type == "firkant4") then

         del3:removeEventListener( "collision" )

       
 local  stov3        = display.newImageRect("stov.png", 20,20)
        stov3.width  = 10+(math.random(10, 50)) 
        stov3.height = stov3.width
        stov3.x      = self.x+(math.random(1, 10)) 
        stov3.y      = self.y-(math.random(1, 10))
        rot         = (math.random(1,360)) 
        stov3.alpha  = 1.0
        stov3:rotate( rot )
        grp:insert(stov3)
        camera:add (stov3,1,false)
 


local tran= transition.to (stov3, {

                                    x          = stov3.x      - (math.random(-50, 50)),
                                    y          = stov3.y      - (math.random( 1, 50)),
                                    width      = stov3.width  + (math.random(1, 50)),
                                    height     = stov3.height + (math.random(1, 50)),
                                    alpha      = 0,
                                    time       = 1000,
                                    onComplete = function ()
                                        display.remove( stov3 )
                                        stov3 = nil
                                        -- Vaktet 2026-09-10: del3 kan allerede ha blitt
                                        -- revet ned (retry) mens denne transitionen ventet.
                                        -- .stage er nil på et fjernet visningsobjekt, se
                                        -- forklaring i TIL-ORJAN.md/KODEBASE.md.
                                        if del3.stage then del3:addEventListener( "collision" ) end
             end} ) 
                                    return stov3
         end
    --return true
    end
end

local function onLocalCollision4( self, event )
 
    if ( event.phase == "began" ) then
        
     if  (self.type == "del4" and event.other.type == "firkant1") or
         (self.type == "del4" and event.other.type == "firkant2") or
         (self.type == "del4" and event.other.type == "firkant3") or
         (self.type == "del4" and event.other.type == "firkant4") then

         del4:removeEventListener( "collision" )

       
 local  stov4        = display.newImageRect("stov.png", 20,20)
        stov4.width  = 10+(math.random(10, 50)) 
        stov4.height = stov4.width
        stov4.x      = self.x+(math.random(1, 10)) 
        stov4.y      = self.y-(math.random(1, 10))
        rot         = (math.random(1,360)) 
        stov4.alpha  = 1.0
        stov4:rotate( rot )
        grp:insert(stov4)
        camera:add (stov4,1,false)
 


local tran= transition.to (stov4, {

                                    x          = stov4.x      - (math.random(-50, 50)),
                                    y          = stov4.y      - (math.random( 1, 50)),
                                    width      = stov4.width  + (math.random(1, 50)),
                                    height     = stov4.height + (math.random(1, 50)),
                                    alpha      = 0,
                                    time       = 1000,
                                    onComplete = function ()
                                        display.remove( stov4 )
                                        stov4 = nil
                                        -- Vaktet 2026-09-10: del4 kan allerede ha blitt
                                        -- revet ned (retry) mens denne transitionen ventet.
                                        -- .stage er nil på et fjernet visningsobjekt, se
                                        -- forklaring i TIL-ORJAN.md/KODEBASE.md.
                                        if del4.stage then del4:addEventListener( "collision" ) end
             end} ) 
                                    return stov4
         end
    --return true
    end
end

local function onLocalCollision5( self, event )
 
    if ( event.phase == "began" ) then
        
     if  (self.type == "del5" and event.other.type == "firkant1") or
         (self.type == "del5" and event.other.type == "firkant2") or
         (self.type == "del5" and event.other.type == "firkant3") or
         (self.type == "del5" and event.other.type == "firkant4") then

         del5:removeEventListener( "collision" )

       
 local  stov5        = display.newImageRect("stov.png", 20,20)
        stov5.width  = 10+(math.random(10, 50)) 
        stov5.height = stov5.width
        stov5.x      = self.x+(math.random(1, 10)) 
        stov5.y      = self.y-(math.random(1, 10))
        rot         = (math.random(1,360)) 
        stov5.alpha  = 1.0
        stov5:rotate( rot )
        grp:insert(stov5)
        camera:add (stov5,1,false)
 


local tran= transition.to (stov5, {

                                    x          = stov5.x      - (math.random(-50, 50)),
                                    y          = stov5.y      - (math.random( 1, 50)),
                                    width      = stov5.width  + (math.random(1, 50)),
                                    height     = stov5.height + (math.random(1, 50)),
                                    alpha      = 0,
                                    time       = 1000,
                                    onComplete = function ()
                                        display.remove( stov5 )
                                        stov5 = nil
                                        -- Vaktet 2026-09-10: del5 kan allerede ha blitt
                                        -- revet ned (retry) mens denne transitionen ventet.
                                        -- .stage er nil på et fjernet visningsobjekt, se
                                        -- forklaring i TIL-ORJAN.md/KODEBASE.md.
                                        if del5.stage then del5:addEventListener( "collision" ) end
             end} ) 
                                    return stov5
         end
    --return true
    end
end

local function onLocalCollision6( self, event )
 
    if ( event.phase == "began" ) then
        
     if  (self.type == "del6" and event.other.type == "firkant1") or
         (self.type == "del6" and event.other.type == "firkant2") or
         (self.type == "del6" and event.other.type == "firkant3") or
         (self.type == "del6" and event.other.type == "firkant4") then

         del6:removeEventListener( "collision" )

       
 local  stov6        = display.newImageRect("stov.png", 20,20)
        stov6.width  = 10+(math.random(10, 50)) 
        stov6.height = stov6.width
        stov6.x      = self.x+(math.random(1, 10)) 
        stov6.y      = self.y-(math.random(1, 10))
        rot         = (math.random(1,360)) 
        stov6.alpha  = 1.0
        stov6:rotate( rot )
        grp:insert(stov6)
        camera:add (stov6,1,false)
 


local tran= transition.to (stov6, {

                                    x          = stov6.x      - (math.random(-50, 50)),
                                    y          = stov6.y      - (math.random( 1, 50)),
                                    width      = stov6.width  + (math.random(1, 50)),
                                    height     = stov6.height + (math.random(1, 50)),
                                    alpha      = 0,
                                    time       = 1000,
                                    onComplete = function ()
                                        display.remove( stov6 )
                                        stov6 = nil
                                        -- Vaktet 2026-09-10: del6 kan allerede ha blitt
                                        -- revet ned (retry) mens denne transitionen ventet.
                                        -- .stage er nil på et fjernet visningsobjekt, se
                                        -- forklaring i TIL-ORJAN.md/KODEBASE.md.
                                        if del6.stage then del6:addEventListener( "collision" ) end
             end} ) 
                                    return stov6
         end
    --return true
    end
end

local function onLocalCollision7( self, event )
 
    if ( event.phase == "began" ) then
        
     if  (self.type == "del7" and event.other.type == "firkant1") or
         (self.type == "del7" and event.other.type == "firkant2") or
         (self.type == "del7" and event.other.type == "firkant3") or
         (self.type == "del7" and event.other.type == "firkant4") then

         del7:removeEventListener( "collision" )

       
 local  stov7        = display.newImageRect("stov.png", 20,20)
        stov7.width  = 10+(math.random(10, 50)) 
        stov7.height = stov7.width
        stov7.x      = self.x+(math.random(1, 10)) 
        stov7.y      = self.y-(math.random(1, 10))
        rot         = (math.random(1,360)) 
        stov7.alpha  = 1.0
        stov7:rotate( rot )
        grp:insert(stov7)
        camera:add (stov7,1,false)
 


local tran= transition.to (stov7, {

                                    x          = stov7.x      - (math.random(-50, 50)),
                                    y          = stov7.y      - (math.random( 1, 50)),
                                    width      = stov7.width  + (math.random(1, 50)),
                                    height     = stov7.height + (math.random(1, 50)),
                                    alpha      = 0,
                                    time       = 1000,
                                    onComplete = function ()
                                        display.remove( stov7 )
                                        stov7 = nil
                                        -- Vaktet 2026-09-10: del7 kan allerede ha blitt
                                        -- revet ned (retry) mens denne transitionen ventet.
                                        -- .stage er nil på et fjernet visningsobjekt, se
                                        -- forklaring i TIL-ORJAN.md/KODEBASE.md.
                                        if del7.stage then del7:addEventListener( "collision" ) end
             end} ) 
                                    return stov7
         end
    --return true
    end
end

local function onLocalCollision8( self, event )
 
    if ( event.phase == "began" ) then
        
     if  (self.type == "del8" and event.other.type == "firkant1") or
         (self.type == "del8" and event.other.type == "firkant2") or
         (self.type == "del8" and event.other.type == "firkant3") or
         (self.type == "del8" and event.other.type == "firkant4") then

         del8:removeEventListener( "collision" )

       
 local  stov8        = display.newImageRect("stov.png", 20,20)
        stov8.width  = 10+(math.random(10, 50)) 
        stov8.height = stov8.width
        stov8.x      = self.x+(math.random(1, 10)) 
        stov8.y      = self.y-(math.random(1, 10))
        rot         = (math.random(1,360)) 
        stov8.alpha  = 1.0
        stov8:rotate( rot )
        grp:insert(stov8)
        camera:add (stov8,1,false)
 


local tran= transition.to (stov8, {

                                    x          = stov8.x      - (math.random(-50, 50)),
                                    y          = stov8.y      - (math.random( 1, 50)),
                                    width      = stov8.width  + (math.random(1, 50)),
                                    height     = stov8.height + (math.random(1, 50)),
                                    alpha      = 0,
                                    time       = 1000,
                                    onComplete = function ()
                                        display.remove( stov8 )
                                        stov8 = nil
                                        -- Vaktet 2026-09-10: del8 kan allerede ha blitt
                                        -- revet ned (retry) mens denne transitionen ventet.
                                        -- .stage er nil på et fjernet visningsobjekt, se
                                        -- forklaring i TIL-ORJAN.md/KODEBASE.md.
                                        if del8.stage then del8:addEventListener( "collision" ) end
             end} ) 
                                    return stov8
         end
    --return true
    end
end

local function onLocalCollision9( self, event )
 
    if ( event.phase == "began" ) then
        
     if  (self.type == "del9" and event.other.type == "firkant1") or
         (self.type == "del9" and event.other.type == "firkant2") or
         (self.type == "del9" and event.other.type == "firkant3") or
         (self.type == "del9" and event.other.type == "firkant4") then

         del9:removeEventListener( "collision" )

       
 local  stov9        = display.newImageRect("stov.png", 20,20)
        stov9.width  = 10+(math.random(10, 50)) 
        stov9.height = stov9.width
        stov9.x      = self.x+(math.random(1, 10)) 
        stov9.y      = self.y-(math.random(1, 10))
        rot         = (math.random(1,360)) 
        stov9.alpha  = 1.0
        stov9:rotate( rot )
        grp:insert(stov9)
        camera:add (stov9,1,false)
 


local tran= transition.to (stov9, {

                                    x          = stov9.x      - (math.random(-50, 50)),
                                    y          = stov9.y      - (math.random( 1, 50)),
                                    width      = stov9.width  + (math.random(1, 50)),
                                    height     = stov9.height + (math.random(1, 50)),
                                    alpha      = 0,
                                    time       = 1000,
                                    onComplete = function ()
                                        display.remove( stov9 )
                                        stov9 = nil
                                        -- Vaktet 2026-09-10: del9 kan allerede ha blitt
                                        -- revet ned (retry) mens denne transitionen ventet.
                                        -- .stage er nil på et fjernet visningsobjekt, se
                                        -- forklaring i TIL-ORJAN.md/KODEBASE.md.
                                        if del9.stage then del9:addEventListener( "collision" ) end
             end} ) 
                                    return stov9
         end
    --return true
    end
end

del1.collision = onLocalCollision1
del1:addEventListener( "collision" )
------------------------------------
checkpoint("level1:cp_1513_after_del1_addEventListener")
del2.collision = onLocalCollision2
del2:addEventListener( "collision" )
------------------------------------
del3.collision = onLocalCollision3
del3:addEventListener( "collision" )
------------------------------------
del4.collision = onLocalCollision4
del4:addEventListener( "collision" )
------------------------------------
del5.collision = onLocalCollision5
del5:addEventListener( "collision" )
------------------------------------
del6.collision = onLocalCollision6
del6:addEventListener( "collision" )
------------------------------------
del7.collision = onLocalCollision7
del7:addEventListener( "collision" )
------------------------------------
del8.collision = onLocalCollision8
del8:addEventListener( "collision" )
------------------------------------
del9.collision = onLocalCollision9
del9:addEventListener( "collision" )
----------------------------------
checkpoint("level1:cp_1537_after_del9_addEventListener")











knekk = function(event)
if event.phase == "began" then


if  (event.object1 == knott1 and event.object2 == knott2) then

print( "knott1 og knott2" )

elseif  (event.object1 == knott2 and event.object2 == knott3) then

knapp1.alpha = 0
Runtime:removeEventListener("collision", onCollision)
Runtime:removeEventListener( "touch", trykk_knapp)
Runtime:removeEventListener( "tap", trykk_knapp)
Runtime:removeEventListener("collision", knekk)
pivot_joint.isMotorEnabled  = false
pivot_joint1.isMotorEnabled = false
pivot_joint2.isMotorEnabled = false
pivot_joint3.isMotorEnabled = false
pivot_joint4.isMotorEnabled = false
pivot_joint5.isMotorEnabled = false
pivot_joint6.isMotorEnabled = false
pivot_joint7.isMotorEnabled = false
display.remove(pivot_joint1)
display.remove(knott2)
knott2 = nil
camera:setFocus( del9 )
print( "knott2 og knott3" )


local blod = display.newImageRect("blod.png", 20,20)
blod.width = 10+(math.random(10, 50)) 
blod.height = blod.width
blod.x = event.object1.x+(math.random(1, 10)) 
blod.y = event.object1.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod:rotate( rot )
blod.alpha =1
camera:add (blod,1,false)

      transition.to( blod, { x = blod.x +- (math.random(-50, 50)),
                             y = blod.y - (math.random( 1, 50)),
                             width = blod.width + (math.random(1, 50)),
                             height = blod.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
                
                
local blod2 = display.newImageRect("blod.png", 20,20)
blod2.width = 10+(math.random(10, 50)) 
blod2.height = blod2.width
blod2.x = event.object2.x+(math.random(1, 10)) 
blod2.y = event.object2.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod2:rotate( rot )
blod2.alpha =1
camera:add (blod2,1,false)

      transition.to( blod2, { x = blod2.x +- (math.random(-50, 50)),
                             y = blod2.y - (math.random( 1, 50)),
                             width = blod2.width + (math.random(1, 50)),
                             height = blod2.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )

-- Rettet 2026-09-15: var "local eventTimer" (7 like steder i denne
-- fila, ett per knott-par som kan knekke), men pausemenu1.lua,
-- dodmenu1.lua og gotomenu.lua prover ALLE aa avbryte akkurat denne
-- tidsforsinkede goto()-timeren med timer.cancel(eventTimer) naar
-- spilleren trykker retry/main menu/levels. Siden "local" gjorde den
-- usynlig utenfor selve denne fila, traff de kallene alltid en
-- udefinert global (alltid nil) i stedet, og avbrøt ingenting - en
-- ventende knekk-timer kunne fortsatt fyre av goto() flere sekunder
-- etter at spilleren allerede hadde forlatt banen. Bevisst global naa
-- (_G.eventTimer), samme mønster som _G.camera/_G.grp.
_G.eventTimer = timer.performWithDelay( 3000, goto)

elseif  (event.object1 == knott3 and event.object2 == knott4) then

knapp1.alpha = 0
Runtime:removeEventListener("collision", onCollision)
Runtime:removeEventListener( "touch", trykk_knapp)
Runtime:removeEventListener( "tap", trykk_knapp)
Runtime:removeEventListener("collision", knekk)
pivot_joint.isMotorEnabled  = false
pivot_joint1.isMotorEnabled = false
pivot_joint2.isMotorEnabled = false
pivot_joint3.isMotorEnabled = false
pivot_joint4.isMotorEnabled = false
pivot_joint5.isMotorEnabled = false
pivot_joint6.isMotorEnabled = false
pivot_joint7.isMotorEnabled = false
display.remove(pivot_joint2)
display.remove(knott3)
knott3 = nil
camera:setFocus( del9 )
print( "knott3 og knott4" )

local blod = display.newImageRect("blod.png", 20,20)
blod.width = 10+(math.random(10, 50)) 
blod.height = blod.width
blod.x = event.object1.x+(math.random(1, 10)) 
blod.y = event.object1.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod:rotate( rot )
blod.alpha =1
camera:add (blod,1,false)

      transition.to( blod, { x = blod.x +- (math.random(-50, 50)),
                             y = blod.y - (math.random( 1, 50)),
                             width = blod.width + (math.random(1, 50)),
                             height = blod.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
                
                
local blod2 = display.newImageRect("blod.png", 20,20)
blod2.width = 10+(math.random(10, 50)) 
blod2.height = blod2.width
blod2.x = event.object2.x+(math.random(1, 10)) 
blod2.y = event.object2.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod2:rotate( rot )
blod2.alpha =1
camera:add (blod2,1,false)

      transition.to( blod2, { x = blod2.x +- (math.random(-50, 50)),
                             y = blod2.y - (math.random( 1, 50)),
                             width = blod2.width + (math.random(1, 50)),
                             height = blod2.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
            
_G.eventTimer = timer.performWithDelay( 3000, goto)


elseif  (event.object1 == knott4 and event.object2 == knott5) then

knapp1.alpha = 0
Runtime:removeEventListener("collision", onCollision)
Runtime:removeEventListener( "touch", trykk_knapp)
Runtime:removeEventListener( "tap", trykk_knapp)
Runtime:removeEventListener("collision", knekk)
pivot_joint.isMotorEnabled  = false
pivot_joint1.isMotorEnabled = false
pivot_joint2.isMotorEnabled = false
pivot_joint3.isMotorEnabled = false
pivot_joint4.isMotorEnabled = false
pivot_joint5.isMotorEnabled = false
pivot_joint6.isMotorEnabled = false
pivot_joint7.isMotorEnabled = false
display.remove(pivot_joint3)
display.remove(knott4)
knott4 = nil
camera:setFocus( del9 )
print( "knott4 og knott5" )

local blod = display.newImageRect("blod.png", 20,20)
blod.width = 10+(math.random(10, 50)) 
blod.height = blod.width
blod.x = event.object1.x+(math.random(1, 10)) 
blod.y = event.object1.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod:rotate( rot )
blod.alpha =1
camera:add (blod,1,false)

      transition.to( blod, { x = blod.x +- (math.random(-50, 50)),
                             y = blod.y - (math.random( 1, 50)),
                             width = blod.width + (math.random(1, 50)),
                             height = blod.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
                
                
local blod2 = display.newImageRect("blod.png", 20,20)
blod2.width = 10+(math.random(10, 50)) 
blod2.height = blod2.width
blod2.x = event.object2.x+(math.random(1, 10)) 
blod2.y = event.object2.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod2:rotate( rot )
blod2.alpha =1
camera:add (blod2,1,false)

      transition.to( blod2, { x = blod2.x +- (math.random(-50, 50)),
                             y = blod2.y - (math.random( 1, 50)),
                             width = blod2.width + (math.random(1, 50)),
                             height = blod2.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
            
_G.eventTimer = timer.performWithDelay( 3000, goto)


elseif  (event.object1 == knott5 and event.object2 == knott6) then

knapp1.alpha = 0
Runtime:removeEventListener("collision", onCollision)
Runtime:removeEventListener( "touch", trykk_knapp)
Runtime:removeEventListener( "tap", trykk_knapp)
Runtime:removeEventListener("collision", knekk)
pivot_joint.isMotorEnabled  = false
pivot_joint1.isMotorEnabled = false
pivot_joint2.isMotorEnabled = false
pivot_joint3.isMotorEnabled = false
pivot_joint4.isMotorEnabled = false
pivot_joint5.isMotorEnabled = false
pivot_joint6.isMotorEnabled = false
pivot_joint7.isMotorEnabled = false
display.remove(pivot_joint4)
display.remove(knott5)
knott5 = nil
camera:setFocus( del9 )
print( "knott5 og knott6" )

local blod = display.newImageRect("blod.png", 20,20)
blod.width = 10+(math.random(10, 50)) 
blod.height = blod.width
blod.x = event.object1.x+(math.random(1, 10)) 
blod.y = event.object1.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod:rotate( rot )
blod.alpha =1
camera:add (blod,1,false)

      transition.to( blod, { x = blod.x +- (math.random(-50, 50)),
                             y = blod.y - (math.random( 1, 50)),
                             width = blod.width + (math.random(1, 50)),
                             height = blod.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
                
                
local blod2 = display.newImageRect("blod.png", 20,20)
blod2.width = 10+(math.random(10, 50)) 
blod2.height = blod2.width
blod2.x = event.object2.x+(math.random(1, 10)) 
blod2.y = event.object2.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod2:rotate( rot )
blod2.alpha =1
camera:add (blod2,1,false)

      transition.to( blod2, { x = blod2.x +- (math.random(-50, 50)),
                             y = blod2.y - (math.random( 1, 50)),
                             width = blod2.width + (math.random(1, 50)),
                             height = blod2.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
            
_G.eventTimer = timer.performWithDelay( 3000, goto)

elseif  (event.object1 == knott6 and event.object2 == knott7) then

knapp1.alpha = 0
Runtime:removeEventListener("collision", onCollision)
Runtime:removeEventListener( "touch", trykk_knapp)
Runtime:removeEventListener( "tap", trykk_knapp)
Runtime:removeEventListener("collision", knekk)
pivot_joint.isMotorEnabled  = false
pivot_joint1.isMotorEnabled = false
pivot_joint2.isMotorEnabled = false
pivot_joint3.isMotorEnabled = false
pivot_joint4.isMotorEnabled = false
pivot_joint5.isMotorEnabled = false
pivot_joint6.isMotorEnabled = false
pivot_joint7.isMotorEnabled = false
display.remove(pivot_joint5)
display.remove(knott6)
knott6 = nil
camera:setFocus( del9 )
print( "knott6 og knott7" )

local blod = display.newImageRect("blod.png", 20,20)
blod.width = 10+(math.random(10, 50)) 
blod.height = blod.width
blod.x = event.object1.x+(math.random(1, 10)) 
blod.y = event.object1.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod:rotate( rot )
blod.alpha =1
camera:add (blod,1,false)

      transition.to( blod, { x = blod.x +- (math.random(-50, 50)),
                             y = blod.y - (math.random( 1, 50)),
                             width = blod.width + (math.random(1, 50)),
                             height = blod.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
                
                
local blod2 = display.newImageRect("blod.png", 20,20)
blod2.width = 10+(math.random(10, 50)) 
blod2.height = blod2.width
blod2.x = event.object2.x+(math.random(1, 10)) 
blod2.y = event.object2.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod2:rotate( rot )
blod2.alpha =1
camera:add (blod2,1,false)

      transition.to( blod2, { x = blod2.x +- (math.random(-50, 50)),
                             y = blod2.y - (math.random( 1, 50)),
                             width = blod2.width + (math.random(1, 50)),
                             height = blod2.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
            
_G.eventTimer = timer.performWithDelay( 3000, goto)

elseif  (event.object1 == knott7 and event.object2 == knott8) then

knapp1.alpha = 0
Runtime:removeEventListener("collision", onCollision)
Runtime:removeEventListener( "touch", trykk_knapp)
Runtime:removeEventListener( "tap", trykk_knapp)
Runtime:removeEventListener("collision", knekk)
pivot_joint.isMotorEnabled  = false
pivot_joint1.isMotorEnabled = false
pivot_joint2.isMotorEnabled = false
pivot_joint3.isMotorEnabled = false
pivot_joint4.isMotorEnabled = false
pivot_joint5.isMotorEnabled = false
pivot_joint6.isMotorEnabled = false
pivot_joint7.isMotorEnabled = false
display.remove(pivot_joint6)
display.remove(knott7)
knott7 = nil
camera:setFocus( del9 )
print( "knott7 og knott8" )

local blod = display.newImageRect("blod.png", 20,20)
blod.width = 10+(math.random(10, 50)) 
blod.height = blod.width
blod.x = event.object1.x+(math.random(1, 10)) 
blod.y = event.object1.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod:rotate( rot )
blod.alpha =1
camera:add (blod,1,false)

      transition.to( blod, { x = blod.x +- (math.random(-50, 50)),
                             y = blod.y - (math.random( 1, 50)),
                             width = blod.width + (math.random(1, 50)),
                             height = blod.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
                
                
local blod2 = display.newImageRect("blod.png", 20,20)
blod2.width = 10+(math.random(10, 50)) 
blod2.height = blod2.width
blod2.x = event.object2.x+(math.random(1, 10)) 
blod2.y = event.object2.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod2:rotate( rot )
blod2.alpha =1
camera:add (blod2,1,false)

      transition.to( blod2, { x = blod2.x +- (math.random(-50, 50)),
                             y = blod2.y - (math.random( 1, 50)),
                             width = blod2.width + (math.random(1, 50)),
                             height = blod2.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
            
_G.eventTimer = timer.performWithDelay( 3000, goto)

elseif  (event.object1 == knott8 and event.object2 == knott9) then

knapp1.alpha = 0
Runtime:removeEventListener("collision", onCollision)
Runtime:removeEventListener( "touch", trykk_knapp)
Runtime:removeEventListener( "tap", trykk_knapp)
Runtime:removeEventListener("collision", knekk)
pivot_joint.isMotorEnabled  = false
pivot_joint1.isMotorEnabled = false
pivot_joint2.isMotorEnabled = false
pivot_joint3.isMotorEnabled = false
pivot_joint4.isMotorEnabled = false
pivot_joint5.isMotorEnabled = false
pivot_joint6.isMotorEnabled = false
pivot_joint7.isMotorEnabled = false
display.remove(pivot_joint7)
display.remove(knott8)
knott8 = nil
camera:setFocus( del9 )
print( "knott8 og knott9" )

local blod = display.newImageRect("blod.png", 20,20)
blod.width = 10+(math.random(10, 50)) 
blod.height = blod.width
blod.x = event.object1.x+(math.random(1, 10)) 
blod.y = event.object1.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod:rotate( rot )
blod.alpha =1
camera:add (blod,1,false)

      transition.to( blod, { x = blod.x +- (math.random(-50, 50)),
                             y = blod.y - (math.random( 1, 50)),
                             width = blod.width + (math.random(1, 50)),
                             height = blod.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
                
                
local blod2 = display.newImageRect("blod.png", 20,20)
blod2.width = 10+(math.random(10, 50)) 
blod2.height = blod2.width
blod2.x = event.object2.x+(math.random(1, 10)) 
blod2.y = event.object2.y-(math.random(1, 10))
rot = (math.random(1,360)) 
blod2:rotate( rot )
blod2.alpha =1
camera:add (blod2,1,false)

      transition.to( blod2, { x = blod2.x +- (math.random(-50, 50)),
                             y = blod2.y - (math.random( 1, 50)),
                             width = blod2.width + (math.random(1, 50)),
                             height = blod2.height + (math.random(1, 50)),
                             alpha = 0,
                             time = 2000,
                             onComplete = function ()display.remove( blod ) end } )
            
  _G.eventTimer = timer.performWithDelay( 3000, goto)

                end         
       end
end
-- Slått på 2026-09-10 (var kommentert bort, selve knekk-mekanikken var
-- ellers ferdig kodet: blod, fjerning av motor-joints og dødsmeny
-- fungerer, bare selve lytteren manglet). Se forklaring i TIL-ORJAN.md.
Runtime:addEventListener("collision", knekk)
----------------------------------------------------------------------------------
checkpoint("level1:cp_2004_after_collision_del9_block")



 del1.y = del1.y
 ---------------------------------------------------------
 
 reff = display.newRect (0,0,50,50)
 reff.x = bredde/2
 reff.y = hoyde/2
 reff.alpha = 0
 grp:insert(reff)






 angel = pivot_joint1.Rotation





    -------------------
--Ferdig spill
    camera.x=-100
    camera.y=-50


 --camera.x=-150
--camera.y=-50



    ----------------------------------
        -- pauseknappen ligger i lib/hud.lua sin gruppe (2026-10-28)
        -- camera:add (knapp1,2,false)
    ----------------------------------
    camera:add (background,6,false)
    ----------------------------------
    camera:add (background1b,5,false)
    camera:add (background2b,5,false)
    camera:add (background3b,5,false)
    camera:add (background4b,5,false)
    camera:add (background5b,5,false)
    camera:add (background6b,5,false)
    camera:add (background7b,5,false)
    camera:add (background8b,5,false)
    camera:add (background9b,5,false)
    camera:add (background10b,5,false)
    camera:add (background11b,5,false)
    camera:add (background12b,5,false)
    camera:add (background13b,3,false)
    camera:add (background14b,3,false)
    camera:add (background15b,3,false)
    camera:add (background16b,3,false)
    camera:add (background17b,3,false)
    camera:add (background18b,3,false)
    camera:add (background19b,3,false)
    camera:add (background20b,3,false)
    ----------------------------------
    camera:add (background1a,4,false)
    camera:add (background2a,4,false)
    camera:add (background3a,4,false)
    camera:add (background4a,4,false)
    camera:add (background5a,4,false)
    camera:add (background6a,4,false)
    camera:add (background7a,4,false)
    camera:add (background8a,4,false)
    camera:add (background9a,4,false)
    camera:add (background10a,4,false)
    camera:add (background11a,4,false)
    camera:add (background12a,4,false)
    camera:add (background13a,3,false)
    camera:add (background14a,3,false)
    camera:add (background15a,3,false)
    camera:add (background16a,3,false)
    camera:add (background17a,3,false)
    camera:add (background18a,3,false)
    camera:add (background19a,3,false)
    camera:add (background20a,3,false)
    ----------------------------------
    
    camera:add (background1,3,false)
    camera:add (background2,3,false)
    camera:add (background3,3,false)
    camera:add (background4,3,false)
    camera:add (background5,3,false)
    camera:add (background6,3,false)
    camera:add (background7,3,false)
    camera:add (background8,3,false)
    camera:add (background9,3,false)
    camera:add (background10,3,false)
    camera:add (background11,3,false)
    camera:add (background12,3,false)
    camera:add (background13,3,false)
    camera:add (background14,3,false)
    camera:add (background15,3,false)
    camera:add (background16,3,false)
    camera:add (background17,3,false)
    camera:add (background18,3,false)
    camera:add (background19,3,false)
    camera:add (background20,3,false)


    -----------------------------------
    camera:add (firkant1,1,false)
    camera:add (firkant2,1,false)
    camera:add (firkant3,1,false)
    camera:add (firkant4,1,false)
    ----------------------------------
   -- camera:add (punkt2,1,false)
    camera:add (punkt,1,false)
    camera:add (del1,1,false)
    camera:add (del2,1,false)
    camera:add (del3,1,false)
    camera:add (del4,1,false)
    camera:add (del5,1,false)
    camera:add (del6,1,false)
    camera:add (del7,1,false)
    camera:add (del8,1,false)
    camera:add (del9,1,false)
    


    --camera:add (del77,1,false)
    camera:setFocus( punkt )
    
    local levelWidth = camera:layer(6).width
    local levelHeight = camera:layer(6).height
   -- camera:setParallax( 0.30, 0.25, 0.20, 0.15, 0.10, 0.1 )
    --camera:setParallax( 0.90, 0.80, 0.70, 0.60, 0.50, 0.4 )
    camera:setParallax(  0.99, 0.80, 0.95, 0.90, 0.80, 0.70 )
    camera:setBounds(200, firkant4.x+firkant4.width/3 , 300, firkant4.y+firkant4.height/3)
    camera.damping = 10
    --camera.damping = 30
    camera:track()
    grp:insert(camera)
    camera:toBack()
camera:layer(2).parallaxRatio=0
-- Rettet 2026-09-15: lag 1 (banen/marken) ble satt inn i "view" sist av
-- perspective.lua sin egen konstruktør og lå derfor alltid øverst,
-- foran lag 2 der pauseknappen bor. parallaxRatio=0 over holder knappen
-- fast på skjermen, men styrte ikke rekkefølgen den tegnes i. toFront()
-- flytter kun lag 2 til fronten av kamera-gruppa, uten å endre hvilket
-- lag knappen faktisk tilhører (og dermed ikke rulle-oppførselen).
camera:layer(2):toFront()
-- Mørket i hulen, tettere for hver bane (2026-09-28, se lib/morke.lua).
require( "lib.morke" ).lag( 1, punkt )
-- Banenummeret som nummerstein øverst til venstre (2026-09-28).
require( "lib.banenummer" ).vis( 1 )

-- Lagt til 2026-09-15 (Mathias: "Marken kunne falle ut av banen på bane
-- 2 uten at det kom opp at den døde. Gjør slik at man dør om man faller
-- ut av verdenen."). Dødssonen har hele tiden vært ETT enkelt rektangel
-- ("dod" øverst i fila, 70000x50 rotert 31,48 grader) lagt som en
-- diagonal linje under banen. Den er lang, men ikke uendelig: regnet ut
-- at den slutter rundt x = 28400, mens siste flis slutter rundt
-- x = 30400 og selve målet (mal2) står på x = 31000. Faller marken av
-- bakken på den aller siste strekningen, altså akkurat der man er når
-- man holder på å fullføre banen, treffer den aldri dødssonen, og faller
-- bare videre i det uendelige uten at dødsmenyen dukker opp.
--
-- Dette er et sikkerhetsnett som ikke er avhengig av "dod" i det hele
-- tatt, og som ikke tar slutt: for hver x finner vi flisa marken er over
-- og dør om den har falt under UNDERKANTEN av den flisa. Underkanten av
-- selve bildet er alltid under all bakke som er tegnet i det, så dette
-- kan ikke gi dødsfall der spilleren egentlig står trygt (et forsøk med
-- én felles skrå linje under alle flisene ble forkastet: målt mot den
-- ekte bakke-kunsten lå den 160 enheter OVER bakken på slutten av bane 1
-- og 3, altså midt i der spilleren faktisk går).
local flisene = { firkant1, firkant2, firkant3, firkant4 }
local FALL_UNDER_FLIS = 600

local function bunnlinjeVed( x )
    local flis = flisene[1]
    for i = 2, #flisene do
        if x >= flisene[i].x - flisene[i].width / 2 then
            flis = flisene[i]
        end
    end
    return flis.y + flis.height / 2 + FALL_UNDER_FLIS
end

local baneVenstre = firkant1.x - firkant1.width
local baneHoyre = firkant4.x + firkant4.width
local harFaltUtAvBanen = false

sjekkUtenforBanen = function()
    if harFaltUtAvBanen then return end
    if punkt == nil or punkt.x == nil then return end
    if punkt.y > bunnlinjeVed( punkt.x )
        or punkt.x < baneVenstre
        or punkt.x > baneHoyre then
        harFaltUtAvBanen = true
        Runtime:removeEventListener( "enterFrame", sjekkUtenforBanen )
        print( "marken falt ut av banen" )
        goto()
    end
end
Runtime:addEventListener( "enterFrame", sjekkUtenforBanen )
local sqCenterX, sqCenterY = reff:localToContent( 0, 0 )


grp.xScale = scaleFactor
grp.yScale = scaleFactor



-- Dobbeltklikk skal gjøre marken helt slapp (motorene på leddene av).
-- Brukte tidligere Runtime "tap"-eventet sin event.numTaps == 2, men det
-- krever at motoren syntetiserer et eget "tap"-event med riktig telling
-- oppå de vanlige "touch"-fasene, noe HTML5-eksporten ikke ser ut til å
-- gjøre pålitelig (derfor virket det ikke). Sjekker i stedet tiden mellom
-- to "began"-faser selv, uavhengig av om "tap" fyres. Samtidig fikset et
-- reelt problem: "ended"-fasen satte tidligere motorene tilbake til på,
-- uansett, så selv om dobbeltklikket hadde blitt oppdaget ville neste
-- berøring umiddelbart slått motorene på igjen.
 local isLimp = false
 local sisteBegan = 0
 local dobbeltklikkVindu = 300 -- ms

 trykk_knapp = function( event )
    if event.phase == "began" then
            local naa = system.getTimer()
            -- Rettet 2026-09-15: å bli slapp krevde dobbeltklikk, men å bli
            -- stram igjen krevde OGSÅ et dobbeltklikk innenfor samme vindu,
            -- altså to klikk. Ett enkelt klikk er nå nok når marken
            -- allerede er slapp.
            if isLimp then
                isLimp = false
            elseif ( naa - sisteBegan ) < dobbeltklikkVindu then
                isLimp = true
                print( "marken slapp: " .. tostring(isLimp) )
            end
            sisteBegan = naa

            if isLimp then
                pivot_joint.isMotorEnabled = false
                pivot_joint1.isMotorEnabled = false
                pivot_joint2.isMotorEnabled = false
                pivot_joint3.isMotorEnabled = false
                pivot_joint4.isMotorEnabled = false
                pivot_joint5.isMotorEnabled = false
                pivot_joint6.isMotorEnabled = false
                pivot_joint7.isMotorEnabled = false
            else
                print( "knapp" )
                pivot_joint.isMotorEnabled = true
                pivot_joint.motorSpeed  = pivot_joint.motorSpeed - 80
                pivot_joint1.isMotorEnabled = true
                pivot_joint1.motorSpeed = pivot_joint.motorSpeed - 80
                pivot_joint2.isMotorEnabled = true
                pivot_joint2.motorSpeed = pivot_joint.motorSpeed - 80
                pivot_joint3.isMotorEnabled = true
                pivot_joint3.motorSpeed = pivot_joint.motorSpeed - 80
                pivot_joint4.isMotorEnabled = true
                pivot_joint4.motorSpeed = pivot_joint.motorSpeed - 80
                pivot_joint5.isMotorEnabled = true
                pivot_joint5.motorSpeed = pivot_joint.motorSpeed - 80
                pivot_joint6.isMotorEnabled = true
                pivot_joint6.motorSpeed = pivot_joint.motorSpeed - 80
                pivot_joint7.isMotorEnabled = true
                pivot_joint7.motorSpeed = pivot_joint.motorSpeed - 80
            end

    elseif event.phase == "ended" then
            if not isLimp then
                pivot_joint.isMotorEnabled = true
                pivot_joint.motorSpeed = 30
                pivot_joint1.isMotorEnabled = true
                pivot_joint1.motorSpeed = 30
                pivot_joint2.isMotorEnabled = true
                pivot_joint2.motorSpeed = 30
                pivot_joint3.isMotorEnabled = true
                pivot_joint3.motorSpeed = 30
                pivot_joint4.isMotorEnabled = true
                pivot_joint4.motorSpeed = 30
                pivot_joint5.isMotorEnabled = true
                pivot_joint5.motorSpeed = 30
                pivot_joint6.isMotorEnabled = true
                pivot_joint6.motorSpeed = 30
                pivot_joint7.isMotorEnabled = true
                pivot_joint7.motorSpeed = 30
            end

    end
end
Runtime:addEventListener( "touch", trykk_knapp)



       local options = {isModal = true,effect = "fade",time = 500,}



local function trykk_knapp1( event )
    if event.phase == "began" then
       physics.pause( )
        print( "knapp1" )
       -- hent(liv)
        --knapp1.alpha = 0
         --Runtime:removeEventListener( "touch", trykk_knapp)
--Runtime:removeEventListener( "tap", trykk_knapp)

         composer.showOverlay( "scenes.pausemenu1",options)
         return true 
    elseif event.phase == "ended" then
       --camera:destroy()
        --camera                               =nil
        
    end
end
knapp1:addEventListener( "touch", trykk_knapp1)
checkpoint("level1:before_end_of_create")


end



function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase
    if ( phase == "will" ) then
        print ("level1 scene:show will")
    elseif ( phase == "did" ) then
        print ("level1 scene:show did")
        --last:pause()
        composer.removeScene("scenes.chooselevel")
        display.remove( last )
        last = nil
    end
end


function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase
    if ( phase == "will" ) then
        --physics.stop( )
       --punktsant = false
      
       print ("level1 scene:hide will")
   elseif ( phase == "did" ) then
       print ("level1 scene:hide did")
if egetKamera then egetKamera:destroy() end
        if camera == egetKamera then camera = nil end
        egetKamera = nil


      -- camera:setFocus( nil )

-- Lagt til 2026-09-10: stov1-stov9-støveffekten (når en kroppsdel
-- lander) venter 1 sekund før den fjerner seg selv og rearmerer delN
-- sin egen kollisjonslytter. transition.to() sine onComplete-kall
-- avbrytes IKKE automatisk av at scenen skjules, så om spilleren dør
-- og går til retry mens en slik effekt fortsatt venter, fyres den opp
-- til 1 sekund senere mot en delN som da allerede er revet ned av
-- retry, og krasjer uhåndtert ("attempt to call method
-- 'addEventListener' (a nil value)", siden en fjernet Corona-scene-
-- objekt mister metodene sine). transition.cancel() uten argumenter
-- avbryter alle ventende transitions, trygt her siden ingenting annet
-- kjører transitions samtidig med selve banen.
transition.cancel()

Runtime:removeEventListener("collision", onCollision)
Runtime:removeEventListener( "touch", trykk_knapp)
Runtime:removeEventListener( "tap", trykk_knapp)
Runtime:removeEventListener("collision", knekk)
Runtime:removeEventListener("collision", onCollision1)


Runtime:removeEventListener( "enterFrame", sjekkUtenforBanen )
composer.removeScene ("scenes.pausemenu1")

       composer.removeScene ("scenes.level1")









   end
end


function scene:destroy( event )

    local sceneGroup = self.view
        print ("level1 scene:destroy did")
    
        
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene