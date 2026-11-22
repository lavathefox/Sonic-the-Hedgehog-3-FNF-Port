local startLives = 3
local maxLives = 99
local livesFile = 'lives.dat'
local practiceKeepsLives = true
local livesInsteadOfHealth = true
local gameOverState = 'states.DataSelectState'

local extraLifeEvery = 50000
local extraLifeRings = 100
local oneUpSound = 'oneUp'

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

local ringBonus = 10
local maxRings = 999
local ringSound = 'ring'
local ringLossSound = 'ringLoss'

local ringShield = true
local ringShieldHealth = 1.0
local invincibleTime = 2.0

local blinkSpeed = 0.25
local blinkColor = 'FF0000'

local genesisPalette = true
local genesisDither = true
local paletteCams = {'camGame', 'camHUD', 'camOther'}
local shaderName = 'genesis'

local alignRight = false
local scoreDigits = 6
local ringDigits = 3

local debugMode = false

local timeLayoutFile = 'data/hud_time_layout.txt'
local timeShift = {0, 0}

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
	rings = {51, 123}, misses2 = {60, 150}, life = {48, 600},
	scoreNum = {220, 23}, timeNum = {172, 72},
	ringNum = {220, 120}, lifeNum = {140, 628}
}

local folder = 'hud/'
local cdTime, showScore, showLives, ringBlink = true, true, true, true

local timeLayout = nil

local lives = startLives
local rings = 0
local ringsLabel = false
local dead, goPending, goStarted, effects = false, false, false, false
local goLength, goClock, tries = 0, 0, 0
local frozenAt = nil
local pitchOn, pitchTime = false, 0

local shownScore, popupId = 0, 0
local pending = {}
local holdTimer, holdAccum, holdTotal, lastBase = 0, 0, 0, 0

local blinkClock, blinkRed = 0, false
local redColor, whiteColor = 0, 0
local hurtTimer, flicker = 0, true
local nextLifeScore, nextRingLife = 0, 0

local drawn = {}
local exists = {}

local songStarted, preTime = false, 0

local function log(text)
	if debugMode then debugPrint(text) end
end

local function pref(name, default)
	local v = getPropertyFromClass('backend.ClientPrefs', 'data.' .. name)
	if v == nil or v == '' then return default end
	return v
end

local function hasImage(path)
	if exists[path] == nil then
		exists[path] = checkFileExists('images/' .. path .. '.png') == true
	end
	return exists[path]
end

local function hasSound(name)
	local key = 'snd:' .. tostring(name)
	if exists[key] == nil then
		exists[key] = name ~= nil and name ~= '' and checkFileExists('sounds/' .. name .. '.ogg') == true
	end
	return exists[key]
end

local function sfx(name, volume)
	if hasSound(name) then playSound(name, volume or 1) end
end

local function loadPrefs()
	local name = string.upper(tostring(pref('sonicHUDStyle', 'DEFAULT')))
	if folders[name] == nil then name = 'DEFAULT' end

	folder = folders[name]
	for k, v in pairs(overrides[name]) do pos[k] = v end

	cdTime = tostring(pref('sonicTimeFormat', 'MM:SS:MS')) == 'MM:SS:MS'
	showScore = pref('sonicShowScore', true) ~= false
	showLives = pref('sonicShowLives', true) ~= false
	ringBlink = pref('sonicRingBlink', true) ~= false
	genesisPalette = genesisPalette and pref('sonicGenesisPalette', true) ~= false
end

local function img(name)
	if hasImage(folder .. name) then return folder .. name end
	return 'hud/' .. name
end

local function numPath(c)
	if c == ':' then return img('numbers/colon3') end
	if c == "'" then return img('numbers/point') end
	if c == '"' then
		if hasImage(folder .. 'numbers/secondpoint') then return folder .. 'numbers/secondpoint' end
		if hasImage('hud/numbers/secondpoint') then return 'hud/numbers/secondpoint' end
		if hasImage(folder .. 'numbers/quote') then return folder .. 'numbers/quote' end
		if hasImage('hud/numbers/quote') then return 'hud/numbers/quote' end
		return img('numbers/point')
	end
	return img('numbers/' .. c)
