local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 4,
	framestyle = 0,
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
	noiceball = false,
	noyoshi= false,

	score = 1,

	jumphurt = true,
	spinjumpsafe = true,
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
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
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



function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

local function getDistance(k,p)
	return k.x < p.x
end

local function setDir(dir, v)
	if (dir and v.direction == 1) or (v.direction == -1 and not dir) then return end
	if dir then
		v.direction = 1
	else
		v.direction = -1
	end
end

local function chasePlayers(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir1 = getDistance(v, plr)
	setDir(dir1, v)
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
		data.health = settings.health
		data.timer = data.timer or 0
		data.animTimer = 0
	end

	if v.heldIndex ~= 0
	or v.isProjectile
	or v.forcedState > 0
	then
		-- Handling
	end

	v.animationFrame = 0
	data.timer = data.timer + 1

	if data.timer > 16 then
		data.animTimer = data.animTimer + 1
		v.animationFrame = math.floor(data.animTimer/5)%config.frames
		SFX.play("koopaling-shell.wav", 100, 1, 16)

		if data.timer > 17 and data.timer < 280 then
			v.speedX = math.clamp(v.speedX + 0.25 * v.direction, -2, 2)
			chasePlayers(v)
		end

		if data.timer == 280 then
			v.speedX = 0
			v.speedY = -4
		end
		
		if v.collidesBlockBottom then
			v.speedY = -8
		end

		if v.speedY > 0 and data.timer > 282 then
			v:kill(HARM_TYPE_VANISH)
			npcutils.hideNPC(v)
			local jr = NPC.spawn(npcID-1,v.x+16,v.y+8,v.section,false,true)
			jr.data.health = data.health
			jr.data.indicatorTimer = 141
			npcutils.faceNearestPlayer(jr)
			jr.animationFrame = -999
			jr.data.state = 4

			jr.data._settings.doesgroundpound = settings.doesgroundpound
			jr.data._settings.doeskoopathrow = settings.doeskoopathrow
			jr.data._settings.doeshammerthrow = settings.doeshammerthrow
			jr.data._settings.health= settings.health
			jr.data._settings.speed = settings.speed
			jr.data._settings.jumpheight = settings.jumpheight
			jr.data._settings.fireamount = settings.fireamount
			jr.data._settings.poundheight = settings.poundheight
			jr.data._settings.koopaspeed = settings.koopaspeed
			jr.data._settings.koopaspeedy = settings.koopaspeedy
			jr.data._settings.throwint = settings.throwint
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = data.frames
	});
end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	
	if v.speedY > 0 and data.timer > 282 then
		npcutils.hideNPC(v)
	end
end

return sampleNPC