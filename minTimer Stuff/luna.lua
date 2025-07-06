local minTimer = require("minTimer") -- load the library
local timer1 = minTimer.create{initValue = minTimer.toTicks{hrs = 0, mins = 0, secs = 5}} -- create a timer object

local canMove = true -- boolean to stop the player
local moveTimer = 0  -- timer to release the player

function onStart()  
   timer1:start()
end

function timer1:onEnd(win)                      -- function that takes place when the specific timer ends, win is true if it closes before the timer reaches 0
    if not win then                             -- check for win
        player:kill()                      -- set the boolean to stop the player
    end                                         -- close the check
end                                             -- close the function

-- this part handles player movement --
function onTick()                         -- function that runs every tick when the game isn't paused
	if player.x >= -199552 then
		timer1:close(minTimer.WIN_CLEAR, true) 
	end
end