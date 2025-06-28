local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local platform = {}
local npcID = NPC_ID

local platformSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 96,
	width = 96,
	height = 32,
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	npcblock = false,
	npcblocktop = true,
	playerblock = false,
	playerblocktop = true,
	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	ignorethrownnpcs = true,
	noyoshi = true,
	nowaterphysics = false,
	harmlessgrab = true,
	harmlessthrown = true,
	sinkspeed = 4,
	notcointransformable = true,
}

npcManager.setNpcSettings(platformSettings)

npcManager.registerHarmTypes(npcID,	{}, {})

function platform.onInitAPI()
	npcManager.registerEvent(npcID, platform, "onTickNPC")
end

function platform.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		v.speedX = 0
		v.speedY = 0
		data.stoodon = false
		data.initialized = true
	end
	
	data.stoodon = false
	for i,p in ipairs(Player.get()) do
		if p.standingNPC == v then
			data.stoodon = true
			break
		end
	end
	if data.stoodon then
		v.speedY = cfg.sinkspeed
	else
		v.speedY = 0
	end
	npcutils.applyLayerMovement(v)
end

return platform