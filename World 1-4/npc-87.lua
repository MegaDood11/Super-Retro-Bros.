local ball = {}
local npcManager = require("npcManager")

local npcID = NPC_ID

function ball.onTickEndNPC(v)
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
	end
	
	if (v.x + v.width > camera.x and v.x < camera.x + camera.width and v.y + v.height > camera.y and v.y < camera.y + camera.height) and not data.spawned then
		v.speedX = 2 * v.direction
		SFX.play(42)
		data.spawned = true
	end
end

function ball.onInitAPI()
	npcManager.registerEvent(npcID, ball, "onTickEndNPC")
end

return ball