--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcUtils = require("npcs/npcutils")
local configTypes = require("configTypes")
local handyCam = require("handycam")
local autoScroll = require("autoscroll")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

local getValue, getID, getValuePredicate, getRange, getRangeInt, getRangeIntConfig, setState, getDamage, playSFXIDOrFile

local STATES = {
	MOVING = 0,
	CHOOSE_ATTACK = 1,
	ATTACK_STANDARD = 2,
	ATTACK_MULTI = 3,
	ATTACK_FLAMETHROWER = 4,
	ATTACK_HAMMER = 5,
	DEFEATED = 10
}

local MAP_HARM_NAME = {
	[HARM_TYPE_JUMP] = "jump",
	[HARM_TYPE_FROMBELOW] = "below",
	[HARM_TYPE_NPC] = "npc",
	[HARM_TYPE_PROJECTILE_USED] = "breath",
	[HARM_TYPE_HELD] = "held",
	[HARM_TYPE_LAVA] = "lava",
	[HARM_TYPE_TAIL] = "tail",
	[HARM_TYPE_SPINJUMP] = "spinjump",
	[HARM_TYPE_SWORD] = "sword"
}

local EMPTY_FUNCTION = function() end

-- because you can't access onEnter inside of a state lolol
local MOVEMENT_PICK_IDLE = function(v)
	local data = v.data
	data.timer = 0

	data.idleStart = getRangeInt(v, "movement.idle.start")
	data.idleLength = getRangeInt(v, "movement.idle.length")
end

local MOVEMENT_PICK_JUMP = function(v)
	local data = v.data
	data.untilJump = getRangeInt(v, "movement.jump.time")
end

local HARM_WITH_TYPE = function(v, name)
	local data = v.data
	local damage, subdamage = getDamage(v, name)

	-- Invulnerable, skip
	if data.invul > 0 then
		return false
	end

	-- No damage, skip
	if damage < 1 and subdamage < 1 then
		return false
	end

	local subunderflow = false
	data.hp = data.hp - damage
	data.subhp = data.subhp - subdamage
	if data.subhp < 1 then
		subunderflow = true
		data.subhp = getValue(v, "hit.health.sub")
		data.hp = data.hp - 1
	end

	if data.hp < 1 then
		setState(v, STATES.DEFEATED)
		return true -- Return true to indicate defeat
	end

	if damage > 0 or subunderflow then
		data.invul = data.invulTime
		playSFXIDOrFile(v, "hit.health.audio.hurt")
	end

	return false
end

local GET_OPACITY = function(v)
	return math.cos(math.pi * 4 * v.data.invul / 64) * 0.4 + 0.6
end

local ARBITRARY_HEIGHT_LIMIT = 512
local function PROPAGATE_SPLASH(v, block, horizontalDistance)
	local data = v.data
	if horizontalDistance > data.splashMaxDistance or not Block.LAVA_MAP[block.id] then
		return
	end
	data.splashBlocks[block] = horizontalDistance / data.splashMaxDistance
	for _, left in Block.iterateIntersecting(block.x - 1, block.y, block.x, block.y + 1) do
		if left and not data.splashBlocks[left] then
			PROPAGATE_SPLASH(v, left, horizontalDistance + left.width)
		end
	end
	for _, right in Block.iterateIntersecting(block.x + block.width, block.y, block.x + block.width + 1, block.y + 1) do
		if right and not data.splashBlocks[right] then
			PROPAGATE_SPLASH(v, right, horizontalDistance + block.width)
		end
	end
	for _, bottom in Block.iterateIntersecting(block.x, block.y + block.height, block.x + 1, block.y + block.height + ARBITRARY_HEIGHT_LIMIT) do
		if bottom then
			data.splashBlocks[bottom] = data.splashBlocks[block]
		end
	end
end

local MARKER_FILTER = function(v)
	return not v:mem(0x64, FIELD_BOOL) and not v.isHidden
end

local ARBITRARY_ARMOR_POINT = 50
local ARBITRARY_RENDER_PRIORITY = 4

local DRAW_HEALTH = function(v)
	local data = v.data
	local settings = data._settings

	local factor = 1.0 - math.min(1.0, data.healthTransitionTimer / data.healthTransitionTime)
	local transitionX = data.healthTransitionX * factor
	local transitionY = data.healthTransitionY * factor

	if not data.iconTexture then
		data.iconTexture = Graphics.loadImageResolved(getValuePredicate(v, "hit.health.graphics.icon.file", not settings["hit.health.graphics.icon.config"]))
		data.iconX = getValue(v, "hit.health.graphics.icon.position.x")
		data.iconY = getValue(v, "hit.health.graphics.icon.position.y")
	end

	if not data.healthTexture then
		data.healthTexture = Graphics.loadImageResolved(getValuePredicate(v, "hit.health.graphics.health.file", not settings["hit.health.graphics.health.config"]))
		data.healthX = getValue(v, "hit.health.graphics.health.position.x")
		data.healthOffsetX = getValue(v, "hit.health.graphics.health.position.offsetx")
		data.healthY = getValue(v, "hit.health.graphics.health.position.y")
		data.healthOffsetY = getValue(v, "hit.health.graphics.health.position.offsety")
	end

	if not data.armorTexture then
		data.armorTexture = Graphics.loadImageResolved(getValuePredicate(v, "hit.health.graphics.armor.file", not settings["hit.health.graphics.armor.config"]))
		data.armorX = getValue(v, "hit.health.graphics.armor.position.x")
		data.armorOffsetX = getValue(v, "hit.health.graphics.armor.position.offsetx")
		data.armorY = getValue(v, "hit.health.graphics.armor.position.y")
		data.armorOffsetY = getValue(v, "hit.health.graphics.armor.position.offsety")
	end

	Graphics.drawImageWP(
		data.iconTexture,
		data.iconX + transitionX,
		data.iconY + transitionY,
		ARBITRARY_RENDER_PRIORITY
	)

	for i = 1, math.min(ARBITRARY_ARMOR_POINT, data.hp) do
		Graphics.drawImageWP(
			data.healthTexture,
			data.iconX + transitionX + data.healthX * i + data.healthOffsetX,
			data.iconY + transitionY + data.healthY * i + data.healthOffsetY,
			ARBITRARY_RENDER_PRIORITY
		)
	end

	for i = ARBITRARY_ARMOR_POINT + 1, data.hp do
		local j = i - ARBITRARY_ARMOR_POINT
		Graphics.drawImageWP(
			data.armorTexture,
			data.iconX + transitionX + data.armorX * j + data.armorOffsetX,
			data.iconY + transitionY + data.armorY * j + data.armorOffsetY,
			ARBITRARY_RENDER_PRIORITY
		)
	end
end

local ATTACKS = {
	"standard",
	"multi",
	"flamethrower",
	"hammer",
}

local ATTACK_TO_STATE = {
	standard = STATES.ATTACK_STANDARD,
	multi = STATES.ATTACK_MULTI,
	flamethrower = STATES.ATTACK_FLAMETHROWER,
	hammer = STATES.ATTACK_HAMMER
}

local GET_ATTACK = function(v)
	local totalWeight = 0
	for i = 1, #ATTACKS do
		totalWeight = totalWeight + getValue(v, "attack." .. ATTACKS[i] .. ".weight")
	end
	local weight = RNG.randomInt(1, totalWeight)
	for i = 1, #ATTACKS do
		local attackWeight = getValue(v, "attack." .. ATTACKS[i] .. ".weight")
		weight = weight - attackWeight
		if attackWeight > 0 and weight <= 0 then
			return ATTACK_TO_STATE[ATTACKS[i]]
		end
	end
	return STATES.MOVING