end

local function lifePath(c) return img('lifenumbers/' .. c) end

local function letterPath(c)
	if c == ' ' then return nil end
	return img('letershud/' .. c)
end

local numFont = {scale = 3, gap = 24, path = numPath}
local scoreFont = {scale = 3, gap = 24, path = numPath, field = scoreDigits}
local ringFont = {scale = 3, gap = 24, path = numPath, field = ringDigits}
local timeFont = {scale = 3, gap = 24, path = numPath}
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

local function loadTimeLayout()
	local text = getTextFromFile(timeLayoutFile)
	if type(text) ~= 'string' or text == '' then
		log('time layout not found, using the default positions')
		return
	end

	local layout = {digits = {}, points = {}}
	for kind, x, y in string.gmatch(text, '(%a+),(%-?[%d%.]+),(%-?[%d%.]+)') do
		local p = {tonumber(x), tonumber(y)}
		if kind == 'digit' then
			layout.digits[#layout.digits + 1] = p
		elseif kind == 'point' then
			layout.points[1] = p
		elseif kind == 'secondpoint' then
			layout.points[2] = p
		end
	end

	if #layout.digits < 5 or #layout.points < 2 then
		debugPrint('[HUD] ' .. timeLayoutFile .. ' needs at least 5 digit slots and 2 points (found ' ..
			#layout.digits .. ' and ' .. #layout.points .. '), using the default positions')
		return
	end

	timeLayout = layout
	log('time layout loaded: ' .. #layout.digits .. ' digits')
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

local function charSprite(n, path, x, y, scale)
	makeLuaSprite(n, path, x, y)
	setScrollFactor(n, 0, 0)
	setObjectCamera(n, 'hud')
	setProperty(n .. '.antialiasing', false)
	scaleObject(n, scale, scale)
	addLuaSprite(n, true)
end

local function drawChars(tag, str, x, y, font)
	local names = {}
	if font.upper then str = string.upper(str) end

	for i = 1, #str do
		local path = font.path(str:sub(i, i))
		if path then
			local n = tag .. i
			charSprite(n, path, x + (i - 1) * font.gap, y, font.scale)
			names[#names + 1] = n
		end
	end

	return names
end

local function render(tag, value, items, scale)
	local d = drawn[tag]
	if not d then
		d = {sprites = {}, paths = {}, xs = {}, ys = {}, vis = {}, count = 0}
		drawn[tag] = d
	end
	d.value = value

	for i = 1, #items do
		local it = items[i]
		local n = tag .. i

		if it.path then
			if not d.sprites[i] then
				charSprite(n, it.path, it.x, it.y, scale)
				d.sprites[i], d.paths[i], d.xs[i], d.ys[i], d.vis[i] = true, it.path, it.x, it.y, true
				if i > d.count then d.count = i end
			else
				if d.paths[i] ~= it.path then
					loadGraphic(n, it.path)
					scaleObject(n, scale, scale)
					d.paths[i] = it.path
				end
				if d.xs[i] ~= it.x then setProperty(n .. '.x', it.x) d.xs[i] = it.x end
				if d.ys[i] ~= it.y then setProperty(n .. '.y', it.y) d.ys[i] = it.y end
				if not d.vis[i] then setProperty(n .. '.visible', true) d.vis[i] = true end
			end
		elseif d.sprites[i] and d.vis[i] then
			setProperty(n .. '.visible', false)
			d.vis[i] = false
		end
	end

	for i = #items + 1, d.count do
		if d.sprites[i] and d.vis[i] then
			setProperty(tag .. i .. '.visible', false)
			d.vis[i] = false
		end
	end
end

local function clearText(tag)
	local d = drawn[tag]
	if not d or d.value == nil then return end
	d.value = nil
	for i = 1, d.count do
		if d.sprites[i] and d.vis[i] then
			setProperty(tag .. i .. '.visible', false)
			d.vis[i] = false
		end
	end
end

local function plainItems(str, p, font)
	local items = {}
	local offset = 0

	if alignRight and font.field and #str < font.field then
		offset = (font.field - #str) * font.gap
	end

	for i = 1, #str do
		items[i] = {
			path = font.path(str:sub(i, i)) or false,
			x = p[1] + offset + (i - 1) * font.gap,
			y = p[2]
		}
	end

	return items
end

local function setText(tag, value, p, font)
	local str = tostring(value)
	if font.upper then str = string.upper(str) end

	local d = drawn[tag]
	if d and d.value == str then return end

	render(tag, str, plainItems(str, p, font), font.scale)
end

local function timeSlotItems(str)
	local items = {}
	local digitIndex = 0
	local ox, oy = pos.time[1] + timeShift[1], pos.time[2] + timeShift[2]

	for i = 1, #str do
		local c = str:sub(i, i)
		local slot

		if c == "'" then
			slot = timeLayout.points[1]
		elseif c == '"' then
			slot = timeLayout.points[2]
		else
			digitIndex = digitIndex + 1
			slot = timeLayout.digits[digitIndex]
		end

		if slot then
			items[i] = {path = numPath(c), x = ox + slot[1], y = oy + slot[2]}
		else
			items[i] = {path = false, x = 0, y = 0}
		end
	end

	return items
end

local function setTimeText(value)
	local d = drawn['sonictime']
	if d and d.value == value then return end

	if cdTime and timeLayout then
		render('sonictime', value, timeSlotItems(value), timeFont.scale)
	else
		render('sonictime', value, plainItems(value, pos.timeNum, timeFont), timeFont.scale)
	end
end

local function elapsedSeconds()
	if songStarted then
		return math.max(0, getSongPosition() or 0) / 1000
	end
	return preTime
end

local function timeString()
	local t = elapsedSeconds()
	local m = math.floor(t / 60)
	local s = math.floor(t % 60)

	if cdTime then
		local cs = math.floor((t - math.floor(t)) * 100)
		local minuteDigits = timeLayout and math.max(1, #timeLayout.digits - 4) or 1
		m = math.min(m, 10 ^ minuteDigits - 1)
		return string.format('%0' .. minuteDigits .. 'd\'%02d"%02d', m, s, cs)
	end

	return string.format('%d:%02d', m, s)
end

local function genesisFragment()
	return table.concat({
		'#pragma header',
		'void main() {',
		'	vec4 c = flixel_texture2D(bitmap, openfl_TextureCoordv);',
		'	float b = mod(floor(mod(gl_FragCoord.x, 2.0)) * 2.0 + floor(mod(gl_FragCoord.y, 2.0)) * 3.0, 4.0);',
		'	float d = ' .. (genesisDither and '(b / 4.0 - 0.375) * 0.5' or '0.0') .. ';',
		'	vec3 q = floor(c.rgb * 7.0 + 0.5 + d) / 7.0;',
		'	gl_FragColor = vec4(clamp(q, 0.0, 1.0), c.a);',
		'}'
	}, '\n')
end

local function applyPalette()
	if not genesisPalette then return end

	local path = 'shaders/' .. shaderName .. '.frag'
	if not checkFileExists(path) then
		local target = path
		if currentModDirectory ~= nil and currentModDirectory ~= '' then
			target = currentModDirectory .. '/' .. path
		end
		saveFile(target, genesisFragment())
		exists = {}
		log('shader written to ' .. target)
	end

	local names = '["' .. table.concat(paletteCams, '","') .. '"]'
	local r = runHaxeCode([[
		try {
			var sf = Type.resolveClass('openfl.filters.ShaderFilter');
			var names = ]] .. names .. [[;

			for (n in names) {
				var cam = Reflect.getProperty(game, n);
				var sh = game.createRuntimeShader(']] .. shaderName .. [[');
				if (cam != null && sh != null) cam.setFilters([Type.createInstance(sf, [sh])]);
			}
			return true;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	]])

	log('palette: ' .. tostring(r))
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

local function giveLife()
	if lives >= maxLives then return end
	lives = lives + 1
	saveLives(lives)
	sfx(oneUpSound, 1)
end

local function addRings(amount)
	if amount <= 0 then return end
	local before = rings
	rings = math.min(rings + amount, maxRings)

	if extraLifeRings > 0 then
		while rings >= nextRingLife and before < nextRingLife do
			if not practiceMode then giveLife() end
			nextRingLife = nextRingLife + extraLifeRings
		end
	end
end

local function checkScoreLife(score)
	if extraLifeEvery <= 0 or botPlay or practiceMode then return end

	while score >= nextLifeScore do
		giveLife()
		nextLifeScore = nextLifeScore + extraLifeEvery
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
		setText('sonicscore', math.max(0, math.floor(shownScore + 0.5)), pos.scoreNum, scoreFont)
	end

	checkScoreLife(score)
end

local function updateRingBlink(elapsed)
	if not (ringBlink and ringsLabel) then return end

	local shouldBlink = rings <= 0 and not dead
	local red = false

	if shouldBlink then
		blinkClock = blinkClock + elapsed
		red = math.floor(blinkClock / blinkSpeed) % 2 == 0
	else
		blinkClock = 0
	end

	if red ~= blinkRed then
		blinkRed = red
		setProperty('ringshud.color', red and redColor or whiteColor)
	end
end

local function updateHurt(elapsed)
	if hurtTimer <= 0 then return end

	hurtTimer = hurtTimer - elapsed
	flicker = not flicker
	setProperty('boyfriend.visible', flicker)

	if hurtTimer <= 0 then
		hurtTimer = 0
		setProperty('boyfriend.visible', true)
	end
end

function onCreate()
	lives = loadLives()
	loadPrefs()
	loadTimeLayout()

	redColor = getColorFromHex(blinkColor)
	whiteColor = getColorFromHex('FFFFFF')
	nextLifeScore = extraLifeEvery > 0 and extraLifeEvery or 0
	nextRingLife = extraLifeRings > 0 and extraLifeRings or 0

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
	hudSprite('misses2', 'misses2', pos.misses2, true, 0)
	hudSprite('hudlife', 'bf_hud-life', pos.life, true, 1)

	ringsLabel = hasImage(folder .. 'rings') or hasImage('hud/rings')
	if ringsLabel then hudSprite('ringshud', 'rings', pos.rings, true, 1) end

	setProperty('time2.visible', false)
	setProperty('score.visible', showScore)
	setProperty('hudlife.visible', showLives)
end

function onCreatePost()
	applyPalette()
end

function onSongStart()
	songStarted = true
	preTime = 0
end

function goodNoteHit(id, dir, noteType, sustain)
	if sustain then
		holdTimer = holdGrace
		return
	end

	local rating = getPropertyFromGroup('notes', id, 'rating')
	local key = type(rating) == 'string' and rating:lower() or nil

	if not popups or botPlay then return end

	local value = key and ratingScores[key] or nil

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

	if not songStarted and not dead then
		preTime = preTime + elapsed
	end

	updateLife()
	setText('sonicrings', rings, pos.ringNum, ringFont)
	setTimeText(timeString())
	updateScore(elapsed)
	updateRingBlink(elapsed)

	if not dead then updateHurt(elapsed) end

	setTextString('botplayTxt', '')
end

function onMonitorCollected(kind)
	if dead then return end

	if kind == 'ring' then
		addRings(ringBonus)
		sfx(ringSound, 1)
	elseif kind == 'life' then
		giveLife()
	end
end

function onRingCollected(amount)
	if dead then return end
	addRings(amount or 1)
	sfx(ringSound, 1)
end

function onGameOver()
	if dead then return Function_Stop end

	if ringShield and rings > 0 then
		rings = 0
		hurtTimer = invincibleTime
		setProperty('health', ringShieldHealth)
		sfx(ringLossSound, 1)
		log('ring shield used')
		return Function_Stop
	end

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

	if ringsLabel then setProperty('ringshud.color', whiteColor) end
	setProperty('boyfriend.visible', true)

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
