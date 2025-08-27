local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
local playerStun = require("playerstun")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 64,
	gfxheight = 64,

	width = 48,
	height = 48,

	gfxoffsetx = 0,
	gfxoffsety = 4,

	frames = 13,
	framestyle = 1,
	framespeed = 8,

	foreground = false,

	speed = 1,
	luahandlesspeed = false,
	nowaterphysics = false,
	cliffturn = false,
	staticdirection = true,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,

	score = 0,

	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	nowalldeath = false,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	health=3,
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]={id=npcID, xoffset=0, xoffsetBack = 0, yoffset=1.7, yoffsetBack = 1.5},
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]={id=npcID, xoffset=0.5, xoffsetBack = 0, yoffset=2.4, yoffsetBack = 1.5},
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

local STATE_IDLE = 0
local STATE_JUMP = 1
local STATE_SPIT = 2
local STATE_SHELL = 3
local STATE_RECOVER = 4
local STATE_GROUNDPOUND = 5
local STATE_HAMMERS = 6
local STATE_KOOPA = 7

local spawnOffset = {
	[-1] = 0,
	[1] = sampleNPCSettings.width / 2
}

local koopaSpawnOffset = {
	[-1] = 16,
	[1] = sampleNPCSettings.width / 2 - 32
}

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function effectconfig.onTick.TICK_BOWSERJR(v)
	if v.timer == v.lifetime-1 then
		v.speedX= 1 * -v.direction
		v.speedY=-7
		v.rotation= 15 * -v.direction
		v.gravity= 0.35
    end
end

