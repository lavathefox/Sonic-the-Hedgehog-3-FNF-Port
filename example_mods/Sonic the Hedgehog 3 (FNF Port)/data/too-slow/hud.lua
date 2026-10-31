local nohud = false
local badending = false

-- ===================== LIVES SYSTEM (Sonic 3 style) =====================
-- true  = the HUD number shows the player's lives ("soniclife")
-- false = the HUD number shows the health like before ("sonichealth")
local SHOW_LIVES = true

local START_LIVES = 3
local MAX_LIVES = 99

-- the lives are saved in <mod folder>/data/lives.dat (created automatically)
local LIVES_FILE = 'lives.dat'

-- when true, dying in practice mode does not cost a life
local PRACTICE_KEEPS_LIVES = true

-- full class path of the state opened after the game over (package.ClassName)
local GAME_OVER_STATE = 'states.DataSelectState'

-- prints what the lives system is doing (load, save, death, game over)
local DEBUG_LIVES = false
-- ==========================================================================

-- ===================== GAME OVER SEQUENCE (Sonic.exe style) =====================
-- 1) "GAME" / "OVER" slide in and the game over sound plays
-- 2) when the game over sound is almost over: the texts fade to red, the animated static
--    fades in and the static sound loops (fading in)
-- 3) the pitch of the static sound drops until it reaches 0
-- 4) at pitch 0 the laugh plays, and END_DELAY seconds later the song ends

local GAME_OVER_SOUND = 'sonicGameOver'
-- length of the game over sound in seconds. 0 = read it automatically.
-- If the effects start only when the sound ends, the length could not be read: set it here.
local GAME_OVER_SOUND_LENGTH = 0
local EFFECTS_START_REMAINING = 2 -- seconds left in the game over sound when step 2 starts

local RED_COLOR = 'FF0000'
local RED_FADE_TIME = 1.2

local STATIC_TAG = 'screenSTATIC' -- sprite tag
local STATIC_IMAGE = 'static' -- image (png + xml) of the animated static
local STATIC_ANIM = 'idle' -- animation name
local STATIC_PREFIX = 'static' -- animation prefix inside the xml
local STATIC_FPS = 12
local STATIC_SCALE = 7
local STATIC_MAX_ALPHA = 0.6 -- 1 = the static fully covers the screen
local STATIC_FADE_TIME = 1.5

local STATIC_SOUND = 'exeStatic'
local STATIC_SOUND_VOLUME = 1
local LAUGH_SOUND = 'exeLaugh'

-- keep this below EFFECTS_START_REMAINING * 2, so the game over sound is still playing when the pitch reaches 0
local PITCH_DROP_TIME = 3 -- seconds the pitch takes to go from 1 to 0
local PITCH_CUTOFF = 0.03 -- at or below this value the pitch counts as 0
local PITCH_TAGS = { GAME_OVER_SOUND } -- sounds slowed down and stopped at pitch 0 (add STATIC_SOUND to slow the static too)

local END_DELAY = 1.7 -- seconds between the laugh and the end of the song

-- prints each step of the game over sequence
local DEBUG_GAME_OVER = false

-- prints errors/steps of the freeze (chart + song stopped on death)
local DEBUG_FREEZE = false
-- ==========================================================================

local healthX = 140
local healthY = 628

local deadStarted = false
local gameOverPending = false -- true when the death was the last life: game over runs after the death
local gameOverStarted = false

local gameOverSoundLength = 0 -- seconds, 0 = unknown
local gameOverClock = 0 -- seconds since the game over sound started (own clock)
local lengthAttempts = 0

local frozenPosition = nil -- song position (ms) at the moment of death
local effectsStarted = false
local pitchActive = false
local pitchTime = 0

local digitScale = 3
local digitSpacing = 8 * digitScale

local letterScale = 3
local letterSpacing = 8 * letterScale

-- ===================== EXTRA FEATURES (V-Slice style) =====================
-- score number counts up smoothly ONLY while a hold note (note piece) is being held.
-- With normal notes the score is shown as usual, and when the hold ends the counter
-- stops and goes straight to the real score.
local SCORE_COUNT_UP = true
local COUNT_UP_SPEED = 12 -- higher = the counter catches up faster

