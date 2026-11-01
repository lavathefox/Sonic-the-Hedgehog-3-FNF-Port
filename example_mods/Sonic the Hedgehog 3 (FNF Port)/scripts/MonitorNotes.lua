local monitors = {
    RingNotes = {anim = 'ringIdle', kind = 'ring', weight = 55},
    LiveNotes = {anim = 'lifeIdle', kind = 'life', weight = 30},
    ContinueNotes = {anim = 'contIdle', kind = 'continue', weight = 15}
}

local order = {'RingNotes', 'LiveNotes', 'ContinueNotes'}
local autoPlace = true
local firstAt = 8000
local minGap = 12000
local maxGap = 25000
local maxPerSong = 8
local replaceHolds = false
local sizeMult = 1.65
local lifeSound = 'extraLife'
local lifeFadeIn = 1.5
local lifePlaysBreakSound = false
local pickupSound = 'monitorBreak'
local maxContinues = 9
local saveName = 'SonicMonitorProgress'
local debugMode = false

local continues = 0
local jingleState = nil
local fadeClock = 0
local oldMusicVolume = 1
local oldVocalsVolume = 1
local oldOpponentVolume = 1
local styledNotes = {}
local setupDone = false
local jingleTag = 'monitorExtraLife'

local function log(message)
    if debugMode then debugPrint('[Monitors] ' .. tostring(message)) end
end

local function safeGet(path, fallback)
    local ok, value = pcall(getProperty, path)
    if ok and value ~= nil then return value end
    return fallback
end

local function safeGroup(group, index, field, fallback)
    local ok, value = pcall(getPropertyFromGroup, group, index, field)
    if ok and value ~= nil then return value end
    return fallback
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function saveContinues()
    if type(setDataFromSave) == 'function' then
        setDataFromSave(saveName, 'continues', continues)
        if type(flushSaveData) == 'function' then flushSaveData(saveName) end
    end
end

local function loadContinues()
    if type(initSaveData) == 'function' then
        initSaveData(saveName)
        local value = getDataFromSave(saveName, 'continues', 0)
        continues = clamp(math.floor(tonumber(value) or 0), 0, maxContinues)
    end
end

local function notify(kind)
    if type(callOnScripts) == 'function' then
        callOnScripts('onMonitorCollected', {kind})
    elseif type(callOnLuas) == 'function' then
        callOnLuas('onMonitorCollected', {kind})
    end
end

local function musicVolumes(music, vocals, opponent)
    local m = clamp(music, 0, 1)
    local v = clamp(vocals, 0, 1)
    local o = clamp(opponent, 0, 1)
    runHaxeCode('if (FlxG.sound.music != null) FlxG.sound.music.volume = ' .. tostring(m) .. ';'
        .. 'if (game.vocals != null) game.vocals.volume = ' .. tostring(v) .. ';'
        .. 'if (game.opponentVocals != null) game.opponentVocals.volume = ' .. tostring(o) .. ';')
end

local function captureVolumes()
    oldMusicVolume = safeGet('songMusicVolume', 1)
    oldVocalsVolume = safeGet('vocals.volume', 1)
    oldOpponentVolume = safeGet('opponentVocals.volume', 1)
    local current = safeGet('music.volume', nil)
    if type(current) == 'number' then oldMusicVolume = current end
    oldMusicVolume = clamp(tonumber(oldMusicVolume) or 1, 0, 1)
    oldVocalsVolume = clamp(tonumber(oldVocalsVolume) or 1, 0, 1)
    oldOpponentVolume = clamp(tonumber(oldOpponentVolume) or 1, 0, 1)
end

local function restoreMusic()
    musicVolumes(oldMusicVolume, oldVocalsVolume, oldOpponentVolume)
    jingleState = nil
    fadeClock = 0
end

local function startLifeJingle()
    if jingleState ~= nil then return end
    captureVolumes()
    jingleState = 'muted'
    fadeClock = 0
    musicVolumes(0, 0, 0)
    playSound(lifeSound, 1, jingleTag)
end

local function collect(kind)
    if kind == 'continue' then
        continues = clamp(continues + 1, 0, maxContinues)
        saveContinues()
    end
    notify(kind)
    if kind == 'life' then
        startLifeJingle()
        if not lifePlaysBreakSound then return end
    end
    playSound(pickupSound, 1)
end

