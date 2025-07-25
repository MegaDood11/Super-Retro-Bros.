local ground = {}

--Register events
function ground.onInitAPI()
	registerEvent(ground, "onTick")
	registerEvent(ground, "onBlockHit")
end

function ground.onTick()
	if player.keys.altRun == KEYS_PRESSED and player.keys.up then 
		if player.character == ground.character1 then
			player.character = ground.character2
		else
			player.character = ground.character1
		end
	end
end

function ground.onBlockHit(e, v, upper, p)
	for _,n in ipairs(NPC.getIntersecting(v.x, v.y - 4, v.x + v.width, v.y)) do
		if (NPC.config[n.id].powerup or n.id == 153) and Block.config[v.id].bumpable then
			if n.x <= v.x + (v.width / 2) then
				n.direction = -1
			else
				n.direction = 1
			end
		end
	end
end

return ground