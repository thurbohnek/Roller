

local bredde = display.contentWidth

local hoyde = display.contentHeight


local liv = {}

-- Lagt til 2026-09-15: livtelleren har nå en egen retry-knapp (se
-- liv.hent lenger ned), og den trenger både composer og physics for å
-- gjøre nøyaktig det samme som retry-knappen i pausemenyen gjør.
local composer = require( "composer" )
local physics = require( "physics" )

-- Selve livteller-objektene. Var utilsiktede globaler før (2026-09-15),
-- ingenting utenfor denne fila har noen gang rørt dem.
local livText, livbilde, livretry

-- File path to the score file
local score_file_path = system.pathForFile( "liv.txt", system.DocumentsDirectory )
local STARTLIV = 10
local liv_igjen = STARTLIV


-----------------------------
-- PRIVATE FUNCTIONS
-----------------------------






local function setHighScore()
    if liv_igjen < 1 then
        print( "nullliv" )
       -- liv_igjen = liv_igjen
       liv_igjen = liv_igjen+3
    end
end

local function lagreliv()
    -- Open the file handle
    local file, errorString = io.open( score_file_path, "w" )

    if not file then
        -- Error occurred; output the cause
        print( "File error: " .. errorString )
    else
        -- Write data to file
        file:write( liv_igjen )
        -- Close the file handle
        io.close( file )
        print("Lagret liv!")
    end

    file = nil
end

local function lastliv()
    -- Open the file handle
    local file, errorString = io.open( score_file_path, "r" )

    if not file then
        -- Error occurred; output the cause
        print( "File error: " .. errorString )
    else
        -- Read data from file
        local contents = file:read( "*a" )
        -- Set liv.liv_igjen as the content of the file
        liv_igjen = tonumber( contents )
        print( "Lastet liv: ", liv_igjen )
        -- Close the file handle
        io.close( file )
    end

    file = nil
end


-------------------------------------------------------------------------
-- Hvor mange forsøk du har igjen ETTER det du holder på med nå.
-- Endret 2026-09-15, Mathias: "Når man er på sitt siste liv bør det stå
-- 0. Er misvisende på måten det står nå. Folk tror de enda har ett
-- ekstra forsøk når det står 1 igjen men om de dør så må de se reklame."
-- Telleren i seg selv (liv_igjen) er uendret, det er bare visningen som
-- trekker fra det forsøket som pågår: står det 0, er dette det siste,
-- og dør du nå kommer reklame-for-liv-skjermen.
local function livIgjenEtterDette()
   local igjen = liv_igjen - 1
   if igjen < 0 then
      igjen = 0
   end
   return igjen
end

function liv.hent( event )
-- Rydder bort forrige teller først. Banefilene kaller denne to ganger
-- (én gang med en gang, én gang tre sekunder ut i banen), så uten dette
-- lå det hele tiden to tellere rett oppå hverandre.
display.remove( livText )
display.remove( livbilde )
display.remove( livretry )
livText, livbilde, livretry = nil, nil, nil

-- Ny stil 2026-10-28: forsøkene vises som en pille med hjerte øverst til
-- høyre i skjermbildet under spill (lib/hud.lua), ved pauseknappen.
local ui = require( "lib.ui" )
local hudGruppe = require( "lib.hud" ).gruppe()
livbilde = ui.pille( hudGruppe, "hjerte", ui.HOYRE - 150, ui.TOPP + 40, 120, tostring( livIgjenEtterDette() ) )
livText = livbilde

-- Retry-knapp rett under livene, skjult til man trykker på dem.
-- Lagt til 2026-09-15, Mathias: "Om man klikker på livene sine bør det
-- være en knapp for å retry, så slipper man å pause også trykke retry".
-- To trykk totalt (livene, så knappen) er med vilje: da kan man ikke
-- starte banen på nytt ved et uhell med ett bomtrykk øverst på skjermen.
livretry = ui.knapp( hudGruppe, { tekst = "Retry", ikon = "igjen", x = ui.HOYRE - 150, y = ui.TOPP + 104,
   bredde = 140, hoyde = 52, farge = "oransje" } )
livretry.isVisible = false

local function visRetryKnapp( event )
   if event.phase == "began" then
      livretry.isVisible = not livretry.isVisible
   end
   return true
end
livText:addEventListener( "touch", visRetryKnapp )

local function gjorRetry( event )
   if event.phase ~= "began" then
      return true
   end
   livretry.isVisible = false
   -- Nøyaktig samme rekkefølge som retry-knappen i pausemenu1.lua, se
   -- forklaringene der: avbryt ventende transitions og den forsinkede
   -- knekk-timeren først (ellers kan de fyre av mot en bane som er revet
   -- ned), stopp fysikken så marken ikke fortsetter å bevege seg under
   -- overgangen, trekk livet, og gå via mellomscenen "gotoretry" (eller
   -- reklame-for-liv-skjermen om livene er brukt opp).
   transition.cancel()
   if _G.eventTimer ~= nil then
      timer.cancel( _G.eventTimer )
      _G.eventTimer = nil
   end
   physics.pause()
   liv.endreliv( 1 )
   liv.lagreliv()
   local target = "scenes.gotoretry"
   if liv.erTom() then
      target = "scenes.adoffer"
   end
   local ok, err = pcall( composer.gotoScene, target, {effect = "fade" , time = 500} )
   if not ok then
      print( "CRASH going to " .. tostring(target) .. " (retry fra livene): " .. tostring(err) )
   end
   return true
end
livretry:addEventListener( "touch", gjorRetry )
end
-------------------------------------------------------------------------





-----------------------------
-- PUBLIC FUNCTIONS
-----------------------------

-- Nullstiller liv til startverdien (10). Brukt når spilleren velger å
-- starte helt på nytt fra bane 1 i stedet for å se reklame
-- (scenes/adoffer.lua sin "fortsett uten"-knapp) etter å ha gått tom.
-- Var en tom stub før, per Mathias 2026-09-15: å starte på nytt bør gi
-- fulle liv igjen.
function liv.new()
   liv_igjen = STARTLIV
end

-- *** NOTE ***
-- save() and load() doesn't check if the file exists!
function liv.lagreliv()
    lagreliv()
end

function liv.lastliv()
    lastliv()
end

-- Trekker fra liv, og lar telleren faktisk nå null (rettet 2026-09-10,
-- den gjorde før det motsatte: la til 2 liv i stedet for å trekke fra
-- ved siste liv, så man kunne aldri tape). Klipper ved 0 i stedet for
-- å gå negativ, se liv.erTom() rett under.
function liv.endreliv( val )
   liv_igjen = liv_igjen - val
   if liv_igjen < 0 then
      liv_igjen = 0
   end
   return true
end

-- Sant når spilleren er tom for liv. Brukes til å vise
-- "se reklame for å få liv tilbake"-skjermen (scenes/adoffer.lua,
-- kort reklame = 1 liv, lang reklame = 3, per Ørjan). Reklamen der er
-- fortsatt en placeholder (ikke koblet til noe ekte SDK ennå).
function liv.erTom()
   return liv_igjen <= 0
end

-- Legger til liv, brukt av reklame-for-liv-skjermen (scenes/adoffer.lua)
-- når spilleren er tom for liv. Var en tom stub før (kommentert ut),
-- fylt inn 2026-09-15 siden akkurat dette hooket allerede fantes med
-- riktig navn og var ment for nettopp dette, ifølge kommentaren ved
-- liv.erTom() over.
function liv.addToScore( val )
   liv_igjen = liv_igjen + val
end

function liv.returnScore()
    return liv_igjen
end 


return liv
 