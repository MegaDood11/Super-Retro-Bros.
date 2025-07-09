local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local trollWoodBlock = {}
local npcID = NPC_ID

local trollWoodBlockSettings = {
	id = npcID,

	gfxwidth = 80,
	gfxheight = 68,
	width = 80,
	height = 64,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 1,
	framestyle = 0,
	framespeed = 8, 

	speed = 1,
	
	npcblock = true,
	npcblocktop = false, 
	playerblock = true,
	playerblocktop = true, 

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,

	score = 0, 
	notcointransformable = true, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	isstationary = true,
	staticdirection = true, 
}

npcManager.setNpcSettings(trollWoodBlockSettings)

npcManager.registerHarmTypes(npcID,{},{})

function trollWoodBlock.onInitAPI()
	npcManager.registerEvent(npcID, trollWoodBlock, "onTickEndNPC")
	npcManager.registerEvent(npcID, trollWoodBlock, "onDrawNPC")
end

function trollWoodBlock.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	npcutils.applyLayerMovement(v)
	
	if v.despawnTimer <= 0 then
		data.offset = 0
		data.offsetGoal = 0
		data.occupiedOffset = false
		data.cooldown = 0
		data.bumpColliderLeft = Colliders.Box(v.x - 4, v.y, 4, v.height)
		data.bumpColliderRight = Colliders.Box(v.x + v.width, v.y, 4, v.height)
		data.enemyColliderLeft = Colliders.Box(v.x - 6, v.y, 6, v.height)
		data.enemyColliderRight = Colliders.Box(v.x + v.width, v.y, 6, v.height)
		return
	end

	if not data.initialized then
		data.initialized = true
		data.offset = 0
		data.offsetGoal = 0
		data.occupiedOffset = false
		data.cooldown = 0
		data.releasedContainer = false
		data.bumpColliderLeft = Colliders.Box(v.x - 4, v.y, 4, v.height)
		data.bumpColliderRight = Colliders.Box(v.x + v.width, v.y, 4, v.height)
		data.enemyColliderLeft = Colliders.Box(v.x - 6, v.y, 6, v.height)
		data.enemyColliderRight = Colliders.Box(v.x + v.width, v.y, 6, v.height)
	end

	data.bumpColliderLeft.x = v.x - 4
	data.bumpColliderLeft.y = v.y
	data.bumpColliderRight.x = v.x + v.width
	data.bumpColliderRight.y = v.y

	data.enemyColliderLeft.x = v.x - 6
	data.enemyColliderLeft.y = v.y
	data.enemyColliderRight.x = v.x + v.width
	data.enemyColliderRight.y = v.y

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		data.offset = 0
		data.offsetGoal = 0
		data.occupiedOffset = false
		data.cooldown = 12
		return
	end

	data.cooldown = data.cooldown - 1

	if data.occupiedOffset then
        	if data.offsetGoal > 0 then data.offset = data.offset + 4
        	elseif data.offsetGoal < 0 then data.offset = data.offset - 4 end
		if data.offset == data.offsetGoal then 
			data.occupiedOffset = false 
			data.offsetGoal = 0
		end
	else
        	if data.offset > 0 then data.offset = data.offset - 4
        	elseif data.offset < 0 then data.offset = data.offset + 4 end
	end

	if data.cooldown <= 0 then
		for _,p in ipairs(Player.get()) do
			if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) and Misc.canCollideWith(v, p) then
				if Colliders.collide(data.bumpColliderLeft, p) or Colliders.collide(data.bumpColliderRight, p) then
					if Colliders.collide(data.bumpColliderLeft, p) then
						data.offsetGoal = 24
						p.speedX = -2
						for _, npc in ipairs(Colliders.getColliding{a = data.enemyColliderRight, b = NPC.HITTABLE, btype = Colliders.NPC}) do npc:harm(HARM_TYPE_TAIL) end
						if not data.releasedContainer then
							if v.ai1 > 0 then
								data.releasedContainer = true
								SFX.play(7)
	                                			local n = NPC.spawn(v.ai1, v.x, v.y + (v.height * 0.5), v.section)
								n.y = n.y - (n.height * 0.5)
								n.forcedState = 4
								n.forcedCounter1 = v.x + v.width
								n.forcedCounter2 = 4
                     	                			n.layerName = "Spawned NPCs"
        	                        			n.friendly = v.friendly
							end
	                        		end
					elseif Colliders.collide(data.bumpColliderRight, p) then
						data.offsetGoal = -24
						p.speedX = 2
						for _, npc in ipairs(Colliders.getColliding{a = data.enemyColliderLeft, b = NPC.HITTABLE, btype = Colliders.NPC}) do npc:harm(HARM_TYPE_TAIL) end
						if not data.releasedContainer then
							if v.ai1 > 0 then
								data.releasedContainer = true
								SFX.play(7)
	                                			local n = NPC.spawn(v.ai1, v.x, v.y + (v.height * 0.5), v.section)
								n.y = n.y - (n.height * 0.5)
								n.forcedState = 4
								n.forcedCounter1 = v.x
								n.forcedCounter2 = 2
                     	                			n.layerName = "Spawned NPCs"
        	                        			n.friendly = v.friendly
							end
	                        		end
					end
					data.occupiedOffset = true
					data.cooldown = 24
					SFX.play(3)
					if SaveData.minusMedals and SaveData.minusMedals >= 8 then -- destory if we have enough medals
						Defines.earthquake = 6
						v:kill(HARM_TYPE_SPINJUMP)
						SFX.play("bridgecollapse.wav")
	        				for j = 1, 16 do
                        				local e = Effect.spawn(10, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        				e.x = e.x - e.width * 0.5
                        				e.y = e.y - e.height * 0.5
		        				e.speedX = RNG.random(-16, 16)
		        				e.speedY = RNG.random(-16, 16)
	       					end  
	        				for j = 1, 32 do
                        				local e = Effect.spawn(74, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        				e.x = e.x - e.width * 0.5
                        				e.y = e.y - e.height * 0.5
		        				e.speedX = RNG.random(-8, 8)
		        				e.speedY = RNG.random(-8, 8)
	        				end  
	        				for j = 1, 48 do
                        				local e = Effect.spawn(51, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        				e.x = e.x - e.width * 0.5
                        				e.y = e.y - e.height * 0.5
		        				e.speedX = RNG.random(-32, 32)
		        				e.speedY = RNG.random(-12, -24)
	        				end  
					end
					break
				end
			end
		end
	end
end

function trollWoodBlock.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
	if not v.data.initialized then return end

	local data = v.data

	npcutils.drawNPC(v, {xOffset = data.offset or 0, priority = -75})
	npcutils.hideNPC(v)
end

return trollWoodBlock