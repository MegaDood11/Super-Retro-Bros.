local npcManager = require("npcManager")
local AI = require("angrySun_ai")

local madMoonNPC = {}
local npcID = NPC_ID

local madMoonNPCSettings = table.join({
	id = npcID,
	gfxwidth=32,
	gfxheight=32,
	gfxoffsety = 0,
	frames=2,
	width=28,
	height=28,
	angryFrames = 1,
	afterimageColour = Color.gray,
	invertedMovement = true,
	horizontalDistance = 60,
	verticalDistance = 64,
	loopLaps = 3,
	swoopDelay = 64,
	stallDelay = 0,
	--projectileNPC = 705,
	iscold = true,
	cameraPositionY = 0.30,
}, AI.sharedSettings)

npcManager.setNpcSettings(madMoonNPCSettings)

AI.register(npcID, true, npcID)

return madMoonNPC