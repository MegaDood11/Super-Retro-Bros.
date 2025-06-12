--[[
	newNoTurnBack.lua [v1]

	by Marioman2007
	- allows you to go back using a warp pipe or a clear pipe
	- allows to set movement direction in both the axes
]]

local noTurnBack = {}

noTurnBack.allowClearPipes = true

local p = player
local cameraPos = {}

local directionMap = {
	[0] =  0, -- None
	[1] =  1, -- Can Go Right/Down
	[2] = -1, -- Can Go Left/Up
}

local functionMap = {
	[1]  = math.max,
	[-1] = math.min,
}

local axisSpecific = {
	horizontal = {
		axis = "x",
		size = "width",
		[1]  = "left",
		[-1] = "right",
	},

	vertical = {
		axis = "y",
		size = "height",
		[1]  = "top",
		[-1] = "bottom",
	},
}

local function getSectionTurnBack(secIdx)
	local newTurnBack = Section(secIdx).settings.newTurnBack or {}

	return directionMap[newTurnBack.horizontal or 0], directionMap[newTurnBack.vertical or 0]
end

local function getCamPosFromPlayer()
	local x = p.x + p.width/2 - camera.width/2
	local y = p.y + p.height/2 - camera.height/2
	local boundary = p.sectionObj.boundary

	x = math.clamp(x, boundary.left, boundary.right - camera.width)
	y = math.clamp(y, boundary.top, boundary.bottom - camera.bottom)

	return x, y
end

local function camLogic(dir, axisName)
	local axisData = axisSpecific[axisName]
	local func = functionMap[dir]
	local boundary = p.sectionObj.boundary
	local axis = axisData.axis

	cameraPos[p.section][axis] = func(cameraPos[p.section][axis], camera[axis])
	camera[axis] = cameraPos[p.section][axis]

	boundary[axisData[dir]] = camera[axis]

	if dir == -1 then
		boundary[axisData[dir]] = boundary[axisData[dir]] + camera[axisData.size]
	end

	p.sectionObj.boundary = boundary
end

function noTurnBack.override(secIdx, value)
	cameraPos[secIdx] = value
end

function noTurnBack.resetPos(secIdx)
	local section = Section(secIdx)
	local boundary = section.boundary
	local origBoundary = section.origBoundary

	for k, axis in ipairs{"horizontal", "vertical"} do
		local axisData = axisSpecific[axis]

		boundary[axisData[1]]  = origBoundary[axisData[1]]
		boundary[axisData[-1]] = origBoundary[axisData[-1]]
	end

	section.boundary = boundary
	cameraPos[p.section] = nil
end

function noTurnBack.onInitAPI()
	registerEvent(noTurnBack, "onSectionChange")
	registerEvent(noTurnBack, "onWarp")
	registerEvent(noTurnBack, "onCameraUpdate")
end

function noTurnBack.onSectionChange(secIdx, pIdx)
	noTurnBack.resetPos(secIdx)
end

function noTurnBack.onWarp(w, plyr)
	noTurnBack.resetPos(p.section)
end

function noTurnBack.onCameraUpdate(camIdx)
	if noTurnBack.allowClearPipes and p.inClearPipe then
		if cameraPos[p.section] ~= nil then
			noTurnBack.resetPos(p.section)
		end

		return
	end

	if cameraPos[p.section] == nil then
		cameraPos[p.section] = vector(camera.x, camera.y)
	end

	local dirX, dirY = getSectionTurnBack(p.section)

	if dirX ~= 0 then
		camLogic(dirX, "horizontal")
	end

	if dirY ~= 0 then
		camLogic(dirY, "vertical")
	end
end

return noTurnBack