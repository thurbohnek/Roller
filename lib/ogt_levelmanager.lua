--[[ ==========================================

	** Change settings in the ogt_lmdata.lua 
	file, not this file! **
	
  Outlaw Game Tools Level Manager (OGTLM) v1.3
  Copyright 2013-2014 Three Ring Ranch
  See more at http://OutlawGameTools.com
  
  This source code may be used in both free and
  commercial projects, but the code itself may 
  not be given away or sold.
  
  In other words, sell or give away the projects
  you create with this code, as long the raw
  source of this file isn't included.

--===========================================]]
local composer = require( "composer" )

local scene = composer.newScene()

local k = require("lib.ogt_lmdata") -- tweak the variables in this file!
-- Lagt til 2026-09-15, per Mathias: kunne før velge og starte en bane
-- rett fra banevalget selv med 0 liv igjen, uten at
-- reklame-for-liv-skjermen (scenes/adoffer.lua) noen gang ble vist -
-- liv ble bare sjekket i pause-/dødsmenyen. Se selectLevel() under.
local liv = require("lib.liv")

local sceneMgr = require( "composer" ) -- or use "storyboard"

local GGData = require( "lib.GGData" )

local widget = require ("widget")

widget.setTheme ( "widget_theme_ios")

--#snippet table.show

-- most commonly used screen coordinates
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
local grid = {}
local prevArrow
local nextArrow
local entryXOffset
local imgPfx = k.imagePrefix or ""
local audPfx = k.audioPrefix or ""

local selectSound
local nextPageSound
local prevPageSound

local swipeOGTLM
local bgswiper


--==============================================================
-- pass in the sound handle and play if audioOn is true.
local function playAudio(snd)
	if k.audioOn and snd then
		audio.play ( snd )
	end
end

--==============================================================
-- hide both the next/prev arrows.
local function hideArrows()
	prevArrow.isVisible = false
	nextArrow.isVisible = false
end


  local function goSomewhere (event)
        
        composer.gotoScene( "scenes.gotomenu" )
end
--==============================================================
-- show the next/prev arrows when they should be visible.
local function showArrows()
	prevArrow.isVisible = (k.currentPage ~= 1)
	nextArrow.isVisible = (k.currentPage < k.numPages)
end
	
local function slideLeft(event)
	hideArrows()
	transition.to ( grid, {time=k.slideTime, x=grid.x-screenWidth, onComplete=showArrows} )
end

local function slideRight(event)
	hideArrows()
	transition.to ( grid, {time=k.slideTime, x=grid.x+screenWidth, onComplete=showArrows} )
end

local function prevPage(event)
	if k.currentPage > 1 then
		k.currentPage = k.currentPage - 1
		slideRight()
		playAudio(prevPageSound)
	end
	return true
end

local function nextPage(event)
	if k.currentPage < k.numPages then
		k.currentPage = k.currentPage + 1
		slideLeft()
		playAudio(nextPageSound)
	end
	return true
end




function k.beforeLeaving ()
print("hei")

local sheetData =  { width = 1200 , height= 540, count = 6 , numFrames = 6, sheetContentWidth = 3600, sheetContentHeight = 1080 }
    local spriteSheet = graphics.newImageSheet("last.png" , sheetData)
 
    local sequenceData = { 
    {name = "lastlast", start = 1,  count=6, time=500, loopCount = 0 }
    }       
    last = display.newSprite (spriteSheet, sequenceData)
	last.xScale = 1.5
    last.yScale = 1.5
    last.x = bredde/2
    last.y = hoyde/2
    last:setSequence("lastlast")
	last:play()
	-- last fjernes i selectLevel() sin goto(), rett før faktisk scenebytte.
end






