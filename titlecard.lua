local titlecard = {}
local skipIntro = false

local titlecardActive
local titlecardTimer = 0

local priority1 = 0
local priority2 = 0

local noJump

local imgFile = Misc.resolveFile("_titlecard.png")
local imgFileHead = Misc.resolveFile("titlecard images/titlecard_head_" .. player.character .. ".png")
local textplus = require("textplus")

local hudFont = textplus.loadFont("smb1HUD/smb1-font.ini")

if imgFile == nil or imgFileHead == nil then
    skipIntro = true
else
    imgFile = Graphics.loadImageResolved("_titlecard.png")
	imgFileHead = Graphics.loadImageResolved("titlecard images/titlecard_head_" .. player.character .. ".png")
end

function titlecard.onStart()
   if Level.filename() ~= GameData.lastPlayedLevel and not skipIntro then
        -- start the intro
		titlecardActive = true
    end
end

function titlecard.onExitLevel(w)
    if w == 0 then
        GameData.lastPlayedLevel = Level.filename()
    end
end

function titlecard.onTick()
	--Pause the game
	if titlecardActive then
		Audio.MusicPause()
		Audio.SeizeStream(-1)
		Misc.pause()
	end
end

function titlecard.onInputUpdate()
	if titlecardActive then
	
		player.keys.jump = false
		player.keys.altJump = false
		
		noJump = 0
		
		--Unpause after a bit or if we jump
		if titlecardTimer >= 192 then
			Misc.unpause()
			Audio.MusicResume()
			Audio.ReleaseStream(-1)
			if titlecardTimer >= 208 then
				titlecardTimer = 0
				titlecardActive = false
			end
		end
		
		if player.rawKeys.altJump == KEYS_PRESSED and titlecardTimer <= 176 then
			titlecardTimer = 177
			priority2 = 1
		end
		
	else
		if noJump then noJump = noJump + 1 if noJump <= 8 then player.keys.jump = false  player.keys.altJump = false end end
	end
end

function titlecard.onDraw()
	if titlecardActive then
		
		titlecardTimer = titlecardTimer + 1
	
		if titlecardTimer >= 128 and titlecardTimer <= 160 then
			priority2 = priority2 + 0.0625
		elseif titlecardTimer > 176 and titlecardTimer <= 208 then
			priority2 = priority2 - 0.0625
			priority1 = -1000
		end
	
		--The backdrop border, this will stay for a bit, then when the second backdrop covers it, it will become 0 and the new backdrop will slowly return to 0
		Graphics.drawScreen{
		color = Color.black,
		priority = priority1,
		}
		
		Graphics.drawScreen{
		color = Color.black .. priority2,
		priority = 1,
		}
	
		--Draw the titlecard
		imgFileDisplay = Sprite{texture = imgFile, width = 305, height = 206}
		imgFileDisplay.position = vector(camera.width/6, camera.height/2)
		imgFileDisplay.width = 305
		imgFileDisplay.height = 206
		imgFileDisplay:draw{priority = priority1}
		
		--Draw the character head
		imgFileDisplay = Sprite{texture = imgFileHead, width = 36, height = 36}
		imgFileDisplay.position = vector(camera.width/3, camera.height / 3.25)
		imgFileDisplay.width = 36
		imgFileDisplay.height = 36
		imgFileDisplay:draw{priority = priority1}
		
		--Draw the text
		textplus.print{
			x=camera.x + 225,
			y=camera.y + 155,
			text="x		".. mem(0x00B2C5AC,FIELD_FLOAT),
			color=Color.white,
			font=hudFont,
			xscale = 2,
			yscale = 2,
			sceneCoords = true,
			priority = priority1
		}
		
	end
end

--Register events
function titlecard.onInitAPI()
	registerEvent(titlecard, "onStart")
	registerEvent(titlecard, "onExitLevel")
	registerEvent(titlecard, "onTick")
	registerEvent(titlecard, "onInputUpdate")
	registerEvent(titlecard, "onDraw")
end

return titlecard