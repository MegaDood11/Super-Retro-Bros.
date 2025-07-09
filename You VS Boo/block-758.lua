local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local trampoline = {}
local blockID = BLOCK_ID

local trampolineSettings = {
	id = blockID,
	frames = 2,
	framespeed = 4,
	jumpstrength = 10,
	disablesspinjumps = true,
	bouncesound = "smbdx-trampoline.ogg"
}

blockManager.setBlockSettings(trampolineSettings)

function trampoline.onInitAPI()
	blockManager.registerEvent(blockID, trampoline, "onTickBlock")
	blockManager.registerEvent(blockID, trampoline, "onDrawBlock")
	registerEvent(trampoline, "onBlockConfigChange")
end

local function getSoundIDOrPath(configName)
	local sfxConfig = Block.config[blockID][configName]
	return tonumber(sfxConfig) or Misc.resolveSoundFile(sfxConfig)
end

local soundConfigName = "bouncesound"
local sfx = getSoundIDOrPath(soundConfigName)

function trampoline.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	local cfg = Block.config[v.id]
	
	if not data.initialized then
		data.animationTimer = 0
		data.initialized = true
	end
	
	for i,p in ipairs(Player.getIntersecting(v.x, v.y - 1, v.x + v.width, v.y)) do
		if Misc.canCollideWith(p, v) and p.isOnGround then
			if p.keys.jump or p.keys.altJump then
				p.speedY = -math.abs(cfg.jumpstrength)
			else
				p.speedY = -6
			end
			if cfg.disablesspinjumps then p:mem(0x50, FIELD_BOOL, false) end
			data.animationTimer = 1
			SFX.play(sfx)
		end
	end
	
	if data.animationTimer >= cfg.frames * cfg.framespeed then
		data.animationTimer = 0
	elseif data.animationTimer > 0 then
		data.animationTimer = data.animationTimer + 1
	end
end

function trampoline.onDrawBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	local cfg = Block.config[v.id]
	
	Graphics.draw{
		type = RTYPE_IMAGE,
		image = Graphics.sprites.block[v.id].img,
		x = v.x,
		y = v.y + v:mem(0x56, FIELD_WORD),
		sourceY = v.height * (math.floor(data.animationTimer / cfg.framespeed) % cfg.frames),
		sourceHeight = v.height,
		priority = -65,
		sceneCoords = true
	}
	blockutils.setBlockFrame(v.id, -1)
end

function trampoline.onBlockConfigChange(id, configName)
	if id ~= blockID then return end
	
	if configName == soundConfigName then sfx = getSoundIDOrPath(configName) end
end

return trampoline