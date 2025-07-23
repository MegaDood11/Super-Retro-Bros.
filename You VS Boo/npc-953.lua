--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	
	frames = 28,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	nowaterphysics = true,

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, 
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = 0
	end

	v.speedY = math.cos(lunatime.tick() / 8) * 1
	v.despawnTimer = 180

	if data.state == 0 then
		v.animationFrame = 0 + (player.section * 2) + ((v.direction + 1) * sampleNPCSettings.frames / 2)
	elseif data.state == 1 then
		v.animationFrame = 1 + (player.section * 2) + ((v.direction + 1) * sampleNPCSettings.frames / 2)
	end
end

--Gotta return the library table!
return sampleNPC