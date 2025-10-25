-- Taken from Betterfied 

function table.clone(t)
    local rt = {};
    for k,v in pairs(t) do
        rt[k] = v;
    end
    setmetatable(rt, getmetatable(t));
    return rt;
end

function math.clamp(a,mi,ma)
    mi = mi or 0;
    ma = ma or 1;
    return math.min(ma,math.max(mi,a));
end

do
    local function exists(path)
        local f = io.open(path,"r")

        if f ~= nil then
            f:close()
            return true
        else
            return false
        end
    end

    Misc.resolveFile = (function(path)
        local inScriptPath = getSMBXPath().. "\\scripts\\".. path
        local inEpisodePath = _episodePath.. path

        return (exists(path) and path) or (exists(inEpisodePath) and inEpisodePath) or (exists(inScriptPath) and inScriptPath) or nil
    end)

    Misc.resolveGraphicsFile = Misc.resolveFile

    -- Make require work better
    local oldRequire = require

    function require(path)
        local inScriptPath = getSMBXPath().. "\\scripts\\".. path.. ".lua"
        local inScriptBasePath = getSMBXPath().. "\\scripts\\base\\".. path.. ".lua"
        local inEpisodePath = _episodePath.. path.. ".lua"

        local path = (exists(inEpisodePath) and inEpisodePath) or (exists(inScriptPath) and inScriptPath) or (exists(inScriptBasePath) and inScriptBasePath)
        assert(path ~= nil,"module '".. path.. "' not found.")

        return oldRequire(path)
    end

    -- reload libs

    -- lunatime
    _G.lunatime = require("engine/lunatime")

    -- Color
    _G.Color = require("engine/color")
end

package.path = package.path .. ";./scripts/?.lua"

local rng = require("base/rng")
local textplus = require("textplus")

local loadTips = require("loadscreenTips")
local tipTable

local tipNum = 0

-- Actual loadscreen stuffs

local time = 0
local image = Graphics.loadImageResolved("loadscreen.png")
local image2 = Graphics.loadImageResolved("loadscreenLogo.png")
local rot = 0
local hasLoaded = false

local fadeOut = 0

local FIRST_PLAYER_CHARACTER_ADDR = mem(0x00B25A20, FIELD_DWORD) + 0x184 + 0xF0
local charMem = mem(FIRST_PLAYER_CHARACTER_ADDR, FIELD_WORD)

local loadingLevel = mem(0x00B25720, FIELD_STRING)

function onDraw()    
	-- tips

	if not hasLoaded then
		Graphics.setMainFramebufferSize(512, 448)

		if loadTips.dLevels[loadingLevel] and (rng.randomInt(1, 2) == 1) then
			tipTable = loadTips.tipTableD
		elseif loadTips.minusLevels[loadingLevel] and (rng.randomInt(1, 3) == 1) then
			tipTable = loadTips.tipTableMinus
		elseif charMem == 7 and (rng.randomInt(1, 3) == 1) then
			tipTable = loadTips.wario
		elseif charMem == 3 and (rng.randomInt(1, 3) == 1) then
			tipTable = loadTips.waluigi
		else
			tipTable = loadTips.tipTable
		end

		hasLoaded = true
	end

	-- Testing texts. Comment out when redundant.

	 textplus.print{
        	x = 0,
        	y = 350,
       		xscale = 2,
        	yscale = 2,
        	text = tostring(loadingLevel),
		font = textplus.loadFont("textplus/font/3.ini"),
        	pivot = {0, 0},
        	maxWidth = 432,
		color = Color.white,
        	priority = -0.1,
    	}
	 textplus.print{
        	x = 0,
        	y = 366,
       		xscale = 2,
        	yscale = 2,
        	text = tostring(loadTips.dLevels[loadingLevel]),
		font = textplus.loadFont("textplus/font/3.ini"),
        	pivot = {0, 0},
        	maxWidth = 456,
		color = Color.white,
        	priority = -0.1,
    	}

---------------------------------------------
	
	 textplus.print{
        	x = 16 - 6,
        	y = 24,
       		xscale = 4,
        	yscale = 4,
        	text = "RETRO TIP:",
		font = textplus.loadFont("textplus/font/3.ini"),
        	pivot = {0, 0},
        	maxWidth = 432,
		color = Color.white * math.min(1, time / 60),
        	priority = -0.1,
    	}

    	if tipNum == 0 and tipTable ~= nil then
        	tipNum = rng.randomInt(1, #tipTable)
    	end

	if tipNum ~= 0 then
    		textplus.print{
        		x = 12,
        		y = 52,
       			xscale = 2,
        		yscale = 2,
        		text = tipTable[tipNum],
			font = textplus.loadFont("textplus/font/3.ini"),
        		pivot = {0, 0},
        		maxWidth = 432,
			color = Color.white * math.min(1, time / 60),
        		priority = -0.1,
    		}
	end

	-- All the other things

	time = time + 1
	rot = rot - 4

	if image then
	Graphics.drawBox{ -- Rotating circle thing
		texture = image,
		x = (438 + 12),
		y = (374 + 12),
		width = 96,
		height = 96,
        	rotation = rot,
		centered = true,
        	color = {1, 1, 1, math.min(1, time / 60)},
	}
	end
	
	if image2 then
	Graphics.drawBox{ -- logo
		texture = image2,
		x = 8,
		y = 384,
		width = 144,
		height = 56,
        	color = {1, 1, 1, math.min(1, time / 60)},
	}
	end

	-- Smooth fade out (from Battle Arena)

        if Misc.getLoadingFinished() then 
            	fadeOut = math.min(1,fadeOut + 1/20)
        end

        if fadeOut < 1 then
            	Misc.setLoadScreenTimeout(15)
        else
            	Misc.setLoadScreenTimeout(0)
        end

    	if fadeOut > 0 then
        	Graphics.drawBox{
            		color = {0, 0, 0, fadeOut},priority = 15,
            		x = 0,y = 0,width = 512,height = 448,
        	}
    	end
end