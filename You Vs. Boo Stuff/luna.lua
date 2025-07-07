local smb1HUD = require("smb1HUD")
smb1HUD.currentWorld = vector(1,"???")

--To set up:

-- Change the world number like normal
-- Set "timer1" to be any time you want
-- Change the x coord to cross on the first line under "function onTick()"
-- Change the boo's speed config, try and get it to cross the finish line just as the timer ends for the best results
-- Place the boo npc anywhere you want in the level, recommended to be on the first screen as the player


local minTimer = require("minTimer") -- load the library
local timer1 = minTimer.create{initValue = minTimer.toTicks{hrs = 0, mins = 0, secs = 5}} -- create a timer object

local canMove = true -- boolean to stop the player
local moveTimer = 0  -- timer to release the player

function onStart()
local r = Routine.run(function()
	Routine.waitFrames(64)
		timer1:start()
		canMove = false
		for _,n in ipairs(NPC.get(953)) do
			n.speedX = NPC.config[n.id].speed * n.direction
			n.data.state = 1
		end
   end)
end

function timer1:onEnd(win)
    if not win then
        player:kill()
		for _,n in ipairs(NPC.get(953)) do
			n.data.state = 2
			n.speedX = 0
			n.dontMove = true
		end
    else
		for _,n in ipairs(NPC.get(953)) do
			n.speedX = 0
			n.dontMove = true
			n.data.state = 0
			local r = Routine.run(function()
				Routine.waitFrames(64)
				n:kill(9)
				Effect.spawn(10, n.x, n.y)
				SFX.play(36)
				
				if not SaveData[tostring(smb1HUD.currentWorld.x)] then
					Routine.waitFrames(64)
					SFX.play(40)
					doWinCondition = true
					doWinConditionTimer = 0
					medalOffset = 0
					Misc.pause()
				end
			end)
		end
	end
end

-- this part handles player movement --
function onTick()
	if player.x >= -199552 then
		timer1:close(minTimer.WIN_CLEAR, true) 
	end

	if canMove then
		for k,v in pairs(player.keys) do
			player.keys[k] = false
		end
	end
end

local gfx = Graphics.loadImageResolved("minTimer/minus medal.png")

function onDraw()
	if doWinCondition then
		Audio.SeizeStream(-1)
		Audio.MusicPause()
		
		doWinConditionTimer = doWinConditionTimer + 1
		
		if doWinConditionTimer <= 96 then medalOffset = medalOffset - 1 end
		
		medal = medal or Sprite{texture = gfx, frames = 2}
		medal.position = vector(player.x, player.y + player.height / 2 + medalOffset)
		medal:draw{sceneCoords = true, frame = math.floor(doWinConditionTimer / 16) % 2 + 1, priority = -45}
		
		if doWinConditionTimer >= 232 then
			doWinCondition = nil
			doWinConditionTimer = 0
			Misc.unpause()
			Audio.MusicResume()
			Audio.ReleaseStream(-1)
			SaveData[tostring(smb1HUD.currentWorld.x)] = true
			
			--IMPORTANT LINE
			--When referring to unlocking the minus world, this is what's used to track how many medals are collected.
			SaveData.minusMedals = (SaveData.minusMedals or 0) + 1
		end
	end
end