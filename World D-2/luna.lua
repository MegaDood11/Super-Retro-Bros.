local effect = Particles.Emitter(camera.x + camera.width,camera.y + camera.height, Misc.resolveFile("p_snowa.ini"))

local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector("D",2)

function onStart()
	local warp2 = Warp.get()[2]
	warp2.entranceWidth=4096
end

function onDraw()
	if player.section > 0 then return end
	effect.x = camera.x + camera.width
	effect.y = camera.y + camera.height
	effect:Draw()
end