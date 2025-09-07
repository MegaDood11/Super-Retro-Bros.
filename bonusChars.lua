local bonusChars = {}

bonusChars.bgoID = 139

bonusChars.characterImages = {
	Graphics.loadImageResolved("bonusImages/mario.png"),
	Graphics.loadImageResolved("bonusImages/luigi.png"),
	nil,
	Graphics.loadImageResolved("bonusImages/toad.png"),
	nil, -- link
	nil, -- megaman
	Graphics.loadImageResolved("bonusImages/wario.png")
}

function bonusChars.onInitAPI()
	registerEvent(bonusChars, "onStart")
end

function bonusChars.onStart()
	Graphics.sprites.background[bonusChars.bgoID].img = bonusChars.characterImages[player.character]
end

return bonusChars