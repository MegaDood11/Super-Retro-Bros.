local blockManager = require("blockManager")
local AI = require("AI/checkpointBlock")
local textplus = require("textplus")

local checkpoint = {}
local blockID = BLOCK_ID

local checkpointSettings = {
	id = blockID,

	sizable = true,
	passthrough = true,


	-- you can use textplus tags
	checkpointText = "Checkpoint!",

	-- settings passed to textplus.parse
	fontSettings = {
		font   = textplus.loadFont("textplus/font/6.ini"),
		xscale = 2,
		yscale = 2,
		plainText = true,
	},
}

blockManager.setBlockSettings(checkpointSettings)
AI.register(blockID)

return checkpoint