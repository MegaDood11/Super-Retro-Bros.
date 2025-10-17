local smasPause = {}

--*******************************************
-- Special thanks to Marioman2007 for helping
--*******************************************

local isPaused = false
local pauseTimer = 0
local pauseState = Audio.MusicVolume()

local boxWidth = 160
local boxHeight = 32

local MAX_WIDTH = 288
local MAX_HEIGHT = 160

local MIN_WIDTH = 160
local MIN_HEIGHT = 32

local pauseDir = 1
blinkTimer = 0
local cursorthing = 7

pauseBoxImage = Graphics.loadImageResolved("pause_screen_backdrop_smas.png")
cursorImage = Graphics.loadImageResolved("pointer_smas_pause_screen.png")

function smasPause.onInitAPI()
    registerEvent(smasPause,"onInputUpdate")
	registerEvent(smasPause,"onPause")
	registerEvent(smasPause,"onDraw")
end

function smasPause.onInputUpdate()

	--Depending on if its on the overworld or not, display two different menus with different uses
	if not textImage then
		if isOverworld then textImage = Graphics.loadImageResolved("text_map_smas_pause_screen.png") textImageType = 1 else textImage = Graphics.loadImageResolved("text_smas_pause_screen.png") textImageType = 0 end
	end

	if isPaused and not Misc.isPausedByLua() then
		isPaused = false
	end

	--Custom pause menu
	if isPaused then
		
		--Stuff to control box movement
		pauseTimer = math.clamp(pauseTimer + pauseDir, 0, 16)
		
        boxWidth = math.clamp((pauseTimer * 8) + MIN_WIDTH, MIN_WIDTH, MAX_WIDTH)
		boxHeight = math.clamp((pauseTimer * 8) + MIN_HEIGHT, MIN_HEIGHT, MAX_HEIGHT)
		
		--Quieten the music when paused
		Audio.MusicVolume(pauseState * 0.5)
		
		if pauseTimer >= 16 then
			--move the cursor, and make it flash
			if player.rawKeys.up == KEYS_PRESSED then
				SFX.play(14)
				if cursorPosition.y > 184 then
					cursorPosition.y = cursorPosition.y - 32
				else
					cursorPosition.y = 248
				end
			elseif player.rawKeys.down == KEYS_PRESSED then
				SFX.play(14)
				if cursorPosition.y < 248 then
					cursorPosition.y = cursorPosition.y + 32
				else
					cursorPosition.y = 184
				end
			end
			
			--Flash code
			blinkTimer = blinkTimer + 1
			
			if blinkTimer % 31 <= 15 then
				cursorthing = -7
			else
				cursorthing = 7
			end
		end
		
		--If you press jump or run, make it either resume or do something else
		if (player.rawKeys.run == KEYS_PRESSED or player.keys.jump == KEYS_PRESSED) and pauseTimer >= 16 then
			pauseDir = -1
			cursorthing = -1000
			blinkTimer = 0
			if cursorPosition.y == 184 then SFX.play(30) else SFX.play("smas-save.wav") end
		end
		
		--Always continue if pause is pressed again
		if player.rawKeys.pause == KEYS_PRESSED and pauseTimer >= 16 then
			pauseDir = -1
			cursorthing = -1000
			blinkTimer = 0
			SFX.play(30)
			cantEnd = true
		end
		
		--Reset variables, and execute code
		if pauseTimer <= 0 then
			isPaused = false
			Misc.unpause()
			pauseTimer = 0
			Audio.MusicVolume(pauseState)
			pauseDir = 1
			
			boxWidth = 160
			boxHeight = 32
			
			if not cantEnd then
				if cursorPosition.y == 216 then
					if textImageType == 0 then
						Level.exit()
					else
						Misc.saveGame()
					end
				elseif cursorPosition.y == 248 then
					if textImageType == 1 then Misc.saveGame() end
					Misc.exitEngine()
				end
			end
			cantEnd = nil
			
			cursorPosition.y = 184
		end
		
	else
		pauseState = Audio.MusicVolume()
	end
end

function smasPause.onPause(eventObj)
	if not eventObj.cancelled then
		-- Prevent normal pausing
		eventObj.cancelled = true
		SFX.play(30)
		isPaused = true	
		Misc.pause()
	end
end

function smasPause.onDraw()
	if isPaused and not Misc.isPausedByLua() then
		isPaused = false
	end

	--Drawing code
	if isPaused then
		if cursorPosition ~= nil then
			cursorSprite = cursorSprite or Sprite{texture = cursorImage,pivot = vector(0.5,0.5)}
			cursorSprite.position = cursorPosition
			cursorSprite:draw{priority = cursorthing}
		else
			cursorPosition = vector(148, 184)
		end
		pauseBoxSprite = pauseBoxSprite or Sprite{texture = pauseBoxImage, width = boxWidth, height = boxHeight, pivot = vector(0.5,0.5)}
		pauseBoxSprite.position = vector(camera.width/2, camera.height/2)
		pauseBoxSprite.width = boxWidth
		pauseBoxSprite.height = boxHeight
		pauseBoxSprite:draw{priority = 6}
		
		local textWidth = math.min(textImage.width, boxWidth)
        local textHeight = math.min(textImage.height, boxHeight)

        Graphics.drawBox{
            texture = textImage,
            x = camera.width/2,
            y = camera.height/2,
            sourceX = (textImage.width - textWidth)/2,
            sourceY = (textImage.height - textHeight)/2,
            sourceWidth = textWidth,
            sourceHeight = textHeight,
            priority = 6,
			centered = true,
        }
		
	end
end

return smasPause