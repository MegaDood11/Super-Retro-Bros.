local smb1HUD = require("smb1HUD")
local endstates = require("game/endstates")

smb1HUD.currentWorld = vector(6,4)

--Uses lua to trigger the boss fight music
function onTick()
	if player.x >= -188896 and not active then
		triggerEvent("Music")
		active = true
	end
end

function onEvent(e)
	if e == "Move" then
		SFX.play("World Clear.spc")
	elseif e == "Toad Free 2" then
		Effect.spawn(804,-188096, -200120)
	elseif e == "Toad Free 5" then
		Level.endState(1)
		endstates.setPlayer(player)
	end
end