end

local PROGRESS_JUMP = function(v)
	if v.collidesBlockBottom then
		v.data.untilJump = v.data.untilJump - 1
		if v.data.untilJump < 1 then
			v.speedY = -getRange(v, "movement.jump.strength")
			MOVEMENT_PICK_JUMP(v)
		end
	end
end

local CHECK_HARM = function(v)
	local data = v.data
	if data.invul > 0 then
		data.invul = data.invul - 1
	else
		local players = Player.get()
		for i = 1, #players do
			local player = players[i]
			if player.deathTimer < 1 then
				local passed, spinjumping = Colliders.bounce(player, v)
				if passed then
					local name = MAP_HARM_NAME[spinjumping and HARM_TYPE_SPINJUMP or HARM_TYPE_JUMP]
					Colliders.bounceResponse(player)
					return HARM_WITH_TYPE(v, name)
				end
			end
		end
	end
end

local POINT_IN_RECT = function(x, y, rect)
	return x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom
end

local OUTSIDE_CAMERAS = function(v)
	local cameras = Camera.get()
	for i = 1, #cameras do
		local rect = cameras[i].bounds
		if POINT_IN_RECT(v.x, v.y, rect) or POINT_IN_RECT(v.x + v.width, v.y, rect) or
		POINT_IN_RECT(v.x, v.y + v.height, rect) or POINT_IN_RECT(v.x + v.width, v.y + v.height, rect)
		then
			return false
		end
	end
	return true
end

local VALID_STATE = function(state)
	for _, i in pairs(STATES) do
		if i == state then
			return true
		end
	end
	return false
end

local DEFAULT_FUNCTIONS = {
	onTick = function(v)
		local data = v.data
		if data.timer < data.idleStart then
			local colliding = Colliders.getColliding({
				a = v,
				b = data.turnid,
				btype = Colliders.NPC,
				section = v.section,
				filter = MARKER_FILTER
			})

			for i = 1, #colliding do
				data.dir = colliding[i].direction
			end

			v.speedX = data.dir * data.speed
		else
			v.speedX = 0
			if data.timer > data.idleStart + data.idleLength then
				MOVEMENT_PICK_IDLE(v)
			end
		end
		PROGRESS_JUMP(v)
		npcUtils.faceNearestPlayer(v)
		CHECK_HARM(v)
	end,
	onDraw = function(v)
		if v.collidesBlockBottom then
			npcUtils.drawNPC(v, {
				frame = math.wrap(v.animationFrame, 0, 4),
				opacity = GET_OPACITY(v)
			})
		else
			npcUtils.drawNPC(v, {
				frame = 2,
				opacity = GET_OPACITY(v)
			})
		end
		DRAW_HEALTH(v)
	end,
	onHarm = function(v, eventToken, harmType, culpritOrNil)
		local data = v.data

		if data.invul > 0 then
			eventToken.cancelled = true
			return
		end

		local name = MAP_HARM_NAME[harmType]
		if not name then
			eventToken.cancelled = true
			return
		end

		-- Hardcoded sounds lol
		if type(culpritOrNil) == "NPC" then
			if culpritOrNil.id == 13 or culpritOrNil.id == 171 then
				SFX.play(9)
			end
		end

		if not HARM_WITH_TYPE(v, name) then
			eventToken.cancelled = true
			return
		end

		if harmType ~= HARM_TYPE_VANISH then
			eventToken.cancelled = true
		end
	end
}

