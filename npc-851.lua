local npcManager = require("npcManager")

--[[
I commented all over this :D

Originally from the basegame

modifications by MarioXHK
]]
local flagpole = {}

local endstates = require("game/endstates")
local mega = require("npcs/ai/megashroom")
local utils = require("npcs/npcutils")

local npcID = NPC_ID

local flagpoleSettings = {
	id = npcID,
	width = 32,
	gfxwidth=32,
	height=32,
	gfxheight=32,
	frames=1,
	framestyle=0,
	framespeed = 8,
	playerblock=true,
	playerblocktop=true,
	npcblock=true,
	npcblocktop=true,
	nohurt=true,
	jumphurt = true,
	nofireball=true,
	noiceball=true,
	nogravity=true,
	noblockcollision=false,
	speed = 1,
	notcointransformable = true,
	isstationary = true,
	luahandlesspeed = true,
	nowaterphysics = true,
	nowalldeath=true,
	noyoshi=true,
	lineguided = true,
	linespeed = 3,
	lineactivebydefault = true,

	score = 0,

	debug = false,
}

npcManager.setNpcSettings(flagpoleSettings)

npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

-- Returns how many players are alive and valid
---@return number
local function alivePlayers()
	local lols = 0
	for _,p in ipairs(Player.get()) do
		if p.isValid and not p:isDead() then
			lols = lols + 1
		end
	end
	return lols
end

-- Returns a resolved sound file if `sefx` is a string. If it's a number, it'll clamp it between 1 and 91.
---@param sefx string|number|nil
---@return string|number|nil
local function resolveSoundSetting(sefx)
	if sefx then
		if tonumber(sefx) then
			sefx = math.clamp(tonumber(sefx),1,91)
		else
			if type(sefx) == "string" then
				sefx = Misc.resolveSoundFile(sefx)
			end
		end
	end
	return sefx
end

-- Attempts to resolve and play a sound
---@param sefx string|number|nil
local function playSoundSetting(sefx)
	sefx = resolveSoundSetting(sefx)
	if sefx then
		SFX.play(sefx)
	end
end

function flagpole.onInitAPI()
	registerEvent(flagpole, "onInputUpdate")
	registerEvent(flagpole, "onNPCHarm")
	registerEvent(flagpole, "onNPCKill")
	registerEvent(flagpole, "onPlayerHarm")
	registerEvent(flagpole, "onPlayerKill")
	npcManager.registerEvent(npcID, flagpole, "onTickNPC")
	npcManager.registerEvent(npcID, flagpole, "onTickEndNPC")
	npcManager.registerEvent(npcID, flagpole, "onCameraDrawNPC")
end

local poleFlagged = false

local levelEnding = false

-- Function that runs when the flagpole `v` has been poled
---@param v NPC the flagpole
---@param p Player? guy on pole
---@param onlyp boolean? if p's the only player
local function flagEnd(v,p,onlyp)
	local data = v.data
	local settings = data._settings
	local first = not onlyp
	if first then
		local r = resolveSoundSetting(settings.fireendsfx)
		if r and settings.levelend and type(data.fireworks) == "number" and data.fireworks > 0 then
			SFX.play(r)
		else
			playSoundSetting(settings.endsfx)
		end
	end
	if settings.levelend then
		if settings.defaultwinanim then
			if p then
				endstates.setPlayer(p)
			end
			if first then
				Level.endState(data.endState)
			end
		end
	else
		poleFlagged = false
		data.grabbingPlayers[p.data.flagpolegrabindex] = nil
		p.data.flagpolegrabindex = nil
	end
	if first then
		data.sprung = true
	end
end

-- Using a routine here to make sure this runs even if the flagpole dies to "no turn back"
---@param p Player
---@param v NPC
local function megaEndRoutine(p,v)
	local settings = v.data._settings
	Routine.waitFrames(settings.smashtime)
	if p.isMega then
		mega.StopMega(p,true)
		Routine.waitFrames(120)
	end
	flagEnd(v,p)
end

