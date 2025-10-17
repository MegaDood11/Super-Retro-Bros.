local smb1HUD = require("smb1HUD")
local textplus = require("textplus")

smb1HUD.currentWorld = vector("TEST", "HUB")

local levelList = {}

local enabled = false
local confirm = false
local select = 1
local select2 = 0
local letsago = false
local timer = 0

function onStart()
	-- Thanks KBM-Quine for helping me figure this out

	for i, l in ipairs(Misc.listFiles(Misc.episodePath())) do
		if string.match(l, ".lvlx", 0) then
			table.insert(levelList, l)
		end
	end
end

function onDraw()
	--for i = #levelList, 1, -1 do
		--Text.print(levelList[i], 0, 16 * (i - 1))
	--end

	if select <= 0 then
		select = #levelList
	elseif select > #levelList then
		select = 1
	end

	select2 = math.clamp(select2, 0, 1)

	if enabled then
		Graphics.drawScreen{priority = 6, color = Color.black .. 0.85}

		if letsago then
			timer = timer + 1
			
			if timer >= 100 then
				Misc.unpause()
				Level.load(levelList[select])
			end

			Graphics.drawScreen{priority = 8, color = Color.black .. (timer / 100)}

    			textplus.print{
        			x = camera.x + (camera.width * 0.5),
        			y = camera.y + (camera.height * 0.5),
        			text = "Let's-a-go!",
				pivot = vector(0.5, 0.5),
				sceneCoords = true,
				priority = 7,
				smooth = false,
				xscale = 5,
				yscale = 5
    			}
		else

    			textplus.print{
        			x = camera.x + (camera.width * 0.5),
        			y = camera.y + (camera.height * 0.2),
        			text = "LEVEL SELECT:",
				pivot = vector(0.5, 0.5),
				sceneCoords = true,
				priority = 7,
				smooth = false,
				xscale = 4,
				yscale = 4
    			}

    			textplus.print{
        			x = camera.x + (camera.width * 0.5),
        			y = camera.y + (camera.height * 0.35),
        			text = levelList[select],
				pivot = vector(0.5, 0.5),
				sceneCoords = true,
				priority = 7,
				color = ((confirm and Color.yellow) or Color.white),
				smooth = false,
				xscale = 2,
				yscale = 2
    			}

			if confirm then
    				textplus.print{
        				x = camera.x + (camera.width * 0.5),
        				y = camera.y + (camera.height * 0.5),
        				text = "Are you sure?",
					pivot = vector(0.5, 0.5),
					sceneCoords = true,
					priority = 7,
					smooth = false,
					xscale = 2,
					yscale = 2
    				}

    				textplus.print{
        				x = camera.x + (camera.width * 0.35),
        				y = camera.y + (camera.height * 0.65),
        				text = "Yes",
					pivot = vector(0.5, 0.5),
					sceneCoords = true,
					priority = 7,
					color = ((select2 == 1 and Color.yellow) or Color.white),
					smooth = false,
					xscale = 2,
					yscale = 2
    				}

    				textplus.print{
        				x = camera.x + (camera.width * 0.65),
        				y = camera.y + (camera.height * 0.65),
        				text = "No",
					pivot = vector(0.5, 0.5),
					sceneCoords = true,
					priority = 7,
					color = ((select2 == 0 and Color.yellow) or Color.white),
					smooth = false,
					xscale = 2,
					yscale = 2
    				}
			end
		end
	end
end

function onInputUpdate()
	if not enabled then return end
	if letsago then return end

	if player.rawKeys.run == KEYS_PRESSED then
		enabled = false
		confirm = false
		SFX.play(30)
		Misc.unpause()
	end

	if player.rawKeys.left == KEYS_PRESSED then
		SFX.play(71)
		if confirm then
			select2 = select2 + 1
		else
			select = select - 1
		end
	elseif player.rawKeys.right == KEYS_PRESSED then
		SFX.play(71)
		if confirm then
			select2 = select2 - 1
		else
			select = select + 1
		end
	end

	if player.rawKeys.jump == KEYS_PRESSED then
		if confirm then
			if select2 == 1 then
				letsago = true
				Audio.MusicChange(player.section, 0)
				SFX.play(28)
			elseif select2 == 0 then
				confirm = false
			end
		else
			confirm = true
			select2 = 0
			SFX.play(47)
		end
	end
end

function onEvent(e)
	if enabled then return end

	if e == "select" then
		enabled = true
		confirm = false
		SFX.play(30)
		Misc.pause()
	end
end