local function selectLevel(event)
	-- Lagt til 2026-09-15: sjekk liv FØR banen i det hele tatt startes,
	-- se forklaringen ved "local liv = require(...)" øverst i fila.
	-- liv.lastliv() må kalles her (ikke bare stole på den siste verdien
	-- fra denne økten): selve banene laster liv fra fil i sin egen
	-- scene:create, men banevalget kan nås FØR noen bane noensinne er
	-- åpnet denne økten (rett etter appstart), da har liv-modulen bare
	-- sin hardkodede standardverdi (10) i minnet ennå, ikke den faktiske
	-- lagrede verdien.
	-- Hvilken bane spilleren faktisk valgte må settes FØR liv-sjekken
	-- under. Rettet 2026-09-15: reklame-/kjøpsskjermen sender spilleren
	-- videre via "gotoretry", som starter k.currentLevel. Siden denne
	-- sjekken returnerte før tilordningen lenger nede, sto k.currentLevel
	-- fortsatt på forrige spilte bane, eller på startverdien 0 (se
	-- ogt_lmdata.lua) om ingen bane var spilt siden appstart. Da endte
	-- kjøpet i "scenes.level0", som ikke finnes. Nå havner spilleren i
	-- banen hen trykket på.
	k.currentLevel = event.target.levelNum
	k.displayText = event.target.displayText

	liv.lastliv()
	if liv.erTom() then
		local ok, err = pcall( sceneMgr.gotoScene, "scenes.adoffer", {effect=k.sboardEffect, time=k.sboardTime} )
		if not ok then
			local msg = "Checkpoint: " .. tostring(_G.LAST_CHECKPOINT) .. "\n" .. tostring(err)
			print( "CRASH going to adoffer (selectLevel, 0 liv): " .. msg )
			local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth - 20, display.contentHeight - 20 )
			bg:setFillColor( 0, 0, 0, 0.85 )
			local t = display.newText( { text = msg, x = display.contentCenterX, y = display.contentCenterY, width = display.contentWidth - 40, font = native.systemFont, fontSize = 14, align = "left" } )
			t:setFillColor( 1, 0.3, 0.3 )
		end
		return true
	end
	-- save the current page so we can come back to that later
	if k.rememberPage then
		local levelInfo  = GGData:new( k.dataFile )
		levelInfo.currentPage = k.currentPage
		levelInfo:save()
	end
	playAudio(selectSound)
	local newScene = k.playScene or k.sequentialScene .. tostring(k.currentLevel)
	if k.sceneNames and k.sceneNames[levelNum] then
		newScene = k.sceneNames[levelNum]
	end
	 function goto()
		print("no")

		if last then
			-- Fjern splash-spriten fra k.beforeLeaving() her, rett før
			-- selve scenebyttet. Ble før aldri fjernet (kommentert bort),
			-- så hvert banevalg la igjen ett objekt til (rettet 2026-09-10).
			display.remove( last )
			last = nil
		end

		-- pcall lagt til 2026-09-10, samme sikkerhetsnett som resten av
		-- navigasjonen i spillet: fanger krasj her og viser en rød
		-- feilboks med sjekkpunkt, i stedet for at hele siden bare dør.
		local ok, err = pcall( sceneMgr.gotoScene, newScene, {effect=k.sboardEffect, time=k.sboardTime} )
		if not ok then
			local msg = "Checkpoint: " .. tostring(_G.LAST_CHECKPOINT) .. "\n" .. tostring(err)
			print( "CRASH going to " .. tostring(newScene) .. " (selectLevel): " .. msg )
			local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth - 20, display.contentHeight - 20 )
			bg:setFillColor( 0, 0, 0, 0.85 )
			local t = display.newText( { text = msg, x = display.contentCenterX, y = display.contentCenterY, width = display.contentWidth - 40, font = native.systemFont, fontSize = 14, align = "left" } )
			t:setFillColor( 1, 0.3, 0.3 )
		end

	end

	if k.swipe then
		--print("Killing swipeOGTLM inside selectLevel")
		bgswiper:removeEventListener("touch", swipeOGTLM)
	end

	-- is there something we need to do before switching scenes?
	if k.beforeLeaving then

		k.beforeLeaving()
	end
		--timer.performWithDelay( 5000, k.beforeLeaving())
	-- give the user visual feedback that the level was touched

	event.target.alpha = 0
	--tile:removeEventListener("tap", selectLevel)
	
	transition.to(event.target, {time = 1000, xScale = 1, yScale=1, onComplete=goto})
	
	--timer.performWithDelay( 5000, goto())
	return true
	
