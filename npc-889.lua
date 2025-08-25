--Super Mario Land Fly originally made by MegaDood. Edited and repurposed into the Mario Bros. Fighter Fly by Ness-Wednesday.
--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local fighterfly = require("AI/fighterfly")
--Create the library table
local Buzz = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local BuzzSettings = {
id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	--Frameloop-related
	frames = 3,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	score = 2,
	jumpHeight = 6,
	waitTime = 30,
    chase = false,
    playSound = false,
    soundID = 24,
    flippedNPC = 890,
    advancedNPC = 889,
    isFlipped = false
}

--Applies NPC settings
npcManager.setNpcSettings(BuzzSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		--[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN] = {id=npcID, speedY=-2.5},
		[HARM_TYPE_SWORD]=10,
	}
);

fighterfly.register(npcID)
return Buzz