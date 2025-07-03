local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector("C",1)

function onStart()
	local warp30 = Warp.get()[4]
	warp30.entranceWidth=4096
end