end


local bDoingTouch
local mAbs = math.abs
local xDistance
local yDistance
local totalSwipeDistanceLeft
local beginX
local beginY

local function checkSwipeDirection()
	if bDoingTouch == true then
		local dir = "none"
		xDistance =  mAbs(endX - beginX) -- abs will return the absolute, or non-negative value, of a given value. 
		yDistance =  mAbs(endY - beginY)
		if xDistance > yDistance then
			if beginX > endX then
				totalSwipeDistanceLeft = beginX - endX
				if totalSwipeDistanceLeft > k.minSwipeDistance then
					dir = "left"
				end
			else 
				totalSwipeDistanceRight = endX - beginX
				if totalSwipeDistanceRight > k.minSwipeDistance then
					dir = "right"
				end
			end
		else 
			if beginY > endY then
				totalSwipeDistanceUp = beginY - endY
				if totalSwipeDistanceUp > k.minSwipeDistance then
					dir = "up"
				end
			else 
				totalSwipeDistanceDown = endY - beginY
				if totalSwipeDistanceDown > k.minSwipeDistance then
					dir = "down"
				end
			end
		end
		return dir
	end
end


function swipeOGTLM(event)
	if event.phase == "began" then
		bDoingTouch = true
		beginX = event.x
		beginY = event.y
	end
	if event.phase == "ended" then
		endX = event.x
		endY = event.y
		--print("endX, endY" , endX, endY)
		--if profSprite.busy == false then
			local dir = checkSwipeDirection()
			if dir == "none" then
				-- what about a tap?
				
			else
				--print("dir", dir)
				--moveProf( dir )
				if dir == "left" then
					nextPage()
				elseif dir == "right" then
					prevPage()
				end
			end
			bDoingTouch = false
		--end
	end
end


--==============================================================
-- get all the saved data and init if this is the first time.
local function loadData()
	local levelInfo  = GGData:new( k.dataFile )

	if k.rememberPage then
		k.currentPage = levelInfo.currentPage or 1
	end
	levelInfo.currentPage = k.currentPage
	
	k.userName = levelInfo.userName or "UserName"
	levelInfo.userName = k.userName
	
	k.audioOn = levelInfo.audioOn or true
	levelInfo.audioOn = k.audioOn
	if k.selectSoundFile then
		selectSound = audio.loadSound ( audPfx .. k.selectSoundFile )
	end
	if k.nextPageSoundFile then
		nextPageSound = audio.loadSound ( audPfx .. k.nextPageSoundFile )
	end
	if k.prevPageSoundFile then
		prevPageSound = audio.loadSound ( audPfx .. k.prevPageSoundFile )
	end
	
	if levelInfo.locked == nil then
		--print ( k.numUnlocked )
		for x = 1, k.totalLevels do
			local locked = false
			if x > k.numUnlocked then
				locked = true
			end
			k.levelLocked[x] = locked
		end
	else
		k.levelLocked = levelInfo.locked
		--if we now have more levels than before, increase lock table
		if #k.levelLocked < k.totalLevels then
			for x = #k.levelLocked+1, k.totalLevels do
				k.levelLocked[x] = 0
			end			
		end
	end

	-- TEMP for debugging: force every level unlocked regardless of any
	-- saved progress from before this was added, so old saves in the
	-- browser can't override it. Remove once done testing.
	for x = 1, k.totalLevels do k.levelLocked[x] = false end

	levelInfo.locked = k.levelLocked

	if levelInfo.starsOnLevel == nil then
		for x = 1, k.totalLevels do
			k.starsOnLevel[x] = 0
		end
	else
		k.starsOnLevel = levelInfo.starsOnLevel
		--if we now have more levels than before, increase star table
		if #k.starsOnLevel < k.totalLevels then
			for x = #k.starsOnLevel+1, k.totalLevels do
				k.starsOnLevel[x] = 0
			end			
		end
	end
	levelInfo.starsOnLevel = k.starsOnLevel

	if levelInfo.levelScores == nil then
		for x = 1, k.totalLevels do
			k.levelScores[x] = 0
		end
	else
		k.levelScores = levelInfo.levelScores
		--if we now have more levels than before, increase score table
		if #k.levelScores < k.totalLevels then
			for x = #k.levelScores+1, k.totalLevels do
				k.levelScores[x] = 0
			end			
		end
	end
	levelInfo.levelScores = k.levelScores
	
	levelInfo:save()
