local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector(5,1)

-- When you get to the underground section, music fades out then plays the 
-- underground theme   
-- - Devious

local hasFadedOut = false
local hasPlayedNew = false
local musTimer = 0

function onTick()
	if player.x > -192608 then
		if not hasFadedOut then
			Audio.MusicFadeOut(0, 2750)
			hasFadedOut = true
		end
		musTimer = musTimer + 1
		if musTimer >= 210 then
			if not hasPlayedNew then
				Audio.MusicChange(0, 4)
				hasPlayedNew = true
			end
		end
	else
		musTimer = 0
	end
end
