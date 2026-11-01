-- Monitor notes for Psych Engine 1.0.4
-- Needs: images/notesMonitors/<NoteType>.png + .xml (animations: ringIdle, lifeIdle, contIdle)

local monitors = {
	RingNotes     = {anim = 'ringIdle', kind = 'ring',     weight = 55},
	LiveNotes     = {anim = 'lifeIdle', kind = 'life',     weight = 30},
	ContinueNotes = {anim = 'contIdle', kind = 'continue', weight = 15}
}

local order = {'RingNotes', 'LiveNotes', 'ContinueNotes'}

-- Placement settings
local autoPlace = true      -- randomly replace notes when the chart has no monitor notes
local firstAt = 8000        -- earliest strum time (ms) for the first monitor
local minGap = 12000        -- minimum distance (ms) between two monitors
local maxGap = 25000        -- maximum distance (ms) between two monitors
local maxPerSong = 8        -- maximum monitors placed automatically
local replaceHolds = false  -- if true, hold note heads can also be replaced (tails keep the old skin)

-- Visual settings
local sizeMult = 166.5        -- 1.0 = same size as an arrow; raise it if the art has transparent padding

-- Extra life jingle settings
local lifeSound = 'extraLife'        -- played when a life monitor is collected
local lifeFadeIn = 1.5               -- seconds to fade inst/vocals back in after the jingle ends
local lifePlaysBreakSound = false    -- also play the normal pickup sound on life monitors

-- Other settings
local maxContinues = 9
local continuesFile = 'continues.dat'
local pickupSound = 'monitorBreak'
local debugMode = false

local continues = 0

-- Jingle state: nil = inactive, 'muted' = jingle playing, 'fading' = fading music back in
local jingleState = nil
local jingleClock = 0

local function log(text)
	if debugMode then debugPrint(text) end
end

local function continuesPath(write)
	if write and currentModDirectory ~= nil and currentModDirectory ~= '' then
		return currentModDirectory .. '/data/' .. continuesFile
	end
	return 'data/' .. continuesFile
end

local function loadContinues()
	local text = getTextFromFile(continuesPath(false))
	local n = nil

	if type(text) == 'string' then
		n = tonumber((string.gsub(text, '%s+', '')))
	end

	return math.max(0, math.min(math.floor(n or 0), maxContinues))
end

local function saveContinues()
	local ok = saveFile(continuesPath(true), tostring(continues))
	log('continues saved: ' .. continues .. ' (' .. tostring(ok) .. ')')
end

local function notify(kind)
	if type(callOnScripts) == 'function' then
		callOnScripts('onMonitorCollected', {kind})
	else
		callOnLuas('onMonitorCollected', {kind})
	end
end

-- Sets the volume of the instrumental and both vocal tracks
local function setMusicVolume(v)
	runHaxeCode([[
		var v = ]] .. string.format('%.4f', v) .. [[;
		if (FlxG.sound.music != null) FlxG.sound.music.volume = v;
		if (game.vocals != null) game.vocals.volume = v;
		if (game.opponentVocals != null) game.opponentVocals.volume = v;
	]])
end

-- Plays the extra life jingle and mutes the music until it finishes
local function startLifeJingle()
	if not checkFileExists('sounds/' .. lifeSound .. '.ogg') then
		log('jingle file not found: sounds/' .. lifeSound .. '.ogg')
		return
	end

	stopSound(lifeSound)
	playSound(lifeSound, 1, lifeSound)

	jingleState = 'muted'
	jingleClock = 0
	setMusicVolume(0)
	log('extra life jingle started')
end

local function collect(kind)
	if kind == 'continue' then
		continues = math.min(continues + 1, maxContinues)
		saveContinues()
	end

	notify(kind)

	if kind == 'life' then
		startLifeJingle()
		if not lifePlaysBreakSound then return end
	end

	if checkFileExists('sounds/' .. pickupSound .. '.ogg') then
		playSound(pickupSound, 1)
	end
end

