
--[[
				   smb1HUD.lua by John Nameless
				A HUD script designed to replicate
				the UI of the all-stars version of 
					   Super Mario Bros.
			
	CREDITS:
	SasPop & Storice - ripped the HUD text sprites from SMAS-SMB1. (https://www.spriters-resource.com/snes/smassmb1/sheet/132605/)
	KoopshiKingGeoshi - made extra sprites for SMAS-SMB1's HUD. (https://www.deviantart.com/koopshikinggeoshi/art/SMB-All-Stars-Font-and-icons-650035211)
	
	TO DO:
	- Implement multiplayer + split-screen support, whenever you have the motivation to do so.
]]--

local tplus = require("textplus")
local starcoin = require("npcs/ai/starcoin")

local smb1HUD = {}
 
smb1HUD.toggles = {
	lives = true,
	score = true,
	coins = true,
	stars = true,
	timer = true,
	world = true,
	character = true,
	starcoins = true,
	reserve = true, -- is also a toggle for showing the health bar for characters using hearts
}

smb1HUD.currentWorld = vector(0,1) -- how inserting your value should work: smb1HUD.currentWorld = vector(*worldNumber*,*levelNumber*)
smb1HUD.coinIconIMG = Graphics.loadImageResolved("smb1HUD/coinIcon.png")
smb1HUD.reserveIMG = Graphics.loadImageResolved("smb1HUD/reserveBox.png")
smb1HUD.heartsIMG = Graphics.loadImageResolved("smb1HUD/hearts.png")
smb1HUD.hudFont = tplus.loadFont("smb1HUD/smb1-font.ini")

local defaultNames = {
	[CHARACTER_MARIO] = "MARIO",
	[CHARACTER_LUIGI] = "LUIGI",
	[CHARACTER_PEACH] = "PEACH",
	[CHARACTER_TOAD] = "TOAD",
	[CHARACTER_LINK] = "LINK",
	[CHARACTER_MEGAMAN] = "MEGAMAN",
	[CHARACTER_WARIO] = "WARIO",
	[CHARACTER_BOWSER] = "BOWSER",
	[CHARACTER_KLONOA] = "KLONOA",
	[CHARACTER_NINJABOMBERMAN] = "BOMBERMAN",
	[CHARACTER_ROSALINA] = "ROSALINA",
	[CHARACTER_SNAKE] = "SNAKE",
	[CHARACTER_ZELDA] = "ZELDA",
	[CHARACTER_ULTIMATERINKA] = "U.RINKA",
	[CHARACTER_UNCLEBROADSWORD] = "BROADSWORD",
	[CHARACTER_SAMUS] = "SAMUS"
}

smb1HUD.characterNames = defaultNames

smb1HUD.getValue = {
	["lives"] = function()
		local lives = ""
		if smb1HUD.toggles.lives then
			lives = "lx"..string.format("%.2d",mem(0x00B2C5AC,FIELD_FLOAT))
		end
		return lives
	end,
	["score"] = function()
		local score = ""
		if smb1HUD.toggles.score then
			score = string.format("%.6d",Misc.score())
		end
		return score
	end,
	["coins"] = function()
		local coins = ""
		if smb1HUD.toggles.coins then
			coins = " x"..string.format("%.2d",Misc.coins())
		end
		return coins
	end,
	["stars"] = function()
		local stars = ""
		if smb1HUD.toggles.stars and mem(0x00B251E0,FIELD_WORD) > 0 then
			stars = "*x"..string.format("%.2d",mem(0x00B251E0,FIELD_WORD))
		end
		return stars
	end,
	["timer"] = function()
		local timer = ""
		if smb1HUD.toggles.timer and Timer.isVisible() then
			timer = "TIME<br> " ..  string.format("%.3d",math.min(Timer.getValue(),999))
		end
		return timer
	end,
	["world"] = function()
		local world = ""
		if smb1HUD.toggles.world then
			world = "WORLD<br>"
			if string.len(tostring(smb1HUD.currentWorld.x)) <= 1 then
				world = world .. " "
			end
			world = world .. tostring(smb1HUD.currentWorld.x) .. "-" .. tostring(smb1HUD.currentWorld.y)
		end
		return world
	end,
	["character"] = function()
		local character = ""
		if smb1HUD.toggles.character then
			if smb1HUD.characterNames[player.character] == nil then
				smb1HUD.characterNames[player.character] = defaultNames[player.character]
			end
			character = tostring(smb1HUD.characterNames[player.character])
		end
		return character
	end,
	["reserve"] = function()
		return player.reservePowerup
	end,
	["health"] = function()
		return math.min(player:mem(0x16, FIELD_WORD),3)
	end,
	["starcoins"] = function()
		local starcoins = ""
		if smb1HUD.toggles.starcoins then
			for coinIDX, v in ipairs(starcoin.getLevelList(Level.filename())) do
				if v ~= 0 then
					starcoins = starcoins .. "s"
				else
					starcoins = starcoins .. "e"
				end
				if coinIDX % 5 == 0 then
					starcoins = starcoins .. "<br>"
				end
			end
		end
		return starcoins
	end
}

local function updateLayout(status,txt)
	if status.curText ~= nil and status.curText == txt then 
		return
	end
	status.curLayout = tplus.layout(
		tplus.parse(
			txt,
			{
				font = smb1HUD.hudFont, 
				xscale = 2,
				yscale = 2,
			}
		)
	)
	status.curText = txt
end

smb1HUD.statuses = {
	["charNscore"] = {
		x = 0,
		y = 30,
		curText = nil,
		curLayout = nil,
		updateFunction = function(status,cam)
			status.x = (cam.width*0.5) - 208
			return smb1HUD.getValue["character"]() .. "<br>" .. smb1HUD.getValue["score"]()
		end
	},
	["collectables"] = {
		x = 0,
		y = 30,
		curText = nil,
		curLayout = nil,
		updateFunction = function(status,cam)
			status.x = (cam.width*0.5) - 80
			if smb1HUD.toggles.reserve then
				status.x = status.x - 24
			end
			if smb1HUD.toggles.coins then
				Graphics.drawImageWP(
					smb1HUD.coinIconIMG,
					status.x,
					status.y + 16,
					0,
					smb1HUD.coinIconIMG.height/3 * math.floor(1 * (math.floor(lunatime.tick() / 10) % 3)),
					smb1HUD.coinIconIMG.width,
					smb1HUD.coinIconIMG.height/3,
					1,
					4.999999
				)
			end
			local txt = smb1HUD.getValue["lives"]() .. "<br>" .. smb1HUD.getValue["coins"]() .. "<br>" .. smb1HUD.getValue["stars"]()
			if smb1HUD.toggles.stars and not smb1HUD.toggles.lives then
				txt = smb1HUD.getValue["stars"]() .. "<br>" .. smb1HUD.getValue["coins"]()
			end
			return txt
		end
	},
	["world"] = {
		x = 0,
		y = 30,
		curText = nil,
		curLayout = nil,
		updateFunction = function(status,cam)
			status.x = (cam.width*0.5) + 32
			if smb1HUD.toggles.reserve then
				status.x = status.x + 8
			end
			return smb1HUD.getValue["world"]() 
		end
	},
	["starcoins"] = {
		x = 0,
		y = 62,
		curText = nil,
		curLayout = nil,
		updateFunction = function(status,cam)
			status.x = ((cam.width*0.5) + 72) - math.floor(0.5*(16 * math.min(#starcoin.getLevelList(Level.filename()),5)))
			if smb1HUD.toggles.reserve then
				status.x = status.x + 8
			end
			if not smb1HUD.toggles.world then
				status.y = 46
			elseif status.y ~= 62 then
				status.y = 62
			end
			return smb1HUD.getValue["starcoins"]()
		end
	},
	["time"] = {
		x = 0,
		y = 30,
		curText = nil,
		curLayout = nil,
		updateFunction = function(status,cam)
			status.x = (cam.width*0.5) + 144
			return smb1HUD.getValue["timer"]()
		end
	},
}

function smb1HUD.drawHUD(idx,priority,isSplit)
	local toggle = smb1HUD.toggles
	local cam = Camera(idx)
	for i,v in pairs(smb1HUD.statuses) do
		updateLayout(
			v,
			v.updateFunction(v,cam)
		)
		if v.curText ~= nil and v.curText ~= "" then
			tplus.render{
				x = v.x,
				y = v.y,
				layout = v.curLayout,
				priority = priority
			}
		end
	end
	
	if not smb1HUD.toggles.reserve or idx > 1 then return end
	
	local args = {
		img = nil,
		x = 0,
		y = 0, 
		sourceX = 0,
		sourceY = 0,
		sourceWidth = 0,
		sourceHeight = 0,
	}
	
	if Graphics.getHUDType(player.character) == Graphics.HUD_ITEMBOX then 
		args.img = smb1HUD.reserveIMG
		args.x = (cam.width*0.5) - 26
		args.y = 18
		args.sourceWidth = args.img.width
		args.sourceHeight = args.img.height
		local reserveID = smb1HUD.getValue["reserve"]()
		if reserveID > 0 then  -- Handles drawing the RESERVE POWERUP a player has
			local config = NPC.config[reserveID]
			local gfxwidth = config.gfxwidth
			local gfxheight = config.gfxheight
			if gfxwidth == 0 then
				gfxwidth = config.width
			end
			if gfxheight == 0 then
				gfxheight = config.height
			end		
			Graphics.drawImageWP(
				Graphics.sprites.npc[reserveID].img, 
				(args.x + args.img.width/2) - (gfxwidth/2), 
				(args.y + args.img.height/2) - (gfxheight/2), 
				args.sourceX, 
				args.sourceY, 
				gfxwidth, 
				gfxheight, 
				1, 
				priority - 0.01
			) 
		end
	elseif Graphics.getHUDType(player.character) == Graphics.HUD_HEARTS then -- Handles getting the amount of HEARTS a player has
		local hp = smb1HUD.getValue["health"]()
		args.x = (cam.width*0.5) - 28
		args.y = 16
		args.img = smb1HUD.heartsIMG
		args.sourceWidth = args.img.width
		args.sourceHeight = args.img.height/4
		args.sourceY = args.sourceHeight * hp
	end
	
	if args.img ~= nil then
		Graphics.drawImageWP(
			args.img, 
			args.x, 
			args.y, 
			args.sourceX, 
			args.sourceY, 
			args.sourceWidth, 
			args.sourceHeight, 
			1, 
			priority - 0.02
		) 
	end
end

function smb1HUD.onInitAPI()
	Graphics.overrideHUD(smb1HUD.drawHUD)
end

return smb1HUD