end

local function getImageSize(img)
	-- get the width and height of a specific image
	-- useful for inside display.newImageRect
	local width = 0
	local height = 0
	local tile = display.newImage(img)
	if tile then
		width = tile.width
		height = tile.height
		display.remove( tile )
	end
	return width,height
end

function k.init(grp, pageNum)
	-- pass in the group from sb scene file
	-- optionally pass in specific page to display

	if k.swipe then
		bgswiper = display.newRect( grp, screenLeft, screenTop, screenWidth, screenHeight )
		bgswiper.x = centerX
		bgswiper.y = centerY
		bgswiper.alpha = .01
		--print("STARTINGSWIPER")
		bgswiper:addEventListener("touch", swipeOGTLM)
	end
	
	--print("INSIDE ogt_levelmanager:init")
	loadData()
	checkpoint("ogt_lm:init_after_loadData")

	if pageNum then k.currentPage = pageNum end
	
	if k.backgroundImage then
		local bgWidth, bgHeight = getImageSize(imgPfx .. k.backgroundImage)
		local bg = display.newImageRect ( imgPfx .. k.backgroundImage, bgWidth, bgHeight )
		bg.x = centerX
		bg.y = centerY
		bg.width=screenWidth
		bg.height=screenHeight
		if grp then
			grp:insert(bg)
		end
	end
	
	-- grab the size of things for later use
	if k.levelSquareImage then k.tileWidth, k.tileHeight = getImageSize(imgPfx .. k.levelSquareImage) end
	if k.starImage then k.starWidth, k.starHeight = getImageSize(imgPfx .. tostring(k.starImage)) end
	if k.lockImage then k.lockWidth, k.lockHeight = getImageSize(imgPfx .. tostring(k.lockImage)) end
	if k.prevImage then k.prevWidth, k.prevHeight = getImageSize(imgPfx .. tostring(k.prevImage)) end
	if k.nextImage then k.nextWidth, k.nextHeight = getImageSize(imgPfx .. tostring(k.nextImage)) end
	checkpoint("ogt_lm:init_after_imagesizes")

	grid = k.makeGrid()
	checkpoint("ogt_lm:init_after_makeGrid")

	if grp then
		grp:insert(grid)
	end

	--put in next/prev arrows
	if k.nextImage then
		prevArrow = display.newImageRect ( grp, imgPfx .. k.prevImage, k.prevWidth, k.prevHeight )
		prevArrow.x = screenLeft + (k.prevWidth/2) + k.prevOffsetX
		prevArrow.y = centerY + k.prevOffsetY
		prevArrow:addEventListener("tap", prevPage)
		
		nextArrow = display.newImageRect ( grp, imgPfx .. k.nextImage, k.nextWidth, k.nextHeight )
		nextArrow.x = screenRight - (k.nextWidth/2) + k.nextOffsetX
		nextArrow.y = centerY + k.nextOffsetY
		nextArrow:addEventListener("tap", nextPage)

		showArrows()
	end
	
end


     