-- Styles chart monitor notes and (optionally) replaces random notes with monitors
local function setupMonitors()
	local names, anims, weights = {}, {}, {}

	for _, name in ipairs(order) do
		names[#names + 1] = "'" .. name .. "'"
		anims[#anims + 1] = "'" .. monitors[name].anim .. "'"
		weights[#weights + 1] = monitors[name].weight
	end

	local result = runHaxeCode([[
		var names = []] .. table.concat(names, ',') .. [[];
		var anims = []] .. table.concat(anims, ',') .. [[];
		var weights = []] .. table.concat(weights, ',') .. [[];
		var autoPlace = ]] .. tostring(autoPlace) .. [[;
		var replaceHolds = ]] .. tostring(replaceHolds) .. [[;
		var firstAt = ]] .. firstAt .. [[;
		var minGap = ]] .. minGap .. [[;
		var maxGap = ]] .. maxGap .. [[;
		var maxCount = ]] .. maxPerSong .. [[;

		var total = 0.0;
		for (w in weights) total += w;

		// Applies texture and animation to a note (size is handled in onSpawnNote)
		function style(n, idx)
		{
			n.texture = 'notesMonitors/' + names[idx];
			n.animation.addByPrefix(anims[idx], anims[idx], 24, true);
			n.animation.play(anims[idx], true);

			try { n.noteSplashData.disabled = true; } catch (e:Dynamic) {}
		}

		// 1) Style monitor notes that already exist in the chart
		var existing = 0;

		for (n in game.unspawnNotes)
		{
			if (n.noteType == null || n.isSustainNote)
				continue;

			var idx = names.indexOf(n.noteType);

			if (idx >= 0)
			{
				style(n, idx);
				existing++;
			}
		}

		if (existing > 0 || !autoPlace)
			return existing;

		// 2) No monitors in the chart: replace random player notes
		var count = 0;
		var nextAt = firstAt;

		for (n in game.unspawnNotes)
		{
			if (count >= maxCount)
				break;

			if (!n.mustPress || n.isSustainNote)
				continue;

			if (!replaceHolds && n.sustainLength > 0)
				continue;

			if (n.strumTime < nextAt)
				continue;

			// Weighted random pick
			var roll = FlxG.random.float(0, total);
			var pick = 0;
			var acc = 0.0;

			for (i in 0...names.length)
			{
				acc += weights[i];

				if (roll < acc)
				{
					pick = i;
					break;
				}
			}

			n.noteType = names[pick];
			style(n, pick);

			nextAt = n.strumTime + FlxG.random.float(minGap, maxGap);
			count++;
		}

		return count;
	]])

	log('monitors ready: ' .. tostring(result))
end

function onCreate()
	continues = loadContinues()
end

function onCreatePost()
	setupMonitors()
end

-- Runs every time a note spawns, after Psych has finished setting it up
function onSpawnNote(id, noteData, noteType, isSustainNote)
	if isSustainNote or not monitors[noteType] then return end

	local frameW = getPropertyFromGroup('notes', id, 'frameWidth')
	local frameH = getPropertyFromGroup('notes', id, 'frameHeight')
	local strumW = getPropertyFromGroup('playerStrums', noteData, 'width')

	-- Scale so the biggest side of the frame matches the strum size * sizeMult
	local s = (strumW * sizeMult) / math.max(frameW, frameH)

	setPropertyFromGroup('notes', id, 'scale.x', s)
	setPropertyFromGroup('notes', id, 'scale.y', s)
	callMethod('notes.members[' .. id .. '].updateHitbox', {})

	-- Keep the bigger sprite centered on the strum
	local w = getPropertyFromGroup('notes', id, 'width')
	local h = getPropertyFromGroup('notes', id, 'height')
	setPropertyFromGroup('notes', id, 'offsetX', (strumW - w) / 2)
	setPropertyFromGroup('notes', id, 'offsetY', (strumW - h) / 2)

	log('monitor spawned: frame ' .. frameW .. 'x' .. frameH .. ', scale ' .. s)
end

function goodNoteHit(id, direction, noteType, isSustainNote)
	if isSustainNote then return end

	local monitor = monitors[noteType]

	if monitor then
		collect(monitor.kind)
	end
end

-- Keeps the music muted during the jingle (Psych resets the vocal volume on every hit),
-- then fades it back in
function onUpdatePost(elapsed)
	if jingleState == 'muted' then
		setMusicVolume(0)
	elseif jingleState == 'fading' then
		jingleClock = jingleClock + elapsed
		local f = math.min(1, jingleClock / lifeFadeIn)

		setMusicVolume(f)

		if f >= 1 then
			jingleState = nil
			log('music restored')
		end
	end
end

-- The jingle ended: start fading the music back in
function onSoundFinished(tag)
	if tag == lifeSound and jingleState == 'muted' then
		jingleState = 'fading'
		jingleClock = 0
		log('jingle finished, fading in')
	end
end

-- Do not leave the jingle running over the game over screen
function onGameOver()
	if jingleState ~= nil then
		jingleState = nil
		stopSound(lifeSound)
	end
end
