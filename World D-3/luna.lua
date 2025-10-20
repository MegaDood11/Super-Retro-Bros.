local effect = Particles.Emitter(camera.x + camera.width,camera.y + camera.height, Misc.resolveFile("p_snowa.ini"))

local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector("D",3)

function onDraw()
	if player.section > 0 then return end
	effect.x = camera.x + camera.width
	effect.y = camera.y + camera.height
	effect:Draw()
end