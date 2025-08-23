local npcManager = require("npcManager")
local ai = require("Ai/fires")

local fire = {}
local npcID = NPC_ID

local fireSettings = {
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	frames = 6,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = false,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	ignorethrownnpcs = true,


	movementSpeed = 1.5,   -- How fast the NPC moves when coming out or retracting back.
	hideTime      = 50,    -- How long the NPC rests before coming out.
	restTime      = 50,    -- How long the NPC rests before retracting back.
	ignorePlayers = false, -- Whether or not the NPC can come out, even if there's a player in the way.
	
	isHorizontal = false, -- Whether or not the NPC is horizontal.
	
	--Emits light if the Darkness feature is active:
	lightradius = 50,
	lightbrightness = 2,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	lightcolor = Color.orange,

}

npcManager.setNpcSettings(fireSettings)
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
)

ai.register(npcID)

return fire