local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 18,
	gfxheight = 16,

	width = 16,
	height = 16,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framestyle = 1,
	framespeed = 8,

	foreground = false,

	speed = 1,
	luahandlesspeed = false,
	nowaterphysics = false,
	cliffturn = false,
	staticdirection = false,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,

	score = 1,

	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	nowalldeath = false,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
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
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.rotation = 0
		data.scale = 0
	end

	if v.heldIndex ~= 0
	or v.isProjectile
	or v.forcedState > 0
	then
		-- Handling
	end

	if lunatime.tick() % 4 == 0 then
		data.rotation = data.rotation + 90*v.direction
	end

	data.scale = data.scale + 0.2

	if data.scale > 1 then
		data.scale = 1
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = data.frames
	});
end

function sampleNPC.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden or not v.data.initialized then return end

	local config = NPC.config[v.id]
	local data = v.data

	local img = Graphics.sprites.npc[v.id].img

	local priority = -45

    Graphics.drawBox{
        texture = img,
        x = v.x + v.width,
        y = v.y + v.height,
        width = config.gfxwidth * data.scale,
		height = config.gfxheight * data.scale,
        sourceY = v.animationFrame * config.gfxheight,
        sourceHeight = config.gfxheight,
        sourceWidth = config.gfxwidth,
        sceneCoords = true,
        centered = true,
        priority = priority,
		rotation = data.rotation
    }

	npcutils.hideNPC(v)
end

return sampleNPC