-- Called functions: onEnter, onExit, onTick, onDraw, onHarm
local STATE_MACHINE = {
	[STATES.MOVING] = {
		onEnter = function(v)
			local data = v.data
			data.tofiretime = getRangeInt(v, "attack.timing.cooldown")
		end,
		onTick = function(v)
			local data = v.data
			if data.timer > data.tofiretime then
				setState(v, STATES.CHOOSE_ATTACK)
			end
			DEFAULT_FUNCTIONS.onTick(v)
		end
	},
	[STATES.CHOOSE_ATTACK] = {
		onEnter = function(v)
			setState(v, GET_ATTACK(v))
		end
	},
	[STATES.ATTACK_STANDARD] = {
		onEnter = function(v)
			local data = v.data
			data.firestate = 0
			data.timer = 0
			data.firereadytimer = getValue(v, "attack.standard.timing.pre")
			data.postfirecooldown = getValue(v, "attack.standard.timing.post")
		end,
		onTick = function(v)
			local data = v.data
			if data.firestate == 0 and data.timer > data.firereadytimer then
				playSFXIDOrFile(v, "attack.standard.breath.audio")
				data.firestate = 1
				local offsetenabled = not data._settings["attack.standard.spawn.offset.config"]
				local offsetx = getValuePredicate(v, "attack.standard.spawn.offset.x", offsetenabled)
				local offsety = getValuePredicate(v, "attack.standard.spawn.offset.y", offsetenabled)
				local spawn = NPC.spawn(
					getID(v, "attack.standard.breath.npc"),
					v.x + v.width * 0.5 + offsetx * -v.direction,
					v.y + offsety,
					v.section,
					false,
					(getValue(v, "attack.standard.spawn.center") == 1) and true or false
				)
				spawn.direction = v.direction
				spawn.speedX = v.direction * getValue(v, "attack.standard.breath.speed")
				if getValue(v, "attack.standard.breath.chase.enabled") == 1 then
					local plr = npcUtils.getNearestPlayer(v)
					spawn.data.startY = spawn.y
					spawn.data.targetY = plr.y + plr.height * 0.5 - spawn.height * 0.5 + getRangeIntConfig(v, "attack.standard.breath.chase.range")
					spawn.data.timer = 0
					spawn.data.travel = math.abs((spawn.data.targetY - spawn.data.startY) / spawn.speedX)
				end
			elseif data.firestate == 1 and data.timer > data.firereadytimer + data.postfirecooldown then
				setState(v, STATES.MOVING)
			end
			DEFAULT_FUNCTIONS.onTick(v)
		end,
		onDraw = function(v)
			local data = v.data
			if data.firestate == 0 then
				npcUtils.drawNPC(v, {
					frame = 4,
					opacity = GET_OPACITY(v)
				})
			elseif data.firestate == 1 then
				npcUtils.drawNPC(v, {
					frame = 6,
					opacity = GET_OPACITY(v)
				})
			end
			DRAW_HEALTH(v)
		end
	},
	[STATES.ATTACK_MULTI] = {
		onEnter = function(v)
			local data = v.data
			data.firestate = 0
			data.timer = 0
			data.firereadytimer = getValue(v, "attack.multi.timing.pre")
			data.postfirecooldown = getValue(v, "attack.multi.timing.post")
		end,
		onTick = function(v)
			local data = v.data
			if data.firestate == 0 and data.timer > data.firereadytimer then
				playSFXIDOrFile(v, "attack.multi.breath.audio")
				data.firestate = 1
				local offsetenabled = not data._settings["attack.multi.spawn.offset.config"]
				local offsetx = getValuePredicate(v, "attack.multi.spawn.offset.x", offsetenabled)
				local offsety = getValuePredicate(v, "attack.multi.spawn.offset.y", offsetenabled)
				local count = getRangeInt(v, "attack.multi.breath.count")
				local chase = getValue(v, "attack.multi.breath.chase.enabled")
				local id = getID(v, "attack.multi.breath.npc")
				local center = (getValue(v, "attack.multi.spawn.center") == 1) and true or false
				local imprecision = getRangeIntConfig(v, "attack.multi.breath.chase.range")
				for i = 1, count do
					local factor = i - count * 0.5
					local spawn = NPC.spawn(
						id,
						v.x + v.width * 0.5 + offsetx * -v.direction,
						v.y + offsety,
						v.section,
						false,
						center
					)
					spawn.direction = v.direction
					spawn.speedX = v.direction * getValue(v, "attack.multi.breath.speed")
					if chase == 1 then
						local plr = npcUtils.getNearestPlayer(v)
						spawn.data.startY = spawn.y
						spawn.data.targetY = plr.y + plr.height * 0.5 - spawn.height * 0.5 + factor * 32 + imprecision
						spawn.data.timer = 0
						spawn.data.travel = math.abs((spawn.data.targetY - spawn.data.startY) / spawn.speedX)
					end
				end
			elseif data.firestate == 1 and data.timer > data.firereadytimer + data.postfirecooldown then
				setState(v, STATES.MOVING)
			end
			DEFAULT_FUNCTIONS.onTick(v)
		end,
		onDraw = function(v)
			local data = v.data
			if data.firestate == 0 then
				npcUtils.drawNPC(v, {
					frame = math.wrap(v.animationFrame, 4, 6),
					opacity = GET_OPACITY(v)
				})
			elseif data.firestate == 1 then
				npcUtils.drawNPC(v, {
					frame = 6,
					opacity = GET_OPACITY(v)
				})
			end
			DRAW_HEALTH(v)
		end
	},
	[STATES.ATTACK_FLAMETHROWER] = {
		onEnter = function(v)
			local data = v.data
			data.firestate = 0
			data.timer = 0
			data.firereadytimer = getValue(v, "attack.flamethrower.timing.pre")
			data.firecooldown = getValue(v, "attack.flamethrower.timing.cooldown")
			data.flamethrowerFadeInTime = getValue(v, "attack.flamethrower.timing.fade.in")
			data.flamethrowerFadeOutTime = getValue(v, "attack.flamethrower.timing.fade.out")
		end,
		onExit = function(v)
			local data = v.data
			if data.flamethrowerSFX then
				data.flamethrowerSFX:stop()
			end
			data.flamethrowerSFX = nil
			data.flamethrowerOffsetX = nil
			data.flamethrowerOffsetY = nil
			data.flamethrowerCount = nil
			data.flamethrowerNPC = nil
			data.flamethrowerCenter = nil
			data.flamethrowerStartTransition = nil
			data.nextFlame = nil
			data.firecooldown = nil
			data.flamethrowerFadeInTime = nil
			data.flamethrowerFadeOutTime = nil
		end,
		onTick = function(v)
			local data = v.data
			v.speedX = 0
			if data.firestate == 0 and data.timer > data.firereadytimer then
				data.firestate = 1
				local offsetenabled = not data._settings["attack.flamethrower.spawn.offset.config"]
				data.flamethrowerSFX = playSFXIDOrFile(v, "attack.flamethrower.breath.audio", 0, 0)
				data.flamethrowerOffsetX = getValuePredicate(v, "attack.flamethrower.spawn.offset.x", offsetenabled)
				data.flamethrowerOffsetY = getValuePredicate(v, "attack.flamethrower.spawn.offset.y", offsetenabled)
				data.flamethrowerCount = getRangeInt(v, "attack.flamethrower.breath.count")
				data.flamethrowerNPC = getID(v, "attack.flamethrower.breath.npc")
				data.flamethrowerCenter = (getValue(v, "attack.flamethrower.spawn.center") == 1) and true or false
				data.nextFlame = data.timer
				data.flamethrowerStartTransition = data.timer
				data.flamethrowerVolume = getValue(v, "attack.flamethrower.breath.audio.volume")

				if data.flamethrowerFadeInTime == 0 then
					data.flamethrowerSFX.volume = data.flamethrowerVolume
				end
			elseif data.firestate == 1 then
				if data.flamethrowerFadeInTime > 0 then
					local t = (data.timer - data.flamethrowerStartTransition) / data.flamethrowerFadeInTime
					if t <= 1 then
						data.flamethrowerSFX.volume = math.lerp(0, data.flamethrowerVolume, t)
					end
				end

				if data.timer > data.nextFlame then
					if data.flamethrowerCount < 1 then
						data.firestate = 2
						data.flamethrowerStartTransition = data.timer
					else
						data.nextFlame = data.nextFlame + data.firecooldown
						local spawn = NPC.spawn(
							data.flamethrowerNPC,
							v.x + v.width * 0.5 + data.flamethrowerOffsetX * -v.direction,
							v.y + data.flamethrowerOffsetY,
							v.section,
							false,
							data.flamethrowerCenter
						)
						spawn.direction = v.direction
						spawn.speedX = v.direction * getRange(v, "attack.flamethrower.breath.speed.x")
						spawn.speedY = -getRange(v, "attack.flamethrower.breath.speed.y")
						data.flamethrowerCount = data.flamethrowerCount - 1
					end
				end
			elseif data.firestate == 2 then
				local t
				if data.flamethrowerFadeOutTime > 0 then
					t = (data.timer - data.flamethrowerStartTransition) / data.flamethrowerFadeOutTime
				else
					t = 1
				end

				if t >= 1 then
					setState(v, STATES.MOVING)
				else
					data.flamethrowerSFX.volume = math.lerp(0, data.flamethrowerVolume, 1 - t)
				end
			end
			PROGRESS_JUMP(v)
			CHECK_HARM(v)
		end,
		onDraw = function(v)
			local data = v.data
			if data.firestate == 0 or data.firestate == 2 then
				npcUtils.drawNPC(v, {
					frame = 6,
					opacity = GET_OPACITY(v)
				})
			elseif data.firestate == 1 then
				npcUtils.drawNPC(v, {
					frame = math.wrap(v.animationFrame, 6, 10),
					opacity = GET_OPACITY(v)
				})
			end
			DRAW_HEALTH(v)
		end
	},
	[STATES.ATTACK_HAMMER] = {
		onEnter = function(v)
			local data = v.data
			data.firestate = 0
			data.timer = 0
			data.firereadytimer = getValue(v, "attack.hammer.timing.pre")
			data.hammerCooldown = getValue(v, "attack.hammer.timing.cooldown")
		end,
		onExit = function(v)
			local data = v.data
			data.hammerOffsetX = nil
			data.hammerOffsetY = nil
			data.hammerCount = nil
			data.hammerNPC = nil
			data.hammerCenter = nil
			data.nextHammer = nil
			data.hammerCooldown = nil
		end,
		onTick = function(v)
			local data = v.data
			v.speedX = 0
			if data.firestate == 0 and data.timer > data.firereadytimer then
				data.firestate = 1
				local offsetenabled = not data._settings["attack.hammer.spawn.offset.config"]
				data.hammerOffsetX = getValuePredicate(v, "attack.hammer.spawn.offset.x", offsetenabled)
				data.hammerOffsetY = getValuePredicate(v, "attack.hammer.spawn.offset.y", offsetenabled)
				data.hammerCount = getRangeInt(v, "attack.hammer.projectile.count")
				data.hammerNPC = getID(v, "attack.hammer.projectile.npc")
				data.hammerCenter = (getValue(v, "attack.hammer.spawn.center") == 1) and true or false
				data.nextHammer = data.timer
			elseif data.firestate == 1 then
				if data.timer > data.nextHammer then
					if data.hammerCount < 1 then
						setState(v, STATES.MOVING)
					else
						playSFXIDOrFile(v, "attack.hammer.projectile.audio")
						data.nextHammer = data.nextHammer + data.hammerCooldown
						local spawn = NPC.spawn(
							data.hammerNPC,
							v.x + v.width * 0.5 + data.hammerOffsetX * -v.direction,
							v.y + data.hammerOffsetY,
							v.section,
							false,
							data.hammerCenter
						)
						spawn.direction = v.direction
						spawn.speedX = v.direction * getRange(v, "attack.hammer.projectile.speed.x")
						spawn.speedY = -getRange(v, "attack.hammer.projectile.speed.y")
						data.hammerCount = data.hammerCount - 1
					end
				end
			end
			PROGRESS_JUMP(v)
			CHECK_HARM(v)
		end,
		onDraw = function(v)
			local data = v.data
			if data.firestate == 0 or data.firestate == 2 then
				npcUtils.drawNPC(v, {
					frame = 12,
					opacity = GET_OPACITY(v)
				})
			elseif data.firestate == 1 then
				npcUtils.drawNPC(v, {
					frame = math.wrap(v.animationFrame, 12, 14),
					opacity = GET_OPACITY(v)
				})
			end
			DRAW_HEALTH(v)
		end
	},
	[STATES.DEFEATED] = {
		onEnter = function(v)
			v.noblockcollision = true
			v.friendly = true
			v.speedX = 0
			local data = v.data
			data.timer = 0
			data.deathState = 0
			data.defaultBehaviour = getValue(v, "defeat.default.enabled") == 1
			data.coyoteTime = getValue(v, "defeat.fall.coyotetime")
			playSFXIDOrFile(v, "defeat.audio.stun")
			if data.defaultBehaviour then
				if Timer.isActive() then
					Timer.toggle()
				end
				Audio.MusicChange(v.section, 0, 0)

				data.sectionDirection = getValue(v, "defeat.default.direction")
				data.sectionExtension = getValue(v, "defeat.default.extension")
			end
			triggerEvent(getValue(v, "defeat.event"))
		end,
		onTick = function(v)
			local data = v.data
			v.speedY = -Defines.npc_grav
			data.timer = data.timer + 1
			if data.timer > data.coyoteTime and data.deathState == 0 then
				data.timer = 0
				playSFXIDOrFile(v, "defeat.audio.fall")
				data.deathState = 1
				data.fallSpeed = getValue(v, "defeat.fall.speed")
				data.fallSpeedLava = getValue(v, "defeat.fall.lavaspeed")
				data.ignoreLava = getValue(v, "defeat.lava.ignore") == 1
				data.splashLava = getValue(v, "defeat.lava.splash.enabled") == 1
				data.inLava = false
			elseif data.deathState == 1 then
				if not data.ignoreLava and not data.inLava then
					local blocks = Colliders.getColliding{
						a = v,
						btype = Colliders.BLOCK
					}

					if data.splashLava then
						data.splashMaxDistance = getValue(v, "defeat.lava.splash.range")
						data.splashTime = getValue(v, "defeat.lava.splash.time")
						data.splashStrength = getValue(v, "defeat.lava.splash.strength")
						data.splashTimeLag = getValue(v, "defeat.lava.splash.timelag")
						data.splashTimer = 0
						data.splashBlocks = {}
					end

					local firstTime = data.inLava == false
					for i = 1, #blocks do
						if Block.LAVA_MAP[blocks[i].id] then
							if not data.inLava then
								playSFXIDOrFile(v, "defeat.audio.lava")
								data.inLava = true
							end

							if firstTime and data.splashLava then
								data.splashBlocks[blocks[i]] = 0
							end
						end
					end

					for i = 1, #blocks do
						PROPAGATE_SPLASH(v, blocks[i], 0)
					end


				end

				v.speedY = data.inLava and data.fallSpeedLava or data.fallSpeed

				-- We can continue once the NPC is outside any camera
				if OUTSIDE_CAMERAS(v) then
					if data.defaultBehaviour then
						data.deathState = 2

						-- Resize the section
						local section = v.sectionObj
						local bounds = section.boundary
						local camera = handyCam[i]
						if data.sectionDirection == 1 then
							bounds.left = bounds.left - data.sectionExtension
						else
							bounds.right = bounds.right + data.sectionExtension
						end
						section.boundary = bounds
					else
						v:kill(HARM_TYPE_VANISH)
					end
				end
			elseif data.deathState == 2 and data.defaultBehaviour then
				if not data.defeatJingle then
					data.defeatJingle = playSFXIDOrFile(v, "defeat.audio.jingle")
				end

				if not data.defeatJingle.isValid or not data.defeatJingle:isplaying() then
					Level.exit(getValue(v, "defeat.default.wintype"))
				end
			end

			if data.splashLava and data.inLava and data.splashBlocks then
				data.splashTimer = data.splashTimer + 1

				for block, factor in pairs(data.splashBlocks) do
					local timelag = factor * data.splashTimeLag
					local time = (data.splashTimer - timelag) / data.splashTime
					if time > 0 and time < 1 then
						local distance = 2 * math.sin(time * 4 * math.pi) * math.sin(-time * math.pi)
						block:translate(0, (1 - factor) * (1 - time) * distance * data.splashStrength)
					end
				end
			end

			if data.defaultBehaviour then
				-- Disable all keys of all players
				for i, player in ipairs(Player.get()) do
					if player.section == v.section then
						for k, v in pairs(player.keys) do
							player.keys[k] = KEYS_UP
						end
						if data.deathState == 2 then
							if data.sectionDirection == 1 then
								player.keys.left = KEYS_DOWN
							else
								player.keys.right = KEYS_DOWN
							end

							-- Fake the section not having been resized
							if player.section == v.section then
								local section = player.sectionObj
								local camera = handyCam[i]
								if data.sectionDirection == 1 then
									camera.x = section.boundary.left + data.sectionExtension + camera.width * 0.5
								else
									camera.x = section.boundary.right - data.sectionExtension - camera.width * 0.5
								end
							end
						end
					end
				end
			end
		end,
		onDraw = function(v)
			npcUtils.drawNPC(v, {
				frame = math.wrap(v.animationFrame, 10, 12)
			})
			DRAW_HEALTH(v)
		end
	}
}

