local blockManager = require("blockManager")
local faceBlockAI = require("faceblock")

local spikeTrap = {}
local blockID = BLOCK_ID

local spikeTrapSettings = {
	id = blockID,
	frames = 8,
	framespeed = 8
}

blockManager.setBlockSettings(spikeTrapSettings)

faceBlockAI.register(blockID, faceBlockAI.TYPE.SOLID, faceBlockAI.TYPE.SPIKE)

return spikeTrap