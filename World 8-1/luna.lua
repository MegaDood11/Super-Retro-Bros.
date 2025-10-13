local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector(8, 1)

-- Run code on level start
function onStart()
	local warp2 = Warp.get()[2]
	warp2.entranceWidth=512
	
	local warp4 = Warp.get()[4]
	warp4.entranceWidth=2048
end