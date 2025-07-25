local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector("A",3)

function onStart()
	local warp3 = Warp.get()[3]
	warp3.entranceWidth=4096
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
    --Your code here
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end

