local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector(6,1)

function onStart()
	local warp2 = Warp.get()[4]
	warp2.entranceWidth=4096
end
