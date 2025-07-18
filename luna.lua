--------------------------------------------------
-- Level code
-- Created 11:10 2025-4-21
--------------------------------------------------
local warpTransition = require("warpTransition")
warpTransition.levelStartTransition = warpTransition.TRANSITION_FADE

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

local retroResolution = require("retroResolution")

local classicFireballs = require("classicFireballs")

local kindHurtBlock = require("kindHurtBlock")

local titlecard = require("titlecard")

local accurateTimer = require("accurateTimer")

local bonusChars = require("bonusChars")

local bonkFlipsMushrooms = require("bonkFlipsMushrooms")

-- Physics adjustments that make the game more like SMB1
Defines.player_walkspeed = 2.4
Defines.player_runspeed = 5.2
Defines.gravity = 10
Defines.player_grav = 0.571
Defines.jumpheight = 22
Defines.jumpheight_bounce = 24
Defines.player_grabShellEnabled = false

-- Physicspatch adjustments that make the game more like SMB1
ppp.speedXDecelerationModifier = -0.0975
ppp.groundTouchingDecelerationMultiplier = 1.5
ppp.groundNotTouchingDecelerationMultiplier = 1.6

ppp.accelerationMaxSpeedThereshold = 6
ppp.accelerationMinSpeedThereshold = 0.1
ppp.accelerationSpeedDifferenceThereshold = 0.5
ppp.accelerationMultiplier = 1.25

ppp.aerialIdleDeceleration = 1

smb1HUD.toggles.reserve = false
smb1HUD.toggles.lives = false

local lastDirection = 1
local lastDucked = false

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
function onTick()
	player.keys.altJump = false -- spinjump
	player.reservePowerup = 0
	player:mem(0x38, FIELD_WORD, math.min(player:mem(0x38, FIELD_WORD), 3))
	player:mem(0x18,FIELD_BOOL,false) --Disable Peach's hover
	if player:mem(0x16,FIELD_WORD) > 2 then --Caps Toad's HP to 2
		player:mem(0x16,FIELD_WORD,2)
	end

	if (player.character > 2 and player.character < 5) and player.powerup == 3 and player.keys.altRun then
		player.keys.altRun = false
	end
	
	-- prevents the player getting flung forward whenever they try to move backwards in a forced state
	if player.forcedState ~= 0 
	and ((player.speedX < 0 and player.keys.right) 
	or (player.speedX > 0 and player.keys.left)) 
	then
		player.speedX = player.speedX * 0.95
	end
	-- prevents the player from ducking/unducking in midair
	if player.forcedState == 0 then
		if not player:isGroundTouching() and lastDucked then
			player.keys.down = KEYS_DOWN
			player:mem(0x12E,FIELD_BOOL,true)
		elseif not player:isGroundTouching() then
			player.keys.down = KEYS_UP
		end
	end
	
	if Timer.get() <= 1 then return end
	if Level.endState() == 0 and player.forcedState ~= 300 then
		Timer.add(-1,true)
	else
		Timer.add(0,true)
	end
end

function onTickEnd()
	if player:isGroundTouching() or player:isUnderwater() then
		lastDirection = player.direction
		lastDucked = player:mem(0x12E,FIELD_BOOL)
	else
		player.direction = lastDirection
	end
end


-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end

-- Death related things

local deathOpacity = 0

local img = Graphics.loadImageResolved("hudTimeUp.png")
local imgw = img.width
local imgh = img.height

function onDraw()
	if player.deathTimer >= 175 then
		deathOpacity = math.min(1, deathOpacity + 0.055)
		Graphics.drawScreen{priority = 5.1, color = Color.black .. deathOpacity}
	end

	if Timer.get() <= 0 then
		if player.deathTimer >= 80 then
			Graphics.drawBox{
				texture = img,
				x = (camera.width/2),
				y = (camera.height/2),
				width = imgw,
				height = imgh,
				centered = true,
				priority = 5,

			}
		end
	end
end