-- Function to smash the pole `v` with the culprit `p` in `dir` direction
---@param v NPC
---@param p Player|nil
---@param dir number?
local function smashpole(v,p,dir)
	local data = v.data
	local settings = data._settings
	local config = NPC.config[v.id]
	if data.lineguide then
		data.lineguide.attachCooldown = 9999
		data.lineguide.state = 2
	end

	playSoundSetting(settings.smashsound)

	v.speedX = settings.speedx * (dir or v.direction)
	v.speedY = settings.speedy
	v.friendly = true
	data.state = 2
	if p then
		Misc.givePoints(settings.smashscore, vector(p.x + p.width, p.y), false)
	else
		Misc.givePoints(settings.smashscore, vector(v.x + v.width/2, v.y + v.height/2), false)
	end
	if settings.smashwin then
		if p then
			Routine.run(megaEndRoutine, p, v)
		else
			flagEnd(v)
		end
	end
end

-- idk... Super Mario Bros Fireworks I guess
local smbfw = {
	[1] = true,
	[3] = true,
	[6] = true,
}

-- Wrap things up! Set off the fireworks and stuff based on the NPC `v`
---@param v NPC
local function wrapthingsup(v)
	local data = v.data
	local settings = data._settings
	if settings.fireworks ~= 0 then -- thank you, mario wiki,
		data.fireworks = 0
		if settings.fireworks == 1 then
			if Timer.isActive() then
				data.fireworks = Timer.getValue() % 10
				if not smbfw[data.fireworks] then
					data.fireworks = 0
				end
			end
		elseif settings.fireworks == 2 then
			if Timer.isActive() and Misc.coins() % 10 == Timer.getValue() % 10 then
				data.fireworks = 3*((Timer.getValue())%2)+3
			end
		elseif settings.fireworks == 3 or (settings.fireworks == 4 and alivePlayers() > 1) then
			if Timer.isActive() and (Timer.getValue()%100)%11 == 0 then
				data.fireworks = math.floor((Timer.getValue()%100)/11)
			end
		elseif settings.fireworks == 5 then
			if Timer.isActive() and Timer.getValue() % 10 == 3 then
				data.fireworks = 3
			end
		elseif settings.fireworks == 6 then
			if Timer.isActive() and (Timer.getValue()%100)%11 == settings.world then
				data.fireworks = math.floor((Timer.getValue()%100)/11)
			end
		end
	end
	data.stopTimer = true
	Misc.npcToCoins()
end

-- Executes when the NPC `v` gets harmed by `r` reason. It also gives the eventToken `e` and the culprit `n`
---@param e EventToken
---@param v NPC
---@param r number
---@param n Player|NPC|nil
function flagpole.onNPCHarm(e,v,r,n)
	if npcID ~= v.id then return end
	if r == HARM_TYPE_FROMBELOW then
		e.cancelled = true
		if v.data.gravity and not v.data.lineguide then
			local settings = v.data._settings
			playSoundSetting(settings.hitsound)
			v.speedY = settings.speedy
		end
	end
end

-- Executes when the NPC `v` gets killed by `r` reason. It also gives the eventToken `e`
---@param e EventToken
---@param v NPC
---@param r number
function flagpole.onNPCKill(e,v,r)
	if npcID ~= v.id then return end
	local data = v.data
	local settings = data._settings
	e.cancelled = true
	if data.state == 0 then
		if r == HARM_TYPE_LAVA then
			data.state = 3
			v.friendly = true
		else
			if settings.smashwin then
				poleFlagged = true
				if settings.levelend then
					wrapthingsup(v)
				end
			end
			smashpole(v)
		end
	end
end