-- What values the settings should have to be counted as "unset", and to use the config value for
local USE_DEFAULT_VALUES = {
	["misc.startstate"] = -1,
	["misc.turnaround.id"] = 0,
	["misc.area.id"] = 0,
	["movement.speed"] = 0.0,
	["movement.idle.start.start"] = -1,
	["movement.idle.start.length"] = -1,
	["movement.idle.length.start"] = -1,
	["movement.idle.length.length"] = -1,
	["movement.jump.time.start"] = -1,
	["movement.jump.time.length"] = -1,
	["movement.jump.strength.start"] = 0.0,
	["movement.jump.strength.length"] = 0.0,
	["attack.timing.cooldown.start"] = -1,
	["attack.timing.cooldown.length"] = -1,
	["attack.standard.weight"] = -1,
	["attack.standard.breath.audio.volume"] = 0,
	["attack.standard.timing.pre"] = -1,
	["attack.standard.timing.post"] = -1,
	["attack.standard.breath.npc.id"] = 0,
	["attack.standard.breath.speed"] = 0,
	["attack.standard.breath.chase.enabled"] = 0,
	["attack.standard.spawn.center"] = 0,
	["attack.standard.spawn.offset.x"] = 0,
	["attack.standard.spawn.offset.y"] = 0,
	["attack.multi.weight"] = -1,
	["attack.multi.breath.audio.volume"] = 0,
	["attack.multi.timing.pre"] = -1,
	["attack.multi.timing.post"] = -1,
	["attack.multi.breath.npc.id"] = 0,
	["attack.multi.breath.speed"] = 0,
	["attack.multi.breath.chase.enabled"] = 0,
	["attack.multi.breath.count.start"] = -1,
	["attack.multi.breath.count.length"] = -1,
	["attack.multi.spawn.center"] = 0,
	["attack.multi.spawn.offset.x"] = 0,
	["attack.multi.spawn.offset.y"] = 0,
	["attack.flamethrower.weight"] = -1,
	["attack.flamethrower.breath.audio.volume"] = 0,
	["attack.flamethrower.timing.pre"] = -1,
	["attack.flamethrower.timing.cooldown"] = -1,
	["attack.flamethrower.timing.fade.in"] = -1,
	["attack.flamethrower.timing.fade.out"] = -1,
	["attack.flamethrower.breath.npc.id"] = 0,
	["attack.flamethrower.breath.speed.x.start"] = 0,
	["attack.flamethrower.breath.speed.x.length"] = 0,
	["attack.flamethrower.breath.speed.y.start"] = 0,
	["attack.flamethrower.breath.speed.y.length"] = 0,
	["attack.flamethrower.breath.count.start"] = -1,
	["attack.flamethrower.breath.count.length"] = -1,
	["attack.flamethrower.spawn.center"] = 0,
	["attack.flamethrower.spawn.offset.x"] = 0,
	["attack.flamethrower.spawn.offset.y"] = 0,
	["attack.hammer.weight"] = -1,
	["attack.hammer.projectile.audio.volume"] = 0,
	["attack.hammer.timing.pre"] = -1,
	["attack.hammer.timing.cooldown"] = -1,
	["attack.hammer.projectile.npc.id"] = 0,
	["attack.hammer.projectile.speed.x.start"] = 0,
	["attack.hammer.projectile.speed.x.length"] = 0,
	["attack.hammer.projectile.speed.y.start"] = 0,
	["attack.hammer.projectile.speed.y.length"] = 0,
	["attack.hammer.projectile.count.start"] = -1,
	["attack.hammer.projectile.count.length"] = -1,
	["attack.hammer.spawn.center"] = 0,
	["attack.hammer.spawn.offset.x"] = 0,
	["attack.hammer.spawn.offset.y"] = 0,
	["hit.health.hp"] = 0,
	["hit.health.sub"] = 0,
	["hit.health.audio.hurt.volume"] = 0,
	["hit.health.invulnerability"] = -1,
	["hit.health.graphics.transition.time"] = -1,
	["hit.health.graphics.transition.position.x"] = 0,
	["hit.health.graphics.transition.position.y"] = 0,
	["hit.health.graphics.icon.position.x"] = -1,
	["hit.health.graphics.icon.position.y"] = -1,
	["hit.health.graphics.health.position.x"] = 0,
	["hit.health.graphics.health.position.y"] = 0,
	["hit.health.graphics.health.position.offsetx"] = 0,
	["hit.health.graphics.health.position.offsety"] = 0,
	["hit.health.graphics.armor.position.x"] = 0,
	["hit.health.graphics.armor.position.y"] = 0,
	["hit.health.graphics.armor.position.offsetx"] = 0,
	["hit.health.graphics.armor.position.offsety"] = 0,
	["hit.definition.jump.damage"] = -1,
	["hit.definition.jump.sub"] = -1,
	["hit.definition.below.damage"] = -1,
	["hit.definition.below.sub"] = -1,
	["hit.definition.npc.damage"] = -1,
	["hit.definition.npc.sub"] = -1,
	["hit.definition.breath.damage"] = -1,
	["hit.definition.breath.sub"] = -1,
	["hit.definition.held.damage"] = -1,
	["hit.definition.held.sub"] = -1,
	["hit.definition.lava.damage"] = -1,
	["hit.definition.lava.sub"] = -1,
	["hit.definition.tail.damage"] = -1,
	["hit.definition.tail.sub"] = -1,
	["hit.definition.spinjump.damage"] = -1,
	["hit.definition.spinjump.sub"] = -1,
	["hit.definition.sword.damage"] = -1,
	["hit.definition.sword.sub"] = -1,
	["battle.music.change"] = 0,
	["battle.room.area.enabled"] = 0,
	["battle.room.area.speed"] = 0,
	["defeat.event"] = "",
	["defeat.lava.ignore"] = 0,
	["defeat.lava.splash.enabled"] = 0,
	["defeat.lava.splash.range"] = 0,
	["defeat.lava.splash.strength"] = 0,
	["defeat.lava.splash.time"] = -1,
	["defeat.lava.splash.timelag"] = -1,
	["defeat.default.enabled"] = 0,
	["defeat.default.direction"] = 0,
	["defeat.default.extension"] = -1,
	["defeat.default.wintype"] = 0,
	["defeat.fall.coyotetime"] = -1,
	["defeat.fall.speed"] = 0,
	["defeat.fall.lavaspeed"] = 0,
	["defeat.audio.stun.volume"] = 0,
	["defeat.audio.fall.volume"] = 0,
	["defeat.audio.lava.volume"] = 0,
	["defeat.audio.jingle.volume"] = 0
}

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 64,
	gfxheight = 76,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 14,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- Vanilla speed config
	speed = 1,

	-- LOGIC
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = true, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt = false, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = false,
	noiceball = true,
	noyoshi = true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	score = 9, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	weight = 1,
	isheavy = true,
	nopowblock = true,

	-- For more info, see the extra settings in-editor pointed to by the comments
	["misc.turnaround.id"] = 753, -- Miscellaneous Settings/Turnaround ID
	["misc.area.id"] = 751, -- Miscellaneous Settings/Area ID
	["misc.startstate"] = STATES.MOVING, -- Miscellaneous Settings/Start State
	["movement.speed"] = 1.0, -- Movement Settings/Speed
	["movement.idle.start.start"] = 32, -- Movement Settings/Idling Interval/Range Lower Bound/Range Lower Bound
	["movement.idle.start.length"] = 224, -- Movement Settings/Idling Interval/Range Lower Bound/Range Length
	["movement.idle.length.start"] = 64, -- Movement Settings/Idling Interval/Range Length/Range Lower Bound
	["movement.idle.length.length"] = 64, -- Movement Settings/Idling Interval/Range Length/Range Lower Bound
	["movement.jump.time.start"] = 256, -- Movement Settings/Jump Settings/Cooldown/Range Lower Bound
	["movement.jump.time.length"] = 64, -- Movement Settings/Jump Settings/Cooldown/Range Length
	["movement.jump.strength.start"] = 5.0, -- Movement Settings/Jump Settings/Strength/Range Lower Bound
	["movement.jump.strength.length"] = 4.0, -- Movement Settings/Jump Settings/Strength/Range Length
	["attack.timing.cooldown.start"] = 128, -- Attack Settings/Timing/Cooldown/Range Lower Bound
	["attack.timing.cooldown.length"] = 64, -- Attack Settings/Timing/Cooldown/Range Length
	["attack.standard.weight"] = 1, -- Attack Settings/Standard/Weight
	["attack.standard.timing.pre"] = 64, -- Attack Settings/Standard/Timing/Prefire Time
	["attack.standard.timing.post"] = 32, -- Attack Settings/Standard/Timing/Postfire Time
	["attack.standard.breath.npc.id"] = 752, -- Attack Settings/Standard/Breath/NPC/ID
	["attack.standard.breath.speed"] = 2.0, -- Attack Settings/Standard/Breath/Speed
	["attack.standard.breath.audio.volume"] = 1, -- Attack Settings/Standard/Breath/Audio/Volume
	["attack.standard.breath.audio.id"] = 0, -- Attack Settings/Standard/Breath/Audio/ID
	["attack.standard.breath.audio.file"] = "marioforeverbowser/sounds/flame.ogg", -- Attack Settings/Standard/Breath/Audio/File
	["attack.standard.breath.chase.enabled"] = 1, -- Attack Settings/Standard/Breath/Chase/Enabled, 1 means enabled and any other value means disabled
	["attack.standard.breath.chase.range.start"] = -16, -- Attack Settings/Standard/Breath/Chase/Imprecision Range/Start
	["attack.standard.breath.chase.range.length"] = 32, -- Attack Settings/Standard/Breath/Chase/Imprecision Range/Length
	["attack.standard.spawn.center"] = 1, -- Attack Settings/Standard/Spawn/Center, 1 means enabled and any other value means disabled
	["attack.standard.spawn.offset.x"] = 0, -- Attack Settings/Standard/Spawn/Offset/X
	["attack.standard.spawn.offset.y"] = 16, -- Attack Settings/Standard/Spawn/Offset/Y
	["attack.multi.weight"] = 0, -- Attack Settings/Multifire/Weight
	["attack.multi.timing.pre"] = 96, -- Attack Settings/Multifire/Timing/Prefire Time
	["attack.multi.timing.post"] = 64, -- Attack Settings/Multifire/Timing/Postfire Time
	["attack.multi.breath.npc.id"] = 752, -- Attack Settings/Multifire/Breath/NPC/ID
	["attack.multi.breath.speed"] = 2.0, -- Attack Settings/Multifire/Breath/Speed
	["attack.multi.breath.count.start"] = 3, -- Attack Settings/Multifire/Breath/Fire Count/Start
	["attack.multi.breath.count.length"] = 2, -- Attack Settings/Multifire/Breath/Fire Count/Length
	["attack.multi.breath.audio.volume"] = 1, -- Attack Settings/Multifire/Breath/Audio/Volume
	["attack.multi.breath.audio.id"] = 0, -- Attack Settings/Multifire/Breath/Audio/ID
	["attack.multi.breath.audio.file"] = "marioforeverbowser/sounds/flame.ogg", -- Attack Settings/Multifire/Breath/Audio/File
	["attack.multi.breath.chase.enabled"] = 1, -- Attack Settings/Multifire/Breath/Chase, 1 means enabled and any other value means disabled
	["attack.multi.breath.chase.range.start"] = -16, -- Attack Settings/Multifire/Breath/Chase/Imprecision Range/Start
	["attack.multi.breath.chase.range.length"] = 32, -- Attack Settings/Multifire/Breath/Chase/Imprecision Range/Length
	["attack.multi.spawn.center"] = 1, -- Attack Settings/Multifire/Spawn/Center, 1 means enabled and any other value means disabled
	["attack.multi.spawn.offset.x"] = 0, -- Attack Settings/Multifire/Spawn/Offset/X
	["attack.multi.spawn.offset.y"] = 16, -- Attack Settings/Multifire/Spawn/Offset/Y
	["attack.flamethrower.breath.npc.id"] = 754, -- Attack Settings/Flamethrower/Breath/NPC/ID
	["attack.flamethrower.weight"] = 0, -- Attack Settings/Flamethrower/Weight
	["attack.flamethrower.timing.pre"] = 128, -- Attack Settings/Flamethrower/Timing/Prefire Time
	["attack.flamethrower.timing.cooldown"] = 4, -- Attack Settings/Flamethrower/Timing/Cooldown Time
	["attack.flamethrower.timing.fade.in"] = 16, -- Attack Settings/Flamethrower/Timing/Audio Fade Time/In
	["attack.flamethrower.timing.fade.out"] = 32, -- Attack Settings/Flamethrower/Timing/Audio Fade Time/Out
	["attack.flamethrower.breath.speed.x.start"] = 5.0, -- Attack Settings/Flamethrower/Breath/Speed/Horizontal Speed/Range Lower Bound
	["attack.flamethrower.breath.speed.x.length"] = 4.0, -- Attack Settings/Flamethrower/Breath/Speed/Horizontal Speed/Range Length
	["attack.flamethrower.breath.speed.y.start"] = 2.0, -- Attack Settings/Flamethrower/Breath/Speed/Vertical Speed/Range Lower Bound
	["attack.flamethrower.breath.speed.y.length"] = 4.0, -- Attack Settings/Flamethrower/Breath/Speed/Vertical Speed/Range Length
	["attack.flamethrower.breath.count.start"] = 40, -- Attack Settings/Flamethrower/Breath/Fire Count/Start
	["attack.flamethrower.breath.count.length"] = 30, -- Attack Settings/Flamethrower/Breath/Fire Count/Length
	["attack.flamethrower.breath.audio.volume"] = 0.5, -- Attack Settings/Flamethrower/Breath/Audio/Volume
	["attack.flamethrower.breath.audio.id"] = 0, -- Attack Settings/Flamethrower/Breath/Audio/ID
	["attack.flamethrower.breath.audio.file"] = "marioforeverbowser/sounds/flameloop.ogg", -- Attack Settings/Flamethrower/Breath/Audio/File
	["attack.flamethrower.spawn.center"] = 1, -- Attack Settings/Flamethrower/Spawn/Center, 1 means enabled and any other value means disabled
	["attack.flamethrower.spawn.offset.x"] = -24, -- Attack Settings/Flamethrower/Spawn/Offset/X
	["attack.flamethrower.spawn.offset.y"] = 24, -- Attack Settings/Flamethrower/Spawn/Offset/Y
	["attack.hammer.projectile.npc.id"] = 30, -- Attack Settings/Hammer/Breath/NPC/ID
	["attack.hammer.weight"] = 0, -- Attack Settings/Hammer/Weight
	["attack.hammer.timing.pre"] = 128, -- Attack Settings/Hammer/Timing/Prefire Time
	["attack.hammer.timing.cooldown"] = 12, -- Attack Settings/Hammer/Timing/Cooldown Time
	["attack.hammer.projectile.speed.x.start"] = 1.0, -- Attack Settings/Hammer/Projectile/Speed/Horizontal Speed/Range Lower Bound
	["attack.hammer.projectile.speed.x.length"] = 4.0, -- Attack Settings/Hammer/Projectile/Speed/Horizontal Speed/Range Length
	["attack.hammer.projectile.speed.y.start"] = 8.0, -- Attack Settings/Hammer/Projectile/Speed/Vertical Speed/Range Lower Bound
	["attack.hammer.projectile.speed.y.length"] = 6.0, -- Attack Settings/Hammer/Projectile/Speed/Vertical Speed/Range Length
	["attack.hammer.projectile.count.start"] = 10, -- Attack Settings/Hammer/Projectile/Fire Count/Start
	["attack.hammer.projectile.count.length"] = 10, -- Attack Settings/Hammer/Projectile/Fire Count/Length
	["attack.hammer.projectile.audio.volume"] = 1.0, -- Attack Settings/Hammer/Projectile/Audio/Volume
	["attack.hammer.projectile.audio.id"] = 25, -- Attack Settings/Hammer/Projectile/Audio/ID
	["attack.hammer.projectile.audio.file"] = "", -- Attack Settings/Hammer/Projectile/Audio/File
	["attack.hammer.spawn.center"] = 1, -- Attack Settings/Hammer/Spawn/Center, 1 means enabled and any other value means disabled
	["attack.hammer.spawn.offset.x"] = -16, -- Attack Settings/Hammer/Spawn/Offset/X
	["attack.hammer.spawn.offset.y"] = 38, -- Attack Settings/Hammer/Spawn/Offset/Y
	["hit.health.hp"] = 5, -- Hit Settings/Health/HP
	["hit.health.sub"] = 5, -- Hit Settings/Health/Sub HP
	["hit.health.invulnerability"] = 192, -- Hit Settings/Health/Invulnerability
	["hit.health.audio.hurt.volume"] = 1.0, -- Hit Settings/Health/Audio/Hurt/Volume
	["hit.health.audio.hurt.id"] = 0, -- Hit Settings/Health/Audio/Hurt/ID
	["hit.health.audio.hurt.file"] = "marioforeverbowser/sounds/hit.ogg", -- Hit Settings/Health/Audio/Hurt/File
	["hit.health.graphics.transition.time"] = 192, -- Hit Settings/Health/Graphics/Transition/Time
	["hit.health.graphics.transition.position.x"] = 0, -- Hit Settings/Health/Graphics/Transition/Position/X
	["hit.health.graphics.transition.position.y"] = -104, -- Hit Settings/Health/Graphics/Transition/Position/Y
	["hit.health.graphics.icon.file"] = "marioforeverbowser/images/hpicon.png", -- Hit Settings/Health/Graphics/Icon/File
	["hit.health.graphics.icon.position.x"] = 704, -- Hit Settings/Health/Graphics/Icon/Position/X
	["hit.health.graphics.icon.position.y"] = 64, -- Hit Settings/Health/Graphics/Icon/Position/Y
	["hit.health.graphics.health.file"] = "marioforeverbowser/images/hp.png", -- Hit Settings/Health/Graphics/Health/File
	["hit.health.graphics.health.position.x"] = -9, -- Hit Settings/Health/Graphics/Health/Position/X
	["hit.health.graphics.health.position.y"] = 0, -- Hit Settings/Health/Graphics/Health/Position/Y
	["hit.health.graphics.health.position.offsetx"] = 0, -- Hit Settings/Health/Graphics/Health/Position/X Offset
	["hit.health.graphics.health.position.offsety"] = 7, -- Hit Settings/Health/Graphics/Health/Position/Y Offset
	["hit.health.graphics.armor.file"] = "marioforeverbowser/images/hparmor.png", -- Hit Settings/Health/Graphics/Armor/File
	["hit.health.graphics.armor.position.x"] = -9, -- Hit Settings/Health/Graphics/Armor/Position/X
	["hit.health.graphics.armor.position.y"] = 0, -- Hit Settings/Health/Graphics/Armor/Position/Y
	["hit.health.graphics.armor.position.offsetx"] = 0, -- Hit Settings/Health/Graphics/Armor/Position/X Offset
	["hit.health.graphics.armor.position.offsety"] = 7, -- Hit Settings/Health/Graphics/Armor/Position/Y Offset
	["hit.definition.jump.damage"] = 1, -- Hit Settings/Definitions/Jump/Damage
	["hit.definition.jump.sub"] = 0, -- Hit Settings/Definitions/Jump/Sub Damage
	["hit.definition.below.damage"] = 0, -- Hit Settings/Definitions/Below/Damage
	["hit.definition.below.sub"] = 0, -- Hit Settings/Definitions/Below/Sub Damage
	["hit.definition.npc.damage"] = 0, -- Hit Settings/Definitions/NPC/Damage
	["hit.definition.npc.sub"] = 1, -- Hit Settings/Definitions/NPC/Sub Damage
	["hit.definition.breath.damage"] = 0, -- Hit Settings/Definitions/Projectile/Damage
	["hit.definition.breath.sub"] = 1, -- Hit Settings/Definitions/Projectile/Sub Damage
	["hit.definition.held.damage"] = 0, -- Hit Settings/Definitions/Held/Damage
	["hit.definition.held.sub"] = 0, -- Hit Settings/Definitions/Held/Sub Damage
	["hit.definition.lava.damage"] = 100, -- Hit Settings/Definitions/Lava/Damage
	["hit.definition.lava.sub"] = 0, -- Hit Settings/Definitions/Lava/Sub Damage
	["hit.definition.tail.damage"] = 0, -- Hit Settings/Definitions/Tail/Damage
	["hit.definition.tail.sub"] = 0, -- Hit Settings/Definitions/Tail/Sub Damage
	["hit.definition.spinjump.damage"] = 1, -- Hit Settings/Definitions/Spin Jump/Damage
	["hit.definition.spinjump.sub"] = 0, -- Hit Settings/Definitions/Spin Jump/Sub Damage
	["hit.definition.sword.damage"] = 1, -- Hit Settings/Definitions/Sword/Damage
	["hit.definition.sword.sub"] = 0, -- Hit Settings/Definitions/Sword/Sub Damage
	["battle.music.change"] = 1, -- Battle Settings/Music/Change
	["battle.music.id"] = -1, -- Battle Settings/Music/ID
	["battle.music.file"] = "marioforeverbowser/sounds/battle.ogg", -- Battle Settings/Music/File
	["battle.room.area.enabled"] = 1, -- Battle Settings/Room Lock/Area/Enabled
	["battle.room.area.speed"] = 1, -- Battle Settings/Room Lock/Area/Speed
	["defeat.lava.ignore"] = 2, -- Defeat Settings/Lava/Ignore Lava
	["defeat.lava.splash.enabled"] = 1, -- Defeat Settings/Lava/Splash/Enabled
	["defeat.lava.splash.range"] = 256, -- Defeat Settings/Lava/Splash/Range
	["defeat.lava.splash.strength"] = 1, -- Defeat Settings/Lava/Splash/Strength
	["defeat.lava.splash.time"] = 192, -- Defeat Settings/Lava/Splash/Time
	["defeat.lava.splash.timelag"] = 32, -- Defeat Settings/Lava/Splash/Time Lag
	["defeat.default.enabled"] = 1, -- Defeat Settings/Default Behaviour/Enabled
	["defeat.default.direction"] = 2, -- Defeat Settings/Default Behaviour/Direction
	["defeat.default.extension"] = 64, -- Defeat Settings/Default Behaviour/Section Extension
	["defeat.default.wintype"] = 2, -- Defeat Settings/Default Behaviour/Level Win Type
	["defeat.event"] = "", -- Defeat Settings/Event
	["defeat.fall.coyotetime"] = 256, -- Defeat Settings/Fall/Coyote Time
	["defeat.fall.speed"] = 1.5, -- Defeat Settings/Fall/Speed
	["defeat.fall.lavaspeed"] = 0.75, -- Defeat Settings/Fall/Lava Speed
	["defeat.audio.stun.volume"] = 1, -- Defeat Settings/Audio/Stun/Volume
	["defeat.audio.stun.id"] = 0, -- Defeat Settings/Audio/Stun/ID
	["defeat.audio.stun.file"] = "marioforeverbowser/sounds/stun.ogg", -- Defeat Settings/Audio/Stun/File
	["defeat.audio.fall.volume"] = 1, -- Defeat Settings/Audio/Fall/Volume
	["defeat.audio.fall.id"] = 0, -- Defeat Settings/Audio/Fall/ID
	["defeat.audio.fall.file"] = "marioforeverbowser/sounds/falling.ogg", -- Defeat Settings/Audio/Fall/File
	["defeat.audio.lava.volume"] = 1, -- Defeat Settings/Audio/Lava/Volume
	["defeat.audio.lava.id"] = 0, -- Defeat Settings/Audio/Lava/ID
	["defeat.audio.lava.file"] = "marioforeverbowser/sounds/lava.ogg", -- Defeat Settings/Audio/Lava/File
	["defeat.audio.jingle.volume"] = 1, -- Defeat Settings/Audio/Jingle/Volume
	["defeat.audio.jingle.id"] = 0, -- Defeat Settings/Audio/Jingle/ID
	["defeat.audio.jingle.file"] = "marioforeverbowser/sounds/defeat.ogg", -- Defeat Settings/Audio/Jingle/File
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		-- HARM_TYPE_JUMP, -- Handled separately due to jumphurt limitations
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		-- HARM_TYPE_SPINJUMP,
		HARM_TYPE_VANISH,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

