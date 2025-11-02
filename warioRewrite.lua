--[[
wario.lua
v1.2.1
Remade practically from scratch by arabslmon/ohmato, 2016
Original (the awful one) by Horikawa Otane
And then Emral took the shop out.
(And then Saturnyoshi made it work again, and added HDOverride stuff)
And then Emral attempted to make the character more playable

warioRewrite.lua
v1.0.5
And then MrNameless decided to fix up the character for Beta 5

Credits:
Emral, Saturnyoshi, Horikawa Otane, arabslmon/ohmato - Made the original basegame wario scripts
DeltomX3 - Orignally implemented the air-dash ability into the original basegame wario script
Marioman2007 - Made the custom character template initially used as a starting point here
MrDoubleA - Made the code snippet for checking if the player's on the ground
Rednaxela - Made the code snippet to disable friction


Things to do:
- fix insta-killing any non-jumphurt npc upon ground pounding them
- fix wario looking really jagged when dashing on slopes.
- fix wario immediately falling down upon being shot out of a barrel

- allow small wario to use his big abilities
- allow the SMW-Wario costume to be compatible with this script (may require updating the SMW-Wario costume itself to make it compatible)
--]]


--[[
To load in this script, put the following in your luna.lua file!

local playerManager = require("playerManager")
local wario = require("warioRewrite")
playerManager.overrideCharacterLib(CHARACTER_WARIO, wario)
--]]


local pm = require("playerManager")

local hisPurpose = {}

-- the X2 character that you want to replace
local WARIO_CHAR = CHARACTER_WARIO

function hisPurpose.onDashStartup(p) -- code that runs upon initiating a dash
	if not p.data.wario then return end
	local data = p.data.wario
	-- put your own code here!
end

function hisPurpose.onAirDashStartup(p) -- code that runs upon initiating an AIR-dash
	if not p.data.wario then return end
	local data = p.data.wario
	-- put your own code here!
end

function hisPurpose.onGroundPoundStartup(p) -- code that runs upon initiating a ground pound
	if not p.data.wario then return end
	local data = p.data.wario
	-- put your own code here!
end

function hisPurpose.onGroundPoundLanding(p) -- code that runs upon landing while ground pounding
	if not p.data.wario then return end
	local data = p.data.wario
	-- put your own code here!
end

hisPurpose.bumperNPCs = table.map{458,582,583,584,585,594,595,596,597,598,599,604,605}

hisPurpose.blacklistedCostumes = table.map{"SMW-WARIO"} -- only for costumes that have their own animation handling for wario

