local smb1HUD = require("smb1HUD")
local textplus = require("textplus")

local fakeHUD = Graphics.loadImageResolved("hudQuestion.png")
local medalHUD = Graphics.loadImageResolved("medalHUD.png")

function onDraw()
	if player.section == 5 then
		smb1HUD.currentWorld = vector(1,"")

		Graphics.drawBox{
			texture = fakeHUD,
			x = 336,
			y = 46,
			priority = 5
		}

		Graphics.drawBox{
			texture = medalHUD,
			x = 6,
			y = 404,
			priority = 5
		}

	 	textplus.print{
        		x = 54,
        		y = 408,
       			xscale = 2,
        		yscale = 2,
        		text = tostring(SaveData.minusMedals or 0),
			font = textplus.loadFont("timerFont.ini"),
        		pivot = {0, 0},
        		maxWidth = 432,
			color = Color.white,
        		priority = 5,
    		}
	else
		smb1HUD.currentWorld = vector(1,2)
	end
end
