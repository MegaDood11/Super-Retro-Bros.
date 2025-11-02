--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local redirector = require("redirector")
local smb1HUD = require("smb1HUD")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Frameloop-related
	frames = 1,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes
	
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	nowaterphysics = true,
	nogravity = true,
	noblockcollision = true,
	ignorethrownnpcs = true,
	nohurt = true,
	
	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	isinteractable = true,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	registerEvent(sampleNPC, "onDraw")
	registerEvent(sampleNPC, "onPostNPCKill")
end

if not SaveData.eggCollected then
	SaveData.eggCollected = {}
end

local thingo = false

function sampleNPC.onTickNPC(v)
	if not v.data.id then v.data.id = Level.filename() end
	for _,collect in ipairs(SaveData.eggCollected) do
		if v.data.id == collect then
			if lunatime.tick() >= 8 then
				v:kill(9)
			end
			thingo = true
		end
	end
end

local display = false
local frame = 0

function sampleNPC.onDraw()
	for _,v in ipairs(NPC.get(npcID)) do
		if v.data.id and Level.filename() == v.data.id then
			display = true
		end
		
		for _,collect in ipairs(SaveData.eggCollected) do
			if v.data.id == collect then
				frame = 1
			end
		end
		
	end
	
	--Where the HUD display happens
	if display and not thingo then
		Graphics.drawImageWP(
			Graphics.loadImageResolved("Yoshi Egg.png"),
			2, 400,
			0, frame * 46,
			46, 46,
			5
		)
	end
end

function sampleNPC.onPostNPCKill(v,reason)
	if v.id == npcID and reason == HARM_TYPE_OFFSCREEN and (npcManager.collected(v,reason) or v:mem(0x138,FIELD_WORD) == 5) then
		local w = Effect.spawn(npcID,0,0)
		w.x = (v.x+(v.width /2)-(w.width /2))
		w.y = (v.y+(v.height/2)-(w.height/2))
		for i = 1,4 do
			local e = Effect.spawn(80,0,0)
			e.x = (v.x+(v.width * 0.25))
			e.y = (v.y+(v.height * 0.25))
			if i % 4 <= 1 then e.speedY = -2 else e.speedY = 2 end
			if i % 2 == 1 then e.speedX = 2 else e.speedX = -2 end
		end
		SFX.play(48)
		SaveData.letterWorldProgress = SaveData.letterWorldProgress + 1
		table.insert(SaveData.eggCollected, v.data.id)
		frame = 1
	end
end

--Gotta return the library table!
return sampleNPC