-- floating score popup next to the receptor when a note is hit
local SCORE_POPUP = true
local popupScale = 2
local popupSpacing = 8 * popupScale
local POPUP_RISE_SPEED = -140 -- starting vertical speed (negative = up)
local POPUP_GRAVITY = 220 -- slows the rise down
local POPUP_FADE_TIME = 0.6
local POPUP_GAP = 10 -- distance from the receptor

-- popup value per rating (Psych default scores; edit if your mod uses other values)
local RATING_SCORES = { sick = 350, good = 200, bad = 100, shit = 50 }
-- safety net for the fallback: a tapped note can never show more than this
local MAX_TAP_SCORE = 350

-- points keep going up while a hold note (note piece) is being held
local HOLD_SCORE = true
local HOLD_SCORE_PER_SECOND = 250
local HOLD_GRACE = 0.1 -- seconds a piece keeps the hold "alive" (pieces do not hit every frame)

-- prints how each popup value was calculated (rating or fallback)
local DEBUG_SCORE = false
-- ==========================================================================

local lives = START_LIVES

local displayedScore = 0
local pendingHits = {} -- taps whose rating was not available (fallback path)
local popupId = 0

local holdTimer = 0 -- > 0 while a hold is active
local holdAccum = 0
local holdTotal = 0 -- every point this script added for holds (never counted as tap score)
local lastBase = 0 -- songScore without hold points, seen on the previous frame

local introStarted = false
local hudHidden = nil -- nil until the first update

-- what is currently drawn for each tag: drawn[tag] = { value = ..., names = { sprite names } }
-- sprites are only rebuilt when the value changes
local drawn = {}

-- ============================ LIVES FILE ============================

-- path used to READ (relative to the mod folders, like any other mod file)
local function livesReadPath()
	return 'data/' .. LIVES_FILE
end

-- path used to WRITE (saveFile is relative to the "mods" folder, so it needs the mod folder name)
local function livesWritePath()
	if currentModDirectory ~= nil and currentModDirectory ~= '' then
		return currentModDirectory .. '/data/' .. LIVES_FILE
	end
	return 'data/' .. LIVES_FILE
end

local function saveLives(value)

	local ok = saveFile(livesWritePath(), tostring(value))

	if DEBUG_LIVES then
		debugPrint('lives saved: ' .. tostring(value) .. ' (ok = ' .. tostring(ok) .. ')')
	end
end

-- reads the .dat; creates it with START_LIVES when it is missing or invalid
local function loadLives()

	local text = getTextFromFile(livesReadPath())
	local value = nil

	if type(text) == 'string' then
		value = tonumber((string.gsub(text, '%s+', '')))
	end

	if value == nil or value < 1 then
		value = START_LIVES
		saveLives(value)
	end

	value = math.floor(value)

	if value > MAX_LIVES then
		value = MAX_LIVES
	end

	if DEBUG_LIVES then
		debugPrint('lives loaded: ' .. tostring(value))
	end

	return value
end

-- ============================ SPRITE HELPERS ============================

local function numberPath(char)
	if char == ':' then
		return 'hud/numbers/colon3'
	end
	return 'hud/numbers/' .. char
end

local function lifePath(char)
	return 'hud/lifenumbers/' .. char
end

local function letterPath(char)
	if char == ' ' then
		return nil -- spaces only move the next letter
	end
	return 'hud/letershud/' .. char
end

-- creates a static HUD sprite (scaled x3, no antialiasing, on the HUD camera)
local function makeHudSprite(tag, image, x, y, front, alpha)

	makeLuaSprite(tag, image, x, y)

	setScrollFactor(tag, 0, 0)
	setObjectCamera(tag, 'hud')

	setProperty(tag .. '.antialiasing', false)

	scaleObject(tag, 3, 3)

	addLuaSprite(tag, front)

	if alpha ~= nil then
		setProperty(tag .. '.alpha', alpha)
	end
end

-- creates one sprite per character; returns the sprite names
local function drawChars(tag, str, x, y, spacing, scale, getPath)

	local names = {}

	for i = 1, #str do

		local path = getPath(string.sub(str, i, i))

		if path ~= nil then

			local name = tag .. i

			makeLuaSprite(name, path, x + ((i - 1) * spacing), y)

			setScrollFactor(name, 0, 0)
			setObjectCamera(name, 'hud')

			setProperty(name .. '.antialiasing', false)

			scaleObject(name, scale, scale)

			addLuaSprite(name, true)

			table.insert(names, name)
		end
	end

	return names
