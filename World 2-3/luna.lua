--------------------------------------------------
-- Level code
-- Created 20:12 2025-6-12


local smb1HUD = require("smb1HUD")
smb1HUD.currentWorld = vector(2,3)
-- Run code on level start
function onStart()
	--NPC.config[235].jumphurt = false
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTickEnd()
    --Your code here
	for i,v in NPC.iterate(235) do
		v:mem(0x1C,FIELD_WORD,3)
		--v.despawnTimer = math.min(v.despawnTimer,10)
	end
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end

