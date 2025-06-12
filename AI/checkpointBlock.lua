local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local textplus = require("textplus")
local easing = require("ext/easing")

local checkpoint = {}
local checkpointEffects = {}


checkpoint.idList = {}
checkpoint.idMap = {}


function checkpoint.register(id)
    local config = Block.config[id]
    
	blockManager.registerEvent(id, checkpoint, "onStartBlock")
	blockManager.registerEvent(id, checkpoint, "onTickEndBlock")

    table.insert(checkpoint.idList, id)
    checkpoint.idMap[id] = textplus.layout(textplus.parse(config.checkpointText, config.fontSettings))
end

function checkpoint.onInitAPI()
	registerEvent(checkpoint, "onTick")
	registerEvent(checkpoint, "onDraw")
end

local function initialize(v, data)
	if data.checkpoint ~= nil then
        return
    end

    local settings = data._settings

    settings.textOffset = settings.textOffset or vector(0, 0)
    settings.playerOffset = settings.playerOffset or vector(0, 0)

    data.checkpoint = Checkpoint{
        x = v.x + v.width/2 + settings.playerOffset.x,
        y = v.y + v.height  + settings.playerOffset.y - 32,
        section = blockutils.getBlockSection(v),
        sound = 58,
    }
end

local function spawnEffect(c, v, xOffset, yOffset)
	local entry = {
        id = v.id,
        x = c.x + xOffset,
        y = c.y + yOffset,
        timer = 0,
        isValid = true,

        target = 64,
        offset = 48,
    }

    table.insert(checkpointEffects, entry)

    Routine.run(function(v)
        while v.timer < 1 do
            v.timer = math.min(v.timer + 0.025, 1)
            Routine.skip()
        end

        Routine.waitFrames(24)

        v.offset = v.offset + v.target
        v.target = 0
        v.timer = 1

        while v.timer > 0 do
            v.timer = math.max(v.timer - 0.075, 0)
            Routine.skip()
        end

        v.isValid = false

    end, entry)
end

-- override basegame's onStart, hacky, but it's the only way
local oldOnStart = Checkpoint.onStart

Checkpoint.onStart = function()
    for k, v in Block.iterate(checkpoint.idList) do
        initialize(v, v.data)
    end

    oldOnStart()
end


function checkpoint.onStartBlock(v)
	initialize(v, v.data)
end

function checkpoint.onTickEndBlock(v)
	initialize(v, v.data)
end

function checkpoint.onTick()
	for _, p in ipairs(Player.get()) do
		for k, v in Block.iterateIntersecting(p.x, p.y, p.x + p.width, p.y + p.height) do
			local data = v.data
			local settings = data._settings

			if checkpoint.idMap[v.id] and data.checkpoint ~= nil and not data.checkpoint.collected and Misc.canCollideWith(p, v) then
                Checkpoint.reset()
				data.checkpoint:collect(p)
                spawnEffect(data.checkpoint, v, settings.textOffset.x, settings.textOffset.y)
			end
		end
	end
end

function checkpoint.onDraw()
	for k = #checkpointEffects, 1, -1 do
        local v = checkpointEffects[k]
        local currentOffset = easing.outSine(v.timer, 0, 1, 1) * v.target
        local layout = checkpoint.idMap[v.id]

        textplus.render{
            x = math.floor(v.x - (layout.width-2)/2 + 8),
            y = math.floor(v.y - (v.offset + currentOffset) - layout.height),
            layout = layout,
            color = Color.white * v.timer,
            sceneCoords = true,
            priority = 5,
        }

        if not v.isValid then
            table.remove(checkpointEffects, k)
        end
    end
end

return checkpoint