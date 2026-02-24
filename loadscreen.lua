-- Taken from Betterfied 

function table.clone(t)
    local rt = {};
    for k,v in pairs(t) do
        rt[k] = v;
    end
    setmetatable(rt, getmetatable(t));
    return rt;
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
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
local hasLoaded = false

local fadeOut = 0

local FIRST_PLAYER_CHARACTER_ADDR = mem(0x00B25A20, FIELD_DWORD) + 0x184 + 0xF0
local charMem = mem(FIRST_PLAYER_CHARACTER_ADDR, FIELD_WORD)

local loadingLevel = mem(0x00B25720, FIELD_STRING)

function onDraw()    
	-- tips

	if not hasLoaded then
		Graphics.setMainFramebufferSize(512, 448)

		if table.contains(loadTips.dLevels,loadingLevel) then -- D World Tips
			tipTable = loadTips.tipTableD
		elseif table.contains(loadTips.minusLevels,loadingLevel) and (rng.randomInt(1, 2) == 1) then -- Minus World Tips
			tipTable = loadTips.tipTableMinus
		elseif charMem == 7 and (rng.randomInt(1, 3) == 1) then -- Wario Tips
			tipTable = loadTips.wario
		elseif charMem == 3 and (rng.randomInt(1, 3) == 1) then -- Waluigi Tips
			tipTable = loadTips.waluigi
		else
			if (rng.randomInt(1, 10) == 1) then -- Meme tips
				tipTable = loadTips.memeTips
			else
				tipTable = loadTips.tipTable -- Regular tips
			end
		end

		hasLoaded = true
	end
	
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

	if image then
	Graphics.drawBox{
		texture = image,
		x = 512-96,
		y = 448-96 - (math.sin(time / 6) * 5),
		width = 96,
		height = 96,
		sourceY = (charMem - 1) * 16,
		sourceHeight = 16,
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