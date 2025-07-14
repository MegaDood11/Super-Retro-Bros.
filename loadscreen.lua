-- taken from betterfied 

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
local tipTable = loadTips.tipTable

local tipNum = 0

-- actual loadscreen stuffs

local time = 0
local image = Graphics.loadImage("loadscreen.png")
local image2 = Graphics.loadImage("loadscreenLogo.png")
local rot = 0

local fadeOut = 0

function onDraw()    
	-- tips
	
	 textplus.print{
        	x = 16 - 6,
        	y = 16,
       		xscale = 4,
        	yscale = 4,
        	text = "RETRO TIP:",
		font = textplus.loadFont("textplus/font/2.ini"),
        	pivot = {0, 0},
        	maxWidth = 432,
		color = Color.white * math.min(1, time / 60),
        	priority = -0.1,
    	}

    	if tipNum == 0 then
        	tipNum = rng.randomInt(1, #tipTable)
    	end

	if tipNum ~= 0 then
    		textplus.print{
        		x = 12,
        		y = 52,
       			xscale = 2,
        		yscale = 2,
        		text = tipTable[tipNum],
			font = textplus.loadFont("textplus/font/2.ini"),
        		pivot = {0, 0},
        		maxWidth = 432,
			color = Color.white * math.min(1, time / 60),
        		priority = -0.1,
    		}
	end

	-- all the other things

	time = time + 1
	rot = rot - 4

	Graphics.drawBox{ -- rotating circle thing
		texture = image,
		x = (438 + 12),
		y = (374 + 12),
		width = 96,
		height = 96,
        	rotation = rot,
		centered = true,
        	color = {1, 1, 1, math.min(1, time / 60)},
	}
	
	Graphics.drawBox{ -- logo
		texture = image2,
		x = 8,
		y = 384,
		width = 144,
		height = 56,
        	color = {1, 1, 1, math.min(1, time / 60)},
	}

        if Misc.getLoadingFinished() then -- smooth fade out (from battle arena)
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