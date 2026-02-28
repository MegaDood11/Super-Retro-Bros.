--[[

    smwMap.lua
    by MrDoubleA

    See main file for more

]]

local smwMap = require("smwMap")


local npcID = NPC_ID
local obj = {}

-- If true, the boo will show up even (greyed out) even if the level itself is locked.
local showBooIfLocked = true


smwMap.setObjSettings(npcID,{
    framesY = 1,

    isLevel = true,
})


return obj