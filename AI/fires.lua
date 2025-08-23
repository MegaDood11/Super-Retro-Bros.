
--************************************************
--Graphics made by, and requested by FireSeraphim.
--************************************************

--***************************************************************************************
--Huge thanks to MrDoubleA for letting me base the fire NPCs off of his piranha plant AI.
--***************************************************************************************

--Code written by MrDoubleA, edited by me.


local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local colliders = require("Colliders")

local fire = {}



local STATE_HIDE  = 0
local STATE_RISE  = 1
local STATE_REST  = 2
local STATE_LOWER = 3


local function getInfo(v)
	local config = NPC.config[v.id]
	local data = v.data

	local settings = v.data._settings

	local configSettings = settings.config

	return config,data,settings,configSettings
end
local function getDirectionInfo(v)
	return "y","spawnY","height","speedY",  "gfxheight","sourceY","yOffset"
end

local function variant1(v)
	local data = v.data
	data.state = STATE_REST
end
local function variant3(v)
	local config,data,settings,configSettings = getInfo(v)
	local riseTable = {
	1,
	1,
	64,
	1,
	}
	data.riseTableIndex = data.riseTableIndex or 1
	configSettings.restTime = riseTable[data.riseTableIndex]
	configSettings.hideTime = riseTable[data.riseTableIndex]
	if data.state == STATE_REST and data.timer == 0 then
		data.riseTableIndex = data.riseTableIndex + 1
		if data.riseTableIndex == 5 then
			data.riseTableIndex = 1
		end
	end	
end

local function move(v,distance)
	local config,data,settings,configSettings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)


	local tip = (v[position]+(v[size]/2))+((v[size]/2)*data.direction)

	tip = tip + (distance*data.direction)

	-- Make sure to keep the position in a valid range
	local upPosition = (data.home+(config[size]*data.direction))
	local downPosition = data.home

	if math.sign(downPosition-tip) == data.direction then
		tip = downPosition
	elseif math.sign(upPosition-tip) == -data.direction then
		tip = upPosition
	end

	-- Reapply the position
	if settings.changeSize then
		v[size] = math.min(math.abs(data.home-tip),config[size])
	end


	v[position] = tip-((v[size]/2)*data.direction)-(v[size]/2)
end

local function initialise(v)
	local config,data,settings,configSettings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)

	data.direction = v.direction
	data.home = v[position]-(v[size]*data.direction)
	data.state = STATE_REST
	data.timer = 0
end

function fire.register(id)
	npcManager.registerEvent(id,fire,"onDrawNPC")
	npcManager.registerEvent(id,fire,"onTickEndNPC")
end

function fire.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local config,data,settings,configSettings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)
	
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.hitbox = colliders.Box(v.x, v.y, v.width, v.height - v.height / 4)
	end
	
	data.hitbox.x = v.x
	data.hitbox.y = v.y + v.height - data.hitbox.height
	
	for _,plr in ipairs(Player.get()) do
		if colliders.collide(plr, data.hitbox) then
			plr:harm()
		end
	end
	
	if v.despawnTimer <= 0 then
		data.state = nil
		return
	end

	if not data.state then
		initialise(v)
	end

	if v:mem(0x136,FIELD_BOOL) then -- If in a projectile state, PANIC!
		v:kill(HARM_TYPE_NPC)
		return
	elseif v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x138,FIELD_WORD) > 0 then -- Held or in a forced state
		return
	end

	
	if v.layerObj ~= nil and not Layer.isPaused() then
		v.x = v.x + v.layerObj.speedX
		v.y = v.y + v.layerObj.speedY
		data.home = data.home + v.layerObj[speed]
	end

	if data.state == STATE_HIDE then
		data.timer = data.timer + 1
		

		if data.timer > configSettings.hideTime then
			data.state = STATE_RISE
			data.timer = 0
			SFX.play("dkc_oil_barrel_flare_up.ogg")
		end
	elseif data.state == STATE_RISE then
		local tip = (v[position]+(v[size]/2))+((v[size]/2)*data.direction)
		local topPosition = data.home+(config[size]*data.direction)

		if tip == topPosition then
			data.state = STATE_REST
			data.timer = 0
		else

			move(v, configSettings.movementSpeed)
		end
	elseif data.state == STATE_REST then
		if not v.friendly then
			data.timer = data.timer + 1

			if data.timer > configSettings.restTime and not v.friendly then
				data.state = STATE_LOWER
				data.timer = 0
			end
		end
	elseif data.state == STATE_LOWER then
		local tip = (v[position]+(v[size]/2))+((v[size]/2)*data.direction)

		if tip == data.home then
			data.state = STATE_HIDE
			data.timer = 0

		else

			move(v, -configSettings.movementSpeed)
		end
	end
	if settings.algorithm == 0 then
		variant1(v, data, settings)
	elseif settings.algorithm == 2 then
		variant3(v, data, settings)
	end
end

function fire.onDrawNPC(v)
	if v.despawnTimer <= 0 or v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x138,FIELD_WORD) > 0 then return end

	local config,data,settings,configSettings = getInfo(v)
	local position,spawnPosition,size,speed, gfxSize,sourcePosition,positionOffset = getDirectionInfo(v)

	if not data.state then
		initialise(v)
	end
	

	-- Determine priority
	local priority = -75
	npcutils.drawNPC(v,{[positionOffset] = offset,[size] = graphicsSize,[sourcePosition] = source,priority = priority})
	npcutils.hideNPC(v)
end

return fire