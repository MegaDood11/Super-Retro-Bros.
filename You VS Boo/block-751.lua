local blockManager = require("blockManager")
local faceBlockAI = require("faceblock")

local faceBlock = {}
local blockID = BLOCK_ID

local faceBlockSettings = {
	id = blockID,
	frames = 8,
	framespeed = 8
}

blockManager.setBlockSettings(faceBlockSettings)

faceBlockAI.register(blockID, faceBlockAI.TYPE.SWITCH)

return faceBlock