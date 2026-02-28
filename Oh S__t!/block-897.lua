local blockmanager = require("blockmanager")
local escalator = require("blocks/ai/escalator")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	frames = 8,
	framespeed = 1,
	speed = 2,
	sizable = true,
	semisolid = false,
	direction = -1
})

escalator.register(blockID)

return block