hisPurpose.settings = {
	
	------------ GROUND-POUND SETTINGS ------------
	
	allowGroundPound = false, -- Should wario be allowed to ground pound (true by default)
	allowHarmBlockPounding = false, -- Should wario be allowed to "hit" harm/lava blocks while ground pounding, forcing you upwards without being harmed (false by default)
	allowGroundPoundCancel = true, -- Should wario be allowed to stop ground pounding by pressing altJump again (true by default) 
	bounceOnGroundPound = true, -- Should wario bounce on NPCs & stop ground pounding when currently ground pounding (true by default)
	poundInstaKill = false, -- Should wario be able to instakill the npc being ground pounded on regardless of how much health it has? (false by default) 
	poundEffect = pm.getGraphic(CHARACTER_WARIO, pm.registerGraphic(CHARACTER_WARIO, "poundFX.png")), -- The image effect used for ground pounding
	
	groundPoundFrame = 24, -- The frame used for ground pounding (30(yoshi-riding) or 24(sliding) by default)
	
	------------ DASH SETTINGS ------------
	allowDashing = true, -- Should wario be allowed to dash (true by default)
	allowAirDash = false, -- Should wario be allowed to perform an air dash (false by default)
	dashBumpNPCs = false, -- Should wario bump into NPCs & stop dashing when currently dashing (true by default) 

	dashEffect = pm.getGraphic(CHARACTER_WARIO, pm.registerGraphic(CHARACTER_WARIO, "chargeFXR.png")), -- The image effect used for dashing
	dashSFX = { -- The SFX used for dashing
		[1] = pm.getSound(CHARACTER_WARIO,pm.registerSound(CHARACTER_WARIO, "wario_footstep1.ogg")),
		[2] = pm.getSound(CHARACTER_WARIO,pm.registerSound(CHARACTER_WARIO, "wario_footstep2.ogg")),
		[3] = pm.getSound(CHARACTER_WARIO,pm.registerSound(CHARACTER_WARIO, "wario_footstep3.ogg")),
	},
	dashSFXRate = 8, -- How many frames will it for a SFX to play take while dashing (8 by default)
	
	dashChargeTime = 24, 	-- How many frames will it take for Wario to startup his dash. Setting it to 1 will allow instant dashing (24 by default)
	dashSpeedcap = 6,		-- What is the possible maximum speed while dashing (8 by default)
	dashAccel = 6,			-- How fast is the acceleration to top speed while dashing (4 by default)
	dashLimit = -1,		-- How many frames can wario dash before automatically stopping. Setting it to -1 will allow dashing indefinitely (-1 by default)
	
	dashFrames = 2, -- How many frames does wario's dash animation have (2 by default)
	dashFramespeed = 0.2, -- How fast should wario's dash animation be played (0.2 by default)
	dashJumpFrame = 33, -- The frame used when dashing in midair (33 by default)
	dashingAnim = {
		[1] = 32,
		[2] = 33,
		[3] = 1,
	},
	
	------------ DUCK/CRAWLING SETTINGS ------------
	
	allowDuckSliding = false, -- Should wario be able to slide on the ground with less friction (false by default)
	allowCrawling = true, -- Should wario be allowed to crawl (true by default)
	crawlAntizip = true, -- Should there be an antizip to prevent wario from unducking when a block is above him (true by default)
	crawlspeed = 2, -- How fast should wario crawl (2 by default)
	
	crawlFrames = 2, -- How many frames does wario's crawl animation have (2 by default)
	crawlFramespeed = 0.1, -- How fast should wario's crawl animation be played (0.1 by default)
	crawlAnim = { -- What frames will be displayed during wario's dash animation (22,23 by default)
		[1] = 22,
		[2] = 23,
	},
	
	------------ MISCELLANEOUS SETTINGS ------------
	
	allowSmallAbilities = true, -- Should wario be able to use his unique abilites, even when he's small (false by default)
	allowSpinjump = false, -- Should wario be able to spinjump (false by default)
	allowCoinsOnKill = false, -- Will enemies be able to drop coins upon being killed (true by default)
	baseWalkingSpeed = 4, -- What is the maximum speed wario can walk fast as (4 by default)
	baseRunningSpeed = 4, -- What is the maximum speed wario can run fast as (4 by default)
	droppedCoinId = 10, -- What npc/coin id will be dropped upon killing an enemy (10 by default) 
	
	barrelFix = true, -- Do you want to fix the issue with wario not properly going through a straight line when shot out of a barrel (true by default)
}

local function isOnGround(p) -- ripped straight from MrDoubleA's SMW Costume scripts
	return (
		p.speedY == 0 -- "on a block"
		or p:isGroundTouching() -- on a block (fallback if the former check fails)
		or p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
		or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
	)
end

function hisPurpose.onInitAPI() -- this function handles initializing the script upon starting a level
	registerEvent(hisPurpose, "onInputUpdate",false)
    registerEvent(hisPurpose, "onTick",false)
	registerEvent(hisPurpose, "onTickEnd",false)
    registerEvent(hisPurpose, "onDraw")
	registerEvent(hisPurpose, "onPostNPCKill")
end

