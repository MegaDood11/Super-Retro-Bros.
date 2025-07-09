local blockManager = require("blockManager")
local faceBlockAI = require("faceblock")

local dottedLineBlock = {}
local blockID = BLOCK_ID

local dottedLineBlockSettings = {
	id = blockID,
	frames = 8,
	framespeed = 8
}

blockManager.setBlockSettings(dottedLineBlockSettings)

faceBlockAI.register(blockID, faceBlockAI.TYPE.SOLID, faceBlockAI.TYPE.NONSOLID)

return dottedLineBlock