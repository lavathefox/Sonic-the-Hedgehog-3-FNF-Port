local titleCardStyle = getPropertyFromClass('backend.ClientPrefs', 'data.sonicTitleCardStyle')

if titleCardStyle == nil or titleCardStyle == '' then
	titleCardStyle = 'DEFAULT'
end

local titleCardEnabled = titleCardStyle == 'DEFAULT'

local titleText = "ANGEL ISLAND"
local titleX = 1856
local titleY = 330

local spawnX = 662

local letterScale = 3.3
local letterOffsets = {}

function clearLetters(tag)
	if not titleCardEnabled then
		return
	end

	for i = 1, 50 do
		removeLuaSprite(tag .. i, true)
	end
end

function getTextWidth(text)
	if not titleCardEnabled then
		return 0
	end

	local total = 0
	text = string.upper(text)

	for i = 1, #text do
		local char = text:sub(i,i)

		if char ~= " " then
			local temp = 'tempLetter'..i
			makeLuaSprite(temp, 'titlecardleters/sonic3/'..char, 0, 0)
			scaleObject(temp, letterScale, letterScale)

			total = total + getProperty(temp..'.width')
			removeLuaSprite(temp, true)
		else
			total = total + (16 * letterScale)
		end
	end

	return total
end

function drawTitle(tag, text, x, y)
	if not titleCardEnabled then
		return
	end

	clearLetters(tag)
	letterOffsets = {}

	text = string.upper(text)
	local totalWidth = getTextWidth(text)

	local offsetX = 0
	local index = 1

	for i = 1, #text do
		local char = text:sub(i,i)

		if char ~= " " then
			local name = tag .. index

			local relativeOffset = offsetX - totalWidth/2
			letterOffsets[index] = relativeOffset

			makeLuaSprite(name, 'titlecardleters/sonic3/'..char, titleX + relativeOffset, y)
			setObjectCamera(name, 'hud')
			setProperty(name..'.antialiasing', false)
			scaleObject(name, letterScale, letterScale)
			addLuaSprite(name, true)

			local w = getProperty(name..'.width')
			offsetX = offsetX + w
			index = index + 1
		else
			offsetX = offsetX + (16 * letterScale)
		end
	end
end

function onCreate()
	if not titleCardEnabled then
		return
	end

	makeLuaSprite('titlescreenback', 'fnf5', 0, 0)
	scaleObject('titlescreenback', 3.4, 3.3)
	setProperty('titlescreenback.antialiasing', false)
	setObjectCamera('titlescreenback', 'hud')
	addLuaSprite('titlescreenback')

	makeLuaSprite('titlescreen1', 'fnf1', 0, -224*3.3)
	scaleObject('titlescreen1', 3.3, 3.3)
	setProperty('titlescreen1.antialiasing', false)
	setObjectCamera('titlescreen1', 'hud')
	addLuaSprite('titlescreen1')

	drawTitle('titlescreen2', titleText, titleX, titleY)

	makeLuaSprite('titlescreen3', 'fnf3', 1056, 0)
	scaleObject('titlescreen3', 3.3, 3.3)
	setProperty('titlescreen3.antialiasing', false)
	setObjectCamera('titlescreen3', 'hud')
	addLuaSprite('titlescreen3')

	makeLuaSprite('titlescreen4', 'fnf4', 1056, 0)
	scaleObject('titlescreen4', 3.3, 3.3)
	setProperty('titlescreen4.antialiasing', false)
	setObjectCamera('titlescreen4', 'hud')
	addLuaSprite('titlescreen4')

	runTimer('blacktransitionthingshit', 1)
end

function onTimerCompleted(tag)
	if not titleCardEnabled then
		return
	end

	if tag == 'blacktransitionthingshit' then
		doTweenY('tt1', 'titlescreen1', 0, 0.3)
		runTimer('tt2incoming', 0.1)
	end

	if tag == 'tt2incoming' then
		for i = 1, 50 do
			if letterOffsets[i] ~= nil then
				local name = 'titlescreen2'..i
				doTweenX('tt2_'..i, name, spawnX + letterOffsets[i], 0.3)
			end
		end

		runTimer('tt3incoming', 0.1)
	end

	if tag == 'tt3incoming' then
		doTweenX('tt3', 'titlescreen3', 0, 0.3)
		runTimer('tt4incoming', 0.1)
	end

	if tag == 'tt4incoming' then
		doTweenX('tt4', 'titlescreen4', 0, 0.3)
		runTimer('out', 2.5)
		runTimer('out1', 2.6)
		runTimer('out2', 2.7)
		runTimer('out3', 2.8)
		runTimer('blackscreenout', 0.8)
	end

	if tag == 'blackscreenout' then
		doTweenAlpha('tt5', 'titlescreenback', 0, 0.2)
	end

	if tag == 'out' then
		doTweenY('tt1', 'titlescreen1', -224*3.3, 0.2)
	end

	if tag == 'out1' then
		for i = 1, 50 do
			if letterOffsets[i] ~= nil then
				local name = 'titlescreen2'..i
				doTweenX('tt2out_'..i, name, titleX + 1056 + letterOffsets[i], 0.2)
			end
		end
	end

	if tag == 'out2' then
		doTweenX('tt3', 'titlescreen3', 1056, 0.2)
	end

	if tag == 'out3' then
		doTweenX('tt4', 'titlescreen4', 1056, 0.2)
	end
end