--Custom local definitions below

-- Return the extra setting value if the predicate passes, or config value otherwise
function getValuePredicate(npc, key, predicate)
	local settings = npc.data._settings
	local settingsValue = settings[key]
	local useDefaultValue = USE_DEFAULT_VALUES[key]
	local cfg = NPC.config[npc.id]
	local cfgValue = cfg[key]
	if predicate then
		return settingsValue or cfgValue
	end
	return cfgValue
end

-- Return the config value if the extra setting is set to the USE_DEFAULT_VALUES, or extra setting value otherwise
function getValue(npc, key)
	local settings = npc.data._settings
	local settingsValue = settings[key]
	local useDefaultValue = USE_DEFAULT_VALUES[key]
	return getValuePredicate(npc, key, not (useDefaultValue and (settingsValue == useDefaultValue)))
end

-- Helper function for getting a random double in a given range using getValue()
function getRange(v, key)
	return getValue(v, key .. ".start") + RNG.random(0, getValue(v, key .. ".length"))
end

-- Helper function for getting a random integer in a given range using getValue()
function getRangeInt(v, key)
	return getValue(v, key .. ".start") + RNG.randomInt(0, getValue(v, key .. ".length"))
end

function getRangeIntConfig(v, key)
	if v.data._settings[key .. ".config"] then
		return NPC.config[v.id][key .. ".start"] + RNG.randomInt(0, NPC.config[v.id][key .. ".length"])
	end
	return getRangeInt(v, key)
