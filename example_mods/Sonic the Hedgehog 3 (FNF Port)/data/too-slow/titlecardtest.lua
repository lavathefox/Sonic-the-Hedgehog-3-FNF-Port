local function pref(name)
	local v = getPropertyFromClass('backend.ClientPrefs', 'data.' .. name)
	if v == nil or v == '' then return nil end
	return tostring(v)
end

if (pref('sonicTitleCardStyle') or 'DEFAULT') ~= 'DEFAULT' then return end

local speeds = {SLOW = 1.5, NORMAL = 1, FAST = 0.65}
local speed = speeds[pref('sonicTitleCardSpeed') or 'NORMAL'] or 1

local titleText = 'ANGEL ISLAND'
local titleX, titleY = 1856, 330
local spawnX = 662

local scale = 3.3
local spaceWidth = 16 * scale
local offScreen = 1056
local panelHeight = 224 * scale
local letterFolder = 'titlecardleters/sonic3/'

local names = {}
local offsets = {}
local widths = {}

local function t(seconds)
	return seconds * speed
end

local function panel(tag, image, x, y, sx, sy)
	makeLuaSprite(tag, image, x, y)
	scaleObject(tag, sx or scale, sy or scale)
	setProperty(tag .. '.antialiasing', false)
	setObjectCamera(tag, 'hud')
	addLuaSprite(tag)
end

local function letterWidth(char)
	if char == ' ' then return spaceWidth end

	if widths[char] == nil then
		makeLuaSprite('tempLetter', letterFolder .. char, 0, 0)
		scaleObject('tempLetter', scale, scale)
		widths[char] = getProperty('tempLetter.width')
		removeLuaSprite('tempLetter', true)
	end

	return widths[char]
end

local function drawTitle(tag, text, y)
	text = string.upper(text)

	local total = 0
	for i = 1, #text do
		total = total + letterWidth(text:sub(i, i))
	end

	local x = 0

	for i = 1, #text do
		local char = text:sub(i, i)

		if char ~= ' ' then
			local name = tag .. (#names + 1)
			local offset = x - total / 2

			makeLuaSprite(name, letterFolder .. char, titleX + offset, y)
			setObjectCamera(name, 'hud')
			setProperty(name .. '.antialiasing', false)
			scaleObject(name, scale, scale)
			addLuaSprite(name, true)

			names[#names + 1] = name
			offsets[#offsets + 1] = offset
		end

		x = x + letterWidth(char)
	end
end

local function moveLetters(prefix, target, time)
	for i, name in ipairs(names) do
		doTweenX(prefix .. i, name, target + offsets[i], time, 'linear')
	end
end

local function cleanup()
	for _, name in ipairs(names) do
		removeLuaSprite(name, true)
	end

	names, offsets = {}, {}

	for _, tag in ipairs({'titlescreenback', 'titlescreen1', 'titlescreen3', 'titlescreen4'}) do
		removeLuaSprite(tag, true)
	end
end

function onCreate()
	panel('titlescreenback', 'fnf5', 0, 0, 3.4, 3.3)
	panel('titlescreen1', 'fnf1', 0, -panelHeight)

	drawTitle('titlescreen2', titleText, titleY)

	panel('titlescreen3', 'fnf3', offScreen, 0)
	panel('titlescreen4', 'fnf4', offScreen, 0)

	runTimer('blacktransitionthingshit', t(1))
end

function onTimerCompleted(tag)
	if tag == 'blacktransitionthingshit' then
		doTweenY('tt1', 'titlescreen1', 0, t(0.3))
		runTimer('tt2incoming', t(0.1))
	elseif tag == 'tt2incoming' then
		moveLetters('tt2_', spawnX, t(0.3))
		runTimer('tt3incoming', t(0.1))
	elseif tag == 'tt3incoming' then
		doTweenX('tt3', 'titlescreen3', 0, t(0.3))
		runTimer('tt4incoming', t(0.1))
	elseif tag == 'tt4incoming' then
		doTweenX('tt4', 'titlescreen4', 0, t(0.3))
		runTimer('blackscreenout', t(0.8))
		runTimer('out', t(2.5))
		runTimer('out1', t(2.6))
		runTimer('out2', t(2.7))
		runTimer('out3', t(2.8))
		runTimer('cleanup', t(3.1))
	elseif tag == 'blackscreenout' then
		doTweenAlpha('tt5', 'titlescreenback', 0, t(0.2))
	elseif tag == 'out' then
		doTweenY('tt1', 'titlescreen1', -panelHeight, t(0.2))
	elseif tag == 'out1' then
		moveLetters('tt2out_', titleX + offScreen, t(0.2))
	elseif tag == 'out2' then
		doTweenX('tt3', 'titlescreen3', offScreen, t(0.2))
	elseif tag == 'out3' then
		doTweenX('tt4', 'titlescreen4', offScreen, t(0.2))
	elseif tag == 'cleanup' then
		cleanup()
	end
end
