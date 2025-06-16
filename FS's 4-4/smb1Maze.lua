local blockManager = require("blockManager")
local paralx2 = require("paralx2")
local newNoTurnBack = require("newNoTurnBack")

local smb1Maze = {}

local restartIDMap = {}
local correctIDMap = {}
local wrongIDMap = {}

local lastRestartPointXPos = nil
local teleportPointXPos = nil
local hasPlayerDecided = false
local hasCorrectSFXPlayed = false
local hasWrongSFXPlayed = false

local TELEPORT_X_DELAY = 448

local bgPosSet = true
local bgPoses = {}


function smb1Maze.register(id, type)
    blockManager.registerEvent(id, smb1Maze, "onTickBlock")

    if type == 1 then
        restartIDMap[id] = true
    elseif type == 2 then
        correctIDMap[id] = true
    elseif type == 3 then
        wrongIDMap[id] = true
    end
end

function smb1Maze.onInitAPI()
    registerEvent(smb1Maze, "onCameraUpdate")
end

local function teleportPlayer()
    -- teleport    
    player:teleport(lastRestartPointXPos, player.y)

    -- reset boundaries
    newNoTurnBack.resetPos(player.section)

    -- reset teleport point
    teleportPointXPos = nil

    bgPoses = {}
    bgPosSet = false

    local bg = player.sectionObj.background
    
    for k, l in ipairs(bg:get()) do
        bgPoses[l.name] = {
            layerX  = l.x,
            cameraX = camera.x,
        }
    end
end

local function correctPath()
    hasPlayerDecided = true

    -- reset restart point for the next restart point
    lastRestartPointXPos = nil
    SFX.play("smb1Maze/Choice-Right.wav")
end

local function wrongPath()
    hasPlayerDecided = true

    if teleportPointXPos == nil then
        teleportPointXPos = player.x + TELEPORT_X_DELAY
        SFX.play("smb1Maze/Choice-Wrong.wav")
    end
end

function smb1Maze.onTickBlock(v)
    if restartIDMap[v.id] then
        if #Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) > 0 then
            lastRestartPointXPos = v.x
            hasPlayerDecided = false
        end
    end

    if correctIDMap[v.id] then
        if #Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) > 0 then
            if not hasCorrectSFXPlayed and not hasPlayerDecided and lastRestartPointXPos ~= nil then
                correctPath()
            end
            hasCorrectSFXPlayed = true
        else
            hasCorrectSFXPlayed = false
        end
    elseif wrongIDMap[v.id] then
        if #Player.getIntersecting(v.x + v.width - 1, v.y, v.x + v.width, v.y + v.height) > 0 then
            if not hasWrongSFXPlayed and not hasPlayerDecided and lastRestartPointXPos ~= nil then
                wrongPath()
            end
            hasWrongSFXPlayed = true
        else
            hasWrongSFXPlayed = false
        end
    end

    if teleportPointXPos == nil then return end

    if player.x >= teleportPointXPos then
        teleportPlayer()
    end
end

function smb1Maze.onCameraUpdate()
    if not bgPosSet then
        local bg = player.sectionObj.background
        
        for k, l in ipairs(bg:get()) do
            local pos = bgPoses[l.name]
            local parallaxX = l.parallaxX

            if parallaxX == nil and l.depth ~= nil then
                local d = l.depth/paralx2.focus
                d = d + 1
                d = 1/(d*d)
                parallaxX = d
            elseif parallaxX == nil then
                -- I hope I don't need to implement this
                -- d = ComputeFitDepth(l,w,h,800,600,bounds,sb)
            end

            l.x = pos.layerX + (camera.x - pos.cameraX) * parallaxX
        end

        bgPosSet = true
    end
end

return smb1Maze