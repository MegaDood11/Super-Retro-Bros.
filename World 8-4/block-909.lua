local blockmanager = require("blockmanager")
local escalator = require("blocks/ai/escalator")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	frames = 1,
	framespeed = 1,
	speed = 2,
	sizable = false,
	semisolid = false,
	direction = -1
})

escalator.register(blockID)

return block