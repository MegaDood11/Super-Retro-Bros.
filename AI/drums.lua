local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
local rng = require("rng")

--******************************************************
--Graphics made by, and requested by FireSeraphim.
--******************************************************

--Thanks to 9thCore for showing me how to add a random death direction.

local drums = {}

local npcIDs = {}

--Register events
function drums.register(id)
	npcManager.registerEvent(id, drums, "onTickNPC")
	registerEvent(drums, "onNPCKill")
	npcIDs[id] = true
end

function drums.onNPCKill(eventObj, v, reason)
	local data = v.data
	if v.id == 991 or v.id == 993 then
		--Kill the Fire NPC if on top of it when the drum is killed.
		for _,p in ipairs(NPC.getIntersecting(v.x, v.y - 5, v.x + v.width, v.y + v.height)) do
			if p.id == 992 or p.id == 994 then
				p:harm(HARM_TYPE_OFFSCREEN)
			end
		end
	end
end

function effectconfig.onTick.TICK_drums(v)
    if v.timer == v.lifetime-1 then
		v.dir = v.dir or rng.randomInt(0, 1)*2-1
		v.speedX = math.abs(v.speedX) * v.dir
    end
end

function drums.onTickNPC(v)
	v.speedY = 0
	for _,p in ipairs(NPC.getIntersecting(v.x - 8, v.y - 8, v.x + v.width + 8, v.y + v.height + 8)) do
		if p.speedX ~= 0 and (NPC.config[p.id].isshell or p.id == 952) then
			v:kill(HARM_TYPE_OFFSCREEN)
		end
	end
end

return drums

