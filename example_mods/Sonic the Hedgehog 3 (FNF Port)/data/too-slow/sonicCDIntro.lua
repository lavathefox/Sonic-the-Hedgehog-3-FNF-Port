local titleCardStyle = getPropertyFromClass('backend.ClientPrefs', 'data.sonicTitleCardStyle')

if titleCardStyle == nil or titleCardStyle == '' then
	titleCardStyle = 'DEFAULT'
end

local titleCardEnabled = titleCardStyle == 'SONIC CD'

local introBarTag = 'sonicCDIntroBar'
local introTextTag = 'sonicCDIntroText'
local blackTag = 'sonicCDIntroBlack'

local title1Tag = 'sonicCDTitle1'
local title2Tag = 'sonicCDTitle2'

local title1 = 'Too'
local title2 = 'Slow'

local hide = 800
local hideY = 760
local introStarted = false

local letterScale = 3.1
local letter2Scale = 3.2
local smallLetterScale = 3.1

local title1SmallLetterY = 100
local title2SmallLetterY = 6

local title1X = 389
local title2X = 389

function clearLetters(tag)
	if not titleCardEnabled then
		return
	end

	for i = 1, 50 do
		removeLuaSprite(tag .. i, true)
	end
end

function getLetterWidth(path, scale)
	if not titleCardEnabled then
		return 0
	end

	local temp = 'sonicCDTempLetter'

	makeLuaSprite(temp, path, 0, 0)
	scaleObject(temp, scale, scale)

	local width = getProperty(temp .. '.width')
	removeLuaSprite(temp, true)

	return width
end

function drawTitle(tag, text, x, y, smallLetterY, firstLetterScale)
	if not titleCardEnabled then
		return
	end

	clearLetters(tag)

	text = string.upper(text)

	local offsetX = 0
	local index = 1

	for i = 1, #text do
		local char = text:sub(i, i)

		if char ~= ' ' then
			local path
			local scale
			local letterY = y

			if i == 1 then
				path = 'titlecardleters/soniccd/' .. char
				scale = firstLetterScale
			else
				path = 'titlecardleters/soniccd/smallleters/' .. char
				scale = smallLetterScale
				letterY = y + smallLetterY
			end

			local name = tag .. index
			local width = getLetterWidth(path, scale)

			makeLuaSprite(name, path, x + offsetX, letterY)
			setObjectCamera(name, 'hud')
			setProperty(name .. '.scrollFactor.x', 1)
			setProperty(name .. '.scrollFactor.y', 1)
			setProperty(name .. '.antialiasing', false)
			scaleObject(name, scale, scale)
			addLuaSprite(name, true)

			offsetX = offsetX + width
			index = index + 1
		end
	end

	return offsetX
end

function moveTitle(tag, amount, duration, tweenPrefix)
	if not titleCardEnabled then
		return
	end

	for i = 1, 50 do
		local name = tag .. i

		if luaSpriteExists(name) then
			doTweenX(tweenPrefix .. i, name, getProperty(name .. '.x') + amount, duration, 'linear')
		end
	end
end

function onCreatePost()
	if not titleCardEnabled then
		return
	end

	sonicIntro()
end

function sonicIntro()
	if not titleCardEnabled then
		return
	end

	if introStarted then
		return
	end

	introStarted = true

	makeLuaSprite(blackTag, nil, 0, 0)
	makeGraphic(blackTag, screenWidth * 2, screenHeight * 2, '000000')
	setObjectCamera(blackTag, 'hud')
	setProperty(blackTag .. '.scrollFactor.x', 0)
	setProperty(blackTag .. '.scrollFactor.y', 0)
	setProperty(blackTag .. '.alpha', 1)
	addLuaSprite(blackTag, true)

	local textY = 199
	local text2Y = 372

	if downscroll then
		textY = 123
	end

	makeLuaSprite(introBarTag, 'titlecard/sonicCD/intro2', 353, 0)
	makeLuaSprite(introTextTag, 'titlecard/sonicCD/intro1withoutleters', 401, textY)

	setObjectCamera(introBarTag, 'hud')
	setObjectCamera(introTextTag, 'hud')

	scaleObject(introBarTag, 3.1, 3.1)
	scaleObject(introTextTag, 3.1, 3.1)

	setProperty(introBarTag .. '.scrollFactor.x', 1)
	setProperty(introBarTag .. '.scrollFactor.y', 1)
	setProperty(introTextTag .. '.scrollFactor.x', 1)
	setProperty(introTextTag .. '.scrollFactor.y', 1)

	setProperty(introBarTag .. '.antialiasing', false)
	setProperty(introTextTag .. '.antialiasing', false)

	addLuaSprite(introBarTag, true)
	addLuaSprite(introTextTag, true)

	drawTitle(title1Tag, title1, title1X, textY, title1SmallLetterY, letterScale)
	drawTitle(title2Tag, title2, title2X, text2Y, title2SmallLetterY, letter2Scale)

	setProperty(introBarTag .. '.y', getProperty(introBarTag .. '.y') - hide)
	setProperty(introTextTag .. '.x', getProperty(introTextTag .. '.x') + hide)

	for i = 1, 50 do
		local title1Sprite = title1Tag .. i
		local title2Sprite = title2Tag .. i

		if luaSpriteExists(title1Sprite) then
			setProperty(title1Sprite .. '.x', getProperty(title1Sprite .. '.x') + hide)
		end

		if luaSpriteExists(title2Sprite) then
			setProperty(title2Sprite .. '.x', getProperty(title2Sprite .. '.x') + hide)
		end
	end

	doTweenAlpha('sonicCDBlackFade', blackTag, 0, 0.5, 'linear')
end

function onTweenCompleted(tag)
	if not titleCardEnabled then
		return
	end

	if tag == 'sonicCDBlackFade' then
		doTweenY('sonicCDBarIn', introBarTag, getProperty(introBarTag .. '.y') + hideY, 0.4, 'linear')
		runTimer('sonicCDTextIn', 0.1)
		runTimer('sonicCDTextOut', 2.2)
		runTimer('sonicCDBarOut', 2.3)
		runTimer('sonicCDTitleIn', 0.1)
		runTimer('sonicCDTitleOut', 2.2)
	end
end

function onTimerCompleted(tag)
	if not titleCardEnabled then
		return
	end

	if tag == 'sonicCDTextIn' then
		doTweenX('sonicCDTextInTween', introTextTag, getProperty(introTextTag .. '.x') - hide, 0.4, 'linear')

	elseif tag == 'sonicCDTextOut' then
		doTweenX('sonicCDTextOutTween', introTextTag, getProperty(introTextTag .. '.x') + hide, 0.4, 'linear')

	elseif tag == 'sonicCDBarOut' then
		doTweenY('sonicCDBarOutTween', introBarTag, getProperty(introBarTag .. '.y') - hide, 0.4, 'linear')

	elseif tag == 'sonicCDTitleIn' then
		moveTitle(title1Tag, -hide, 0.4, 'sonicCDTitle1In')
		moveTitle(title2Tag, -hide, 0.4, 'sonicCDTitle2In')

	elseif tag == 'sonicCDTitleOut' then
		moveTitle(title1Tag, hide, 0.4, 'sonicCDTitle1Out')
		moveTitle(title2Tag, hide, 0.4, 'sonicCDTitle2Out')
	end
end
