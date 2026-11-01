local function pref(name)
	local v = getPropertyFromClass('backend.ClientPrefs', 'data.' .. name)
	if v == nil or v == '' then return nil end
	return tostring(v)
end

if pref('sonicTitleCardStyle') ~= 'SONIC CD' then return end

local speeds = {SLOW = 1.5, NORMAL = 1, FAST = 0.65}
local speed = speeds[pref('sonicTitleCardSpeed') or 'NORMAL'] or 1

local title1, title2 = 'Too', 'Slow'
local title1X, title2X = 389, 389
local bigScale1, bigScale2, smallScale = 3.1, 3.2, 3.1
local smallOffset1, smallOffset2 = 100, 6
local letterFolder = 'titlecardleters/soniccd/'

local hide, hideY = 800, 760

local blackTag = 'sonicCDIntroBlack'
local barTag = 'sonicCDIntroBar'
local textTag = 'sonicCDIntroText'

local started = false
local widths = {}
local letters1, letters2 = {}, {}

local function t(seconds)
	return seconds * speed
end

local function letterWidth(path, scale)
	local key = path .. scale

	if widths[key] == nil then
		makeLuaSprite('sonicCDTempLetter', path, 0, 0)
		scaleObject('sonicCDTempLetter', scale, scale)
		widths[key] = getProperty('sonicCDTempLetter.width')
		removeLuaSprite('sonicCDTempLetter', true)
	end

	return widths[key]
end

local function hudSprite(name, scale, front)
	setObjectCamera(name, 'hud')
	setProperty(name .. '.antialiasing', false)
	scaleObject(name, scale, scale)
	addLuaSprite(name, front)
end

local function drawTitle(tag, text, x, y, smallOffset, bigScale)
	local names = {}
	local offset = 0

	text = string.upper(text)

	for i = 1, #text do
		local char = text:sub(i, i)

		if char ~= ' ' then
			local path = letterFolder .. char
			local scale = bigScale
			local letterY = y

			if i > 1 then
				path = letterFolder .. 'smallleters/' .. char
				scale = smallScale
				letterY = y + smallOffset
			end

			local name = tag .. (#names + 1)

			makeLuaSprite(name, path, x + offset + hide, letterY)
			hudSprite(name, scale, true)

			names[#names + 1] = name
			offset = offset + letterWidth(path, scale)
		end
	end

	return names
end

local function moveLetters(names, amount, prefix)
	for i, name in ipairs(names) do
		doTweenX(prefix .. i, name, getProperty(name .. '.x') + amount, t(0.4), 'linear')
	end
end

local function removeLetters(names)
	for _, name in ipairs(names) do
		removeLuaSprite(name, true)
	end
end

local function startIntro()
	if started then return end
	started = true

	local textY = downscroll and 123 or 199
	local text2Y = 372

	makeLuaSprite(blackTag, nil, 0, 0)
	makeGraphic(blackTag, screenWidth * 2, screenHeight * 2, '000000')
	setObjectCamera(blackTag, 'hud')
	setScrollFactor(blackTag, 0, 0)
	addLuaSprite(blackTag, true)

	makeLuaSprite(barTag, 'titlecard/sonicCD/intro2', 353, -hide)
	makeLuaSprite(textTag, 'titlecard/sonicCD/intro1withoutleters', 401 + hide, textY)
	hudSprite(barTag, 3.1, true)
	hudSprite(textTag, 3.1, true)

	letters1 = drawTitle('sonicCDTitle1', title1, title1X, textY, smallOffset1, bigScale1)
	letters2 = drawTitle('sonicCDTitle2', title2, title2X, text2Y, smallOffset2, bigScale2)

	doTweenAlpha('sonicCDBlackFade', blackTag, 0, t(0.5), 'linear')
end

local function cleanup()
	removeLetters(letters1)
	removeLetters(letters2)
	letters1, letters2 = {}, {}

	removeLuaSprite(blackTag, true)
	removeLuaSprite(barTag, true)
	removeLuaSprite(textTag, true)
end

function onCreatePost()
	startIntro()
end

function onTweenCompleted(tag)
	if tag ~= 'sonicCDBlackFade' then return end

	doTweenY('sonicCDBarIn', barTag, getProperty(barTag .. '.y') + hideY, t(0.4), 'linear')

	runTimer('sonicCDTextIn', t(0.1))
	runTimer('sonicCDTitleIn', t(0.1))
	runTimer('sonicCDTextOut', t(2.2))
	runTimer('sonicCDTitleOut', t(2.2))
	runTimer('sonicCDBarOut', t(2.3))
	runTimer('sonicCDCleanup', t(2.9))
end

function onTimerCompleted(tag)
	if tag == 'sonicCDTextIn' then
		doTweenX('sonicCDTextInTween', textTag, getProperty(textTag .. '.x') - hide, t(0.4), 'linear')
	elseif tag == 'sonicCDTextOut' then
		doTweenX('sonicCDTextOutTween', textTag, getProperty(textTag .. '.x') + hide, t(0.4), 'linear')
	elseif tag == 'sonicCDBarOut' then
		doTweenY('sonicCDBarOutTween', barTag, getProperty(barTag .. '.y') - hide, t(0.4), 'linear')
	elseif tag == 'sonicCDTitleIn' then
		moveLetters(letters1, -hide, 'sonicCDTitle1In')
		moveLetters(letters2, -hide, 'sonicCDTitle2In')
	elseif tag == 'sonicCDTitleOut' then
		moveLetters(letters1, hide, 'sonicCDTitle1Out')
		moveLetters(letters2, hide, 'sonicCDTitle2Out')
	elseif tag == 'sonicCDCleanup' then
		cleanup()
	end
end
