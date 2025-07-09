local blockManager = require("blockManager")
local faceBlockAI = require("faceblock")

local timerFaceBlock = {}
local blockID = BLOCK_ID

local timerFaceBlockSettings = {
	id = blockID,
	frames = 12,
	framespeed = 8
}

blockManager.setBlockSettings(timerFaceBlockSettings)

faceBlockAI.register(blockID, faceBlockAI.TYPE.TIMERSWITCH)

return timerFaceBlock