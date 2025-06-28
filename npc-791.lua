-- moving lift from lost levels
-- based on math platforms from basegame, edited by cold soup

local npcManager = require("npcManager")
local redirector = require("redirector")

local moveLift = {}

local bgoPoint = Colliders.Point(0,0)
local npcBox = Colliders.Box(0,0,1,1)

local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local moveSettings = {
	id = npcID, 
	gfxwidth = 64, 
	gfxheight = 32, 
	width = 64,
	height = 32, 
	frames = 1, 
	framestyle = 0, 
	framespeed = 8, 
	score = 0, 
	blocknpctop = -1, 
	playerblocktop = -1, 
	ignorethrownnpcs = true,
	nohurt = 1, 
	nogravity = 1, 
	noblockcollision = 1, 
	noyoshi = 1, 
	noiceball = 1, 
	notcointransformable = true,
	nowalldeath = true,

	luahandlesspeed = true,
	speed = 2.5,
	
	despawntime = 95,
	deatheffect = 10,
	notcointransformable = true,
}

local configFile = npcManager.setNpcSettings(moveSettings);

-- register functions
function moveLift.onInitAPI()
	npcManager.registerEvent(npcID, moveLift, "onTickEndNPC")
end

--*********************************************
--                                            *
--                   AI                       * 
--                                            *
--*********************************************

function moveLift.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
	local config = NPC.config[v.id]

	-- reset everything when offscreen or grabbed or in reserve box
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then
		data.initialized = false
		return
	end
	
	--Initialize
	if not data.initialized then
		v.x = v.spawnX
		v.y = v.spawnY

        data.despawning = false
		data.despawnTimer = config.despawntime

		data.initialized = true
	end

	-- check for player standing on the NPC
	if (v.ai3 == 0) then
		for _,p in ipairs(Player.get()) do
			if (p.standingNPC ~= nil and p.standingNPC.idx == v.idx) then
				v.ai3 = 2;
				v.speedX = config.speed * v.direction;
				break;
			end
		end
	end

	-- terminus collision
	for _,b in ipairs(BGO.getIntersecting(v.x,v.y,v.x+v.width,v.y+v.height)) do
		bgoPoint.x = b.x + 16
		bgoPoint.y = b.y + 16

		-- collision box is a small square in the middle of the platform. scales with speed
		local boxwidth = math.max(8,math.abs(v.speedX) + 4)
		local boxheight = math.max(8,math.abs(v.speedY) + 6)

		npcBox.x = v.x + (v.width/2) - (boxwidth/2)
		npcBox.y = v.y + (v.height/2) - (boxheight/2)
		npcBox.width = boxwidth
		npcBox.height = boxheight

		if not v.isHidden and Colliders.collide(bgoPoint,npcBox) then
			if b.id == redirector.TERMINUS then
				data.despawning = true
			end
		end
	end

	-- despawn behavior
	if data.despawning then
		data.despawnTimer = data.despawnTimer - 1

		-- flash when despawning
		v.animationFrame = -1 + (lunatime.tick() % 2)

		if data.despawnTimer <= 0 then
			Effect.spawn(config.deatheffect, v.x+(v.width/2)-16, v.y)
    		v:kill(HARM_TYPE_VANISH)
		end
	end
end

return moveLift;