end

function getID(npc, key)
	if npc.data._settings[key .. ".config"] then
		return NPC.config[npc.id][key .. ".id"]
	end
	return getValue(npc, key .. ".id")
end

function getDamage(v, name)
	return getValue(v, "hit.definition." .. name .. ".damage"), getValue(v, "hit.definition." .. name .. ".sub")
end

function playSFXIDOrFile(v, key, vol, ...)
	local predicate = not v.data._settings[key .. ".config"]
	local id = getValuePredicate(v, key .. ".id", predicate)
	if not vol then
		vol = getValue(v, key .. ".volume")
	end
	if id == 0 then
		return SFX.play(getValuePredicate(v, key .. ".file", predicate), vol, ...)
	else
		return SFX.play(id, vol, ...)
	end
end

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

--[[
	if STATE_MACHINE[state] exists
		if STATE_MACHINE[state][key] exists, return STATE_MACHINE[state][key]
		otherwise,
			if DEFAULT_FUNCTIONS[key] exists, return DEFAULT_FUNCTIONS[key]
			otherwise, return EMPTY_FUNCTION
	otherwise,
		if DEFAULT_FUNCTIONS[key] exists, return DEFAULT_FUNCTIONS[key]
		otherwise, return EMPTY_FUNCTION
]]
local function getStateFunctionality(state, key)
	return (STATE_MACHINE[state] and STATE_MACHINE[state][key]) or (DEFAULT_FUNCTIONS[key] or EMPTY_FUNCTION)
