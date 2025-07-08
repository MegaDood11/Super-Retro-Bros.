--[[

	Extended Koopas
	Made by MrDoubleA

	See extendedKoopas.lua for full credits

]]

local npcManager = require("npcManager")

local extendedKoopas = require("extendedKoopas")

local koopa = {}
local npcID = NPC_ID

local deathEffect = (npcID - 3)


local koopaSettings = {
	id = npcID,

	jumphurt = true,
	spinjumpsafe = true,
}

npcManager.setNpcSettings(koopaSettings)
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA},
	{[HARM_TYPE_FROMBELOW] = 892,
	[HARM_TYPE_NPC] = 892,
	[HARM_TYPE_HELD] = 892,
	[HARM_TYPE_TAIL] = 892,
	[HARM_TYPE_PROJECTILE_USED] = 892,
	[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
})


extendedKoopas.registerKoopa(npcID)


return koopa