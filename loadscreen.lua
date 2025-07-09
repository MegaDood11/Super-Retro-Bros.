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

-- tippy table

local tipTable = {
	"This was a pain to code :'(",
	"The power of a starman lets you stomp on enemies like normal!",
	"Collect Minus Medals and you might be in for a surprise...",
	"Some goal poles can be jumped over, see what happens if you do!",
	"The Beetroot can defeat enemies that fireballs can't.",
	"Use the Jumping Lui to your advantage. Some ceilings can be jumped over!",
	"Check the credits file to see who made what level!",
	"Not all bonus areas are underground, sometimes a vine can take you to the skies!",
	"Defeat Bowser with fireballs and you might find an imposter!",
	"Keep searching, the end of the game might not be the end of the levels.",
	"Luigi can jump higher, but be careful as he's a lot more slippery!",
	"There might be more characters to unlock than just the Mario Bros.",
	"Hammer Bros. are no joke, it's usually best to just run under them, or bonk them from below.",
	"Cheep Cheeps like to jump out of the water sometimes, so be careful on bridges!",
	"Hit every block you can, you never know what's inside...",
	"Low on lives? 1-UP Mushrooms are often found in hidden nooks.",
	"Did you know these are randomized?",
	"Ever feel stuck? Just walk to the right!",
	"Ever feel stuck? Just walk to the left if you even can!",
	"Kondor Koopas are unused in the original SMB1!",
	"Todd. was. here.",
	"so retro",
	"So Retro.",
	"SO RETRO!",
	"The Rip Lair is a group of random people who do cool (and random) stuff",
	"Beware of strong winds! They can push you off ledges.",
	"Some bloopers can swim without the need of water!",
	"kill everyone",
	"kill everything",
	"If you see a grumpy looking green Toad with a monobrow, say hi!",
	"If you jump 2401 times on the 20th tile in 1-3, you unlock Waluigi! (Lie)",
	"You can use the Beetroot to plow through walls of bricks! Maybe you'll find something special in them...",
	"Ripro is rip + retro.",
	"In bonus rooms, the character head will change depending on your character.",
	"They say there's a castle filled with Bowsers, found in a place unknown...",
	"The timer is much faster than normal (for the sake of accuracy), so... hurry up!",
	"Beyond the goal pole, you might find a mysterious pipe... why don't you enter it?",
	"There are nine worlds because Bowser forgot to buy Daisy pizza.",
	"Hurry! After defeating Lakitu, he may return within a few seconds.",
	"Bewear of poison mushrooms. Their icky taste will make you lose your powerup.",
	"Don't stomp on the Bloopers underwater. You can only stomp on Bloopers that swim in the air.",
	"Throughout your journey, some familiar foes from past adventures may appear...",
	"Get off quick! Standing on lift platforms for too long will cause them to fall!",
	"Heads up! Koopa Troopas can still hurt you for a brief period after bonking them from below.",
	"Larger Goombas will split into two smaller Goombas when stomping on them.",
	"Bowser Jr. is full of surprises. He'll sometimes throw Koopa shells or toss hammers just like his dad.",
	"Remember to introduce the first enemy of your level in a safe environment.",
	"The FitnessGram Pacer Test is a multistage aerobic capacity test that progressively gets more difficult as it continues.",
	"Trans rights are human rights!",
	"Bunnings Warehouse",
	"This has become a bit. My sanity has perished. Help me."
}

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
		x = (438 + 16),
		y = (374 + 4),
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