end

local function runStateFunctionality(v, key, ...)
	getStateFunctionality(v.data.state, key)(v, ...)
end

function setState(v, newState)
	if not VALID_STATE(newState) then
		newState = STATES.MOVING
	end
	
	runStateFunctionality(v, "onExit")
	v.data.state = newState
	runStateFunctionality(v, "onEnter")
	v.data.timer = 0
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = data._settings
	
	if v.despawnTimer <= 1 then
		return
	end
	v.despawnTimer = 180 -- Never despawn once spawned

	if not data.initialized then
		data.initialized = true

		data.healthTransitionTimer = 0
		data.healthTransitionTime = getValue(v, "hit.health.graphics.transition.time")
		data.healthTransitionX = getValue(v, "hit.health.graphics.transition.position.x")
		data.healthTransitionY = getValue(v, "hit.health.graphics.transition.position.y")
		data.timer = 0
		data.invul = 0
		data.invulTime = getValue(v, "hit.health.invulnerability")
		data.hp = getValue(v, "hit.health.hp")
		data.subhp = getValue(v, "hit.health.sub")
		data.state = getValue(v, "misc.startstate")
		data.dir = RNG.randomInt(0, 1) * 2 - 1
		data.speed = getValue(v, "movement.speed")
		data.turnid = getID(v, "misc.turnaround")
		MOVEMENT_PICK_IDLE(v)
		MOVEMENT_PICK_JUMP(v)
		setState(v, data.state)

		if getValue(v, "battle.room.area.enabled") == 1 then
			local blockID = getID(v, "misc.area")
			local areaID = settings["battle.room.area.id"]
			if areaID == -1 then
				for _, block in Block.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) do
					if block.id == blockID then
						data.boundaryBlock = block
						break
					end
				end
			else
				for _, block in Block.iterate(blockID) do
					if block.data._settings["id"] == areaID then
						data.boundaryBlock = block
						break
					end
				end
			end

			if not data.boundaryBlock then
				Misc.warn("Could not find area block of id " .. areaID .. ", skipped area lock", 0)
			else
				local player = npcUtils.getNearestPlayer(v)

				autoScroll.lockScreen(player.idx)
				autoScroll.scrollToBox(
					data.boundaryBlock.x,
					data.boundaryBlock.y,
					data.boundaryBlock.x + data.boundaryBlock.width,
					data.boundaryBlock.y + data.boundaryBlock.height,
					getValue(v, "battle.room.area.speed"),
					v.section
				)
			end
		end

		if getValue(v, "battle.music.change") == 1 then
			local newID = getValuePredicate(v, "battle.music.id", not settings["battle.music.config"])
			if newID == -1 then
				local episodePath = Misc.episodePath()
				local fullMusicPath = Misc.resolveFile(getValuePredicate(v, "battle.music.file", not settings["battle.music.config"]))
				local pathDifference = fullMusicPath:sub(#episodePath + 1, -1)
				Audio.MusicChange(v.section, pathDifference, 0)
			else
				Audio.MusicChange(v.section, newID, 0)
			end
		end
	end

	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0
	then
		return
	end

	runStateFunctionality(v, "onTick")
	npcUtils.applyLayerMovement(v)

	data.timer = data.timer + 1
	data.healthTransitionTimer = data.healthTransitionTimer + 1
end

function sampleNPC.onDrawNPC(v)
	if Defines.levelFreeze then return end

	if v.despawnTimer <= 1 then
		return
	end

	-- Hardcoded, just use movement state frames
	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0 then
		getStateFunctionality(STATES.MOVING, "onDraw")(v)
		npcUtils.hideNPC(v, nil)
		return
	end

	runStateFunctionality(v, "onDraw")
	npcUtils.hideNPC(v, nil)
end

function sampleNPC.onNPCHarm(eventToken, v, harmType, culpritOrNil)
	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0 then
		return
	end

	if v.id ~= npcID then return end
	if harmType == HARM_TYPE_VANISH then return end

	runStateFunctionality(v, "onHarm", eventToken, harmType, culpritOrNil)
end

--Gotta return the library table!
return sampleNPC