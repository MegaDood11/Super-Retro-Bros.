local airshipScroll = require("AI/airshipScroll")
local autoscrollDX = require("AI/autoscrollDX")

autoscrollDX.scrollRight(1)

airshipScroll.sections = {0} --What sections the effect should be applied to. Note that this is a table.
airshipScroll.intensity = .01 --What speed should the effect should scroll at.
airshipScroll.movementLimit = 0.8 --How long should the effect should scroll for.
airshipScroll.movingLayer = "shipWater" --Whatever layer is here will scroll up and down with the screen, allowing you to have stuff like the water in SMB3's World 8-Ship.