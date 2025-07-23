local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local validIDs = {}
local sidestepper = {}

function sidestepper.register(npcID)
	npcManager.registerEvent(npcID, sidestepper, "onTickEndNPC")
	registerEvent(sidestepper, "onNPCHarm")
	registerEvent(sidestepper, "onPlayerHarm")
end

function sidestepper.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if not table.contains(validIDs, v.id) then table.insert (validIDs, (table.maxn(validIDs) + 1), v.id) end
	
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
		v.ai1 = 0 --NPC State
		v.ai2 = 0 --Is the NPC taking knockback?
		v.ai3 = 0 --NPC cooldown
		v.ai4 = 0 --Stored direction
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	Text.print(v.ai1, 100, 100)
	Text.print(v.ai2, 100, 116)
	Text.print(v.direction, 100, 132)
	
	if v.ai3 > 0 then
		v.ai3 = v.ai3 - 1
	end
	
	if NPC.config[v.id].isFlipped then
		if v.ai2 == 1 then
			v.friendly = false
			v.speedX = 0
		end
		
		v.nohurt = true
		v.jumphurt = false
		
		if Colliders.collide(player, v) then
			Misc.givePoints(2, {x = v.x, y = v.y}, true)
			v:kill(HARM_TYPE_NPC)
		end
		
		v:mem(0x12E, FIELD_WORD, 1)
		data.stunTimer = data.stunTimer + 1
		
		if data.stunTimer == 200 then
			v.speedY = -4
			v.ai1 = 0
			data.stunTimer = 0
			v:transform(NPC.config[v.id].advancedNPC)
		elseif data.stunTimer > 175 then
			v.animationTimer = v.animationTimer + 1
		end
	elseif v.ai1 == 0 then
		if v.ai2 == 0 then
			v.speedX = (NPC.config[v.id].speed + .2) * v.direction
		end
		
		if v.animationFrame == 5 then
			v.animationFrame = 1
		elseif v.animationFrame > 1 then
			v.animationFrame = 0
		end
	elseif not NPC.config[v.id].isFlipped then
		if v.ai2 == 0 then
			v.speedX = (NPC.config[v.id].speed + 1 + .2) * v.direction
		end
		
		v.animationTimer = v.animationTimer + .5
		
		if v.animationFrame < 2 then
			v.animationFrame = 3
		elseif v.animationFrame > 3 then
			v.animationFrame = 2
		end
	end
	
	if v.collidesBlockBottom and v.ai3 == 0 and v.ai2 == 1 then
		v.direction = v.ai4
		v.ai2 = 0
	end
end

function sidestepper.onNPCHarm(eventObj, v, killReason, culprit)
	if not table.contains(validIDs, v.id) or v.isGenerator then return end
	
	local data = v.data
	
	if killReason == HARM_TYPE_FROMBELOW or killReason == HARM_TYPE_TAIL or killReason == HARM_TYPE_SWORD then
		eventObj.cancelled = true
		
		if v.ai3 == 0 then
			if v.ai1 == 1 then
				v.ai1 = 0
				data.stunTimer = 0
				v:transform(NPC.config[v.id].flippedNPC)
			elseif NPC.config[v.id].isFlipped == true then
				v.ai1 = 0
				data.stunTimer = 0
				v:transform(NPC.config[v.id].flippedNPC)
			else
				v.ai1 = v.ai1 + 1
			end
			SFX.play(2)
			v.ai2 = 1
			v.ai3 = 10
			v.ai4 = v.direction
			v.speedX = (NPC.config[v.id].speed + .2) * player.direction
			v.speedY = -4
		end
	elseif killReason == HARM_TYPE_NPC then
		if v.ai1 == 0 and NPC.config[v.id].isFlipped == false then
			eventObj.cancelled = true
			SFX.play(9)
			v.ai1 = v.ai1 + 1
			v.ai2 = 1
			v.ai4 = v.direction
			v.speedX = (NPC.config[v.id].speed + .2) * culprit.direction
			v.speedY = -4
		end
	end
end

return sidestepper