local out = 500
local alpha = 1
local fadeout = 50
local timeleft = 65*6.5
local playery = 0

local screenw,screenh = 512,448
--screenw,screenh = 800,600

local function outBounce(t, b, c, d) -- taken from easing.lua
  t = t / d
  if t < 1 / 2.75 then
    return c * (7.5625 * t * t) + b
  elseif t < 2 / 2.75 then
    t = t - (1.5 / 2.75)
    return c * (7.5625 * t * t + 0.75) + b
  elseif t < 2.5 / 2.75 then
    t = t - (2.25 / 2.75)
    return c * (7.5625 * t * t + 0.9375) + b
  else
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
  end
end

local characterDeathEffects = {
	3,
	5,
	129, -- peach
	130,
	nil, -- link
	nil, -- megaman
	150
}

-- Address of the first player's character. Equivalent to 'player.character', except the player class doesn't exist in loading screens
local FIRST_PLAYER_CHARACTER_ADDR = mem(0x00B25A20,FIELD_DWORD) + 0x184 + 0xF0
local charMem = mem(FIRST_PLAYER_CHARACTER_ADDR,FIELD_WORD)

local deathEffectID = characterDeathEffects[charMem]

function onDraw()
	timeleft = timeleft - 1

	if timeleft - 64 < fadeout then
		alpha = alpha - (1/timeleft)
	end

	if timeleft < 320 then
		out = math.max(56, out - 8)
	end

	playery = math.min(playery + 0.01, 1)
	local ease = outBounce(playery, -64, (screenh/2 + 64), 1)

	if alpha > 0 then
		local img = Graphics.sprites.hardcoded["59"].img
		local imgw = img.width/2
		local imgh = img.height

		local img2 = Graphics.sprites.effect[deathEffectID].img
		local imgw2 = img2.width*2

		Graphics.drawBox{
			texture = img,
			x = screenw/2 - imgw - out,
			y = screenh/2 - imgh/2,
			sourceWidth = imgw,
			color = {1.0, 1.0, 1.0, alpha}
		}

		Graphics.drawBox{
			texture = img,
			x = screenw/2 + out,
			y = screenh/2 - imgh/2,
			sourceWidth = imgw,
			sourceX = imgw,
			color = {1.0, 1.0, 1.0, alpha}
		}

		Graphics.drawBox{
			texture = img2,
			x = screenw/2 - img2.width,
			y = ease - img2.height,
			width = imgw2,
			height = img2.height*2,
			color = {1.0, 1.0, 1.0, alpha}
		}
	end

	if timeleft <= 0 then
		Misc.setGameoverCompleted()
	end
end