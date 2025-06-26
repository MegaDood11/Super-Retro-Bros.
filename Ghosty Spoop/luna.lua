local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector("C", 3)

function onEvent(e)
	if e == "Lights Off" then
		local sec = Section(17)
		sec.darkness.enabled = true
	end
end

function onStart()
	local warp30 = Warp.get()[29]
	warp30.entranceWidth=2048
end