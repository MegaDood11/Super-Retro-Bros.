local airshipScroll = require("AI/airshipScroll")
local autoscrollDX = require("AI/autoscrollDX")
local endstates = require("game/endstates")

autoscrollDX.scrollRight(1.1)

local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector(8,4)


airshipScroll.sections = {0} --What sections the effect should be applied to. Note that this is a table.
airshipScroll.intensity = .01 --What speed should the effect should scroll at.
airshipScroll.movementLimit = 0.8 --How long should the effect should scroll for.
airshipScroll.movingLayer = "shipWater" --Whatever layer is here will scroll up and down with the screen, allowing you to have stuff like the water in SMB3's World 8-Ship.

function onNPCKill(eventObj, v, reason)
	if v.id == 896 and v.data.health <= 0 then
		triggerEvent("Music Change")
		timer = true
	end
end

function onTick()
	if player.x >= -179160 - 32 and not active then
		triggerEvent("Toad Free 1")
		active = true
	end
	
	if timer then Timer.add(2,true) end
end

function onEvent(e)
	if e == "Music Change" then
		SFX.play("World Clear.spc")
		local r = Routine.run(function() Routine.waitFrames(96) triggerEvent("Pillar") SFX.play("bridgecollapse.wav") end)
	elseif e == "Toad Free 5" then
		Level.endState(9)
		endstates.setPlayer(player)
	end
end