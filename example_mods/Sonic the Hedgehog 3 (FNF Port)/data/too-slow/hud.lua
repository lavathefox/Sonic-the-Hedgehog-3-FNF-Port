local startLives = 3
local maxLives = 99
local livesFile = 'lives.dat'
local practiceKeepsLives = true
local livesInsteadOfHealth = true
local gameOverState = 'states.DataSelectState'

local goSound = 'sonicGameOver'
local goSoundLength = 0
local effectsAt = 2
local staticSound = 'exeStatic'
local laughSound = 'exeLaugh'
local pitchDropTime = 3
local endDelay = 1.7

local scoreCountUp = true
local popups = true
local holdScore = true
local holdPerSecond = 250
local holdGrace = 0.1
local ratingScores = {sick = 350, good = 200, bad = 100, shit = 50}

local blinkAt = 20
local debugMode = false

local folders = {
	['DEFAULT'] = 'hud/',
	['SONIC 1/CD'] = 'hud/sonic1/',
	['SONIC 2'] = 'hud/sonic2/'
}

local overrides = {
	['DEFAULT'] = {},
	['SONIC 1/CD'] = {},
	['SONIC 2'] = {}
}

local pos = {
	score = {51, 23}, time = {51, 74}, time2 = {60, 97},
	misses = {51, 123}, misses2 = {60, 150}, life = {48, 600},
	scoreNum = {220, 23}, timeNum = {172, 72},
	missNum = {220, 120}, lifeNum = {140, 628}
}

local folder = 'hud/'
local cdTime, showScore, showLives, ringBlink = false, true, true, true

local lives = startLives
local dead, goPending, goStarted, effects = false, false, false, false
local goLength, goClock, tries = 0, 0, 0
local frozenAt = nil
local pitchOn, pitchTime = false, 0

local shownScore, popupId = 0, 0
local pending = {}
local holdTimer, holdAccum, holdTotal, lastBase = 0, 0, 0, 0

local introDone, blinking, blinkOn = false, false, true
local drawn = {}
local exists = {}

local function log(text)
	if debugMode then debugPrint(text) end
end

local function pref(name, default)
	local v = getPropertyFromClass('backend.ClientPrefs', 'data.' .. name)
	if v == nil or v == '' then return default end
	return v
end

local function loadPrefs()
	local name = string.upper(tostring(pref('sonicHUDStyle', 'DEFAULT')))
	if folders[name] == nil then name = 'DEFAULT' end

	folder = folders[name]
	for k, v in pairs(overrides[name]) do pos[k] = v end

	cdTime = tostring(pref('sonicTimeFormat', 'MM:SS')) == 'MM:SS:MS'
	showScore = pref('sonicShowScore', true) ~= false
	showLives = pref('sonicShowLives', true) ~= false
	ringBlink = pref('sonicRingBlink', true) ~= false
end

local function hasImage(path)
	if exists[path] == nil then
		exists[path] = checkFileExists('images/' .. path .. '.png') == true
	end
	return exists[path]
end

local function img(name)
	if hasImage(folder .. name) then return folder .. name end
	return 'hud/' .. name
end

local function numPath(c)
	if c == ':' then return img('numbers/colon3') end
	if c == "'" then return img('numbers/point') end
	if c == '"' then
		if hasImage(folder .. 'numbers/quote') then return folder .. 'numbers/quote' end
		if hasImage('hud/numbers/quote') then return 'hud/numbers/quote' end
		return img('numbers/point')
	end
	return img('numbers/' .. c)
end

local function lifePath(c)
	return img('lifenumbers/' .. c)
end

local function letterPath(c)
	if c == ' ' then return nil end
	return img('letershud/' .. c)
end

local numFont = {scale = 3, gap = 24, path = numPath}
local lifeFont = {scale = 3, gap = 24, path = lifePath}
local letterFont = {scale = 3, gap = 24, path = letterPath, upper = true}
local popupFont = {scale = 2, gap = 16, path = numPath}

local function livesPath(write)
	if write and currentModDirectory ~= nil and currentModDirectory ~= '' then
		return currentModDirectory .. '/data/' .. livesFile
	end
	return 'data/' .. livesFile
end

local function saveLives(n)
	local ok = saveFile(livesPath(true), tostring(n))
	log('lives saved: ' .. n .. ' (' .. tostring(ok) .. ')')
end

local function loadLives()
	local text = getTextFromFile(livesPath(false))
	local n = nil

	if type(text) == 'string' then
		n = tonumber((string.gsub(text, '%s+', '')))
	end

	if n == nil or n < 1 then
		n = startLives
		saveLives(n)
	end

	return math.min(math.floor(n), maxLives)
end