function hisPurpose.initCharacter(p) -- this function handles initializing/modifying physics upon switching to/starting a level as wario

	-- changes the default physics for wario
	Defines.player_runspeed = hisPurpose.settings.baseRunningSpeed
	Defines.player_walkspeed = hisPurpose.settings.baseWalkingSpeed
	Defines.gravity = 12
	Defines.player_grav = 0.4
	
	-- changes the fireballs to be twice the size
	NPC.config[13].gfxwidth = 16;	NPC.config[265].gfxwidth = 32;
	NPC.config[13].gfxheight = 16;	NPC.config[265].gfxheight = 32;
	NPC.config[13].height = 16;		NPC.config[265].height = 32;
	NPC.config[13].width = 16;		NPC.config[265].width = 32;
	
	-- initialize wario exclusive data
	p.data.wario = {
		canAirDash = true,
		isGroundPounding = false,
		isCrawling = false,
		isDucking = false,
		
		startedGroundPound = false,
		startedDash = false,
		
		disableDash = false, -- feel free to change these via "player.data.wario.disableDash = true/false" in your luna.lua file
		disableAirDash = false, -- feel free to change these via "player.data.wario.disableAirDash = true/false" in your luna.lua file
		disableGroundPound = false, -- feel free to change these via "player.data.wario.disableGroundPound = true/false" in your luna.lua file
		disableCrawling = false, -- feel free to change these via "player.data.wario.disableCrawling = true/false" in your luna.lua file
		
		groundPoundCombo = 2,
		dashTimer = 0,
		dashDuration = 0,
		dashCrawltimer = 0,
		lockedDirection = 0,
		
		animTimer = {
			dash = 0,
			gPound = 0,
			crawl = 0,
		},
		
		barrelTimer = 0,
	}
end

function hisPurpose.cleanupCharacter(p)	-- this function handles changing the physics back to normal upon switching out of wario
	-- Return physics to normal
	Defines.player_runspeed = nil
	Defines.player_walkspeed = nil
	Defines.jumpheight = nil
	Defines.jumpheight_bounce = nil
	Defines.gravity = nil
	Defines.player_grav = nil
	
	-- Reset grabbing ability
	--Defines.player_grabSideEnabled = nil
	--Defines.player_grabShellEnabled = nil
	
	-- Reset dimensions for player-thrown fireball/iceball
	NPC.config[13].gfxwidth = 16;	NPC.config[265].gfxwidth = 16;
	NPC.config[13].gfxheight = 16;	NPC.config[265].gfxheight = 16;
	NPC.config[13].height = 16;		NPC.config[265].height = 16;
	NPC.config[13].width = 16;		NPC.config[265].width = 16;
	
	-- remove all the wario data values
	p.data.wario = nil
end


function hisPurpose.onInputUpdate() -- this function handles starting up wario's abilities upon the respective button of said abilities are pressed
	for _,p in ipairs(Player.get()) do
		if p.character == WARIO_CHAR and not Misc.isPaused() and not p:mem(0x4A,FIELD_BOOL) and p.deathTimer == 0 and p.forcedState == 0 and Level.winState() == 0 and p.data.wario then -- only run when you're wario.
			pm.winStateCheck() -- prevents any key pressing if the player has touched a level exit
			
			local data = p.data.wario
			local settings = hisPurpose.settings
		
			if p.inLaunchBarrel and settings.barrelFix then
				data.barrelTimer = 20
			end
		
			if not data.isGroundPounding and data.barrelTimer <= 0 then
				if p.keys.altRun == KEYS_PRESSED and (p.powerup > 1 or settings.allowSmallAbilities) and data.dashTimer == 0 and settings.allowDashing and not data.disableDash then -- initiates dashing upon pressing altRun 
					if isOnGround(p) then
						data.animTimer.dash = 0
						data.dashDuration = 0
						data.dashTimer = settings.dashChargeTime
					end
					data.lockedDirection = p.direction
				end
				
			elseif p.keys.altJump == KEYS_PRESSED and settings.allowGroundPoundCancel then -- cancels ground-pounding upon re-pressing altJump
				data.isGroundPounding = false
			end
			
			-- initiate air-dash
			if settings.allowAirDash and p.holdingNPC == nil and not data.isDucking and data.barrelTimer <= 0 and not isOnGround(p) and data.dashTimer <= 0 and data.canAirDash and p.keys.altRun == KEYS_PRESSED and not data.disableAirDash then
				hisPurpose.onAirDashStartup(p)
				p.speedY = -7
				data.isGroundPounding = false
				data.canAirDash = false
				
				data.animTimer.dash = 0
				data.dashDuration = 0
				data.dashTimer = 1
				data.lockedDirection = p.direction
			end
			
			if p.holdingNPC ~= nil or p.mount ~= 0 then -- prevents dashing if holding a npc or on a mount
				data.dashTimer = 0
			end
			
		end
	end
