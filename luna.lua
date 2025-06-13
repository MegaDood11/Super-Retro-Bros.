--------------------------------------------------
-- Level code
-- Created 11:10 2025-4-21
--------------------------------------------------
local warpTransition = require("warpTransition")

local customCamera = require("customCamera")

local spawnzones = require("spawnzones")

local extendedKoopas = require("extendedKoopas")

local jumpbuffer = require("jumpbuffer")

local coyotetime = require("coyotetime")

local antizip = require("antizip")

local ppp = require("playerphysicspatch")

local noTurnBack = require("newNoTurnBack")

local smb1HUD = require("smb1HUD")

local smasPause = require("smasPause")

local luigiHitsBlocksNormally = require("luigiHitsBlocksNormally")

-- Physics adjustments that make the game more like SMB1
Defines.player_walkspeed = 2.4
Defines.player_runspeed = 5.2
Defines.gravity = 10
Defines.player_grav = 0.571
Defines.jumpheight = 22
Defines.jumpheight_bounce = 24

-- Physicspatch adjustments that make the game more like SMB1
ppp.speedXDecelerationModifier = -0.0975
ppp.groundTouchingDecelerationMultiplier = 1.5
ppp.groundNotTouchingDecelerationMultiplier = 1.25

ppp.accelerationMaxSpeedThereshold = 6
ppp.accelerationMinSpeedThereshold = 0.1
ppp.accelerationSpeedDifferenceThereshold = 0.5
ppp.accelerationMultiplier = 0.9

ppp.aerialIdleDeceleration = 1

smb1HUD.toggles.reserve = false
smb1HUD.toggles.lives = false

local lastDirection = 1

-- Run code on level start
function onStart()
    Player.setCostume(CHARACTER_MARIO,"Smb1-mario",true)
    Player.setCostume(CHARACTER_LUIGI,"Smb1-luigi",true)

    Graphics.setMainFramebufferSize(512,448)
end

function onCameraUpdate()
    camera.width, camera.height = Graphics.getMainFramebufferSize()
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick() -- every frame of gameplay
	player:mem(0x154, FIELD_WORD, 0)
	player.keys.altJump = false -- spinjump
	if Timer.get() <= 1 then return end
	Timer.add(-1,true)
end

function onTickEnd()
	if player:isGroundTouching() or player:isUnderwater() then
		lastDirection = player.direction
	else
		player.direction = lastDirection
	end

end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end