local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	passthrough = true,
	sizable = true,
	
	nipperSpore = 772,
	nipperDandelion = 773,
})

local sfx =  SFX.play("wind.ogg", 1, 0)
sfx:pause()

local directions = {
[1] = vector.v2(-1,0),
[2] = vector.v2(1,0),
[3] = vector.v2(0,-1),
[4] = vector.v2(0,1)
}

function block.onTickBlock(v)
	if v.isHidden then sfx:pause() end
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data
	if play then
		sfx:resume()
	else
		sfx:pause()
	end
	data.direction = directions[v.data._settings.direction + 1]
end

function block.onCollideBlock(v,n)
	local data = v.data
	
	if (n.__type == "Player") then
	
		local e = Effect.spawn(blockID, camera.x, camera.y)
		e.x = e.x + (math.random(camera.width))
		e.y = e.y + (math.random(camera.height))
		
		e.speedX, e.speedY = (-v.data._settings.force + 42) * data.direction.x, (-v.data._settings.force + 42) * data.direction.y
		sfx:resume()

		if v.data._settings.direction == 0 then
			if v.data._settings.force >= Defines.player_runspeed then
				n.speedX = math.clamp(n.speedX, -v.data._settings.force, Defines.player_runspeed - (v.data._settings.force / 1.5))
			end
		elseif v.data._settings.direction == 1 then
			if v.data._settings.force >= Defines.player_runspeed then
				n.speedX = math.clamp(n.speedX, -(Defines.player_runspeed - (v.data._settings.force / 1.5)), v.data._settings.force)
			end
		elseif v.data._settings.direction == 2 then
			if v.data._settings.force <= Defines.gravity then
				n.speedY = math.min(n.speedY, v.data._settings.force-(Defines.player_grav+0.00001))
			else
				n.speedY = -v.data._settings.force + Defines.gravity
			end
		else
			if v.data._settings.force <= Defines.gravity then
				n.speedY = math.max(n.speedY, n.speedY * v.data._settings.force)
			else
				n.speedY = v.data._settings.force
			end
		end
		
		if v.data._settings.direction <= 1 then
			if not n.keys.right and v.data._settings.direction == 0 then
				n:mem(0x138, FIELD_FLOAT, -(0.04166666666 * v.data._settings.force))
			elseif not n.keys.left and v.data._settings.direction == 1 then
				n:mem(0x138, FIELD_FLOAT, (0.04166666666 * v.data._settings.force))
			end
		end
		
		for _,e in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			if e.id == Block.config[v.id].nipperDandelion then
				e.ai1 = 1
			elseif e.id == Block.config[v.id].nipperSpore then
				if v.data._settings.direction ~= 3 then
					e.x, e.y =  e.x + v.data._settings.force / 2 * data.direction.x, e.y + v.data._settings.force / 2 * data.direction.y
				else
					e.speedX, e.speedY = v.data._settings.force / 2 * data.direction.x, v.data._settings.force / 2 * data.direction.y
				end
			end
		end
		
	else
		sfx:pause()
	end
end

function block.onInitAPI()
	blockmanager.registerEvent(blockID, block, "onCollideBlock")
	blockmanager.registerEvent(blockID, block, "onTickBlock")
end

return block
