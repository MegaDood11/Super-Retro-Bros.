local time = 0
local image = Graphics.loadImage("loadscreen.png")
local rot = 0
local fadeOut = 0

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
        	color = {1, 1, 1, math.min(1, time / 60)},
	}

        if Misc.getLoadingFinished() then
            	fadeOut = math.min(1,fadeOut + 1/10)
        end

        if fadeOut < 1 then
            	Misc.setLoadScreenTimeout(15)
        else
            	Misc.setLoadScreenTimeout(0)
        end

    	if fadeOut > 0 then
        	Graphics.drawBox{
            		color = {0, 0, 0, fadeOut},priority = 15,
            		x = 0,y = 0,width = 512,height = 448,
        	}
    	end
end