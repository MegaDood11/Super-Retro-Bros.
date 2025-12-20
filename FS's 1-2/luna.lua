local smb1HUD = require("smb1HUD")
local textplus = require("textplus")

local fakeHUD = Graphics.loadImageResolved("hudQuestion.png")
local medalHUD = Graphics.loadImageResolved("medalHUD.png")

local warpSFX = ("minusWarp.spc")

local capture = Graphics.CaptureBuffer()
local warpTime = 0
local hasDisorted = false
local opacity = 0
local pipeTime = 0

local oldTime

local shader = Shader()
shader:compileFromFile(nil, Misc.resolveFile("wave.frag"))

function onTick()
	for k,p in ipairs(Player.get()) do
    		if (p:mem(0x15E, FIELD_WORD) == 10 and p.forcedState == 3) then 
			p:mem(0x124, FIELD_DFLOAT, 2) 
			pipeTime = pipeTime + 1
			if pipeTime == 40 then
				Audio.MusicChange(5, 0)
				SFX.play(warpSFX)
				hasDisorted = true
				Misc.pause()
			end
		end
	end
end

function onDraw()
	if hasDisorted then
		capture:captureAt(9)
		warpTime = warpTime + 1

		if warpTime >= 300 then
			hasDisorted = false
			Misc.unpause()

			Level.exit(6)
		end

		-- Text.print(warpTime, 0, 0)
		
		Graphics.drawBox{
			texture = capture,
			
			x = 0,
			y = 0,
			
			shader = shader,
			uniforms = {
				time = warpTime * (1 + (warpTime / 200)),
				intensity = warpTime / (300 / 96),
			},
			
			priority = 9
		}
	end

	if player.section == 5 then
		if warpTime >= 200 then
			opacity = math.min(1, opacity + 0.01)
			Graphics.drawScreen{priority = 12, color = Color.black .. opacity}
		end

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

		if oldTime then
			Timer.set(RNG.randomInt(101,999), false)
		else
			oldTime = Timer.get()
		end
	else
		smb1HUD.currentWorld = vector(1,2)
		if oldTime then
			Timer.set(oldTime, true)
			oldTime = nil
		end
	end
end