end

-- removes every sprite drawn for this tag
local function clearDigits(tag)

	local entry = drawn[tag]

	if entry == nil then
		return
	end

	drawn[tag] = nil

	for _, name in ipairs(entry.names) do
		removeLuaSprite(name, true)
	end
end

-- true when this tag already shows exactly this value
local function isDrawn(tag, value)

	local entry = drawn[tag]

	return entry ~= nil and entry.value == value
end

local function setNumber(tag, value, x, y, align)

	if isDrawn(tag, value) then
		return
	end

	clearDigits(tag)

	local str = tostring(value)
	local totalWidth = string.len(str) * digitSpacing
	local startX = x

	if align == 'center' then
		startX = x - totalWidth / 2
	elseif align == 'right' then
		startX = x - totalWidth + 5
	end

	local names = drawChars(tag, str, startX, y, digitSpacing, digitScale, numberPath)

	drawn[tag] = { value = value, names = names }
end

-- draws a number with the life font (used for both lives and health)
local function setHealthNumber(tag, value, x, y)

	if isDrawn(tag, value) then
		return
	end

	clearDigits(tag)

	local names = drawChars(tag, tostring(value), x, y, digitSpacing, digitScale, lifePath)

	drawn[tag] = { value = value, names = names }
end

local function setLetters(tag, text, x, y)

	if isDrawn(tag, text) then
		return
	end

	clearDigits(tag)

	local names = drawChars(tag, string.upper(text), x, y, letterSpacing, letterScale, letterPath)

	drawn[tag] = { value = text, names = names }
end

-- ============================ SCORE POPUP ============================

-- creates a floating number above (downscroll) or below (upscroll) the receptor of the hit note
local function spawnScorePopup(direction, value)

	local strumX = getPropertyFromGroup('playerStrums', direction, 'x')
	local strumY = getPropertyFromGroup('playerStrums', direction, 'y')
	local strumW = getPropertyFromGroup('playerStrums', direction, 'width')
	local strumH = getPropertyFromGroup('playerStrums', direction, 'height')

	if strumX == nil or strumY == nil then
		return
	end

	popupId = popupId + 1

	local str = tostring(value)
	local totalWidth = string.len(str) * popupSpacing

	local startX = strumX + ((strumW or 0) - totalWidth) / 2
	local startY = 0

	if downscroll == true then
		startY = strumY - popupSpacing - POPUP_GAP
	else
		startY = strumY + (strumH or 0) + POPUP_GAP
	end

	local names = drawChars('scpop' .. popupId .. '_', str, startX, startY, popupSpacing, popupScale, numberPath)

	for _, name in ipairs(names) do

		setProperty(name .. '.velocity.y', POPUP_RISE_SPEED)
		setProperty(name .. '.acceleration.y', POPUP_GRAVITY)

		-- the sprite is removed in onTweenCompleted (tag = sprite name)
		doTweenAlpha(name, name, 0, POPUP_FADE_TIME, 'quadIn')
	end
end

-- ============================ HUD VISIBILITY ============================

local function applyHudVisibility(hide)

	if hide then

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
end

-- ============================ SOUND HELPERS ============================

-- length (in seconds) of a sound started with playSound and a tag; 0 if it cannot be read.
-- First tries the sound that is playing, then the sound file itself.
local function getSoundLength(tag)

	local length = runHaxeCode([[
		try
		{
			var s = game.modchartSounds.get(']] .. tag .. [[');

			if (s != null && s.length > 0)
				return s.length / 1000;
		}
		catch (e:Dynamic) {}

		try
		{
			var pathsClass = Type.resolveClass('backend.Paths');
			var snd = Reflect.callMethod(pathsClass, Reflect.field(pathsClass, 'sound'), [']] .. tag .. [[']);

			if (snd != null && snd.length > 0)
				return snd.length / 1000;
		}
		catch (e:Dynamic) {}

		return 0;
	]])

	if type(length) == 'number' then
		return length
	end

	return 0
