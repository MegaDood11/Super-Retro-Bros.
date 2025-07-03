local smb1HUD = require("smb1HUD")

smb1HUD.currentWorld = vector("B",3)

function onStart()
	local warp2 = Warp.get()[2]
	warp2.entranceWidth=4096
end

function onTickEnd()
    for k,v in pairs(NPC.get(229,player.section)) do
        v.ai1 = 1
    end
end