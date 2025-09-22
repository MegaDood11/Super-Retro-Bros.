local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local friendlyNPC = require("npcs/ai/friendlies")

local toad = {}
local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	
	frames = 5, 
	framestyle = 1, 
	gfxoffsety = 2,
	jumphurt = 1,
	ignorethrownnpcs = 1,
	nofireball=1,
	noiceball=1,
	noyoshi=1,
	grabside=0,
	grabtop=0,
	isshoe=0,
	isyoshi=0,
	isstationary = false,
	nowalldeath = true,
	nohurt=1,
	score = 0,
	spinjumpsafe=0,
	
	width = 32,
	gfxwidth = 60,
	height = 64,
	gfxheight = 55,
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
	},
	{
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_NPC] = 10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
)

friendlyNPC.register(npcID)

function toad.onInitAPI()
	npcManager.registerEvent(npcID, toad, "onTickEndNPC")
end

function toad.onTickEndNPC(v)
	if not v.friendly then for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do NPC.spawn(9,p.x,p.y):collect() end end
	if Defines.levelFreeze then return end

	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.timer = 0
		v.speedY = -5
		v.speedX = 1.5 * v.direction
		SFX.play(24, 0.5)
	end

	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

        if v.collidesBlockBottom then
		v.speedX = 0
        	data.timer = data.timer + 1
		
		if player.character == CHARACTER_TOAD then
			v.dontMove = true
			v.animationFrame = 4
			if data.timer == 100 then
				Layer.get("?"):show(true)
			end
		else
			if data.timer <= 55 then
				v.animationFrame = 2
			elseif data.timer > 55 and data.timer < 128 then
				v.animationFrame = 3
			elseif data.timer >= 128 then
				v.animationFrame = 4
				v.dontMove = true
			end
		end
        else
		if data.timer < 360 then
			if v.speedY < 0 then v.animationFrame = 0 else v.animationFrame = 1 end
         
		else
			v.animationFrame = 4
		end
			

        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = 5
	});
end

return toad