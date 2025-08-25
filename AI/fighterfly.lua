local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local validIDs = {}
local fighterfly = {}

function fighterfly.register(npcID)
	npcManager.registerEvent(npcID, fighterfly, "onTickEndNPC")
	registerEvent(fighterfly, "onNPCHarm")
	registerEvent(fighterfly, "onPlayerHarm")
end

function fighterfly.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	
	if not table.contains(validIDs, v.id) then table.insert (validIDs, (table.maxn(validIDs) + 1), v.id) end

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		v.ai1 = 0 --NPC State
		v.ai2 = 0 --Is the NPC taking knockback?
		v.ai3 = 0 --NPC cooldown (hurt timer)
		v.ai4 = 0 --Stored direction
		data.timer = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Text.print(v.ai1, 100, 100)
	--Text.print(v.ai2, 100, 116)
	--Text.print(v.direction, 100, 132)
	
	if v.ai3 > 0 then
		v.ai3 = v.ai3 - 1
	end
	
	if cfg.isFlipped then
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
		
		if data.stunTimer == cfg.returnTime then
			v.speedY = -6
			v.ai1 = 1
			data.stunTimer = 0
			v:transform(cfg.advancedNPC)
		elseif data.stunTimer > cfg.animationSpeedUp then
			v.animationTimer = v.animationTimer + 1
		end
	elseif v.ai1 >= 0 then
		v.ai1=0
		if v.collidesBlockBottom then
			v.speedX = 0
			data.timer = data.timer + 1
			v.friendly = false
			v.animationFrame = 0
            if cfg.chase then
			    if plr.x < v.x then
				    v.direction = DIR_LEFT
			    else
				    v.direction = DIR_RIGHT
			    end
            end
			if data.timer >= cfg.waitTime then
				v.speedY = -cfg.jumpHeight
				if cfg.playSound then
					SFX.play(cfg.soundID)
				end
			end
		else
			
			v.speedX = 1.4 * v.direction
			
			v.animationFrame = math.floor((lunatime.tick() / 1) % 2) + 1
			
			data.timer = 0
		end
	end
	
	if v.collidesBlockBottom and v.ai3 == 0 and v.ai2 == 1 then
		v.direction = v.ai4
		v.ai2 = 0
	end
end

function fighterfly.onNPCHarm(eventObj, v, killReason, culprit)
	if not table.contains(validIDs, v.id) or v.isGenerator then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]

	if v.ai3 > 0 then
		eventObj.cancelled = true
		return
	end
	
	if killReason == HARM_TYPE_FROMBELOW or killReason == HARM_TYPE_TAIL or killReason == HARM_TYPE_SWORD then
		if v.ai3 == 0 then
			if v.ai1 == 0 or cfg.isFlipped then
				v.ai1 = 0
				data.stunTimer = 0
				v:transform(cfg.flippedNPC)
			end
			SFX.play(2)
			v.ai1 = v.ai1 + 1
			v.ai2 = 1
			v.ai3 = 15
			v.ai4 = v.direction
			v.speedX = (cfg.speed + .2) * player.direction
			v.speedY = -4
		end
	end
end

return fighterfly