end


function hisPurpose.onTick()  -- this function handles wario's abilities themselves & their behavior + interactions with NPCs & blocks
	for _,p in ipairs(Player.get()) do
		if p.character == WARIO_CHAR and p.data.wario then
			local data = p.data.wario
			local settings = hisPurpose.settings
			
			if data.barrelTimer > 0 then -- fixes wario falling down immediately upon getting shot out of a barrel
				p.keys.run = KEYS_UP
				p.keys.altRun = KEYS_UP
				p.speedX = p.speedX * 0.975
				if p.speedY > -Defines.player_grav then p.speedY = p.speedY - (Defines.player_grav - 0.03) end
				data.barrelTimer = math.max(data.barrelTimer - 1, 0)
			end
			
			if isOnGround(p) then -- refreshes air dash & resets ground-pound combo counter
				data.canAirDash = true
				data.groundPoundCombo = 2
				data.barrelTimer = 0
			end
			
			if p:isClimbing() or p.mount ~= 0 or p.deathTimer ~= 0 or p:mem(0x4A,FIELD_BOOL) or data.barrelTimer > 0 then -- prevent abilites if climbing, on a mount, dead, or in/shot out of a barrel respectively.
				data.isCrawling = false
				data.isDucking = false
				data.isGroundPounding = false
				data.groundPoundCombo = 2
				data.dashTimer = 0
				
				data.animTimer.dash = 0
				data.animTimer.gPound = 0
				data.animTimer.crawl = 0
			end
			
			------------ GROUND-POUND HANDLING ------------
			if p:isClimbing() or p:mem(0x36, FIELD_BOOL) or 
			(p.powerup <= 1 and not settings.allowSmallAbilities) 
			or data.disableGroundPound then -- prevents ground pounding if climbing, swimming, or when data.disableGroundPound is true
				data.isGroundPounding = false
			end
			-- handles ground pounding
			if data.isGroundPounding then 
				p:mem(0x164, FIELD_WORD, 0)
				p.keys.left = KEYS_UP
				p.keys.right = KEYS_UP
				p.keys.down = KEYS_UP
				
				p.speedX = 0
				p.speedY = math.min(p.speedY + 0.4, 13) -- makes the player fall faster directly instead of using Defines.player_grav
				
				data.dashTimer = 0
				
				if not data.startedGroundPound then
					hisPurpose.onGroundPoundStartup(p)
					data.startedGroundPound = true
				end
				
				local hasPounded = false
				if p.speedY > 0 then
					data.animTimer.gPound = data.animTimer.gPound + 1
					
					for _,block in Block.iterateIntersecting(p.x, p.y + p.height, p.x + p.width, p.y + p.height + 6 + p.speedY) do -- handles ground pounding blocks
						-- If block is visible
						if block.isHidden == false and block:mem(0x5A, FIELD_BOOL) == false then
							-- If the block should be broken, destroy it
							if Block.MEGA_SMASH_MAP[block.id] then -- if the block can be hit/broken
								if block.contentID > 0 or p.powerup <= 1 then
									block:hit(true, p)
								else
									block:remove(true)
								end
							elseif (Block.SOLID_MAP[block.id] or (Block.SEMISOLID_MAP[block.id] and p.y + p.height <= block.y + 4)
							or Block.PLAYERSOLID_MAP[block.id]) and not Block.SLOPE_MAP[block.id] 
							and ((not Block.LAVA_MAP[block.id] and not Block.HURT_MAP[block.id]) or settings.allowHarmBlockPounding) then -- if the block CAN'T be broken
								block:hit(true, p)
								hasPounded = true
							end
						end
					end
				end
				for _, npc in NPC.iterateIntersecting(p.x, p.y + p.height, p.x + p.width, p.y + p.height + p.speedY) do -- handles ground pounding NPCs
					if NPC.HITTABLE_MAP[npc.id] and (not NPC.config[npc.id].jumphurt) 
					and (not npc.friendly) and npc.despawnTimer > 0 and (not npc.isGenerator) 
					and npc.forcedState == 0 and npc.heldIndex == 0 then
						local oldScore = NPC.config[npc.id].score
						NPC.config[npc.id].score = data.groundPoundCombo
						if not settings.poundInstaKill then
							if NPC.MULTIHIT_MAP[npc.id] then
								npc:harm(1)
							else
								npc:harm(8)
							end
						else
							npc:kill(8)
						end
						NPC.config[npc.id].score = oldScore
						data.groundPoundCombo = math.min(data.groundPoundCombo + 1, 10)
						if settings.bounceOnGroundPound then
							Colliders.bounceResponse(p)
							data.isGroundPounding = false
						else
							p.speedY = p.speedY + 1.5
						end
					end
				end
				if (isOnGround(p) or hasPounded) and data.isGroundPounding then -- stop ground pound upon landing on a Block or a NPC
					hisPurpose.onGroundPoundLanding(p)
					data.isGroundPounding = false
					if p.powerup > 1 then
						SFX.play(37)
						Defines.earthquake = math.max(Defines.earthquake, 4)
					else 
						SFX.play(3)
					end
					p.speedY = -4
				end
			else
				data.startedGroundPound = false
				
			end
			------------ END OF GROUND-POUND HANDLING ------------
			

			------------ DASH HANDLING ------------
			if data.dashTimer > 0 then -- handles dashing
				p:mem(0x164, FIELD_WORD, 0)
				p.keys.left = KEYS_UP
				p.keys.right = KEYS_UP
				p.keys.run = KEYS_UP
				p.keys.down = KEYS_UP
				
				data.animTimer.dash = data.animTimer.dash + 1
				
				if p.keys.altRun == KEYS_UP or p:isClimbing() or p.forcedState ~= 0 or p:mem(0x50, FIELD_BOOL)
				or (data.dashDuration >= settings.dashLimit and settings.dashLimit > -1) 
				or data.disableDash or not settings.allowDashing then
					data.dashTimer = 0
					data.animTimer.dash = 0
					data.lockedDirection = p.direction
				end

				if data.dashTimer == 1 then
				
					Defines.player_runspeed = settings.dashSpeedcap -- required to prevent issues with slopes & colliding with them
					Defines.player_walkspeed = settings.dashSpeedcap -- required to prevent issues with slopes & colliding with them
					--p:mem(0x154,FIELD_WORD,-2)
					
					-- Increase speed
					if not data.startedDash then
						hisPurpose.onDashStartup(p)
						data.startedDash = true
					end
					p.direction = data.lockedDirection
					p.speedX = math.min(math.abs(p.speedX) + settings.dashAccel, settings.dashSpeedcap) * data.lockedDirection
					
					data.dashDuration = data.dashDuration + 1
			
					-- Destroy blocks when dashing
					local left = 0; local right = 0
					local top = p.y + 4
					local bottom = player.y + player.height - 2
					if data.lockedDirection == -1 then
						right = p.x
						left = right + p.speedX
					else
						left = p.x + p.width
						right = left + p.speedX
					end
					local bumpedBlock = false
					local bumpedNPC = false
					for _,block in Block.iterateIntersecting(left, top, right, bottom) do -- handles hitting blocks
						-- If block is visible
						if block.isHidden == false and not block:mem(0x5A, FIELD_BOOL) then
							-- If the block should be broken, destroy it
							if Block.MEGA_SMASH_MAP[block.id] then
								if block.contentID > 0 or p.powerup <= 1 then
									block:hit(false, p)
									bumpedBlock = true
								else
									block:remove(true)
								end
							elseif Block.MEGA_HIT_MAP[block.id] or (Block.SOLID_MAP[block.id] and not Block.SLOPE_MAP[block.id]) then
								block:hit(false, p)
								bumpedBlock = true
							end
						end
					end
					
					for _, npc in NPC.iterateIntersecting(left, top, right, bottom) do -- handles hitting NPCs
						if (not npc.friendly) and npc.despawnTimer > 0 and (not npc.isGenerator) and npc.forcedState == 0 and npc.heldIndex == 0 then
							if NPC.HITTABLE_MAP[npc.id] then
								npc:harm(3)
								if settings.dashBumpNPCs or NPC.MULTIHIT_MAP[npc.id] or p.powerup == 1 then
									bumpedNPC = true
								end
							elseif hisPurpose.bumperNPCs[npc.id] then-- if the npc is a bumper, turn wario around
								data.lockedDirection = data.lockedDirection * -1
								if npc.id ~= 458 then SFX.play(Misc.resolveSoundFile("bumper")) end
								break
							end
						end
					end
					
					if p:mem(0x148, FIELD_WORD) ~= 0 or p:mem(0x14C, FIELD_WORD) ~= 0 or bumpedNPC then	
						data.dashTimer = 0
						data.animTimer.dash = 0
						p.speedX = -2 * data.lockedDirection
						p.speedY = -4
						if p.powerup > 1 and not bumpedNPC then
							SFX.play(37)
							Defines.earthquake = math.max(Defines.earthquake, 4)
						else 
							SFX.play(3)
						end
					end
				elseif data.dashTimer > 0 then
					data.dashTimer = data.dashTimer - 1
				end
			else -- Cap run/walk speed when not dashing
				Defines.player_runspeed = settings.baseRunningSpeed
				Defines.player_walkspeed = settings.baseWalkingSpeed
				--p:mem(0x154,FIELD_WORD,math.max(p:mem(0x154,FIELD_WORD),0))
				data.startedDash = false
			end
			------------ END OF DASH HANDLING ------------
			
		
			------------ DUCK/CRAWL HANDLING ------------
			
			-- Prevents unducking
			if data.isDucking and settings.crawlAntizip then
				local ps = PlayerSettings.get(pm.getBaseID(WARIO_CHAR) , p.powerup)
				local unduckHeight = ps.hitboxHeight -- gets wario's hurtbox as if he wasn't ducking
				local speedXMod = settings.crawlspeed * p.direction
				
				player.keys.altJump = KEYS_UNPRESSED
				
				-- checks if a block is above wario when crouched
				for k,v in Block.iterateIntersecting(p.x + speedXMod, p.y + p.height - unduckHeight, p.x + p.width + speedXMod, p.y) do 
					if Block.SOLID_MAP[v.id] and (not v.isHidden) and not v:mem(0x5A, FIELD_BOOL) then
						p:mem(0x12E, FIELD_BOOL, true) -- force the player to stay ducked if a block is above them
						p.keys.down = KEYS_DOWN -- forcing the player's down keys to be held is also needed to keep them ducked
						break
					end
				end
			end
				
			-- handles crawling
			if p:mem(0x12E, FIELD_BOOL) and p.keys.down == KEYS_DOWN and p.mount == 0 then
				data.dashTimer = 0
				data.isDucking = true
				if isOnGround(p) then
					if settings.allowDuckSliding then
						p.speedX = math.max(math.abs(p.speedX) - 0.095, 0) * p.direction
					else
						p.speedX = p.speedX * 0.95
					end
					if (p.keys.left or p.keys.right) and settings.allowCrawling then
						player.speedX = settings.crawlspeed * p.direction
						data.animTimer.crawl = data.animTimer.crawl + 1
						data.isCrawling = true
					elseif settings.allowDuckSliding then -- following code from Rednaxela
						p:mem(0x138, FIELD_FLOAT, p.speedX) -- << turns off friction when ducking on ground to allow sliding
						p.speedX = 0 -- << turns off friction when ducking on ground to allow sliding
						data.isCrawling = false
					else
						data.isCrawling = false
					end
				end
			else
				data.isDucking = false
				data.isCrawling = false
				data.animTimer.crawl = 0
			end
		------------ END OF DUCK/CRAWL HANDLING ------------
		
		end -- wario character check end
	end -- player getting loop end
