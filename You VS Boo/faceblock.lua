local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local faceBlock = {}
local blockIDs = {}

--type constants
faceBlock.TYPE = {
	SWITCH = 0,
	TIMERSWITCH = 1,
	SOLID = 2,
	NONSOLID = 3,
	SPIKE = 4
}

--default setting values
faceBlock.defaultSettings = {
	timerLength = 3,
	flipFrames = 3,
	flipFrameSpeed = 4
}

faceBlock.hitSFX = "faceblock-flip.ogg"
faceBlock.timerSFX = "faceblock-timer.ogg"
faceBlock.pauseOnPlayerForcedState = true
faceBlock.pauseWhenOffScreen = false

function faceBlock.register(id, state1, state2)
	blockManager.registerEvent(id, faceBlock, "onTickBlock")
	blockManager.registerEvent(id, faceBlock, "onDrawBlock")
	if not state2 then state2 = state1 end
	blockIDs[id] = {state1, state2}
end

function faceBlock.onInitAPI()
	registerEvent(faceBlock, "onBlockHit")
	registerEvent(faceBlock, "onPostBlockHit")
	registerEvent(faceBlock, "onTick")
	registerEvent(faceBlock, "onTickEnd")
end

local state = 0
local timer = 0
local countTimer = 0
local flipTimer = -1

function faceBlock.getState()
	return state
end

function faceBlock.getCountTimer()
	return countTimer
end

function faceBlock.getFlipTimer()
	return flipTimer
end

local function getMaxTotalFlipFrames()
	local maxFlipFrames = 0
	for _,id in ipairs(table.unmap(blockIDs)) do
		local cfg = Block.config[id]
		local flipFrames = (cfg.flipframes or faceBlock.defaultSettings.flipFrames) * (cfg.flipframespeed or faceBlock.defaultSettings.flipFrameSpeed)
		if flipFrames > maxFlipFrames then maxFlipFrames = flipFrames end
	end
	return maxFlipFrames
end