local function hudSprite(tag, name, p, front, alpha)
	makeLuaSprite(tag, img(name), p[1], p[2])
	setScrollFactor(tag, 0, 0)
	setObjectCamera(tag, 'hud')
	setProperty(tag .. '.antialiasing', false)
	scaleObject(tag, 3, 3)
	addLuaSprite(tag, front)
	if alpha then setProperty(tag .. '.alpha', alpha) end
end

local function drawChars(tag, str, x, y, font)
	local names = {}
	if font.upper then str = string.upper(str) end

	for i = 1, #str do
		local path = font.path(str:sub(i, i))

		if path then
			local n = tag .. i
			makeLuaSprite(n, path, x + (i - 1) * font.gap, y)
			setScrollFactor(n, 0, 0)
			setObjectCamera(n, 'hud')
			setProperty(n .. '.antialiasing', false)
			scaleObject(n, font.scale, font.scale)
			addLuaSprite(n, true)
			names[#names + 1] = n
		end
	end

	return names
end

local function clearText(tag)
	local d = drawn[tag]
	if not d then return end
	drawn[tag] = nil
	for _, n in ipairs(d.names) do removeLuaSprite(n, true) end
end

local function setText(tag, value, p, font)
	local d = drawn[tag]
	if d and d.value == value then return end

	clearText(tag)
	drawn[tag] = {value = value, names = drawChars(tag, tostring(value), p[1], p[2], font)}
end

local function cdString()
	local t = math.max(0, getSongPosition() or 0) / 1000
	local m = math.min(math.floor(t / 60), 9)
	local s = math.floor(t % 60)
	local cs = math.floor((t - math.floor(t)) * 100)
	return string.format('%d\'%02d"%02d', m, s, cs)
end

local function popup(dir, value)
	local sx = getPropertyFromGroup('playerStrums', dir, 'x')
	local sy = getPropertyFromGroup('playerStrums', dir, 'y')
	if sx == nil or sy == nil then return end

	local sw = getPropertyFromGroup('playerStrums', dir, 'width') or 0
	local sh = getPropertyFromGroup('playerStrums', dir, 'height') or 0

	popupId = popupId + 1

	local str = tostring(value)
	local x = sx + (sw - #str * popupFont.gap) / 2
	local y = sy + sh + 10
	if downscroll then y = sy - popupFont.gap - 10 end

	for _, n in ipairs(drawChars('scpop' .. popupId .. '_', str, x, y, popupFont)) do
		setProperty(n .. '.velocity.y', -140)
		setProperty(n .. '.acceleration.y', 220)
		doTweenAlpha(n, n, 0, 0.6, 'quadIn')
	end
end

local function soundLength(tag)
	local len = runHaxeCode([[
		try {
			var s = game.modchartSounds.get(']] .. tag .. [[');
			if (s != null && s.length > 0) return s.length / 1000;
		} catch (e:Dynamic) {}

		try {
			var p = Type.resolveClass('backend.Paths');
			var snd = Reflect.callMethod(p, Reflect.field(p, 'sound'), [']] .. tag .. [[']);
			if (snd != null && snd.length > 0) return snd.length / 1000;
		} catch (e:Dynamic) {}

		return 0;
	]])

	if type(len) == 'number' then return len end
	return 0
end

local function setPitch(tag, pitch)
	if type(setSoundPitch) == 'function' then
		setSoundPitch(tag, pitch)
	else
		runHaxeCode("var s = game.modchartSounds.get('" .. tag .. "'); if (s != null) s.pitch = " .. string.format('%.4f', pitch) .. ';')
	end
end

local function freezeSong()
	frozenAt = getSongPosition()

	local r = runHaxeCode([[
		try {
			game.generatedMusic = false;
			game.canPause = false;

			if (FlxG.sound.music != null) FlxG.sound.music.pause();
			if (game.vocals != null) game.vocals.pause();
			if (game.opponentVocals != null) game.opponentVocals.pause();

			game.notes.visible = false;
			game.strumLineNotes.visible = false;
			game.grpNoteSplashes.visible = false;
			return true;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	]])

	log('freeze: ' .. tostring(r))
end

local function keepFrozen()
	if frozenAt == nil then return end

	setPropertyFromClass('backend.Conductor', 'songPosition', frozenAt)

	runHaxeCode([[
		if (FlxG.sound.music != null && FlxG.sound.music.playing) FlxG.sound.music.pause();
		if (game.vocals != null && game.vocals.playing) game.vocals.pause();
		if (game.opponentVocals != null && game.opponentVocals.playing) game.opponentVocals.pause();
	]])
end

local function openGameOverState()
	local ok = runHaxeCode([[
		var c = Type.resolveClass(']] .. gameOverState .. [[');
		if (c == null) return false;

		var b = Type.resolveClass('backend.MusicBeatState');
		var s = Type.createInstance(c, []);

		if (b != null) Reflect.callMethod(b, Reflect.field(b, 'switchState'), [s]);
		else FlxG.switchState(s);

		return true;
	]])

	if ok ~= true then
		debugPrint('could not open ' .. gameOverState .. ', using exitSong')
		exitSong()
	end
end

local function goText(tag, image, fromX, toX)
	makeLuaSprite(tag, image, fromX, 300)
	setProperty(tag .. '.antialiasing', false)
	scaleObject(tag, 3, 3)
	setObjectCamera(tag, 'other')
	addLuaSprite(tag, true)
	doTweenX(tag, tag, toX, 0.3)
end

local function startGameOver()
	if goStarted then return end
	goStarted = true

	goText('gamee', 'textgame', -280, 280)
	goText('over', 'over', 840, 280)

	playSound(goSound, 1, goSound)

	goClock, tries = 0, 0
	goLength = goSoundLength > 0 and goSoundLength or soundLength(goSound)
	log('game over started, sound = ' .. goLength .. 's')
end

local function startEffects()
	if effects then return end
	effects = true

	doTweenColor('gameeRed', 'gamee', 'FF0000', 1.2, 'linear')
	doTweenColor('overRed', 'over', 'FF0000', 1.2, 'linear')

	makeAnimatedLuaSprite('screenSTATIC', 'static', 0, 0)
	addAnimationByPrefix('screenSTATIC', 'idle', 'static', 12, true)
	objectPlayAnimation('screenSTATIC', 'idle', true)
	setObjectCamera('screenSTATIC', 'other')
	scaleObject('screenSTATIC', 7, 7)
	setProperty('screenSTATIC.alpha', 0)
	addLuaSprite('screenSTATIC', true)
	doTweenAlpha('exeStaticFade', 'screenSTATIC', 0.6, 1.5, 'linear')

	playSound(staticSound, 0, staticSound, true)
	soundFadeIn(staticSound, 1.5, 0, 1)

	pitchTime = 0
	pitchOn = true
end

local function finishPitch()
	pitchOn = false
	stopSound(goSound)
	playSound(laughSound, 1, laughSound)
	runTimer('gameOverEnd', endDelay)
	log('laugh played')
end

local function updateGameOver(elapsed)
	if not goStarted then return end

	goClock = goClock + elapsed

	if not effects then
		if goLength <= 0 and tries < 30 then
			tries = tries + 1
			goLength = soundLength(goSound)
			if goLength <= 0 and tries == 30 then
				debugPrint('could not read the length of "' .. goSound .. '", set goSoundLength')
			end
		end

		if goLength > 0 then
			local played = math.max(goClock, (getSoundTime(goSound) or 0) / 1000)
			if goLength - played <= effectsAt then startEffects() end
		end
	end

	if pitchOn then
		pitchTime = pitchTime + elapsed
		local pitch = math.max(0, 1 - pitchTime / pitchDropTime)

		if pitch <= 0.03 then
			finishPitch()
		else
			setPitch(goSound, pitch)
		end
	end
end

local function updateLife()
	if not showLives then
		clearText('soniclife')
		clearText('sonichealth')
		return
	end

	if livesInsteadOfHealth then
		setText('soniclife', lives, pos.lifeNum, lifeFont)
	else
		local hp = math.max(0, math.min(99, math.floor(getProperty('health') * 50)))
		setText('sonichealth', hp, pos.lifeNum, lifeFont)
	end
end

local function updateScore(elapsed)
	local score = getProperty('songScore')

	if scoreCountUp and holdTimer > 0 then
		shownScore = shownScore + (score - shownScore) * math.min(1, elapsed * 12)
		if math.abs(score - shownScore) < 1 then shownScore = score end
	else
		shownScore = score
	end

	if not showScore then
		clearText('sonicscore')
		clearText('sonicbotplay')
	elseif botPlay then
		clearText('sonicscore')
		setText('sonicbotplay', 'BOTPLAY', pos.scoreNum, letterFont)
	else
		clearText('sonicbotplay')
		setText('sonicscore', math.max(0, math.floor(shownScore + 0.5)), pos.scoreNum, numFont)
	end
end

function onCreate()
	lives = loadLives()
	loadPrefs()

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

	hudSprite('score', 'score', pos.score, true, 1)
	hudSprite('time', 'time', pos.time, false, 1)
	hudSprite('time2', 'time2', pos.time2, false, 0)
	hudSprite('misses', 'misses', pos.misses, true, 0)
	hudSprite('misses2', 'misses2', pos.misses2, true, 0)
	hudSprite('hudlife', 'bf_hud-life', pos.life, true)

	setProperty('time2.visible', false)
	setProperty('score.visible', showScore)
	setProperty('hudlife.visible', showLives)
end

function goodNoteHit(id, dir, noteType, sustain)
	if sustain then
		holdTimer = holdGrace
		return
	end

	if not popups or botPlay then return end

	local rating = getPropertyFromGroup('notes', id, 'rating')
	local value = type(rating) == 'string' and ratingScores[rating:lower()] or nil

	if value then
		popup(dir, value)
	else
		pending[#pending + 1] = dir
	end
end

function onUpdatePost(elapsed)
	if dead then
		keepFrozen()
		return
	end

	if holdScore and holdTimer > 0 and not botPlay then
		holdAccum = holdAccum + holdPerSecond * elapsed
		local add = math.floor(holdAccum)

		if add > 0 then
			holdAccum = holdAccum - add
			holdTotal = holdTotal + add
			addScore(add)
		end
	end

	holdTimer = math.max(0, holdTimer - elapsed)
	if holdTimer == 0 then holdAccum = 0 end

	local base = getProperty('songScore') - holdTotal
	local delta = base - lastBase
	lastBase = base

	if #pending > 0 then
		if popups and delta > 0 then
			local each = math.min(math.floor(delta / #pending), 350)

			if each > 0 then
				for _, dir in ipairs(pending) do popup(dir, each) end
			end
		end

		pending = {}
	end
end

function onUpdate(elapsed)
	updateGameOver(elapsed)

	setProperty('time2.alpha', getProperty('misses2.alpha'))

	if curStep >= 1 and not introDone then
		introDone = true
		doTweenAlpha('scoreFade', 'score', 1, 0.7, 'linear')
		doTweenAlpha('timeFade', 'time', 1, 0.7, 'linear')
		doTweenAlpha('missFade', 'misses', 1, 0.7, 'linear')
		doTweenAlpha('lifeFade', 'hudlife', 1, 0.7, 'linear')
	end

	local misses = math.min(getProperty('songMisses'), 99)

	updateLife()
	setText('sonicmisses', misses, pos.missNum, numFont)
	setText('sonictime', cdTime and cdString() or getTextString('timeTxt'), pos.timeNum, numFont)
	updateScore(elapsed)

	if ringBlink and not blinking and misses >= blinkAt then
		blinking, blinkOn = true, false
		setProperty('misses.alpha', 0)
		runTimer('blink1', 0.2, 0)
	end

	setTextString('botplayTxt', '')
end

function onGameOver()
	if dead then return Function_Stop end
	dead = true

	if not (practiceKeepsLives and practiceMode) then
		lives = lives - 1

		if lives <= 0 then
			lives = 0
			goPending = true
			saveLives(startLives)
		else
			saveLives(lives)
		end
	end

	cancelTimer('blink1')

	makeLuaSprite('tailsdeath', 'dead', getProperty('boyfriend.x'), getProperty('boyfriend.y'))
	setProperty('tailsdeath.antialiasing', false)
	setObjectCamera('tailsdeath', 'game')
	setObjectOrder('tailsdeath', getObjectOrder('boyfriendGroup') + 1)
	addLuaSprite('tailsdeath', true)

	setProperty('boyfriend.visible', false)

	freezeSong()
	playSound('death', 1)
	setProperty('health', 0.001)

	doTweenY('tailsdeathjump', 'tailsdeath', getProperty('tailsdeath.y') - 110, 0.5, 'sineOut')

	return Function_Stop
end

function onSoundFinished(tag)
	if tag == goSound and goStarted and not effects then
		startEffects()
	end
end

function onTimerCompleted(tag)
	if tag == 'gameOverEnd' then
		openGameOverState()
	elseif tag == 'blink1' and not dead then
		blinkOn = not blinkOn
		setProperty('misses.alpha', blinkOn and 1 or 0)
	end
end

function onTweenCompleted(tag)
	if tag:sub(1, 5) == 'scpop' then
		removeLuaSprite(tag, true)
	elseif tag == 'tailsdeathjump' then
		doTweenY('tailsdeathfall', 'tailsdeath', getProperty('tailsdeath.y') + 1700, 2.75, 'sineIn')

		makeLuaSprite('blackdeath', '', 0, 0)
		makeGraphic('blackdeath', screenWidth or 1280, screenHeight or 720, '000000')
		setObjectCamera('blackdeath', 'other')
		addLuaSprite('blackdeath', true)
		setProperty('blackdeath.alpha', 0)

		doTweenAlpha('blackdeathFade', 'blackdeath', 1, 1, 'linear')
	elseif tag == 'blackdeathFade' then
		if goPending then startGameOver() else restartSong(false) end
	end
end