end -- onTick end

function hisPurpose.onTickEnd() -- sets/animates the frame according to the current action
	for _,p in ipairs(Player.get()) do
		if p.character == WARIO_CHAR and not hisPurpose.blacklistedCostumes[Player.getCostume(WARIO_CHAR)] and p.data.wario then -- only run when you're wario and not using the SMW-Wario Costume.
			local data = p.data.wario
			local settings = hisPurpose.settings
			-- Show the ground-pounding frame
			if data.isGroundPounding then
				p.frame = settings.groundPoundFrame		
			end
			-- Show & animate dashing frames
			if data.dashTimer > 0 then
				p.frame = settings.dashingAnim[1 + math.floor(data.animTimer.dash * settings.dashFramespeed) % settings.dashFrames]
				if not isOnGround(p) then p.frame = settings.dashJumpFrame end -- only show the dash jump frame if airborne
			end
			-- Show & animate crawling frames
			if data.isCrawling then
				p.frame = settings.crawlAnim[1 + math.floor(data.animTimer.crawl * settings.crawlFramespeed) % settings.crawlFrames] 
			end
		end
	end
end

function hisPurpose.onDraw() -- draws the effects when using wario's abilities
	for _,p in ipairs(Player.get()) do
		if p.character == WARIO_CHAR and p.data.wario then
			local data = p.data.wario
			local settings = hisPurpose.settings
			
			 -- draws the ground pound effect
			if data.isGroundPounding and p.speedY > 0 then
				local poundFrame = settings.poundEffect.height / 3
				Graphics.drawBox{
					texture = settings.poundEffect,	
					priority = -24,
					x = p.x + (p.width * 0.5),
					y = p.y + (p.height * 0.85),
					sourceY = poundFrame * (math.floor(data.animTimer.gPound * 0.25) % 3),  -- handles animating the ground pound effect & what frame should be chosen
					sourceHeight = poundFrame,
					centered = true,
					sceneCoords = true
				}			
			end
			
			-- handles playing the dash SFX & spawning dust particles when dashing on the ground
			if not Misc.isPaused() and isOnGround(p) and data.dashTimer > 0 and data.animTimer.dash % settings.dashSFXRate == 0 then 
				Effect.spawn(74, p.x + RNG.random(p.width/2) + 4 + p.speedX, p.y + p.height + RNG.random(-4, 4) - 4)
				SFX.play(RNG.irandomEntry(settings.dashSFX))
			end
			
			-- draws the dashing effect
			if data.dashTimer == 1 and p:mem(0x108, FIELD_WORD) == 0 then 
				local dashFX = settings.dashEffect
				local h = dashFX.height / 3
				Graphics.drawBox{
					texture = dashFX,
					priority = -24,
					width = dashFX.width * p.direction,
					x = p.x + (p.width * 0.5) + ((p.width * 0.65) * data.lockedDirection),
					y = p.y + (p.height * 0.5),
					sourceY = h * (math.floor(data.animTimer.dash * 0.25) % 3), -- handles animating the dash effect & what frame should be chosen
					sourceHeight = h,
					centered = true,
					sceneCoords = true
				}
			end
		end
	end
end

function hisPurpose.onPostNPCKill(v, harm) -- spawns in coins upon killing an NPC
	if not hisPurpose.settings.allowCoinsOnKill then return end
	
	local someoneIsWario = false
	for _,p in ipairs(Player.get()) do
		if p.character == WARIO_CHAR then  -- checks if one of the players is at least playing as wario
			someoneIsWario = true
			break
		end
	end
	if not someoneIsWario then return end
	
	-- If the player kills an enemy, drop some coins (ignore death of projectiles, powerups, in lava, an iceball, or egg)
	if harm > 8 or harm == 6 or harm == 4 or (not NPC.HITTABLE_MAP[v.id]) then return end
	for i = 1, NPC.config[v.id].score do
		local coin = NPC.spawn(hisPurpose.settings.droppedCoinId, v.x + 0.5 * v.width, v.y + 0.5 * v.height, v.section, false, true)
		coin.speedX = RNG.random(-2,2)
		coin.speedY = RNG.random(-4)
		coin.ai1 = 1
		v:mem(0x74, FIELD_WORD, -1)
	end
end

return hisPurpose