local function harmPlayers(v)
	for _,p in ipairs(Player.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
		local collision = (Misc.canCollideWith(p, v) and v:collidesWith(p))
		if (collision == 1 and p.mount == MOUNT_NONE) or collision > 0 then p:harm() end
	end
end

function faceBlock.toggle()
	state = 1 - state
	countTimer = 0
	flipTimer = 0
	EventManager.callEvent("onFaceBlockSwitch", state)
	SFX.play(faceBlock.hitSFX)
end

local function isInSection(v, section)
	local boundary = Section(section).boundary
	return (v.x >= boundary.left - v.width and v.x < boundary.right and v.y >= boundary.top - v.height and v.y < boundary.bottom)
end

local function getTimerBlock()
	local ids = table.unmap(blockIDs)
	local sections = {}
	
	local timerBlock
	for _,p in ipairs(Player.get()) do table.insert(sections, p.section) end
	for _,block in Block.iterate(ids) do
		if blockIDs[block.id][state + 1] == faceBlock.TYPE.TIMERSWITCH and not block.isHidden and not block:mem(0x5A, FIELD_BOOL) then
			for j,section in ipairs(sections) do
				if isInSection(block, section) then
					timerBlock = block
					break
				end
			end
		end
	end
	return timerBlock
end

local function increaseBlockCount()
	local ids = table.unmap(blockIDs)
	for _,block in Block.iterate(ids) do
		if blockIDs[block.id][state + 1] == faceBlock.TYPE.TIMERSWITCH then
			block.data.timer = block.data.timer + 1
			if block.data.timer < (Block.config[block.id].timerlength or faceBlock.defaultSettings.timerLength) then SFX.play(faceBlock.timerSFX) end
			EventManager.callEvent("onTimerFaceBlockCount", block, (Block.config[block.id].timerlength or faceBlock.defaultSettings.timerLength) - block.data.timer)
		end
	end
end

local function blockOnScreen()
	local ids = table.unmap(blockIDs)
	for _,block in Block.iterate(ids) do
		if blockIDs[block.id][state + 1] == faceBlock.TYPE.TIMERSWITCH and blockutils.isOnScreen(block) then
			return true
		end
	end
	return false
end

function faceBlock.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	local cfg = Block.config[v.id]
	
	if not data.initialized then
		data.timer = 0
		data.animationTimer = 0
		data.initialized = true
	end
	
	local timerLength = cfg.timerlength or faceBlock.defaultSettings.timerLength
	if data.timer >= timerLength then
		faceBlock.toggle()
		data.timer = 0
	end
	
	data.animationTimer = data.animationTimer + 1
	
	if blockIDs[v.id][state + 1] == faceBlock.TYPE.SPIKE then harmPlayers(v) end
end

function faceBlock.onDrawBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	local cfg = Block.config[v.id]
	
	local oppositeState = 1 - state
	local flipFrames = cfg.flipframes or faceBlock.defaultSettings.flipFrames
	local flipFrameSpeed = cfg.flipframespeed or faceBlock.defaultSettings.flipFrameSpeed
	local timerLength = cfg.timerlength or faceBlock.defaultSettings.timerLength
	
	local frames = cfg.frames * 0.5 - flipFrames
	local timerFrames = (cfg.frames * 0.5 - flipFrames) / timerLength
	local currentFrame = math.floor(data.animationTimer / cfg.framespeed) % frames
	local currentTimerFrame = math.floor(data.animationTimer / cfg.framespeed) % timerFrames + data.timer
	local currentFlipFrame = math.floor(math.max(0, flipTimer) / flipFrameSpeed) % flipFrames
	local idle = (flipTimer >= flipFrames * flipFrameSpeed or flipTimer == -1)
	
	if blockIDs[v.id][state + 1] == faceBlock.TYPE.TIMERSWITCH then
		if idle then
			blockutils.setBlockFrame(v.id, currentTimerFrame + state * frames)
		else
			blockutils.setBlockFrame(v.id, frames * 2 + oppositeState * flipFrames + currentFlipFrame)
		end
	else
		if idle then
			blockutils.setBlockFrame(v.id, currentFrame + state * frames)
		else
			blockutils.setBlockFrame(v.id, frames * 2 + oppositeState * flipFrames + currentFlipFrame)
		end
	end
end

function faceBlock.onBlockHit(eventToken, v, fromUpper, culprit)
	if not blockIDs[v.id] or (blockIDs[v.id][state + 1] ~= faceBlock.TYPE.SWITCH and blockIDs[v.id][state + 1] ~= faceBlock.TYPE.TIMERSWITCH) then return end
	
	if not v:mem(0x52, FIELD_BOOL) then
		faceBlock.toggle()
		v.data.timer = 0
	else
		eventToken.cancelled = true
	end
end

function faceBlock.onTick()
	local ids = table.unmap(blockIDs)
	
	for _,id in ipairs(ids) do
		local cfg = Block.config[id]
		local blockState = blockIDs[id][state + 1]
		
		cfg.bumpable = (blockState == faceBlock.TYPE.SWITCH or blockState == faceBlock.TYPE.TIMERSWITCH)
		cfg.passthrough = (blockState == faceBlock.TYPE.NONSOLID)
	end
	
	local timerBlock = getTimerBlock()
	if timerBlock then
		if countTimer >= lunatime.toTicks(1) then
			increaseBlockCount()
			countTimer = 0
		end
		if (not faceBlock.pauseOnPlayerForcedState or not Layer.isPaused()) and (not faceBlock.pauseWhenOffScreen or blockOnScreen()) then countTimer = countTimer + 1 end
	end
end

function faceBlock.onTickEnd()
	if flipTimer ~= -1 then
		if flipTimer >= getMaxTotalFlipFrames() then
			flipTimer = -1
		else
			flipTimer = flipTimer + 1
		end
	end
end

return faceBlock