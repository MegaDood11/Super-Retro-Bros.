local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector("",3)

local warpTrigger = true

function onWarp(w, p)
	if w == Warp.get()[9] or w == Warp.get()[10] then
		warpTrigger = true
	end
end

function onTick()
	if player.x >= -118656 and warpTrigger then
		triggerEvent("Warp NPC1")
		warpTrigger = false
	end
end