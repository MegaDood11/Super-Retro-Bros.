local smb1HUD = require("smb1HUD")
smb1HUD.currentWorld = vector(1,"???")

--To set up:

-- Change the world number like normal
-- Set "timer1" to be any time you want
-- Change the x coord next to "winPosition", the player needs to cross this in order to win the race
-- Place the boo npc anywhere you want in the level, recommended to be on the first screen as the player

local startPosition
local winPosition = -199584

local minTimer = require("minTimer") -- load the library
local timer1 = minTimer.create{initValue = minTimer.toTicks{hrs = 0, mins = 0, secs = 5}} -- create a timer object

local canMove = true -- boolean to stop the player
local moveTimer = 0  -- timer to release the player

function onStart()
local r = Routine.run(function()
	Routine.waitFrames(64)
		timer1:start()
		canMove = false
		startPosition = player.x
		for _,n in ipairs(NPC.get(953)) do
			n.speedX = (winPosition - startPosition) / math.floor(timer1.initValue)
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
				pauseMusic = true
				SFX.play("Music/Battle Mode Winner.spc")
				Routine.waitFrames(224)
				
				if not SaveData[tostring(smb1HUD.currentWorld.x)] then
					SFX.play("Music/Golden Coin.spc")
					doWinCondition = true
					doWinConditionTimer = 0
					medalOffset = 0
					Misc.pause()
				else
					pauseMusic = nil
					Audio.MusicResume()
					Audio.ReleaseStream(-1)
					Audio.MusicChange(player.section, "Music/Album.spc|0;g=2;e0")
				end
			end)
		end
	end
end

-- this part handles player movement --
function onTick()
	if player.x >= winPosition then
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
		
		doWinConditionTimer = doWinConditionTimer + 1
		
		if doWinConditionTimer <= 96 then medalOffset = medalOffset - 1 end
		
		medal = medal or Sprite{texture = gfx, frames = 2}
		medal.position = vector(player.x, player.y + player.height / 2 + medalOffset)
		medal:draw{sceneCoords = true, frame = math.floor(doWinConditionTimer / 16) % 2 + 1, priority = -45}
		
		if doWinConditionTimer >= 464 then
			pauseMusic = nil
			doWinCondition = nil
			doWinConditionTimer = 0
			Misc.unpause()
			Audio.MusicResume()
			Audio.ReleaseStream(-1)
			Audio.MusicChange(player.section, "Music/Album.spc|0;g=2;e0")
			SaveData[tostring(smb1HUD.currentWorld.x)] = true
			
			--IMPORTANT LINE
			--When referring to unlocking the minus world, this is what's used to track how many medals are collected.
			SaveData.minusMedals = (SaveData.minusMedals or 0) + 1
		end
	end
	
	if pauseMusic then
		Audio.SeizeStream(-1)
		Audio.MusicPause()
	end
end