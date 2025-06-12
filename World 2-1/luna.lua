local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector(2,1)

function onStart()
	local warp2 = Warp.get()[2]
	warp2.entranceWidth=4096
end