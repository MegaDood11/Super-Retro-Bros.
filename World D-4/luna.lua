local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector("D",4)

local lightning = 0
local randomLightning = RNG.randomInt(80, 256)
local screenFlash = Color(1, 0.95, 0.4)
local flashOpacity = 0

function onTick()
	lightning = lightning + 1
	if lightning >= randomLightning then
		if lightning == randomLightning + 8 then SFX.play(43) end
		if lightning <= randomLightning + 12 then
			flashOpacity = flashOpacity + 0.08333
		else
			flashOpacity = flashOpacity - 0.08333
			if lightning >= randomLightning + 24 then
				lightning = 0
				randomLightning = RNG.randomInt(80, 256)
				flashOpacity = 0
			end
		end
	else
		flashOpacity = 0
	end
end

function onDraw()
	Graphics.drawScreen{
	color = screenFlash .. flashOpacity,
	priority = -100,
	}
end