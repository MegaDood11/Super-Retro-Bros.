local time = 0
local image = Graphics.loadImage("loadscreen.png")
local rot = 0

function onDraw()    
	if image == nil then
		return
	end

	time = time + 1
	rot = rot - 4

	Graphics.drawBox{
		texture = image,
		x = (438 + 32),
		y = (374 + 32),
		width = 64,
		height = 64,
		sourceWidth = 64,
		sourceHeight = 64,
        rotation = rot,
		centered = true,
		sceneCoords = false,
        color = {1, 1, 1, math.min(1, time / 48)},
	}
end