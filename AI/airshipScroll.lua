local airshipScroll = {}

local scrollActive = false
local bobUp = -1
local scrollspeed = 0
local scrollTimer = 0

airshipScroll.sections = {0}
airshipScroll.intensity = .01
airshipScroll.movementLimit = 1
airshipScroll.movingLayer = "shipWater"

function airshipScroll.onInitAPI()
	registerEvent(airshipScroll, "onCameraUpdate")
end

function airshipScroll.onCameraUpdate()
	local currentSection = Section(player.section)
	local sectionPos = currentSection.boundary
	local ogSectPos = currentSection.origBoundary
	local shipWater = Layer.get(airshipScroll.movingLayer)

	if table.icontains(airshipScroll.sections, player.section) then
		scrollActive = true
	else
		scrollActive = false
		shipWater.speedY = 0
	end
	
	if scrollActive then
		local archiveSection = currentSection
		
		if Misc.isPaused() == false then
			scrollspeed = scrollspeed + scrollTimer
			scrollTimer = scrollTimer + airshipScroll.intensity * bobUp
			if scrollTimer >= airshipScroll.movementLimit or scrollTimer <= -airshipScroll.movementLimit then
				bobUp = -bobUp
			end
			shipWater.speedY = scrollTimer
			shipWater.pauseDuringEffect = false
		else
			shipWater.speedY = 0
		end
		
		if camera.y <= ogSectPos.top then
			camera.y = sectionPos.top - scrollspeed
		end
		
		camera.y = camera.y + scrollspeed
		sectionPos.top = ogSectPos.top + scrollspeed
		currentSection.boundary = sectionPos
	end
end

return airshipScroll