end

-- changes the pitch of a tagged sound (uses setSoundPitch when it exists, haxe otherwise)
local function setSoundPitchSafe(tag, pitch)

	if type(setSoundPitch) == 'function' then
		setSoundPitch(tag, pitch)
		return
	end

	runHaxeCode("var s = game.modchartSounds.get('" .. tag .. "'); if (s != null) s.pitch = " .. string.format('%.4f', pitch) .. ';')
end

-- ============================ FREEZE ============================

-- freezes the chart and the song without touching playbackRate (animations keep running)
local function freezeSong()

	frozenPosition = getSongPosition()

	local ok = runHaxeCode([[
		try
		{
			// chart: no spawn, no note movement, no input, no misses, no events
			game.generatedMusic = false;
			game.canPause = false;

			// song
			if (FlxG.sound.music != null)
				FlxG.sound.music.pause();

			if (game.vocals != null)
				game.vocals.pause();

			if (game.opponentVocals != null)
				game.opponentVocals.pause();

			// notes disappear
			game.notes.visible = false;
			game.strumLineNotes.visible = false;
			game.grpNoteSplashes.visible = false;

			return true;
		}
		catch (e:Dynamic)
		{
			return Std.string(e);
		}
	]])

	if DEBUG_FREEZE then
		debugPrint('freeze result: ' .. tostring(ok) .. ' at ' .. tostring(frozenPosition) .. 'ms')
	end
end

-- called every frame after the death: keeps the song and the conductor stopped
local function keepFrozen()

	if frozenPosition == nil then
		return
	end

	-- the conductor never moves (HUD time stays still, no resync can restart the song)
	setPropertyFromClass('backend.Conductor', 'songPosition', frozenPosition)

	-- safety: if the game resynced and the song started again, pause it again
	runHaxeCode([[
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.pause();

		if (game.vocals != null && game.vocals.playing)
			game.vocals.pause();

		if (game.opponentVocals != null && game.opponentVocals.playing)
			game.opponentVocals.pause();
	]])
end

-- ============================ GAME OVER ============================

-- leaves the song without saving the score and opens GAME_OVER_STATE
local function goToGameOverState()

	local opened = runHaxeCode([[
		var stateClass = Type.resolveClass(']] .. GAME_OVER_STATE .. [[');

		if (stateClass == null)
			return false;

		var beatClass = Type.resolveClass('backend.MusicBeatState');
		var newState = Type.createInstance(stateClass, []);

		if (beatClass != null)
			Reflect.callMethod(beatClass, Reflect.field(beatClass, 'switchState'), [newState]);
		else
			FlxG.switchState(newState);

		return true;
	]])

	if opened ~= true then

		-- the class was not found: fall back to the normal Psych exit
		debugPrint('game over: could not open ' .. GAME_OVER_STATE .. ', using exitSong instead')

		exitSong()
	end
end

-- creates one "GAME" / "OVER" text on the 'other' camera (in front of the black fade)
local function makeGameOverText(tag, image, startX, targetX)

	makeLuaSprite(tag, image, startX, 300)
	setProperty(tag .. '.antialiasing', false)
	scaleObject(tag, 3, 3)
	setObjectCamera(tag, 'other')
	addLuaSprite(tag, true)
	doTweenX(tag, tag, targetX, 0.3)
end

-- runs after the death animation (the black fade) when the last life was lost:
-- "GAME" and "OVER" slide in over the black screen and the game over sound plays
local function startGameOver()

	if gameOverStarted then
		return
	end

	gameOverStarted = true

	makeGameOverText('gamee', 'textgame', -280, 280)
	makeGameOverText('over', 'over', 280 * 3, 280)

	-- the third argument is the sound tag, used by onSoundFinished
	playSound(GAME_OVER_SOUND, 1, GAME_OVER_SOUND)

	-- needed to know when the sound is almost over
	gameOverClock = 0
	lengthAttempts = 0

	if GAME_OVER_SOUND_LENGTH > 0 then
		gameOverSoundLength = GAME_OVER_SOUND_LENGTH
	else
		gameOverSoundLength = getSoundLength(GAME_OVER_SOUND)
	end

	if DEBUG_GAME_OVER then
		debugPrint('game over started (sound length = ' .. tostring(gameOverSoundLength) .. 's)')
	end
