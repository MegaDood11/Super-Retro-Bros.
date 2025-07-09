local smb1HUD = require("smb1HUD")
local textplus = require("textplus")
local minTimer = require("minTimer")
local blockutils = require("blocks/blockutils")

-- do not touch these values

local canMove = false -- boolean to stop the player
local canTrans = false
local hasTransitioned = false
local screenOpa = 0
local hasWon = false
local racingSection = -1

local startPositionX = {} -- automatically registers itself based on the location of the boo
local winPosition = { -- register for each section/world
	-198592, -- world 1
	-179616, -- world 2
	 -- world 3
	 -- world 4
	 -- world 5
	 -- world 6
	 -- world 7
	 -- world 8
	 -- world 9
	 -- world A
	 -- world B
	 -- world C
	 -- world D
	 -- world minus
}

local times = { -- register for each section/world
	minTimer.toTicks{hrs = 0, mins = 0, secs = 5}, -- world 1
	minTimer.toTicks{hrs = 0, mins = 0, secs = 2}, -- world 2
	 -- world 3
	 -- world 4
	 -- world 5
	 -- world 6
	 -- world 7
	 -- world 8
	 -- world 9
	 -- world A
	 -- world B
	 -- world C
	 -- world D
	 -- world minus
}

local timer1 = minTimer.create{initValue = 0} -- create a timer object
local switchBlockID = 757

function onStart()
	for _,n in ipairs(NPC.get(953)) do
		startPositionX[n.section] = n.x
	end
	triggerEvent("raceBegin")
	racingSection = player.section
end

function onEvent(eventName)
        if eventName == "raceBegin" then
                local r = Routine.run(function()
			--SFX.play("SFX/minigame_clear.ogg")
			canTrans = true
			canMove = true
		--	Audio.MusicFadeOut(0, 900)

			Routine.waitFrames(60)

			Audio.MusicChange(player.section, 0)
			SFX.play("race fanfare.mp3")
			player.x = startPositionX[player.section] 
			player.speedX = 0
			player.speedY = 0
			player.direction = 1

			Routine.waitFrames(179)

			timer1:start()
			timer1:addTime(times[player.section+1])

			canMove = false

			blockutils.setBlockFrame(switchBlockID, 1)
			Block.config[switchBlockID].passthrough = true

			for _,n in ipairs(NPC.get(953)) do
				n.speedX = (winPosition[n.section+1] - startPositionX[n.section]) / math.floor(times[n.section+1])
				n.data.state = 1
			end
   		end)
        end
end

function timer1:onStart()
	Audio.MusicChange(player.section, "Music/Race.spc|0;g=2;e0")
end

function timer1:onEnd(win)
    	if not win then -- You lose
		for _,n in ipairs(NPC.get(953)) do
			local r = Routine.run(function()
				Routine.waitFrames(24)

				n.data.state = 2
				n.speedX = 0
				n.dontMove = true
			end)

			if n.section == player.section then
				player.x = (n.x + 32)
				player.y = n.y
				player.speedX = 3
				player.speedY = -5

				SFX.play(38)
				SFX.play(41, 0.5)
			end
		end

		local r = Routine.run(function()
			Routine.waitFrames(224)

			doWinCondition = true
			doWinConditionTimer = 500
			medalOffset = -1000
		end)

		SFX.play("battleDraw.ogg")
    	else -- You win
		for _,n in ipairs(NPC.get(953)) do
			n.speedX = 0
			n.dontMove = true
			n.data.state = 0

			local r = Routine.run(function()
				Routine.waitFrames(64)

				n:kill(9)
				Effect.spawn(10, n.x, n.y)
				SFX.play(36)
			end)
		end

		local r2 = Routine.run(function()
			Routine.waitFrames(64)

			SFX.play("Music/Battle Mode Winner.spc")

			Routine.waitFrames(240)

			doWinCondition = true

			if not SaveData[tostring(player.section)] then
				SFX.play("Music/Golden Coin.spc")
				hasWon = true
				doWinConditionTimer = 0
				medalOffset = 0
				Misc.pause()
			else
				doWinConditionTimer = 500
				medalOffset = -1000
			end
		end)

		canMove = true
	end

	Audio.MusicChange(player.section, 0)
end

local worldNums = {1, 2, 3, 4, 5, 6, 7, 8, 9, "A", "B", "C", "D", ""}

function onTick()
	smb1HUD.currentWorld = vector(worldNums[player.section+1], "R")

	if player.x >= winPosition[racingSection+1] then
		timer1:close(minTimer.WIN_CLEAR, true) 
	end

	if canMove then
		for k,v in pairs(player.keys) do
			player.keys[k] = false
		end
	end
end

local gfx = Graphics.loadImageResolved("minusMedal.png")

local fakeHUD 
local h1 = Graphics.loadImageResolved("medalHUD.png")
local h2 = Graphics.loadImageResolved("medalHUDClaimed.png")

--IMPORTANT LINE
--When referring to unlocking the minus world, this is what's used to track how many medals are collected.

