local smb1HUD = require("smb1HUD")
local endstates = require("game/endstates")

smb1HUD.currentWorld = vector("B",4)

--Uses lua to trigger the boss fight music
function onTick()
	if player.x >= -193696 and player.section == 0 and not active then
		Audio.MusicChange(0, "Music/Bowser.spc|0;g=2;e0")
		active = true
	end
end

function onEvent(e)
	if e == "Move" then
		SFX.play("World Clear.spc")
	elseif e == "Toad Free 2" then
		Effect.spawn(804,-192904, -200120)
	elseif e == "Toad Free 5" then
		Level.endState(9)
		endstates.setPlayer(player)
	end
end