end

-- the game over sound is almost over: texts fade to red, the static fades in and loops
local function startGameOverEffects()

	if effectsStarted then
		return
	end

	effectsStarted = true

	if DEBUG_GAME_OVER then
		debugPrint('game over effects started')
	end

	-- GAME / OVER fade to red
	doTweenColor('gameeRed', 'gamee', RED_COLOR, RED_FADE_TIME, 'linear')
	doTweenColor('overRed', 'over', RED_COLOR, RED_FADE_TIME, 'linear')

	-- animated static (fades in, covers the screen)
	makeAnimatedLuaSprite(STATIC_TAG, STATIC_IMAGE, 0, 0)
	addAnimationByPrefix(STATIC_TAG, STATIC_ANIM, STATIC_PREFIX, STATIC_FPS, true)
	objectPlayAnimation(STATIC_TAG, STATIC_ANIM, true)

	setObjectCamera(STATIC_TAG, 'other')
	scaleObject(STATIC_TAG, STATIC_SCALE, STATIC_SCALE)

	setProperty(STATIC_TAG .. '.alpha', 0)

	addLuaSprite(STATIC_TAG, true)

	doTweenAlpha('exeStaticFade', STATIC_TAG, STATIC_MAX_ALPHA, STATIC_FADE_TIME, 'linear')

	-- static sound: loops forever and fades in
	playSound(STATIC_SOUND, 0, STATIC_SOUND, true)
	soundFadeIn(STATIC_SOUND, STATIC_FADE_TIME, 0, STATIC_SOUND_VOLUME)

	-- the pitch starts dropping right away
	pitchTime = 0
	pitchActive = true
end

-- the pitch reached 0: silence the slowed sounds, laugh, and end the song after END_DELAY
local function finishPitchDrop()

	pitchActive = false

	for _, tag in ipairs(PITCH_TAGS) do
		stopSound(tag)
	end

	playSound(LAUGH_SOUND, 1, LAUGH_SOUND)

	runTimer('gameOverEnd', END_DELAY)

	if DEBUG_GAME_OVER then
		debugPrint('pitch reached 0: laugh played, the song ends in ' .. END_DELAY .. 's')
	end
end

local function updatePitchDrop(elapsed)

	if not pitchActive then
		return
	end

	pitchTime = pitchTime + elapsed

	local pitch = math.max(0, 1 - pitchTime / PITCH_DROP_TIME)

	if pitch <= PITCH_CUTOFF then
		finishPitchDrop()
		return
	end

	for _, tag in ipairs(PITCH_TAGS) do
		setSoundPitchSafe(tag, pitch)
	end
end

local function updateGameOver(elapsed)

	if not gameOverStarted then
		return
	end

	gameOverClock = gameOverClock + elapsed

	-- trigger: the game over sound has EFFECTS_START_REMAINING seconds left
	if not effectsStarted then

		-- length still unknown: keep trying for a short while
		if gameOverSoundLength <= 0 and lengthAttempts < 30 then

			lengthAttempts = lengthAttempts + 1
			gameOverSoundLength = getSoundLength(GAME_OVER_SOUND)

			if gameOverSoundLength <= 0 and lengthAttempts == 30 then
				debugPrint('game over: could not read the length of "' .. GAME_OVER_SOUND .. '". Set GAME_OVER_SOUND_LENGTH (seconds) at the top of the script.')
			end
		end

		if gameOverSoundLength > 0 then

			-- own clock, backed up by the real position of the sound (whichever is further)
			local played = math.max(gameOverClock, (getSoundTime(GAME_OVER_SOUND) or 0) / 1000)

			if gameOverSoundLength - played <= EFFECTS_START_REMAINING then
				startGameOverEffects()
			end
		end
	end

	updatePitchDrop(elapsed)
end

-- ============================ CALLBACKS ============================

