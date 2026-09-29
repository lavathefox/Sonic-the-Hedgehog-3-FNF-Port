local scrspd = 0.9
local twnspd = 1
local sprint = true

local timerfake = false
local begin = true
local forthelowends = false
local nohud = false
local badending = false

local healthX = 140
local healthY = 628

local deadStarted = false

local digitScale = 3
local digitSpacing = 8 * digitScale

local letterScale = 3
local letterSpacing = 8 * letterScale

function clearDigits(tag)

	for i = 1, 20 do
		removeLuaSprite(tag .. i, true)
	end

	removeLuaSprite(tag, true)
end

function setNumber(tag, value, x, y, align)

	clearDigits(tag)

	local str = tostring(value)
	local len = string.len(str)

	local totalWidth = len * digitSpacing
	local startX = x

	if align == 'center' then
	    startX = x - totalWidth / 2
	elseif align == 'right' then
	    startX = x - totalWidth + 5
	end

	for i = 1, len do

		local char = string.sub(str, i, i)
		local name = tag .. i

		local spritePath = ''

		if char == ':' then
			spritePath = 'hud/numbers/colon3'
		else
			spritePath = 'hud/numbers/' .. char
		end

		makeLuaSprite(name, spritePath, startX + ((i - 1) * digitSpacing), y)

		setScrollFactor(name, 0, 0)
		setObjectCamera(name, 'hud')

		setProperty(name .. '.antialiasing', false)

		scaleObject(name, digitScale, digitScale)

		addLuaSprite(name, true)
	end
end

function setHealthNumber(tag, value, x, y)

	clearDigits(tag)

	local str = tostring(value)
	local len = string.len(str)

	for i = 1, len do

		local char = string.sub(str, i, i)
		local name = tag .. i

		makeLuaSprite(name, 'hud/lifenumbers/' .. char, x + ((i - 1) * digitSpacing), y)

		setScrollFactor(name, 0, 0)
		setObjectCamera(name, 'hud')

		setProperty(name .. '.antialiasing', false)

		scaleObject(name, digitScale, digitScale)

		addLuaSprite(name, true)
	end
end

function setLetters(tag, text, x, y)

	clearDigits(tag)

	text = string.upper(text)

	for i = 1, #text do

		local char = text:sub(i, i)

		if char ~= " " then

			local spritePath = 'hud/letershud/' .. char

			local name = tag .. i

			makeLuaSprite(name, spritePath, x + ((i - 1) * letterSpacing), y)

			setScrollFactor(name, 0, 0)
			setObjectCamera(name, 'hud')

			setProperty(name .. '.antialiasing', false)

			scaleObject(name, letterScale, letterScale)

			addLuaSprite(name, true)
		end
	end
end

function onCreate()

	setProperty('scoreTxt.alpha', 0)
	setProperty('botplayTxt.visible', false)

	setProperty('healthBar.alpha', 0)
	setProperty('healthBarBG.alpha', 0)

	setProperty('showRating', false)
	setProperty('showComboNum', false)

	setProperty('iconP1.alpha', 0)
	setProperty('iconP2.alpha', 0)

	setProperty('timeBar.visible', false)
	setProperty('timeTxt.visible', false)

	makeLuaSprite('score', 'hud/score', 51, 23)
	setScrollFactor('score', 0, 0)
	setObjectCamera('score', 'hud')
	setProperty('score.antialiasing', false)
	scaleObject('score', 3, 3)
	addLuaSprite('score', true)
	setProperty('score.alpha', 1)

	makeLuaSprite('time', 'hud/time', 51, 74)
	setObjectCamera('time', 'hud')
	setProperty('time.antialiasing', false)
	scaleObject('time', 3, 3)
	addLuaSprite('time', false)
	setProperty('time.alpha', 1)

	makeLuaSprite('time2', 'hud/time2', 60, 97)
	setScrollFactor('time2', 0, 0)
	setObjectCamera('time2', 'hud')
	setProperty('time2.antialiasing', false)
	scaleObject('time2', 3, 3)
	addLuaSprite('time2', false)
	setProperty('time2.alpha', 0)
	setProperty('time2.visible', false)

	makeLuaSprite('misses', 'hud/misses', 51, 123)
	setObjectCamera('misses', 'hud')
	setProperty('misses.antialiasing', false)
	scaleObject('misses', 3, 3)
	addLuaSprite('misses', true)
	setProperty('misses.alpha', 0)

	makeLuaSprite('misses2', 'hud/misses2', 60, 150)
	setScrollFactor('misses2', 0, 0)
	setObjectCamera('misses2', 'hud')
	setProperty('misses2.antialiasing', false)
	scaleObject('misses2', 3, 3)
	addLuaSprite('misses2', true)
	setProperty('misses2.alpha', 0)

	makeLuaSprite('hudlife', 'hud/bf_hud-life', 48, 600)
	setScrollFactor('hudlife', 0, 0)
	setObjectCamera('hudlife', 'hud')
	setProperty('hudlife.antialiasing', false)
	scaleObject('hudlife', 3, 3)
	addLuaSprite('hudlife', true)
