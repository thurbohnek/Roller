-- Marken med samme fysikk som i banene (lagt til 2026-09-28), til
-- minispillene.
--
-- Bygget likt som i banefilene (level1-9.lua, rundt "local del1 ="): ni
-- deler (hale.png, sju del1.png, hode.png) med samme former, tetthet og
-- friksjon, åtte "pivot"-ledd med motor (+30, maks 500, grenser 0-38
-- grader) og "punkt" sveiset til midtdelen. Styringen er den samme som
-- trykk_knapp i banene:
--   trykk (began)  -> motorene snur (-50 / -130), marken strekker seg ut
--   slipp (ended)  -> motorene tilbake til +30, marken krøller seg til en ring
--   dobbelttrykk   -> motorene av, marken er slapp
--   ett trykk når slapp -> stram igjen
-- Knekk-systemet (knottene) er ikke med, så marken knekker ikke i
-- minispillene.
--
-- Bruk:
--     local markfysikk = require( "lib.markfysikk" )
--     local mark = markfysikk.lag( verden, x, y )
--     mark:trykk() / mark:slipp()     -- fra en touch-lytter
--     mark:senter()                   -- sentrum av marken, til kamera og måling
--     mark:fjern()

local physics = require( "physics" )
local physicsData = ( require "lib.shapedefs5" ).physicsData( 1.0 )

local M = {}

M.DOBBELTKLIKK = 300 -- ms, som dobbeltklikkVindu i banene

local oppgradering = require( "lib.oppgradering" )
local drakt = oppgradering.drakt

function M.lag( forelder, x, y )
	local mark = { deler = {}, ledd = {} }

	local function del( bilde, b, h, dx, dy )
		local d = display.newImageRect( forelder, bilde, b, h )
		d.x, d.y = x + dx, y + dy
		return d
	end

	local del1 = del( drakt( "hale.png" ), 55, 35, 0, 0 )
	del1.width, del1.height = 27, 17
	physics.addBody( del1, "dynamic", { density = 1.0, friction = 0.3, bounce = 0.2,
		shape = { -13, 8, -13, -8, 11, 3, 14, 0, 11, -3 } } )
	mark.deler[1] = del1
	for i = 2, 8 do
		local d = del( drakt( "del1.png" ), 34, 17, -27 * ( i - 1 ), 0 )
		physics.addBody( d, "dynamic", physicsData:get( "del1" ) )
		mark.deler[i] = d
	end
	local del9 = del( drakt( "hode.png" ), 30, 25, -217, 2 )
	physics.addBody( del9, "dynamic", { density = 1.0, friction = 1.3, bounce = 0.2,
		shape = { -15, -5, -12, -10, -10, -10, 0, -9, 14, -11, 0, -11, 14, 6, -12, 4 } } )
	mark.deler[9] = del9
	for _, d in ipairs( mark.deler ) do d.erMark = true end
	mark.midt = mark.deler[5]
	mark.hode = del9
	oppgradering.settPaaHatt( forelder, del9 )

	local punkt = display.newRect( forelder, x - 108, y - 40, 10, 10 )
	punkt.alpha = 0
	physics.addBody( punkt, "dynamic" )
	punkt.isSensor = true
	mark.punkt = punkt

	for i = 1, 8 do
		local a = mark.deler[i]
		local j = physics.newJoint( "pivot", a, mark.deler[i + 1], a.x - 14, a.y )
		j.isMotorEnabled = true
		j.motorSpeed = 30
		j.maxMotorTorque = 500
		j.isLimitEnabled = true
		j:setRotationLimits( 0, 38 )
		mark.ledd[i] = j
	end
	mark.sveis = physics.newJoint( "weld", punkt, mark.deler[5], punkt.x + 108, mark.deler[4].y + 10 )

	local slapp = false
	local sisteBegan = 0

	-- Samme logikk som trykk_knapp i banefilene.
	function mark:trykk()
		local naa = system.getTimer()
		if slapp then
			slapp = false
		elseif ( naa - sisteBegan ) < M.DOBBELTKLIKK then
			slapp = true
		end
		sisteBegan = naa
		if slapp then
			for _, j in ipairs( mark.ledd ) do j.isMotorEnabled = false end
		else
			local forste = mark.ledd[1]
			forste.isMotorEnabled = true
			forste.motorSpeed = forste.motorSpeed - 80
			for i = 2, #mark.ledd do
				mark.ledd[i].isMotorEnabled = true
				mark.ledd[i].motorSpeed = forste.motorSpeed - 80
			end
		end
	end

	function mark:slipp()
		if slapp then return end
		for _, j in ipairs( mark.ledd ) do
			j.isMotorEnabled = true
			j.motorSpeed = 30
		end
	end

	function mark:erSlapp()
		return slapp
	end

	-- Laveste punkt (størst y) av alle delene, omtrent.
	function mark:bunn()
		local y = -math.huge
		for _, d in ipairs( mark.deler ) do
			if d.y + 9 > y then y = d.y + 9 end
		end
		return y
	end

	-- Sentrum av hele marken (snittet av delene). Når marken ruller som
	-- en ring, er dette midt i ringen og står rolig, mens hver enkelt del
	-- går rundt og rundt. Brukes av kameraet og til målinger.
	function mark:senter()
		local sx, sy, n = 0, 0, 0
		for _, d in ipairs( mark.deler ) do
			if d.x then
				sx, sy, n = sx + d.x, sy + d.y, n + 1
			end
		end
		if n == 0 then return nil end
		return sx / n, sy / n
	end

	-- Farten til marken som helhet (snittet av delene).
	function mark:fart()
		local sx, sy, n = 0, 0, 0
		for _, d in ipairs( mark.deler ) do
			if d.getLinearVelocity then
				local vx, vy = d:getLinearVelocity()
				sx, sy, n = sx + vx, sy + vy, n + 1
			end
		end
		if n == 0 then return 0, 0, 0 end
		sx, sy = sx / n, sy / n
		return math.sqrt( sx * sx + sy * sy ), sx, sy
	end

	function mark:fjern()
		for _, j in ipairs( mark.ledd ) do
			if j.removeSelf then j:removeSelf() end
		end
		if mark.sveis and mark.sveis.removeSelf then mark.sveis:removeSelf() end
		for _, d in ipairs( mark.deler ) do display.remove( d ) end
		display.remove( punkt )
		mark.deler, mark.ledd = {}, {}
	end

	return mark
end

return M