function onCreate()

	-- lives are loaded first (creates the .dat with START_LIVES if it does not exist)
	lives = loadLives()

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

	makeHudSprite('score', 'hud/score', 51, 23, true, 1)
	makeHudSprite('time', 'hud/time', 51, 74, false, 1)
	makeHudSprite('time2', 'hud/time2', 60, 97, false, 0)
	setProperty('time2.visible', false)
	makeHudSprite('misses', 'hud/misses', 51, 123, true, 0)
	makeHudSprite('misses2', 'hud/misses2', 60, 150, true, 0)
	makeHudSprite('hudlife', 'hud/bf_hud-life', 48, 600, true)
end

-- note pieces keep the hold alive; tapped notes spawn a popup
function goodNoteHit(id, direction, noteType, isSustainNote)

	if isSustainNote then
		holdTimer = HOLD_GRACE
		return
	end

	if not SCORE_POPUP or nohud or botPlay then
		return
	end

	-- preferred path: the value comes from the rating of this exact note
	local rating = getPropertyFromGroup('notes', id, 'rating')
	local value = nil

	if type(rating) == 'string' then
		value = RATING_SCORES[string.lower(rating)]
	end

	if value ~= nil then

		spawnScorePopup(direction, value)

		if DEBUG_SCORE then
			debugPrint('popup by rating: ' .. rating .. ' = ' .. value)
		end
	else
		-- rating not available yet: resolve it later from the score difference
		table.insert(pendingHits, direction)
	end
end

