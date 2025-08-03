local timer = {}

--Register events
function timer.onInitAPI()
	registerEvent(timer, "onDraw")
	registerEvent(timer, "onLevelExit")
	registerEvent(timer, "onWarp")
	registerEvent(timer, "onEvent")
end

local muteMusic = 0
local isWarping = false
local currentSection = player.section

function timer.onDraw()
	if Timer.getValue() <= Timer.hurryTime then
		if not isWarping then Audio.SeizeStream(-1) end
		muteMusic = muteMusic + 1
		if muteMusic <= 144 then
			Audio.MusicVolume(0)
			Audio.MusicStop()
		else
			Audio.MusicVolume(64)
			Audio.MusicResume()
			Audio.MusicSetTempo(1.375)
			Audio.MusicSetSpeed(1.15)
		end
	end
	
	if Level.endState() ~= 0 or player.forcedState == 300 or player.deathTimer > 0 then
		Audio.MusicStop()
	end
end

function timer.onLevelExit()
	if Timer.getValue() <= Timer.hurryTime then
		Audio.ReleaseStream(-1)
	end
end

function timer.onEvent(e)
	if Timer.getValue() <= Timer.hurryTime then
		Audio.ReleaseStream(-1)
		isWarping = true
		Audio.MusicSetTempo(1.375)
		Audio.MusicSetSpeed(1.15)
	end
end

function timer.onWarp(warp,p)
	if Timer.getValue() > Timer.hurryTime then return end
    if warp.exitSection ~= currentSection then
		if Section(currentSection).music == Section(warp.exitSection).music then return end
		isWarping = true
		Audio.ReleaseStream(-1)
		if muteMusic <= 144 then
			Audio.SeizeStream(warp.exitSection)
			Audio.MusicStop()
		end
		if Timer.getValue() <= Timer.hurryTime and muteMusic > 144 then
			Audio.MusicSetTempo(1.375)
			Audio.MusicSetSpeed(1.15)
		end
		
		currentSection = warp.exitSection
		
    end
end

return timer