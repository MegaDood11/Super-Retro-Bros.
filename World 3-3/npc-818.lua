--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local rad, sin, cos, pi = math.rad, math.sin, math.cos, math.pi

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	frames = 4,
	framestyle = 1,
	framespeed = 8,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,

	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	turnTime = 160,
	calmActiveradius = 256,
	angryActiveradius = 448,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]={id=npcID + 1, yoffset=1, yoffsetBack = 1},
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

local STATE_CALM = 0
local STATE_CHASE = 1

local function getDistance(k,p)
	return k.x < p.x
end

local function setDir(dir, v)
	if (dir and v.data._basegame.direction == 1) or (v.data._basegame.direction == -1 and not dir) then return end
	if dir then
		v.data._basegame.direction = 1
	else
		v.data._basegame.direction = -1
	end
end

local function chasePlayers(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir1 = getDistance(v, plr)
	setDir(dir1, v)
end

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = STATE_CALM
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_CALM
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_CALM
	end
	
	v.ai3 = v.ai3 + 1
	
	if v.forcedState ~= 0 then
		v.ai3 = 0
	end
	
	if v.ai2 <= 0 then
		data.w = 1 * pi/100
		data.timer = data.timer or 0
		data.timer = data.timer + 1
		v.speedY = -8 * data.w * cos(data.w*data.timer)
	end
	
	if data.state == STATE_CALM then
		v.animationFrame = math.floor(lunatime.tick() / 8) % 2 + 2
		if v.ai2 <= 0 then
			v.ai1 = v.ai1 + 1
			if v.ai1 >= sampleNPCSettings.turnTime then
				v.ai1 = 0
				v.direction = -v.direction
			end
			v.speedX = 1.25 * v.direction
			if math.abs(plr.x-v.x)<=sampleNPCSettings.calmActiveradius and v.ai3 >= 32 then
				v.spawnY = v.y
				v.ai1 = 0
				v.ai2 = 1
				npcutils.faceNearestPlayer(v)
			end
		else
			v.y = v.y - 1
			if v.y <= v.spawnY - 8 then
				data.state = STATE_CHASE
			end
		end
	else
		v.animationFrame = math.floor(lunatime.tick() / 8) % 2
		if v.ai2 > 0 then
			if v.y < v.spawnY then
				v.y = v.y + 1
			end
			if v.y >= v.spawnY then
				v.ai2 = 0
			end
		else
			chasePlayers(v)
			v.speedX = math.clamp(v.speedX + 0.075 * data.direction, -3, 3)
			if math.abs(plr.x-v.x)>sampleNPCSettings.angryActiveradius then
				data.state = STATE_CALM
			end
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
	
end

--Gotta return the library table!
return sampleNPC