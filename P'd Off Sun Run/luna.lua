local smb1HUD = require("smb1HUD")
local effectconfig = require("game/effectconfig")

smb1HUD.currentWorld = vector(9, 1)

local shouldFade = false
local fadeTimer = 0

function effectconfig.onTick.TICK_BUB(v)
   	v.speedX = (math.sin(v.timer * 0.05) * 0.7)*v.direction
end

function onTick()
	if shouldFade then
    		local bg = player.sectionObj.background
		fadeTimer = fadeTimer + 1

    		for k, v in ipairs(bg:get()) do
			if v.name == "badland-sky" or v.name == "hills" then
				if fadeTimer % 25 == 0 then
					v.opacity = math.min(1, v.opacity + 0.1)
				end
			end					
		end

		if RNG.randomInt(1,18) == 1 then
        		local e = Effect.spawn(800, camera.x-128 + RNG.random(0, camera.width+256), camera.y + camera.height)
			e.direction = RNG.randomSign()
        	end
	end
end

function onEvent(e)
	if e == "startFade" then
		shouldFade = true
	end
end
