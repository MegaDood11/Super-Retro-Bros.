local npc = {}
local npcManager = require("npcManager")
local id = NPC_ID

npcManager.setNpcSettings({
	id = id,
	
	gfxheight = 16,
	height = 16,
	width = 64,
	gfxwidth = 64,
	
	frames = 1,
	
	nogravity = true,
	noblockcollision = true,
	
	jumphurt = true,
	nohurt = true,
	
	noiceball = true,
	noyoshi = true,
	
	playerblocktop = true,
	npcblocktop = true,
})

local function platformFix(v, p)
	local x,y = p.x, p.y + p.height
	local w,h = x + p.width, y + v.speedY
	
	for _,b in Block.iterateIntersecting(x, y, w, h) do
		if b.isValid and not b.isHidden and b:mem(0x5A, FIELD_WORD) == 0 then
			p.y = b.y - p.height
			p.speedY = 0
			
			break
		end
	end
end

function npc.onTickEndNPC(v)
	if v.ai1 == 2 then
		v.speedY = v.speedY + Defines.npc_grav
		
		if v.speedY > 0 then
			for k,p in ipairs(Player.get()) do
				if p.standingNPC and p.standingNPC == v then
					platformFix(v, p)
				end
			end
		end
	elseif v.ai1 == 0 then
		v.speedY = 3 * v.direction
	end
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end


return npc