-- Initialize the flagpole `v` animation sequence based on the grabbing player `p`, the direction `dir`, if the flagpole was touched at the top `cleared` and if the level should end `ending`
---@param v NPC
---@param p Player
---@param dir number
---@param cleared boolean
---@param ending boolean
local function initiateSequence(v, p, dir, cleared, ending)
	local data = v.data
	local settings = data._settings
	local cfg = NPC.config[v.id]
	local smashed = (p.isMega or p.mount == MOUNT_CLOWNCAR)
	if (not smashed) or settings.smashwin then
		data.grabbingPlayers[#data.grabbingPlayers+1] = p
		p.data.flagpolegrabindex = #data.grabbingPlayers
		p.direction = dir
		poleFlagged = true
		p:mem(0x50, FIELD_BOOL, false)
		if settings.levelend and ending then
			wrapthingsup(v)
		end
	end

	if smashed then
		smashpole(v,p,dir)
	else
		p.speedX = 0
		p.speedY = 0
		data.state = 1
		local polelength = settings.polelength*settings.segmentlength
		local quintiplea = polelength
		if cleared then
			quintiplea = quintiplea+p.height
		end
		p.y = math.max(p.y, v.y - quintiplea)
		local gradient = (p.y + p.height - (v.y - polelength)) / (polelength*1.1)
		local clampedGradient = math.ceil((1 - math.clamp(gradient, 0, 0.89)) * 10)
		if cleared then
			Misc.givePoints(10, vector(p.x + p.width, p.y), false)
		else
			Misc.givePoints(math.clamp(clampedGradient,2,9), vector(p.x + p.width, p.y), true)
		end
	end
end

-- Executes after all the inputs have been updated every tick
function flagpole.onInputUpdate()
	if Level.endState() == 0 and levelEnding then
		for k,p in ipairs(Player.get()) do
			for i, _ in pairs(p.keys) do
				p.keys[i] = false
			end
		end
	end
end

-- The function that every game tick for the NPC `v`
---@param v NPC
function flagpole.onTickNPC(v)
	if v.isHidden then return end
	v.despawnTimer = 5
	if not v.data.initialized then return end
	local data = v.data
	--if data.fireworks then
	--	Text.print(data.fireworks,100,100)
	--end
	local settings = data._settings
	local config = NPC.config[v.id]
	local first = true
	if data.stopTimer then if player.forcedState == 300 then Timer.setActive(false) else Timer.add(1,true) end end
	if poleFlagged and #data.grabbingPlayers > 0 then
		if data.forced then
			for _,p2 in ipairs(Player.get()) do
				if p2.isValid and not (p2.data.flagpolegrabindex or p2:isDead()) then
					local p = data.grabbingPlayers[data.highest]
					p2.x = p.x
					p2.y = p.y
				end
			end
		end
		for _,p in ipairs(data.grabbingPlayers) do
			if p.isValid then
				for i, _ in pairs(p.keys) do
					p.keys[i] = false
				end
				if data.sprung and not settings.defaultwinanim then
					if not data.ptimer[p.data.flagpolegrabindex] then
						data.ptimer[p.data.flagpolegrabindex] = math.floor(math.min(data.grabbingPlayers[data.lowest].y-p.y)/2)
					end
					data.ptimer[p.data.flagpolegrabindex] = data.ptimer[p.data.flagpolegrabindex] + 1
					local timber = data.ptimer[p.data.flagpolegrabindex]
					if first then
						if not data.endtimer then
							data.endtimer = 0
						end
						first = false
						data.endtimer = data.endtimer + 1

						if data.endtimer > lunatime.toTicks(settings.winwait) then
							if ((not data.fireworks) or data.fireworks <= 0) or not data.castle then
								if settings.dismount ~= 0 then
									for _,p2 in ipairs(Player.get()) do
										if p2.isValid then
											if (settings.dismount == p2.mount or settings.dismount == 4) then
												p2.mount = 0
											end
										end
									end
								end
								Level.exit(Level.endStateToWinType(data.endState))
							elseif data.fireworks and data.fireworks > 0 then
								if data.endtimer % settings.fwf == 0 then
									data.fireworks = data.fireworks - 1
									local b = data.castle
									Effect.spawn(settings.feffect,RNG.random((b.x-64)+settings.cfoffsetx,b.x+b.width+64+settings.cfoffsetx),RNG.random(b.y-128,b.y+settings.cfoffsety))
									playSoundSetting(settings.fireworksfx)
									Misc.score(settings.fpoints)
								end
								if data.fireworks <= 0 then
									data.endtimer = lunatime.toTicks(2.3)
								end
							end
						end
					end

					if p.data.insidecastle and ((settings.invisible and p.data.flagpolegrabindex == data.highest) or (p.data.flagpolegrabindex == data.lowest and not settings.invisible)) then
						data.youdidit = true
						local b = data.castle
						if settings.invisible then
							p.x = b.x+b.width/2-p.width/2
						end
						local scl = settings.castleflagscale
						if data.castleflag and not data.castleflagpos then
							data.castleflagpos = ((data.castleflag.height/settings.castleflagframes)*scl)/2
						end
						--if Timer.isActive() and Timer.getValue() > 0 then
						--	Timer.set(Timer.getValue()-1)
						--	Misc.score(50)
						--end
					end

					if timber > 0 and (not data.youdidit) then
						if data.fallcastle[p.idx] then
							if data.fallcastle[p.idx] == 0 then
								if p:isOnGround() then
									data.fallcastle[p.idx] = 1
									data.nomas[p.idx] = false
								else
									data.nomas[p.idx] = true
									p.speedX = 0
								end
							elseif data.fallcastle[p.idx] == 1 and not p:isOnGround() then
								data.fallcastle[p.idx] = 2
								data.nomas[p.idx] = true
								p.speedX = 0
							elseif data.nomas[p.idx] and p:isOnGround() and data.fallcastle[p.idx] == 2 and not data.undecided then
								data.fallcastle[p.idx] = 3
								data.nomas[p.idx] = false
							end
						end
						if data.nomas[p.idx] then
							p.keys.left = false
							p.keys.right = false
						else
							if data.flagdir == 1 then
								p.keys.right = true
								p.keys.left = false
								for _,b in BGO.iterateIntersecting(p.x+p.width/2,p.y,p.x+p.width/2,p.y+p.height) do
									if b.isValid and not b.isHidden then
										if b.id == settings.bgo and b.x+b.width/2 <= p.x+p.width/2 then
											if not data.castle then
												data.castle = b
											end
											p.data.insidecastle = true
											if settings.invisible then
												p.forcedState = FORCEDSTATE_INVISIBLE
											end
										end
									end
								end
							elseif data.flagdir == -1 then
								p.keys.left = true
								p.keys.right = false
								for _,b in BGO.iterateIntersecting(p.x+p.width/2,p.y,p.x+p.width/2,p.y+p.height) do
									if b.isValid and not b.isHidden then
										if b.id == settings.bgo and b.x+b.width/2 >= p.x+p.width/2 then
											if not data.castle then
												data.castle = b
											end
											p.data.insidecastle = true
											if settings.invisible then
												p.forcedState = FORCEDSTATE_INVISIBLE
											end
										end
									end
								end
							end
						end
						if timber == 32 and ((settings.dismount ~= 0 and settings.dismount == p.mount) or (settings.dismount == 4 and p.mount ~= 0)) then
							p.keys.altJump = true
							if settings.dismount == 2 then
								data.fallcastle[p.idx] = 0
							end
						elseif timber == 48 and data.undecided then
							data.nomas[p.idx] = true
						end
					end
				end
			end
		end
	end
end

-- Function that runs after onTick and internal smbx code for the NPC `v`
---@param v NPC
function flagpole.onTickEndNPC(v)
	local data = v.data
	local settings = data._settings
	local cfg = NPC.config[v.id]
	v:mem(0x154, FIELD_BOOL, false) -- fix noturnback despawn yo
	local polelength = settings.polelength*settings.segmentlength
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		if v:mem(0x124, FIELD_BOOL) then
			for k,c in ipairs(Camera.get()) do
				if v.y - polelength - NPC.config[v.id].gfxheight <= c.x + c.height then
					v.despawnTimer = 180
					break
				end
			end
		end
		if v.despawnTimer <= 0 then return end
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.grabbingPlayers = {}
		data.timer = 0
		if not settings.defaultwinanim then
			data.timer = -settings.multidelay
		end
		data.fallcastle = {}
		data.collider = data.collider or Colliders.Box(0,0,2,polelength + 2)
		data.topcol = data.topcol or Colliders.Circle(0,0,settings.topradius)
		data.animationTimer = data.animationTimer or 0
		data.state = 0
		data.sprung = false
		data.yippee = false
		data.flagPos = vector(settings.flagoffsetx, settings.flagoffsety)
		data.endState = settings.endstate+1
		data.undecided = false
		data.polecleared = false
		data.flagdir = v.direction
		data.gravity = settings.havegravity
		data.nomas = {}
		data.ptimer = {}
		data.lowest = 0
		data.highest = 0
		if v.direction == 0 then
			data.flagdir = RNG.randomSign()
			data.undecided = true
		elseif settings.flagmirror then
			data.flagdir = -data.flagdir
		end
		local snd = resolveSoundSetting(settings.flagsfx)
		if snd then
			data.flagsound = SFX.create{
				x = v.x,
				y = v.y,
				falloffRadius = 99999,
				sound = snd,
				falloffType = SFX.FALLOFF_NONE,
				play = false,
				loops = 1,
				parent = v,
			}
		else
			data.flagsound = nil
		end
		if settings.block and settings.block ~= 0 then
			local img = Graphics.sprites.block[settings.block].img

			if img then
				v.width = img.width
				v.height = img.height
				v.spawnX = v.spawnX-(v.width-32)/2
				v.spawnY = v.spawnY-(v.height-32)
			end
		end
	end

	if v.heldIndex ~= 0 or v.forcedState > 0 then
		if v.heldIndex ~= 0 then
			data.gravity = true
		end
		return
	end

	if cfg.debug then
		data.collider:Debug(true)
		data.topcol:Debug(true)
	end

	

	data.animationTimer = data.animationTimer + 1

	if data.state ~= 2 then
		utils.applyLayerMovement(v)
	end
	-- Put main AI below here
	data.collider.x = v.x + 0.5 * v.width - 1
	data.collider.y = v.y - data.collider.height
	data.topcol.x = v.x+v.width/2
	data.topcol.y = v.y-(polelength+data.topcol.radius)
	if not data.sprung then
		if data.state == 0 and not poleFlagged then
			if not v.friendly then
				for k,p in ipairs(Player.getIntersecting(v.x - 64, v.y - (polelength+data.topcol.radius*2), v.x + v.width + 64, v.y + v.height)) do
					if (p.isMega or p.mount == MOUNT_CLOWNCAR) and Colliders.speedCollide(p, v) then
						initiateSequence(v, p, p.direction, true, false)
						return
					end

					local topped = (settings.topbonus and Colliders.speedCollide(p,data.topcol) and p.y+p.height < polelength)

					if Colliders.speedCollide(p, data.collider) or topped then
						if topped then
							p.y = data.topcol.y-p.height
							data.polecleared = true
						end
						initiateSequence(v, p, p.direction, topped, true)
					end
				end
			end
		elseif data.state == 1 and #data.grabbingPlayers > 0 then
			data.timer = data.timer + 1
			if #data.grabbingPlayers >= alivePlayers() then
				data.timer = math.max(data.timer,0)
			elseif data.timer <= 0 then
				for k,p in ipairs(Player.getIntersecting(v.x - 64, v.y - polelength, v.x + v.width + 64, v.y + v.height)) do
					if (not p.data.flagpolegrabindex) and Colliders.speedCollide(p, data.collider) then
						initiateSequence(v, p, p.direction, false, false)
					end
				end
			end
			if data.timer > 0 then
				data.lowest = 0
				data.highest = 0
				local low = 1000000000
				local high = -1000000000
				for _,p in ipairs(data.grabbingPlayers) do
					if p.isValid then
						if p.y < low then
							low = p.y
							data.lowest = p.data.flagpolegrabindex
						end
						if p.y > high then
							high = p.y
							data.highest = p.data.flagpolegrabindex
						end
					end
				end
				if settings.levelend and not levelEnding then
					levelEnding = true
					for k,sss in ipairs(Section.get()) do
						sss.music = 0
					end
				end
			end
			local second = false
			local toppings = 0
			for _,p in ipairs(data.grabbingPlayers) do
				if p.isValid then
					if settings.useforcedstate then
						p.forcedState = FORCEDSTATE_FLAGPOLE
					else
						p.speedY = -Defines.player_grav
					end
					p.x = v.x + 0.5 * v.width - ((p.direction + 1) * 0.5) * (p.width - 4)
					if p.mount == 0 and p.character ~= CHARACTER_ULTIMATERINKA then
						if (p.character == CHARACTER_MARIO or p.character == CHARACTER_LUIGI) and p.powerup ~= 1 then
							p.frame = 30
						elseif (p.powerup == 1 and p.character ~= CHARACTER_NINJABOMBERMAN and p.character ~= CHARACTER_SNAKE and p.character ~= CHARACTER_UNCLEBROADSWORD) or p.character == CHARACTER_LINK then
							p.frame = 5
						else
							p.frame = 10
						end
						
					end
					if data.timer >= settings.delay then
						if not data.playedsound then
							data.playedsound = true
							if settings.fireworks == 7 and data.polecleared then
								if Timer.isActive() then
									data.fireworks = math.clamp(math.ceil((Timer.getValue()/100)*1.5),1,8)
								else
									data.fireworks = 3
								end
							end
							if data.flagsound then
								data.flagsound:play()
							end
						end
						if settings.levelend and not data.forced then
							data.forced = true
							for _,p2 in ipairs(Player.get()) do
								if p2.isValid and not (p2.data.flagpolegrabindex or p2:isDead()) then
									if settings.dismount ~= 0 and (settings.dismount == p2.mount or settings.dismount == 4) then
										p2.mount = 0
									end
									p2.forcedState = FORCEDSTATE_INVISIBLE
								end
							end
						end
						local stp = settings.stopearly and not (data.stoppedflag or data.polecleared)
						if settings.useforcedstate then
							if p.y + p.height < v.y then
								p.y = p.y + settings.polespeed
								local topped = false
								if #data.grabbingPlayers > 1 then
									for _,p2 in ipairs(data.grabbingPlayers) do
										if p2.isValid and p2 ~= p and p2.y < p.y+p.height and p2.y > p.y then
											p.y = p2.y-p.height
											topped = true
											break
										end
									end
								end
								if topped then
									toppings = toppings + 1
								end
								if p.y + p.height >= v.y then
									p.y = v.y - p.height
									if not topped then
										toppings = toppings + 1
									end
									if stp and toppings >= #data.grabbingPlayers then
										data.stoppedflag = true
										data.timer = math.ceil(polelength/settings.polespeed)+settings.delay
									end
								end
							else
								toppings = toppings + 1
								if stp and toppings >= #data.grabbingPlayers then
									data.stoppedflag = true
									data.timer = math.ceil(polelength/settings.polespeed)+settings.delay
								end
							end
						elseif not p:isOnGround() then
							p.speedY = settings.polespeed
						else
							if stp then
								data.stoppedflag = true
								data.timer = math.ceil(polelength/settings.polespeed)+settings.delay
							end
						end
						local t = (data.timer - settings.delay)/(polelength/settings.polespeed)
						if not second then
							if settings.stopearly and not data.polecleared then
								if not data.stoppedflag then
									data.flagPos.y = math.clamp(data.flagPos.y + settings.polespeed,settings.flagoffsety,polelength + settings.flagendoffsety)
								end
							else
								data.flagPos = math.lerp(vector(settings.flagoffsetx, settings.flagoffsety), vector(settings.flagendoffsetx, polelength + settings.flagendoffsety), math.min(t, 1))
							end
							if t >= 1 then
								data.stoppedflag = true
								if data.flagsound then
									data.flagsound:stop()
								end
							end
						end
						if t >= settings.requirementmultiplier then
							p.forcedState = 0
							flagEnd(v,p,second)
						end
						second = true
					end
				end
			end
		end
		if data.state == 2 or (data.gravity and not data.lineguide) then
			v.speedY = v.speedY + Defines.npc_grav
			if data.state ~= 2 then
				v.noblockcollision = false
			else
				v.noblockcollision = true
			end
		else
			v.noblockcollision = true
			if not data.notfirsttime then
				v.x = v.spawnX
				v.y = v.spawnY
			end
		end
	elseif poleFlagged and #data.grabbingPlayers > 0 then
		--local p = data.grabbingPlayer
		--p.direction = v.direction
--
		--p.speedX = math.clamp((p.speedX+Defines.player_walkspeed*v.direction*0.1),-Defines.player_walkspeed,Defines.player_walkspeed)
	end

	if data.castleflagpos then
		data.castleflagpos = math.max(data.castleflagpos-cfg.speed,-((data.castleflag.height/settings.castleflagframes)*settings.castleflagscale)/2)
	end
end

-- Function that runs every time the screen is drawn to a specific camera's `idx` for the NPC `v`
---@param v NPC
---@param idx integer
function flagpole.onCameraDrawNPC(v,idx)
	if v.despawnTimer <= 0 then return end

	local data = v.data

	if not data.initialized then return end

	local cam = Camera.get()[idx]

	local settings = data._settings

	if not data.drawinit then
		local pain = Misc.resolveGraphicsFile(settings.poletoppath)
		if pain then
			data.poletopgfx = Graphics.loadImage(pain)
		end
		local epig = Misc.resolveGraphicsFile(settings.polepath)
		if epig then
			data.polegfx = Graphics.loadImage(epig)
		end
		local fgy = Misc.resolveGraphicsFile(settings.flagpath)
		if fgy then
			data.flaggfx = Graphics.loadImage(fgy)
		end
		local yipe = Misc.resolveGraphicsFile(settings.winflagpath)
		if yipe then
			data.winflaggfx = Graphics.loadImage(yipe)
		end
		local hura = Misc.resolveGraphicsFile(settings.cflagpath)
		if hura then
			data.castleflag = Graphics.loadImage(hura)
			data.castleflagframe = 0
		end
		local yay = Misc.resolveGraphicsFile(settings.topflagpath)
		if yay then
			data.topflaggfx = Graphics.loadImage(yay)
			data.topflaggfxframe = 0
		end
		data.drawinit = true
	end

	local cfg = NPC.config[v.id]

	local polelength = settings.polelength*settings.segmentlength
	local t = math.floor(data.animationTimer/cfg.framespeed)

	local p = -45
	if cfg.foreground then
		p = - 15
	end
	if cfg.priority then
		p = cfg.priority
	end
	if v.forcedState > 0 then
		p = -75
	end

	if data.state == 3 then
		p = math.min(p,-11)
	end

	local block = settings.block
	local img

	if block and block ~= 0 then
		img = Graphics.sprites.block[block].img
	end

	if img and (v.x+v.width >= cam.x and v.x <= cam.x+cam.width) and (v.y+v.height >= cam.y and v.y <= cam.y+cam.height) then
		utils.hideNPC(v)
		Graphics.drawBox{
			texture = img,
			x = v.x+v.width/2,
			y = v.y+v.height/2,
			sourceX = 0,
			sourceY = 0,
			sourceWidth = v.width,
			sourceHeight = v.height,
			centered = true,
			sceneCoords = true,
			priority = p,
		}
	end

	local x = v.x + v.width/2 + cfg.gfxoffsetx
	local y = v.y + cfg.gfxoffsety - polelength - NPC.config[v.id].gfxheight

	local pgfxw = 16
	local pgfxh = 16

	local pscale = settings.polegfxscale
	local ptscale = settings.poletopgfxscale
	if data.polegfx and (x+(data.polegfx.width*pscale)/2 >= cam.x and x-(data.polegfx.width*pscale)/2 <= cam.x+cam.width) then -- Pole
		local asdf = 1
		local ghjk = data.polegfx.width * pscale * settings.polelength
		local wasd = (data.polegfx.width * pscale * settings.polelength)/2

		pgfxw = data.polegfx.width
		pgfxh = data.polegfx.height

		if settings.repeatpole then
			asdf = settings.polelength
			ghjk = data.polegfx.width * pscale
			wasd = (data.polegfx.width * pscale)/2
		end
		for i = 1, asdf do
			Graphics.drawBox{
				texture = data.polegfx,
				x = x,
				y = y+i*data.polegfx.height*2 + wasd,
				sourceX = 0,
				sourceY = 0,
				sourceWidth = data.polegfx.width,
				sourceHeight = data.polegfx.height,
				width = data.polegfx.width * pscale,
				height = ghjk,
				centered = true,
				sceneCoords = true,
				priority = p-0.02,
			}
		end
		-- local pgfwidth = cfg.polegfxwidth+cfg.gfxspacing*2
	end

	if data.poletopgfx and (x+(data.poletopgfx.width * ptscale)/2 >= cam.x and v.x-(data.poletopgfx.width * ptscale)/2 <= cam.x+cam.width) and (y >= cam.y and y-(data.poletopgfx.height * ptscale) <= cam.y+cam.height) then -- Top
		Graphics.drawBox{
			texture = data.poletopgfx,
			x = x,
			y = y + (data.poletopgfx.height * ptscale)/2 ,
			sourceX = 0,
			sourceY = 0,
			sourceWidth = data.poletopgfx.width,
			sourceHeight = data.poletopgfx.height,
			width = data.poletopgfx.width * ptscale,
			height = data.poletopgfx.height * ptscale,
			centered = true,
			sceneCoords = true,
			priority = p,
		}
	end

	if data.castleflagpos and data.castleflag and data.castle then
		if lunatime.drawtick() % cfg.framespeed == 0 then
			data.castleflagframe = data.castleflagframe + 1
			if data.castleflagframe >= settings.castleflagframes then
				data.castleflagframe = 0
			end
		end
		local b = data.castle
		--Text.print("flag",b.x+b.width/2-camera.x,b.y+data.castleflagpos-camera.y)
		local pp = settings.cfprior
		if pp == -100 then
			pp = BGO.config[b.id].priority-0.01
		end
		if (b.x+b.width/2+settings.cfoffsetx >= cam.x and (b.x-b.width/2)+settings.cfoffsetx <= cam.x+cam.width) and (b.y+b.height/2+settings.cfoffsety >= cam.y and (b.y-b.height/2)+settings.cfoffsety <= cam.y+cam.height) then
			Graphics.drawBox{
				texture = data.castleflag,
				x = b.x+b.width/2+settings.cfoffsetx,
				y = b.y+data.castleflagpos+settings.cfoffsety,
				sourceWidth = data.castleflag.width,
				sourceHeight = data.castleflag.height/settings.castleflagframes,
				sourceX = 0,
				sourceY = (data.castleflag.height/settings.castleflagframes)*data.castleflagframe,
				width = data.castleflag.width * settings.castleflagscale,
				height = (data.castleflag.height/settings.castleflagframes) * settings.castleflagscale,
				centered = true,
				sceneCoords = true,
				priority = pp,
			}
		end
	end

	y = y + pgfxh*2

	if data.flaggfx then -- Flag
		local flagFrame = (t % settings.flagframes)

		local fgfxh = data.flaggfx.height/settings.flagframes

		local xl = x + (data.flagPos.x+2)*data.flagdir
		local yl = y + data.flagPos.y + (pgfxh * settings.flagscale)/2

		local txt = data.flaggfx


		if data.winflaggfx and (data.sprung or #data.grabbingPlayers > 0) then
			yl = v.y + (settings.flagoffsety-data.flagPos.y) - (pgfxh * settings.flagscale)/2
		end

		if data.flagPos.y == polelength + settings.flagendoffsety and data.topflaggfx and not data.yippee then -- doing it here because the numbers are conveniently here already
			data.yippee = true
			Effect.spawn(147,xl-(data.flaggfx.width*settings.flagscale)/2,yl-(fgfxh*settings.flagscale)/2)
		end

		if data.yippee and data.topflaggfx then
			txt = data.topflaggfx
		elseif data.winflaggfx and (data.sprung or #data.grabbingPlayers > 0) then
			txt = data.winflaggfx
		end


		if (xl+data.flaggfx.width/2 >= cam.x and xl-data.flaggfx.width/2 <= cam.x+cam.width) and (yl+fgfxh/2 >= cam.y and yl-fgfxh/2 <= cam.y+cam.height) then
			Graphics.drawBox{
				texture = txt,
				x = xl,
				y = yl,
				sourceX = math.max(data.flaggfx.width*-data.flagdir,0),
				sourceY = fgfxh*flagFrame,
				sourceWidth = data.flaggfx.width*data.flagdir,
				sourceHeight = fgfxh,
				width = pgfxw * settings.flagscale,
				height = pgfxh * settings.flagscale,
				centered = true,
				sceneCoords = true,
				priority = p-0.01,
			}
		end
	end
end

-- Runs when a player `p` is harmed, giving the EventToken `e` which can be cancelled
---@param p Player
---@param e EventToken
function flagpole.onPlayerHarm(e,p)
	if p.data.flagpolegrabindex and levelEnding then
		e.cancelled = true
	end
end

-- Runs when a player `p` is killed, giving the EventToken `e` which can be cancelled
---@param p Player
---@param e EventToken
function flagpole.onPlayerKill(e,p)
	if p.data.flagpolegrabindex and levelEnding then
		e.cancelled = true
	end
end

return flagpole