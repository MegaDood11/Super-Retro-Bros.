local fastFireballs = {}
--v1.1
--overhauled to work with custom powerups by John Nameless
 
local textplus = require("textplus")
 
function fastFireballs.onInitAPI()
    registerEvent(fastFireballs, "onTickEnd")
    registerEvent(fastFireballs, "onNPCKill")
end

fastFireballs.limit = 2
fastFireballs.shootingProjectiles = table.map{13,265,171,952}

local isOwned = {}
local linkChars = table.map{5,12,16}
local ownedProjectiles = {}
for i = 1,2 do
	ownedProjectiles[i] = {}
end
 
function fastFireballs.onTickEnd()
    for kp, p in ipairs(Player.get()) do
        if not linkChars[p.character] and not Cheats.get("flamethrower").active then
			--Assosiate Fireball to Player
			if ownedProjectiles[p.idx] and #ownedProjectiles[p.idx] >= fastFireballs.limit then
				p:mem(0x160, FIELD_WORD,math.max(p:mem(0x160, FIELD_WORD),5)) 
			elseif not p.isSpinJumping then
				p:mem(0x160, FIELD_WORD,0)
			end
			if (p.keys.run == KEYS_PRESSED or p.keys.altRun == KEYS_PRESSED and not p.isSpinJumping) or p.isSpinJumping then
				for k,v in NPC.iterateIntersecting(p.x - 12, p.y - 34 - math.max(p.speedY,0), p.x + p.width + 8, p.y + p.height + 8) do
					if v.isValid and not v.isHidden and not v.friendly then
						if fastFireballs.shootingProjectiles[v.id] and not isOwned[v] then
							table.insert(ownedProjectiles[p.idx],v)
							isOwned[v] = true
							if p.isSpinJumping then
								p:mem(0x160, FIELD_WORD,30)
							end
						end
					end
				end
			end
			for i,v in ipairs(ownedProjectiles[p.idx]) do
				if ((v.x + v.width < camera.x) or (v.x > camera.x + camera.width)) and v.y+v.height >= camera.y then
					v.despawnTimer = math.min(v.despawnTimer,0)
				end
			end
		end
    end
end
 
function fastFireballs.onNPCKill(eventObj, npc, harmtype)
	if not fastFireballs.shootingProjectiles[npc.id] then return end
    for _, p in ipairs(Player.get()) do
		for i,v in ipairs(ownedProjectiles[p.idx]) do
			if v == npc then
			   table.remove(ownedProjectiles[p.idx],i)
			   isOwned[v] = nil
			   break
			end
		end
    end
end
 
return fastFireballs