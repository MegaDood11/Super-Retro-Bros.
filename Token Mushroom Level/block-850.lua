--Blockmanager is required for setting basic Block properties
local blockManager = require("blockManager")
local feet = require("blocks/ai/stoodon")

local blockID = BLOCK_ID
local sampleBlock = {}

--Defines Block config for our Block. You can remove superfluous definitions.
local sampleBlockSettings = {
	id = blockID,
	frames = 1,
	sizable = true,
	semisolid = true,
}

--- function by MDA
local function isOnGround(p) -- Detects if the player is on the ground, the redigit way. Sometimes more reliable than just p:isOnGround().
    return (
        (p.speedY == 0 and not p.climbing) -- "on a block"
        or p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
        or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
    )
end

--Code runs when you stand on the block. Move the block and player standing on it in accordance to the extra settings, and set data.stoodOn to true
feet.register(blockID, function(v, p)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data
	if v.height >= 64 then
		p.y = p.y + v.data._settings.speed * ((v.data._settings.direction * 2) - 1)
		v.height = v.height - v.data._settings.speed * ((v.data._settings.direction * 2) - 1)
		v.y = v.y + v.data._settings.speed * ((v.data._settings.direction * 2) - 1)
	end
	data.stoodOn = true
end)

function sampleBlock.onInitAPI()
    blockManager.registerEvent(blockID, sampleBlock, "onTickBlock")
end

function sampleBlock.onTickBlock(v)
	local data = v.data
	
	--A variable that determines where its original height is, so it knows how far to retract back down
	if data.originalHeight == nil then data.originalHeight = v.height end
	
	--If NOT being stood on, slow down the speed and return to its original height
	if not data.stoodOn then
		if math.abs(v.height - data.originalHeight) >= 4 then
			if lunatime.tick() % 3 == 0 then
				v.height = v.height + (math.ceil(v.data._settings.speed / 4)) * (math.sign(data.originalHeight - v.height))
				v.y = v.y - (math.ceil(v.data._settings.speed / 4)) * (math.sign(data.originalHeight - v.height))
			end
		end
	end
	
	--Keep all blocks in the same group
	for _,n in ipairs(Block.get(blockID)) do
		if n.idx ~= v.idx and n.data._settings.group == v.data._settings.group then
			if data.stoodOn and n.height >= 64 then
				n.height = n.height + n.data._settings.speed * ((n.data._settings.direction * 2) - 1)
				n.y = n.y - n.data._settings.speed * ((n.data._settings.direction * 2) - 1)
			end
		end
	end
	
	data.stoodOn = false
	
end

--Applies blockID settings
blockManager.setBlockSettings(sampleBlockSettings)

--Gotta return the library table!
return sampleBlock