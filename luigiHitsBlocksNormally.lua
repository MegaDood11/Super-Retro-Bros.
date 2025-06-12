local luigi = {}

--Register events
function luigi.onInitAPI()
	registerEvent(luigi, "onBlockHit")
end


function luigi.onBlockHit(e, v, upper, p)
    if not p then return end


    if e.cancelled or v.contentID == 0 or v.contentID > 99 then
        return
    end

    if (p.character == 2 or p.character == 4) then
		p.data.luigiHitsBlocksNormally = 1
        local oldChar = p.character
        p.character = 1
        v:hit(upper, p)
        p.character = oldChar
		p.data.luigiHitsBlocksNormally = nil
        e.cancelled = true
    end
end

return luigi