function sampleNPC.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = data.state or STATE_IDLE
		data.timer = data.timer or 0
		data.health = settings.health
		data.landTimer = 0
		data.requiredJumps = RNG.randomEntry({1,2})
		data.timesJumped = 0
		data.requiredSpits = settings.fireamount
		data.timesSpat = 0
		data.npc = nil
		data.attackChooseTimer = 0
	end

	if v.heldIndex ~= 0
	or v.isProjectile
	or v.forcedState > 0
	then
		-- Handling
	end

	data.timer = data.timer + 1

	v.collisionGroup = "113"

	if data.state == STATE_IDLE then
		v.animationFrame = 0

		if data.timer > 40 then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_JUMP
			data.timer = 0
		end
	elseif data.state == STATE_JUMP then
		v.animationFrame = 1

		if data.timer == 6 then v.speedY = -settings.jumpheight v.speedX = RNG.randomEntry({settings.speed,-settings.speed}) end

		if data.timer > 6 then
			v.animationFrame = 2
		end

		if v.collidesBlockBottom and data.timer > 8 then
			data.landTimer = data.landTimer + 1
			v.animationFrame = 0
			v.speedX = 0

			if data.landTimer > 32 then
				data.state = STATE_JUMP
				data.timesJumped = data.timesJumped + 1
				npcutils.faceNearestPlayer(v)
				data.landTimer = 0
				data.timer = 0

				if data.timesJumped == data.requiredJumps then
					data.timer = 0
					npcutils.faceNearestPlayer(v)
					data.state = RNG.randomEntry({STATE_SPIT,STATE_GROUNDPOUND,STATE_KOOPA,STATE_HAMMERS})
					data.timesJumped = 0
					data.requiredJumps = RNG.randomEntry({1,2})
					data.landTimer = 0
				end 
			end
		end
	elseif data.state == STATE_SPIT then
		v.animationFrame = math.floor(data.timer/8)%4+3

		if data.timer < 32 then
			npcutils.faceNearestPlayer(v)
		end

		local playerX = player.x + player.width / 2
		local playerY = player.y + player.height / 2 + 2

		if data.timer == 31 then
			local n = NPC.spawn(npcID+2, v.x+spawnOffset[v.direction], v.y+16, player.section, false)
			data.homing = vector.v2(
			   (player.x) - (v.x + v.width),
			   (player.y) - (v.y + v.height)+32
		   ):normalize() * 1.5
		   n.speedX = data.homing.x
		   n.speedY = data.homing.y
		   npcutils.hideNPC(n)
			SFX.play(18)
		end

		if data.timer > 31 then
			v.animationFrame = 6
		end

		if data.timer > 64 then
			data.state = STATE_SPIT
			data.timesSpat = data.timesSpat + 1
			npcutils.faceNearestPlayer(v)
			data.timer = 0

			if data.timesSpat == data.requiredSpits then
				npcutils.faceNearestPlayer(v)
				data.state = STATE_IDLE
				data.timesSpat = 0
				data.timer = 0
			end 
		end
	elseif data.state == STATE_SHELL then
		v.animationFrame = 2

		settings.health = data.health
		v.friendly = true

		if data.timer > 2 and v.collidesBlockBottom then
			v:kill(HARM_TYPE_VANISH)
			npcutils.hideNPC(v)

			local shell = NPC.spawn(npcID+1,v.x+26,v.y+32,v.section,false,true)
			shell.data.health = data.health
			shell.friendly = false

			shell.data._settings.doesgroundpound = settings.doesgroundpound
			shell.data._settings.doeskoopathrow = settings.doeskoopathrow
			shell.data._settings.doeshammerthrow = settings.doeshammerthrow
			shell.data._settings.health= settings.health
			shell.data._settings.speed = settings.speed
			shell.data._settings.jumpheight = settings.jumpheight
			shell.data._settings.fireamount = settings.fireamount
			shell.data._settings.poundheight = settings.poundheight
			shell.data._settings.koopaspeed = settings.koopaspeed
			shell.data._settings.koopaspeedy = settings.koopaspeedy
			shell.data._settings.throwint = settings.throwint
		end
	elseif data.state == STATE_RECOVER then
		v.animationFrame = 2

		if data.timer > 2 and v.collidesBlockBottom then
			data.landTimer = data.landTimer + 1
			v.animationFrame = 1

			if data.landTimer > 6 then
				data.state = STATE_IDLE
				data.landTimer = 0
				data.timer = 0
			end
		end
	elseif data.state == STATE_GROUNDPOUND then
		if not settings.doesgroundpound then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_SPIT
			data.timer = 0
		else
			v.animationFrame = 1

			if data.timer == 6 then v.speedY = -settings.poundheight end
	
			if data.timer > 6 then
				v.animationFrame = 2
			end
	
			if data.timer > 42 and data.timer < 54 then
				v.speedY = -Defines.npc_grav
			end
	
			if data.timer > 54 then
				v.animationFrame = 7
			end
	
			if data.timer > 8 and v.collidesBlockBottom then
				data.landTimer = data.landTimer + 1
				v.animationFrame = 8
	
				if data.landTimer == 1 then
					Defines.earthquake = 6
					SFX.play(37)
					Animation.spawn(10, v.x - 17, v.y + v.height - 16)
					Animation.spawn(10, v.x + v.width - 15, v.y + v.height - 16)
					for k, p in ipairs(Player.get()) do
						if p:isGroundTouching() and not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == player.section then
							playerStun.stunPlayer(k, 90)
						end
					end
				end
	
				if data.landTimer > 36 then
					npcutils.faceNearestPlayer(v)
					data.state = STATE_SPIT
					data.landTimer = 0
					data.timer = 0
				end
			end
		end
	elseif data.state == STATE_HAMMERS then
		if not settings.doeshammerthrow then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_SPIT
			data.timer = 0
		else
			v.animationFrame = math.floor(data.timer/8)%4+3

			if data.timer > 22 then
				v.animationFrame = math.floor(data.timer/6)%4+9
	
				if data.timer > 23 and data.timer < 160 then
					if data.timer % settings.throwint == 0 then
						local projectile = NPC.spawn(npcID+3, v.x+24, v.y+16, v.section,false,true)
						npcutils.hideNPC(projectile)
						projectile.direction = v.direction
						projectile.speedX = RNG.randomEntry({1.5 * projectile.direction,2 * projectile.direction,2.5 * projectile.direction})
						projectile.speedY = RNG.randomEntry({-7,-7.5,-8})
						SFX.play(25)
					end
				end
	
				if data.timer > 160 then
					v.animationFrame = 5
	
					if data.timer > 168 then
						npcutils.faceNearestPlayer(v)
						data.state = STATE_SPIT
						data.timer = 0
					end
				end
			end
		end
	elseif data.state == STATE_KOOPA then
		if not settings.doeskoopathrow then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_SPIT
			data.timer = 0
		else
			v.animationFrame = math.floor(data.timer/8)%4+3

			if data.timer == 23 then
				data.npc = NPC.spawn(113,v.x+koopaSpawnOffset[v.direction],v.y-16,player.section)
				data.npc.friendly = true
				SFX.play(23)
			end
	
			if data.timer > 22 then
				v.animationFrame = 9
	
				if data.timer > 23 and data.timer < 82 then
					if data.npc and data.npc.isValid then
						if v.direction == 1 then
							data.npc.x = v.x-16
						else
							data.npc.x = v.x+32
						end
		
						data.npc.y = v.y-20
						data.npc.direction = v.direction
					end
				end
	
				if data.timer == 82 then
					if data.npc and data.npc.isValid then
						data.npc.y = data.npc.y - 18
						data.npc.speedX = settings.koopaspeed*v.direction
						data.npc.friendly = false
						data.npc:mem(0x136,FIELD_BOOL,true)
						data.npc.speedY = -settings.koopaspeedy
						SFX.play(25)
					end
				end
	
				if data.timer > 82 then
					v.animationFrame = 11
				elseif data.timer > 86 then
					v.animationFrame = 10
				end
	
				if data.timer > 120 then
					v.animationFrame = 5
	
					if data.timer > 126 then
						npcutils.faceNearestPlayer(v)
						data.state = STATE_SPIT
						data.timer = 0
					end
				end
			end
		end
	end

	if v.animationFrame >= 0 then
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end

	if data.state ~= STATE_DEFEATED then
		if reason ~= HARM_TYPE_LAVA then
			if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP then
				SFX.play(39)
				data.health = data.health - 1
				data.state = STATE_SHELL
				data.timer = 0
				v.speedX = 0
				v.speedY = -4
			elseif reason == HARM_TYPE_SWORD then
				if v:mem(0x156, FIELD_WORD) <= 0 then
					data.health = data.health - 1
					SFX.play(39)
					v:mem(0x156, FIELD_WORD,20)
				end
				if Colliders.downSlash(player,v) then
					player.speedY = -6
				end
			elseif reason == HARM_TYPE_NPC then
				if culprit then
					if type(culprit) == "NPC" then
						if culprit.id == 13  then
							SFX.play(9)
							data.health = data.health - 0.3
						elseif culprit.id == 171  then
							SFX.play(9)
							SFX.play(39)
							data.health = data.health - 1
							data.state = STATE_SHELL
							data.timer = 0
							v.speedX = 0
							v.speedY = -4
						else
							SFX.play(39)
							data.health = data.health - 1
							data.state = STATE_SHELL
							data.timer = 0
							v.speedX = 0
							v.speedY = -4
						end
					else
						data.health = data.health - 1
					end
				else
					data.health = data.health - 1
				end
			elseif reason == HARM_TYPE_LAVA and v ~= nil then
				v:kill(HARM_TYPE_OFFSCREEN)
			elseif v:mem(0x12, FIELD_WORD) == 2 then
				v:kill(HARM_TYPE_OFFSCREEN)
			else
				data.iFrames = true
				data.health = data.health - 5
			end
			if culprit then
				if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
					culprit:kill(HARM_TYPE_NPC)
				elseif culprit.__type == "Player" then
					--Bit of code taken from the basegame chucks
					if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
						culprit.speedX = -5
					else
						culprit.speedX = 5
					end
				elseif type(culprit) == "NPC" and (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45) and culprit.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
					culprit:kill(HARM_TYPE_NPC)
				end
			end
			if data.health <= 0 and reason ~= HARM_TYPE_OFFSCREEN then
				v:kill(HARM_TYPE_NPC)
			elseif data.health > 0 then
				v:mem(0x156,FIELD_WORD,60)
			end
		else
			v:kill(HARM_TYPE_LAVA)
		end
	else
		v:kill(HARM_TYPE_NPC)
	end
	eventObj.cancelled = true
end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	
    if data.state == STATE_SHELL then
	    if data.timer > 2 and v.collidesBlockBottom then
		    npcutils.drawNPC(v,{priority = -32})
	    end
    end
end

return sampleNPC