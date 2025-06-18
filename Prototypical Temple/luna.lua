local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector(3,2)

function onStart()
	local warp2 = Warp.get()[2]
	warp2.entranceWidth=512
end