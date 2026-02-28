--[[

    smwMap.lua
    by MrDoubleA

    See main file for more

]]

local smwMap = require("smwMap")


local npcID = NPC_ID
local obj = {}


smwMap.setObjSettings(npcID,{
    framesY = 4,

    onTickObj = (function(v)
        local totalFrames = smwMap.getObjectConfig(v.id).framesY
		v.frameY = smwMap.doBasicAnimation(v,totalFrames - 1,4)
		v.graphicsOffsetX = -4
		v.graphicsOffsetY = -40 + math.cos(v.data.animationTimer / 16) * 4
    end),

    isLevel = true,

    hasDestroyedAnimation = false,
})


return obj