SaveData.minusMedals = SaveData.minusMedals or 0

function onDraw()
	if doWinCondition then
		
		doWinConditionTimer = doWinConditionTimer + 1
		
		if doWinConditionTimer <= 130 then medalOffset = medalOffset - 1 end
		
		medal = medal or Sprite{texture = gfx, frames = 2}
		medal.position = vector(player.x + (player.width / 2) - (gfx.width / 2), player.y + player.height / 2 + medalOffset)
		medal:draw{sceneCoords = true, frame = math.floor(doWinConditionTimer / 8) % 2 + 1, priority = -45}

		if doWinConditionTimer >= 130 then
			textplus.print{
        			x = player.x + (player.width * 0.5),
        			y = player.y + medalOffset - 180,
				sceneCoords = true,
       				xscale = 2,
        			yscale = 2,
        			text = "you got a minus medal!",
				font = textplus.loadFont("textplus/font/smb1-c.ini"),
        			pivot = {0.5, 0},
        			maxWidth = 400,
				color = Color.white,
        			priority = 5,
    			}

			-- outlines lol

			textplus.print{
        			x = player.x + (player.width * 0.5) - 2,
        			y = player.y + medalOffset - 180 - 2,
				sceneCoords = true,
       				xscale = 2,
        			yscale = 2,
        			text = "you got a minus medal!",
				font = textplus.loadFont("textplus/font/smb1-c.ini"),
        			pivot = {0.5, 0},
        			maxWidth = 400,
				color = Color.black,
        			priority = 4,
    			}
			textplus.print{
        			x = player.x + (player.width * 0.5) - 2,
        			y = player.y + medalOffset - 180 + 2,
				sceneCoords = true,
       				xscale = 2,
        			yscale = 2,
        			text = "you got a minus medal!",
				font = textplus.loadFont("textplus/font/smb1-c.ini"),
        			pivot = {0.5, 0},
        			maxWidth = 400,
				color = Color.black,
        			priority = 4,
    			}
			textplus.print{
        			x = player.x + (player.width * 0.5) + 2,
        			y = player.y + medalOffset - 180 - 2,
				sceneCoords = true,
       				xscale = 2,
        			yscale = 2,
        			text = "you got a minus medal!",
				font = textplus.loadFont("textplus/font/smb1-c.ini"),
        			pivot = {0.5, 0},
        			maxWidth = 400,
				color = Color.black,
        			priority = 4,
    			}
			textplus.print{
        			x = player.x + (player.width * 0.5) + 2,
        			y = player.y + medalOffset - 180 + 2,
				sceneCoords = true,
       				xscale = 2,
        			yscale = 2,
        			text = "you got a minus medal!",
				font = textplus.loadFont("textplus/font/smb1-c.ini"),
        			pivot = {0.5, 0},
        			maxWidth = 400,
				color = Color.black,
        			priority = 4,
    			}

			-- shadows

			textplus.print{
        			x = player.x + (player.width * 0.5) + 8,
        			y = player.y + medalOffset - 180 + 14,
				sceneCoords = true,
       				xscale = 2,
        			yscale = 2,
        			text = "you got a minus medal!",
				font = textplus.loadFont("textplus/font/smb1-c.ini"),
        			pivot = {0.5, 0},
        			maxWidth = 400,
				color = Color.black * 0.5,
        			priority = 3,
    			}
		end
		
		if doWinConditionTimer >= 460 then
			doWinCondition = nil
			doWinConditionTimer = 0

			Misc.unpause()
			canMove = false

			Audio.MusicChange(player.section, "Music/Album.spc|0;g=2;e0")
			
			if hasWon then
				if not SaveData[tostring(player.section)] then
					SaveData[tostring(player.section)] = true
					SaveData.minusMedals = SaveData.minusMedals + 1
					hasWon = false
				end
			end
		end
	end

	-- Fade into the race

	if canTrans then
		--[[if not hasTransitioned then
			screenOpa = math.min(1, screenOpa + 0.01666)
			if screenOpa >= 1 then
				hasTransitioned = true
			end
		else]]
			screenOpa = math.max(0, screenOpa - 0.025)
			if screenOpa <= 0 then
				hasTransitioned = false
				canTrans = false
			end
		--end
	end

	if screenOpa > 0 then
		Graphics.drawScreen{priority = 4, color = Color.black .. screenOpa}
	end

	-- HUD

	if SaveData[tostring(player.section)] then
		fakeHUD = h1
	else
		fakeHUD = h2
	end

	if fakeHUD then
		Graphics.drawBox{
			texture = fakeHUD,
			x = 6,
			y = 404,
			priority = 5
		}
	end

	 textplus.print{
        	x = 54,
        	y = 408,
       		xscale = 2,
        	yscale = 2,
        	text = tostring(SaveData.minusMedals),
		font = textplus.loadFont("timerFont.ini"),
        	pivot = {0, 0},
        	maxWidth = 432,
		color = Color.white,
        	priority = 5,
    	}
end