local bonusScore = 5000
local countingBonus = false
local actClearStarted = false

local textScale = 3
local textSpacing = 8 * textScale

local numberScale = 3
local numberSpacing = 8 * numberScale

local currentBonusDisplay = bonusScore

local clearedSoundLength = 3.5

function clearSprites(tag, max)
	for i = 1, max do
		removeLuaSprite(tag..i, true)
	end
end

function getBonusWidth(text)

	local total = 0
	text = string.upper(text)

	for i = 1, #text do

		local c = text:sub(i,i)

		if c ~= " " then

			local path = ''

			if c == ':' then
				path = 'hud/letershud/colon2'
			else
				path = 'hud/letershud/'..c
			end

			local temp = 'tempBonus'..i

			makeLuaSprite(temp, path, 0, 0)
			scaleObject(temp, textScale, textScale)

			total = total + getProperty(temp..'.width')

			removeLuaSprite(temp, true)

		else
			total = total + textSpacing
		end
	end

	return total
end

function drawBonusText(tag, text, x, y)

	clearSprites(tag, 200)

	text = tostring(text)
	text = string.upper(text)

	local total = getBonusWidth(text)

	local offX = 0
	local index = 1

	for i = 1, #text do

		local c = text:sub(i,i)

		if c ~= " " then

			local rel = offX - total/2

			local path = ''

			if c == ':' then
				path = 'hud/letershud/colon2'
			else
				path = 'hud/letershud/'..c
			end

			local name = tag..index

			makeLuaSprite(name, path, x + rel, y)

			setObjectCamera(name, 'other')
			setProperty(name..'.antialiasing', false)

			scaleObject(name, textScale, textScale)

			addLuaSprite(name, false)

			offX = offX + getProperty(name..'.width')

			index = index + 1

		else
			offX = offX + textSpacing
		end
	end
end

function drawBonusNumbers(tag, value, x, y)

	clearSprites(tag, 50)

	local str = tostring(value)
	local totalWidth = string.len(str) * numberSpacing

	for i = 1, #str do

		local num = str:sub(i,i)
		local posX = x - totalWidth/2 + ((i-1) * numberSpacing)

		local name = tag..i

		makeLuaSprite(name, 'hud/numbers/'..num, posX, y)

		setObjectCamera(name, 'other')
		setProperty(name..'.antialiasing', false)

		scaleObject(name, numberScale, numberScale)

		addLuaSprite(name, false)
	end
end

function onCreate()

	makeLuaSprite('blue', 'blue', -300, -300)
	setObjectCamera('blue', 'other')
	scaleObject('blue', 10, 10)
	setProperty('blue.alpha', 0)
	setBlendMode('blue', 'multiply')
	addLuaSprite('blue', true)

	makeLuaSprite('black', 'black', -50, 0)
	setObjectCamera('black', 'other')
	scaleObject('black', 6, 6)
	setProperty('black.alpha', 0)
	addLuaSprite('black', true)

	makeLuaSprite('sonichas', 'end/s3/bfgot', -960, 0)
	scaleObject('sonichas', 3, 3)
	setObjectCamera('sonichas', 'other')
	addLuaSprite('sonichas')

	makeLuaSprite('passed', 'end/s3/through', -960, 0)
	scaleObject('passed', 3, 3)
	setObjectCamera('passed', 'other')
	addLuaSprite('passed')
end

function onEndSong()

	if not actClearStarted then

		actClearStarted = true

		playSound('CLEARED STAGE', 1)

		canPause = false
		nohud = true

		setProperty('camHUD.alpha', 0)

		runTimer("startAfterSound", clearedSoundLength)
		runTimer("Cleared Zone", 0.25)

		return Function_Stop
	end

	return Function_Continue
end

function onTimerCompleted(tag)

	if tag == "Cleared Zone" then
		doTweenX('sonichas','sonichas', 60, 0.3, 'linear')
		runTimer("Cleared Zone2", 0.25)
	end

	if tag == "Cleared Zone2" then
		doTweenX('passed', 'passed', 60, 0.25, 'linear')
		runTimer("Cleared Zone3", 0.25)
	end

	if tag == "Cleared Zone3" then
		drawBonusText('bonusLabel', 'SCORE BONUS:', 340, 430)
		drawBonusNumbers('bonusValue', currentBonusDisplay, 600, 430)
	end

	if tag == "startAfterSound" then
		countingBonus = true
		playSound('scoreGaining')
	end

	if tag == "finishBonus" then
		stopSound('scoreGaining')
		playSound('scoreEARNED', 1)
		runTimer("Cleared Zone5", 3)
	end

	if tag == "Cleared Zone5" then

		doTweenAlpha('blueIn','blue',1,0.6,'sineOut')
		doTweenAlpha('blackIn','black',1,0.5,'sineOut')

		runTimer("EXIT SONG", 1.2)
	end

	if tag == "EXIT SONG" then
		endSong()
	end
end

function onUpdate(elapsed)

	if countingBonus then

		if currentBonusDisplay > 0 then

			local take = 120

			currentBonusDisplay = currentBonusDisplay - take

			if currentBonusDisplay < 0 then
				take = take + currentBonusDisplay
				currentBonusDisplay = 0
			end

			addScore(take)

			drawBonusNumbers('bonusValue', currentBonusDisplay, 600, 430)

		else
			countingBonus = false
			runTimer("finishBonus", 0.1)
		end
	end
end
