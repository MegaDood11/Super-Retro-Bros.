--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")
local playerStun = require("playerstun")
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 80,
	gfxwidth = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 8,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.
	staticdirection = true,
	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	health=5,
	quakestunframes = 70
	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local fireangles = {-3,0,3}

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		
		--v.ai1 is False Bowser's state
		--0 = wandering, 1 = about to fire, 2 = firing
		v.ai1 = 0
		--v.ai2 is the fire timer
		v.ai2 = 0
		--v.ai3 is the random jump chance
		v.ai3 = math.random(1, 50)
		--v.ai4 is the hurt timer
		v.ai4 = 0
		--v.ai5 is the hammer throwing timer
		v.ai5 = 0
		
		--False Bowser's current healths
		v.currenthealth = sampleNPCSettings.health
		--v.walkingtimer is how much False Bowser walks before turning around
		v.walkingtimer = 0
		--v.walkingdirection is the direction False Bowser is moving
		v.walkingdirection = v.direction
		--v.initialdirection is False Bowser's initial direction. If the player is beyond their initial direction then they'll chase the player
		v.initialdirection = v.direction
		--v.hammerRNG dictates whether or not Bowser should throw a hammer
		v.hammerRNG = 0
		--v.airBorne is to help with causing earthquakes
		v.airBorne = false
		
		mercyinvincibility = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	if player.x < v.x + (v.width / 2) then
		v.direction = -1
	else
		v.direction = 1
	end
	
	v.speedY = v.speedY + (-Defines.npc_grav + 0.15)
	
	--Speed control
	if v.ai1 == 1 then
		if v.collidesBlockBottom then
			v.speedX = 0
		end
		
		v.ai2 = v.ai2 + 1
		
		if v.ai2 == 30 then
			v.ai2 = 0
			v.ai1 = 2
			v.ai5 = 80
			z = NPC.spawn(801, v.x, v.y)
			z.speedX = 2.5 * v.direction
			z.speedY = RNG.randomEntry(fireangles)
			SFX.play("falsebowserfire.wav")
		end
	else
		if v.direction ~= v.initialdirection then
			v.speedX = sampleNPCSettings.speed * v.direction
		else
			v.speedX = sampleNPCSettings.speed * v.walkingdirection
			
			v.walkingtimer = v.walkingtimer - v.walkingdirection
			
			if v.walkingtimer == 40 or v.walkingtimer == -40 then
				v.walkingdirection = v.walkingdirection * -1
			end
		end
		
		--Random jumping
		v.ai3 = math.random(1, 100)
		
		if v.ai3 == 20 and v.collidesBlockBottom then
			v.speedY = -5.5
		end
		
		--Fire shooting
		if v.ai5 < 100 and data._settings.fire then
			v.ai2 = v.ai2 + 1
		end
		
		if v.ai1 == 0 and v.ai2 >= 100 + math.random(-20, 50) then
			v.ai1 = 1
			v.ai2 = 0
		end
		if v.ai1 == 2 and v.ai2 == 30 then
			v.ai1 = 0
			v.ai2 = 0
			if v.ai5 > 99 then
				v.ai5 = 99
			end
		end
		
		--Hammer throwing
		if v.ai1 ~= 2 and data._settings.hammers then
			v.ai5 = v.ai5 + 1
		end
		
		if v.ai5 >= 100 and v.ai1 ~= 2 then
			Graphics.draw{
				type = RTYPE_IMAGE,
				image = Graphics.sprites.npc[30].img, 
				x = v.x + (v.width / 3), 
				y = v.y - 16,
				sceneCoords = true,
				sourceX = 0, 
				sourceY = 0, 
				sourceWidth = 32,
				sourceHeight = 32,
				priority = -44
			}
		end
			
		if v.ai5 >= 125 then
			v.hammerRNG = math.random(1, 5)
			
			if v.hammerRNG == 1 then
				h = NPC.spawn(30, v.x + (v.width / 3), v.y - 16)
				h.speedX = 4 * v.direction
				h.speedY = -7
				SFX.play{sound=25, delay=7}
			end
		end
		
		if v.ai5 == 170 then
			v.ai5 = math.random(-50, 80)
		end
	end
	
	if v.ai4 > 0 then
		v.ai4 = v.ai4 - 1
	end
	
	if mercyinvincibility > 0 then
		mercyinvincibility = mercyinvincibility - 1
	end
	
	if v.currenthealth <= 0 then
		v:kill(HARM_TYPE_OFFSCREEN)
		if data._settings.deathEffect ~= 0 then
			e = Animation.spawn(data._settings.deathEffect, v.x + (v.width / 2), v.y)
			e.speedX = -3 * v.direction
			e.direction = v.direction
			e.speedY = -6
		end
	end
	
	--Causing earthquakes
	if v.collidesBlockBottom == false and data._settings.quake then
		v.airBorne = true
	end
	
	if v.collidesBlockBottom and v.airBorne == true then
		for k, p in ipairs(Player.get()) do --Section copypasted from the Sledge Bros. code
			if p:isGroundTouching() and not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == player.section then
				playerStun.stunPlayer(k, sampleNPCSettings.quakestunframes)
			end
		end
		v.airBorne = false
		SFX.play(37)
		Defines.earthquake = 6
	end
	
	--Graphics Stuff
	utils.restoreAnimation(v)
	walk = utils.getFrameByFramestyle(v, {
		frames = 4,
		gap = 4,
		offset = 0
	})
	jump = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 5,
		offset = 2
	})
	preparefire = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 3,
		offset = 4
	})
	fire = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 2,
		offset = 5
	})
	hurt = utils.getFrameByFramestyle(v, {
		frames = 2,
		gap = 0,
		offset = 6
	})
	
	if v.ai4 == 0 then
		if v.ai1 == 0 then
			if v.collidesBlockBottom then
				v.animationFrame = walk
			else
				v.animationFrame = jump
			end
		elseif v.ai1 == 1 then
			v.animationFrame = preparefire
		elseif v.ai1 == 2 then
			v.animationFrame = fire
		end
	else
		v.animationFrame = hurt
		v.animationTimer = v.animationTimer + 100
	end
end

function sampleNPC.onNPCHarm(eventObj, v, killReason, culprit)
	if npcID ~= v.id or v.isGenerator then return end
	
	if killReason ~= HARM_TYPE_LAVA then
		eventObj.cancelled = true
		if mercyinvincibility == 0 then
			if type(culprit) == "NPC" then
				if v.currenthealth then v.currenthealth = v.currenthealth - 1 end
				v.ai4 = 20
				mercyinvincibility = 3
				SFX.play(9)
			elseif killReason == HARM_TYPE_SWORD then
				if v.currenthealth then v.currenthealth = v.currenthealth - 1 end
				v.ai4 = 20
				SFX.play(9)
				mercyinvincibility = 3
			end
		end
	end
end

--Gotta return the library table!
return sampleNPC