function k.makeGrid(pageNum)
	--========================================
	-- grid code
	--========================================
	-- returns a display group holding all the goodies
	
	local tmpGrid = display.newGroup ( )
	
	local currPage = pageNum or k.currentPage
	
	local xPos
	local yPos
	local levelNum = 0



     local tilbake = display.newImageRect( tmpGrid, "tilbake.png", 200, 150 )
     tilbake.x = bredde-bredde+(tilbake.width/2)
     tilbake.y = 80
      tilbake:addEventListener( "tap", goSomewhere )
checkpoint("ogt_lm:makeGrid_after_tilbake")


	for page = 1, k.numPages do
		xPos = (centerX + ((page-1) * screenWidth) + k.gridOffsetX) - (k.numCols * k.tileWidth + k.numCols * k.colSpace) / 2
		yPos = (centerY + k.gridOffsetY) - (k.numRows * k.tileHeight + k.numRows * k.rowSpace) / 2
		for row = 1, k.numRows do
			for col = 1, k.numCols do
				levelNum = levelNum + 1
				if levelNum <= k.totalLevels then
					local tile
					if k.customLevel then
						tile = k.customLevel(levelNum)
						tmpGrid:insert(tile)
					else
						tile = display.newImageRect(tmpGrid, imgPfx .. k.levelSquareImage, k.tileWidth, k.tileHeight)
					end
					tile.x = xPos + (col * (k.tileWidth + k.colSpace) - k.tileWidth/2 - k.colSpace/2)
					tile.y = yPos + row * (k.tileHeight + k.rowSpace) - k.tileHeight/2 - k.rowSpace/2
					tile.gridPos = {x=col, y=row}
					tile.levelNum = levelNum



					local levelNumText
					local dispText = tostring(levelNum)
					if k.showLevelNum then
						--print("k.levelLocked[levelNum]", k.levelLocked[levelNum])
						if not k.levelLocked[levelNum] or (k.levelLocked[levelNum] and k.showLevelNumTextWhenLocked) then	
							if k.tileNums and k.tileNums[levelNum] then
								dispText = k.tileNums[levelNum]
							end
							if k.levelNumEmbossedFont then
								levelNumText = display.newEmbossedText(tmpGrid, dispText, tile.x, tile.y, k.levelNumFontName, k.levelNumFontSize )
							else
								levelNumText = display.newText(tmpGrid, dispText, tile.x, tile.y, k.levelNumFontName, k.levelNumFontSize )
							end
							levelNumText.x = levelNumText.x + k.levelNumTextXOffset
							levelNumText.y = levelNumText.y + k.levelNumTextYOffset
							levelNumText:setFillColor(k.levelNumFontColor[1], k.levelNumFontColor[2], k.levelNumFontColor[3])
						 end
					end
					tile.displayText = dispText
					
					-- do we need a lock on here?
					if k.levelLocked[levelNum] and k.lockImage then
						local lock = display.newImageRect ( tmpGrid, imgPfx .. k.lockImage, k.lockWidth, k.lockHeight )
						lock.x = tile.x + k.lockOffsetX
						lock.y = tile.y + k.lockOffsetY
					end
							
					-- do we need stars on the level?
					if k.starImage and not k.levelLocked[levelNum] then
						if levelNum == 31 then
							--print(table.show(k.starsOnLevel))
						end
						--print(levelNum, #k.starsOnLevel, k.starsOnLevel[levelNum])

						for i = 1, k.maxStars do
							local starX = (tile.x - tile.width/2) + (i * (tile.width/(k.maxStars+1)))
							local star = display.newImageRect(tmpGrid, imgPfx .. k.starImage, k.starWidth, k.starHeight)
							star.x = starX + k.starOffsetX + (k.singleStarOffsetX[i] or 0)
							star.y = tile.y + tile.height/2 - star.height/2 + k.starOffsetY + (k.singleStarOffsetY[i] or 0)
							if i > k.starsOnLevel[levelNum] and k.showMissingStar then
								star.alpha = .3
							elseif i > k.starsOnLevel[levelNum] and not k.showMissingStar then
								star.alpha = 0
							end
						end
					end
					
					-- should we show a score for the level?
					local scoreText
					if k.showScore and (not k.levelLocked[levelNum] or (k.levelLocked[levelNum] and k.showScoreWhenLocked)) then	
						local scoreT = k.getLevelScore(levelNum)
						scoreT = (k.scorePrefix or "") .. scoreT .. (k.scoreSuffix or "")
						if k.scoreEmbossedFont then
							scoreText = display.newEmbossedText(tmpGrid, scoreT, tile.x, tile.y, k.scoreFontName, k.scoreFontSize )
						else
							scoreText = display.newText(tmpGrid, scoreT, tile.x, tile.y, k.scoreFontName, k.scoreFontSize )
						end
						scoreText.x = tile.x + k.scoreTextXOffset
						scoreText.y = tile.y + tile.height/2 + scoreText.height/2 + k.scoreTextYOffset
						scoreText:setFillColor(k.scoreFontColor[1], k.scoreFontColor[2], k.scoreFontColor[3])
					 end
					
					
					if not k.levelLocked[levelNum] then
						-- since level is unlocked, make it clickable
						
					--unction kantrokk( event )
						--	print( "1" )
						tile:addEventListener("tap", selectLevel)	
						--print( "2" )		
						--end

						
						--timer.performWithDelay( 3000, kantrokk )
					end

				end
			end
		end
	end
	checkpoint("ogt_lm:makeGrid_after_tile_loop")
	-- see if we need to start on page 1 or page we last came from.
	if k.rememberPage then
		tmpGrid.x = tmpGrid.x - ((k.currentPage - 1) * screenWidth)
	end




	return tmpGrid
end



--==============================================================
-- should the audio clicks play or not?
-- onOrOff - boolean true or false (true = audio plays)
function k.updateAudio(onOrOff)
	local levelInfo = GGData:new( k.dataFile )
	levelInfo.audioOn = onOrOff or true
	levelInfo:save()
end

--==============================================================
-- save the score for a given level
-- score - the score to be saved
-- lvl - the level for the score, or k.currentLevel is left blank.
function k.updateScore(score, lvl)
	local levelNum = lvl or k.currentLevel
	local levelInfo = GGData:new( k.dataFile )
	levelInfo.levelScores[levelNum] = score
	levelInfo:save()
end

--==============================================================
-- returns the score saved for the level passed in, 
-- or k.currentLevel.
function k.getLevelScore(lvl)
	local levelNum = lvl or k.currentLevel
	local levelInfo = GGData:new( k.dataFile )
	local score = levelInfo.levelScores[levelNum]
	return score
end

--==============================================================
-- returns the username for the dataFile passed in, 
-- or k.dataFile if left blank
function k.getUserName(dataFile)
	local dFile = dataFile or k.dataFile
	local levelInfo = GGData:new( dFile )
	local userName = levelInfo.userName
	return userName
end

--==============================================================
-- save userName to dataFile or k.dataFile if left blank.
function k.updateUserName(uname, dataFile)
	local dFile = dataFile or k.dataFile
	local levelInfo = GGData:new( dFile )
	levelInfo.userName = uname
	levelInfo:save()
end

--==============================================================
-- save numStars to lvl or k.currentLevel if left blank.
function k.updateStars(numStars, lvl)
	local levelNum = lvl or k.currentLevel
	local levelInfo = GGData:new( k.dataFile )
	levelInfo.starsOnLevel[levelNum] = numStars
	levelInfo:save()
end

function k.getLevelStars(lvl)
	local levelNum = lvl or k.currentLevel
	local levelInfo = GGData:new( k.dataFile )
	local numStars = levelInfo.starsOnLevel[levelNum]
	return numStars
end

--==============================================================
-- lock is true or false, whether the level lvl is locked or not.
function k.updateLock(lock, lvl)
	local levelNum = lvl or k.currentLevel+1
	local lock = lock or false
	--print("levelNum", levelNum)
	if levelNum > 0 and levelNum <= k.totalLevels then
		local levelInfo = GGData:new( k.dataFile )
		-- Rettet 2026-10-28: locked ble bare laget av det gamle banevalget
		-- (loadData), så en ny spiller fikk krasj her ved første mål.
		levelInfo.locked = levelInfo.locked or {}
		levelInfo.locked[levelNum] = lock
		levelInfo:save()
	end
end
-- just a shortcut that can be used to call the previous function.
function k.unlockNextLevel()
	-- Lagt til 2026-10-28: banene kaller denne når målet nås, så her
	-- registreres også at banen er fullført (lib/framgang.lua).
	require( "lib.framgang" ).fullfor( k.currentLevel )
	k.updateLock()
end

-- is the specified level locked?
function k.getLockStatus(lvl)
	local levelNum = lvl or k.currentLevel
	local levelInfo = GGData:new( k.dataFile )
	local locked = levelInfo.locked[levelNum]
	return locked
end


--==============================================================
-- pass in a level (or use k.currentLevel) and get back a
-- boolean to let you know whether there's a next level.
function k.anotherLevel(currLvl)
	local levelNum = currLvl or k.currentLevel
	return levelNum+1 <= k.totalLevels
end

--==============================================================
-- pass in a level number (or use k.currentLevel) and the next level
-- will be loaded and started. works on sequential and named levels only.
function k.loadNextLevel(currLvl)
	local levelNum = currLvl or k.currentLevel
	local success = false
	if k.anotherLevel(levelNum) then
		success = true
		k.currentLevel = levelNum + 1
		local newScene = k.playScene or k.sequentialScene .. tostring(k.currentLevel)
		if k.sceneNames and k.sceneNames[levelNum] then
			newScene = k.sceneNames[levelNum]
		end
		sceneMgr.gotoScene ( newScene, {effect=k.sboardEffect, time=k.sboardTime} )
	end
end


--==============================================================
-- lock all levels except k.numUnlocked and change all stars to 0.
-- also resets all scores to 0. Doesn't touch username.
-- you'd do this if you wanted to reset everything back to "new".

function k.resetLevels(dataFile)
	local dFile = dataFile or k.dataFile
	local levelInfo  = GGData:new( dFile )

	for x = 1, k.totalLevels do
		local locked = false
		if x > k.numUnlocked then
			locked = true
		end
		k.levelLocked[x] = locked
	end
	levelInfo.locked = k.levelLocked

	for x = 1, k.totalLevels do
		k.starsOnLevel[x] = 0
	end
	levelInfo.starsOnLevel = k.starsOnLevel

	for x = 1, k.totalLevels do
		k.levelScores[x] = 0
	end
	levelInfo.levelScores = k.levelScores
	
	levelInfo:save()
end

return k

--[[ =========================================
Update History

To-Do List (maybe)
Allow image-based level numbers instead of just font-based.
Little dots at the bottom to show which page is active.

v1.3
Refactored code to make swiping more reliable.

v1.2
Changed swipe() to swipeOGTLM() to guard against collisions.
Comment changes to refer to Composer rather than Storyboard.

v1.1
Fixed swipe code -- listener wasn't being removed after level selected.

v1.0
k.beforeLeaving is the name of function to call after choosing level but before going there.

v0.6
Removed debug code that was accidentally left in the last version.

v0.5
Broke game data out into separate file: ogt_lmdata.lua for easier updating.
Tweaked the code so it works with Composer or Storyboard.
Added k.singleStarOffsetX and k.singleStarOffsetY tables for star tweaking.
Added boolean k.showMissingStar to show (or not) shadow of missing stars.
Now you can swipe left or right on the screen to page.
Fixed showing level name/number underneath lock.
Fixed dev problem when you'd increase number of levels.
	
v0.4
k.loadNextLevel() fixed to allow named scenes
Misc tweaks to shorten code, etc.
Added k.updateUserName(uname, dataFile)
Added k.getUserName(dataFile)
Added k.getLockStatus(lvl)
New parameter for k.resetLevels(dataFile)

--==========================================]]