end

function onUpdate(elapsed)

	setProperty('time2.alpha', getProperty('misses2.alpha'))

	if curStep == 1 then

		doTweenAlpha('scoreFade', 'score', 1, 0.7, 'linear')
		doTweenAlpha('timeFade', 'time', 1, 0.7, 'linear')
		doTweenAlpha('missFade', 'misses', 1, 0.7, 'linear')
		doTweenAlpha('lifeFade', 'hudlife', 1, 0.7, 'linear')
	end

	local hp = math.floor(getProperty('health') * 50)

	if hp < 0 then
		hp = 0
	end

	if hp > 99 then
		hp = 99
	end

	setHealthNumber('hudhealth', hp, healthX, healthY)

	local m = getProperty('songMisses')

	if m > 99 then
		m = 99
	end

	setNumber('sonicmisses', m, 222, 120)

	local timeStr = getTextString('timeTxt')

	setNumber('sonictime', timeStr, 169+3, 61+11, 'left')

	if not botPlay then

		clearDigits('sonicbotplay')

		local sc = getProperty('songScore')

		setNumber('sonicscore', sc, 223, 23)

	else

		clearDigits('sonicscore')

		setLetters('sonicbotplay', 'BOTPLAY', 223, 23)
	end

	if m >= 20 and badending == false then

		runTimer('blink1', 0.2)

		setProperty('misses.alpha', 0)

		badending = true
	end

	if nohud == true and curStep >= 128 then

		setProperty('misses.visible', false)
		setProperty('misses2.visible', false)

		setProperty('time.visible', false)
		setProperty('time2.visible', false)

		setProperty('score.visible', false)

		setProperty('hudlife.visible', false)

	else

		setProperty('misses.visible', true)
		setProperty('misses2.visible', true)

		setProperty('time.visible', true)
		setProperty('score.visible', true)

		setProperty('hudlife.visible', true)
	end

	setTextString('botplayTxt', '')
end

function onGameOver()

	if deadStarted then
		return Function_Stop
	end

	deadStarted = true

	local bfX = getProperty('boyfriend.x')
	local bfY = getProperty('boyfriend.y')

	makeLuaSprite('tailsdeath', 'tailsdeath', bfX, bfY)
	setProperty('tailsdeath.antialiasing', false)
	setObjectCamera('tailsdeath', 'game')
	setObjectOrder(
		'tailsdeath',
		getObjectOrder('boyfriendGroup') + 1
	)

	addLuaSprite('tailsdeath', true)

	setProperty('boyfriend.visible', false)

	setProperty('playbackRate', 0)

	playSound('death', 1)

	setProperty('health', 0.001)

	doTweenY(
		'tailsdeathjump',
		'tailsdeath',
		getProperty('tailsdeath.y') - 110,
		0.5,
		'sineOut'
	)

	return Function_Stop
end

function onTweenCompleted(tag)

	if tag == 'tailsdeathjump' then

		doTweenY(
			'tailsdeathfall',
			'tailsdeath',
			getProperty('tailsdeath.y') + 1700,
			2.75,
			'sineIn'
		)

		makeLuaSprite('blackdeath', '', 0, 0)
		makeGraphic('blackdeath', 1280, 720, '000000')
		setObjectCamera('blackdeath', 'other')
		addLuaSprite('blackdeath', true)
		setProperty('blackdeath.alpha', 0)

		doTweenAlpha(
			'blackdeathFade',
			'blackdeath',
			1,
			1,
			'linear'
		)
	end

	if tag == 'blackdeathFade' then
		restartSong(false)
	end
end
