local smb1HUD = require("smb1HUD")
local smb1Maze = require("smb1Maze")

smb1HUD.currentWorld = vector(7, 4)
smb1Maze.teleportXDelay = 440

local active = false

function onTick()
    -- credits to 9thCore on despawning off-camera NPCs
    for _, v in NPC.iterate(153) do
        if v.x - v.width < camera.x or camera.x + camera.width + v.width < v.x then
            v:kill(HARM_TYPE_VANISH)
        end
    end

    if player.x >= -193312 and not active then
		triggerEvent("Music")
		active = true
	end
end

function onEvent(e)
	if e == "Move" then
		SFX.play("../Music/World Clear.spc")
	elseif e == "Toad Free 2" then
		Effect.spawn(804,-192192, -200120)
	end
end