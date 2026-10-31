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

local healthX = 140
local healthY = 628

local deadStarted = false
local gameOverPending = false -- true when the death was the last life: game over runs after the death
local gameOverStarted = false

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

-- remembers what is currently drawn for each tag, so sprites are only rebuilt when the value changes
local lastDrawn = {}

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

function clearDigits(tag)

	if lastDrawn[tag] == nil then
		return
	end

	lastDrawn[tag] = nil

	for i = 1, 20 do
		removeLuaSprite(tag .. i, true)
	end

	removeLuaSprite(tag, true)
end

function setNumber(tag, value, x, y, align)

	if lastDrawn[tag] == value then
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

	drawChars(tag, str, startX, y, digitSpacing, digitScale, numberPath)

	lastDrawn[tag] = value
end

-- draws a number with the life font (used for both lives and health)
function setHealthNumber(tag, value, x, y)

	if lastDrawn[tag] == value then
		return
	end

	clearDigits(tag)

	drawChars(tag, tostring(value), x, y, digitSpacing, digitScale, lifePath)

	lastDrawn[tag] = value
end

function setLetters(tag, text, x, y)

	if lastDrawn[tag] == text then
		return
	end

	clearDigits(tag)

	drawChars(tag, string.upper(text), x, y, letterSpacing, letterScale, letterPath)

	lastDrawn[tag] = text
end

-- ============================ SCORE POPUP ============================

-- creates a floating number above (downscroll) or below (upscroll) the receptor of the hit note
function spawnScorePopup(direction, value)

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

-- ============================ GAME OVER ============================

-- runs after the death animation (the black fade) when the last life was lost:
-- "GAME" and "OVER" slide in over the black screen and the game over sound plays
local function startGameOver()

	if gameOverStarted then
		return
	end

	gameOverStarted = true

	-- the sprites are on the 'other' camera and added in front, so they stay above the black fade
	makeLuaSprite('gamee', 'textgame', -280, 300)
	setProperty('gamee.antialiasing', false)
	scaleObject('gamee', 3, 3)
	setObjectCamera('gamee', 'other')
	addLuaSprite('gamee', true)
	doTweenX('gamee', 'gamee', 280, 0.3)

	makeLuaSprite('over', 'over', 280 * 3, 300)
	setProperty('over.antialiasing', false)
	scaleObject('over', 3, 3)
	setObjectCamera('over', 'other')
	addLuaSprite('over', true)
	doTweenX('over', 'over', 280, 0.3)

	-- the third argument is the sound tag, used by onSoundFinished
	playSound('sonicGameOver', 1, 'sonicGameOver')
end

-- leaves the song without saving the score and opens GAME_OVER_STATE
local function goToGameOverState()

	local opened = runHaxeCode([[
		var stateClass = Type.resolveClass(']] .. GAME_OVER_STATE .. [[');

		if (stateClass == null)
			return false;

		var menuClass = Type.resolveClass('states.DataSelectState');
		var newState = Type.createInstance(stateClass, []);

		if (menuClass != null)
			Reflect.callMethod(menuClass, Reflect.field(menuClass, 'switchState'), [newState]);
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

		runTimer('blink1', 0.2) -- note: there is no onTimerCompleted for this timer yet

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

	setProperty('playbackRate', 0)

	playSound('death', 1)

	setProperty('health', 0.001)

	doTweenY('tailsdeathjump', 'tailsdeath', getProperty('tailsdeath.y') - 110, 0.5, 'sineOut')

	return Function_Stop
end

-- the game over sound ended: leave the song without saving the score
function onSoundFinished(tag)

	if tag == 'sonicGameOver' then
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
		makeGraphic('blackdeath', 1280, 720, '000000')
		setObjectCamera('blackdeath', 'other')
		addLuaSprite('blackdeath', true)
		setProperty('blackdeath.alpha', 0)

		doTweenAlpha('blackdeathFade', 'blackdeath', 1, 1,'linear')
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