local function randomMonitor()
    local total = 0
    for _, name in ipairs(order) do total = total + monitors[name].weight end
    local roll = math.random() * total
    local current = 0
    for _, name in ipairs(order) do
        current = current + monitors[name].weight
        if roll <= current then return name end
    end
    return order[#order]
end

local function setupMonitors()
    if setupDone then return end
    setupDone = true
    local length = tonumber(safeGet('unspawnNotes.length', 0)) or 0
    local existing = 0
    for i = 0, length - 1 do
        local noteType = safeGroup('unspawnNotes', i, 'noteType', '')
        if monitors[noteType] and not safeGroup('unspawnNotes', i, 'isSustainNote', false) then
            existing = existing + 1
        end
    end
    if existing == 0 and autoPlace then
        local nextAt = firstAt
        local count = 0
        for i = 0, length - 1 do
            if count >= maxPerSong then break end
            local mustPress = safeGroup('unspawnNotes', i, 'mustPress', false)
            local sustain = safeGroup('unspawnNotes', i, 'isSustainNote', false)
            local holdLength = tonumber(safeGroup('unspawnNotes', i, 'sustainLength', 0)) or 0
            local noteType = safeGroup('unspawnNotes', i, 'noteType', '')
            local time = tonumber(safeGroup('unspawnNotes', i, 'strumTime', 0)) or 0
            if mustPress and not sustain and (replaceHolds or holdLength <= 0)
                and (noteType == nil or noteType == '') and time >= nextAt then
                local selected = randomMonitor()
                setPropertyFromGroup('unspawnNotes', i, 'noteType', selected)
                nextAt = time + minGap + math.random() * math.max(0, maxGap - minGap)
                count = count + 1
            end
        end
        log('Automatically placed: ' .. count)
    else
        log('Existing chart monitors: ' .. existing)
    end
    for i = 0, length - 1 do
        local noteType = safeGroup('unspawnNotes', i, 'noteType', '')
        if monitors[noteType] and not safeGroup('unspawnNotes', i, 'isSustainNote', false) then
            setPropertyFromGroup('unspawnNotes', i, 'texture', 'notesMonitors/' .. noteType)
            pcall(setPropertyFromGroup, 'unspawnNotes', i, 'noteSplashData.disabled', true)
        end
    end
end

local function styleSpawnedNote(id, noteData, noteType)
    if styledNotes[id] then return end
    local monitor = monitors[noteType]
    if not monitor then return end
    styledNotes[id] = true
    setPropertyFromGroup('notes', id, 'texture', 'notesMonitors/' .. noteType)
    local anim = monitor.anim
    local code = 'var n = game.notes.members[' .. tostring(id) .. '];'
        .. 'if (n != null) {'
        .. 'n.animation.addByPrefix("' .. anim .. '", "' .. anim .. '", 24, true);'
        .. 'n.animation.play("' .. anim .. '", true);'
        .. '}'
    runHaxeCode(code)
    local frameW = tonumber(safeGroup('notes', id, 'frameWidth', 0)) or 0
    local frameH = tonumber(safeGroup('notes', id, 'frameHeight', 0)) or 0
    local strumW = tonumber(safeGroup('playerStrums', noteData, 'width', 112)) or 112
    if frameW <= 0 or frameH <= 0 then return end
    local scale = strumW * sizeMult / math.max(frameW, frameH)
    setPropertyFromGroup('notes', id, 'scale.x', scale)
    setPropertyFromGroup('notes', id, 'scale.y', scale)
    runHaxeCode('var n = game.notes.members[' .. tostring(id) .. ']; if (n != null) n.updateHitbox();')
    local width = tonumber(safeGroup('notes', id, 'width', strumW)) or strumW
    local height = tonumber(safeGroup('notes', id, 'height', strumW)) or strumW
    setPropertyFromGroup('notes', id, 'offset.x', (width - strumW) / 2)
    setPropertyFromGroup('notes', id, 'offset.y', (height - strumW) / 2)
end

function onCreate()
    loadContinues()
end

function onCreatePost()
    setupMonitors()
end

function onSpawnNote(id, noteData, noteType, isSustainNote)
    if not isSustainNote and monitors[noteType] then
        styleSpawnedNote(id, noteData, noteType)
    end
end

function goodNoteHit(id, direction, noteType, isSustainNote)
    if not isSustainNote and monitors[noteType] then collect(monitors[noteType].kind) end
end

function onUpdatePost(elapsed)
    if jingleState == 'muted' then
        musicVolumes(0, 0, 0)
    elseif jingleState == 'fading' then
        fadeClock = fadeClock + elapsed
        local factor = clamp(fadeClock / math.max(lifeFadeIn, 0.01), 0, 1)
        musicVolumes(oldMusicVolume * factor, oldVocalsVolume * factor, oldOpponentVolume * factor)
        if factor >= 1 then restoreMusic() end
    end
end

function onSoundFinished(tag)
    if tag == jingleTag and jingleState == 'muted' then
        jingleState = 'fading'
        fadeClock = 0
    end
end

function onGameOver()
    if jingleState ~= nil then
        stopSound(jingleTag)
        restoreMusic()
    end
end

function onDestroy()
    if jingleState ~= nil then
        stopSound(jingleTag)
        restoreMusic()
    end
end
