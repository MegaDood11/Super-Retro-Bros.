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
local ownedProjectiles = {}
for i = 1,2 do
	ownedProjectiles[i] = {}
end
 
local function isShootingProjectile(v)
	local config = NPC.config[v.id]
	return (
		(
			fastFireballs.shootingProjectiles[v.id] -- basegame projectiles 
			or (
				v.id >= 751 
				and config.nohurt 
				and not config.grabside 
				and not config.grabtop
				and not config.powerup
				and not config.isinteractable		
			) -- custom powerup projectiles
		)
	)
end
 
function fastFireballs.onTickEnd()
    for kp, p in ipairs(Player.get()) do
        if not p:mem(0x50, FIELD_BOOL) then
			--Assosiate Fireball to Player
			if p.keys.run == KEYS_PRESSED or p.keys.altRun == KEYS_PRESSED then
				for k,v in NPC.iterateIntersecting(p.x - 12, p.y - 34 - math.max(p.speedY,0), p.x + p.width + 8, p.y + p.height + 8) do
					if v.isValid then
						if fastFireballs.shootingProjectiles[v.id] and not isOwned[v] then
							table.insert(ownedProjectiles[p.idx],v)
							isOwned[v] = true
						end
					end
				end
			end
			if ownedProjectiles[p.idx] and #ownedProjectiles[p.idx] >= fastFireballs.limit then
				p:mem(0x160, FIELD_WORD,5)
			else
				p:mem(0x160, FIELD_WORD,0)
			end
			for i,v in ipairs(ownedProjectiles[p.idx]) do
				if v.isValid then
					v.despawnTimer = math.min(v.despawnTimer,1)
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