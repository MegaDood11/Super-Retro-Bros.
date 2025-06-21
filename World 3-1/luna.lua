local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector(3,1)

-- Run code on level start
function onStart()
	local warp6 = Warp.get()[6]
	warp6.entranceWidth=128
end