-- runs after the game processed the input of this frame, so the score is already updated
function onUpdatePost(elapsed)

	-- after death: keep the song/conductor stopped, no hold score or popups
	if deadStarted then
		keepFrozen()
		return
	end

	-- points rising while a note piece is held
	if HOLD_SCORE and holdTimer > 0 and not botPlay then

		holdAccum = holdAccum + HOLD_SCORE_PER_SECOND * elapsed

		local add = math.floor(holdAccum)

		if add > 0 then
			holdAccum = holdAccum - add
			holdTotal = holdTotal + add
			addScore(add)
		end
	end

	holdTimer = math.max(0, holdTimer - elapsed)

	-- hold ended: stop adding points and drop the leftover fraction
	if holdTimer == 0 then
		holdAccum = 0
	end

	-- score without any hold points added by this script
	local base = getProperty('songScore') - holdTotal
	local delta = base - lastBase
	lastBase = base

	-- fallback: taps whose rating was unknown (chords split the points evenly)
	if #pendingHits > 0 then

		if SCORE_POPUP and not nohud and delta > 0 then

			local each = math.min(math.floor(delta / #pendingHits), MAX_TAP_SCORE)

			if each > 0 then

				for i = 1, #pendingHits do
					spawnScorePopup(pendingHits[i], each)
				end

				if DEBUG_SCORE then
					debugPrint('popup by fallback: delta = ' .. delta .. ', shown = ' .. each)
				end
			end
		end

		pendingHits = {}
	end
end

function onUpdate(elapsed)

	-- game over sequence (red texts, static, pitch drop, laugh)
	updateGameOver(elapsed)

	setProperty('time2.alpha', getProperty('misses2.alpha'))

	-- intro fade (runs once)
	if curStep >= 1 and not introStarted then

		introStarted = true

		doTweenAlpha('scoreFade', 'score', 1, 0.7, 'linear')
		doTweenAlpha('timeFade', 'time', 1, 0.7, 'linear')
		doTweenAlpha('missFade', 'misses', 1, 0.7, 'linear')
		doTweenAlpha('lifeFade', 'hudlife', 1, 0.7, 'linear')
	end

	-- life number: lives (soniclife) or health (sonichealth)
	if SHOW_LIVES then

		setHealthNumber('soniclife', lives, healthX, healthY)

	else

		local hp = math.floor(getProperty('health') * 50)

		if hp < 0 then
			hp = 0
		end

		if hp > 99 then
			hp = 99
		end

		setHealthNumber('sonichealth', hp, healthX, healthY)
	end

	local m = getProperty('songMisses')

	if m > 99 then
		m = 99
	end

	setNumber('sonicmisses', m, 220, 120)

	local timeStr = getTextString('timeTxt')

	setNumber('sonictime', timeStr, 169+3, 61+11, 'left')

	-- score counter
	local sc = getProperty('songScore')
	local holding = holdTimer > 0

	if SCORE_COUNT_UP and holding then

		-- hold active: the number climbs smoothly
		if displayedScore ~= sc then

			displayedScore = displayedScore + (sc - displayedScore) * math.min(1, elapsed * COUNT_UP_SPEED)

			if math.abs(sc - displayedScore) < 1 then
				displayedScore = sc
			end
		end
	else
		-- no hold (normal notes) or the hold just ended: show the real score right away
		displayedScore = sc
	end

	-- there is no sprite for the minus sign, so negative scores are shown as 0
	local shownScore = math.max(0, math.floor(displayedScore + 0.5))

	if not botPlay then

		clearDigits('sonicbotplay')

		setNumber('sonicscore', shownScore, 220, 23)

	else

		clearDigits('sonicscore')

		setLetters('sonicbotplay', 'BOTPLAY', 220, 23)
	end

	if m >= 20 and badending == false then

		runTimer('blink1', 0.2) -- note: there is no handler for this timer yet

		setProperty('misses.alpha', 0)

		badending = true
	end

	local hideHud = (nohud == true and curStep >= 128)

	if hideHud ~= hudHidden then
		hudHidden = hideHud
		applyHudVisibility(hideHud)
	end

	setTextString('botplayTxt', '')
end

function onGameOver()

	if deadStarted then
		return Function_Stop
	end

	deadStarted = true

	-- every death costs one life (unless practice mode is keeping them)
	if not (PRACTICE_KEEPS_LIVES and practiceMode) then

		lives = lives - 1

		if lives <= 0 then

			-- last life lost: the death plays normally, then the game over runs
			-- the next attempt starts with fresh lives
			lives = 0
			gameOverPending = true
			saveLives(START_LIVES)

			if DEBUG_LIVES then
				debugPrint('game over: lives reset to ' .. START_LIVES)
			end

		else

			saveLives(lives)

			if DEBUG_LIVES then
				debugPrint('player died: ' .. lives .. ' lives left')
			end
		end
	end

	-- death: Tails jumps, the screen fades to black
	local bfX = getProperty('boyfriend.x')
	local bfY = getProperty('boyfriend.y')

	makeLuaSprite('tailsdeath', 'dead', bfX, bfY)
	setProperty('tailsdeath.antialiasing', false)
	setObjectCamera('tailsdeath', 'game')
	setObjectOrder('tailsdeath', getObjectOrder('boyfriendGroup') + 1)

	addLuaSprite('tailsdeath', true)

	setProperty('boyfriend.visible', false)

	-- stops the chart and the song, hides the notes (animations keep running)
	freezeSong()

	playSound('death', 1)

	setProperty('health', 0.001)

	doTweenY('tailsdeathjump', 'tailsdeath', getProperty('tailsdeath.y') - 110, 0.5, 'sineOut')

	return Function_Stop
end

-- safety net: if the game over sound ended before the effects started
-- (for example its length could not be read), start them now
function onSoundFinished(tag)

	if tag == GAME_OVER_SOUND and gameOverStarted and not effectsStarted then

		debugPrint('game over: the sound ended before the effects started (length unknown). Set GAME_OVER_SOUND_LENGTH at the top of the script.')

		startGameOverEffects()
	end
end

-- END_DELAY seconds after the laugh: leave the song without saving the score
function onTimerCompleted(tag)

	if tag == 'gameOverEnd' then
		goToGameOverState()
	end
end

function onTweenCompleted(tag)

	-- score popup digits are removed when their fade ends
	if string.sub(tag, 1, 5) == 'scpop' then
		removeLuaSprite(tag, true)
		return
	end

	if tag == 'tailsdeathjump' then

		doTweenY('tailsdeathfall', 'tailsdeath', getProperty('tailsdeath.y') + 1700, 2.75, 'sineIn')

		makeLuaSprite('blackdeath', '', 0, 0)
		makeGraphic('blackdeath', screenWidth or 1280, screenHeight or 720, '000000')
		setObjectCamera('blackdeath', 'other')
		addLuaSprite('blackdeath', true)
		setProperty('blackdeath.alpha', 0)

		doTweenAlpha('blackdeathFade', 'blackdeath', 1, 1, 'linear')
	end

	if tag == 'blackdeathFade' then

		if gameOverPending then
			-- the death is over: now the game over runs
			startGameOver()
		else
			restartSong(false)
		end
	end
end
