local ripro = {}
local newcheats = require("game/newcheats")

--Register events
function ripro.onInitAPI()
	registerEvent(ripro, "onTick")
end

local function registerHeldCheat(name, spawnedNPC, alias)
    local aliases = table.iclone(alias)
	Cheats.register(name,{isCheat = true, activateSFX = 7, aliases = aliases,
	onActivate = (function() 
		Effect.spawn(10, player.x, player.y - 48)
		local n = NPC.spawn(spawnedNPC, player.x, player.y - 48, player.section, false)
		n.dontMove = true
		n.speedY = -6
	end)
	})
end

function ripro.onTick()

	--Cheats!
	registerHeldCheat("needamushroom", 185, {"needasupermushroom", "mushroom", "supermushroom"})
	registerHeldCheat("needaflower", 14, {"needafireflower", "flower", "fireflower"})
	registerHeldCheat("needastarman", 293, {"needasuperstar", "superstar", "starman"})
	registerHeldCheat("needabeetroot", 951, {"beetroot"})
	registerHeldCheat("needajumpinglui", 761, {"jumpinglui"})
	registerHeldCheat("needa1up", 187, {"1up"})
	registerHeldCheat("needapoisonmushroom", 153, {"poisonmushroom"})
	
	Cheats.register("raisetheflag",{isCheat = true,
	onActivate = (function() 
		for _,v in ipairs(NPC.get(394)) do
			player.section = v.section
			player.x = v.x + 16
			player.y = v.y - 360
		end
	end)
	})
	
	Cheats.register("mrrip",{isCheat = true,
	onActivate = (function() 
		SFX.play(Misc.resolveSoundFile("yeah.ogg"))
	end)
	})
	
	Cheats.register("icanfly",{isCheat = true,
	onActivate = (function() 
		SFX.play(Misc.resolveSoundFile("bonusImages/Hey I can fly.wav"))
		player.speedY = -500
	end)
	})
	
end

return ripro