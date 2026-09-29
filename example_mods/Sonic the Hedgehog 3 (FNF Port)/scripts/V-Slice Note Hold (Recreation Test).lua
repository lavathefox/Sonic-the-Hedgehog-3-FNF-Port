local colors = {'Purple', 'Blue', 'Green', 'Red'}
local path = 'rgbHold'

local holdSprites = {}
local holdReady = false

local holdOffsetX = -40
local holdOffsetY = -41

local endOffsetX = -55
local endOffsetY = -61

function createHoldSprite(color)
    local tag = 'hold' .. color
    local animationName = string.lower(color)

    makeAnimatedLuaSprite(tag, path, 0, 0)

    addAnimationByPrefix(tag, 'hold', 'note hold rgb ' .. animationName, 24, true)
    addAnimationByPrefix(tag, 'end', 'note splash rgb ' .. animationName, 24, false)

    addLuaSprite(tag, true)
    setObjectCamera(tag, 'hud')
    scaleObject(tag, 3, 3)
    setProperty(tag .. '.visible', false)

    holdSprites[color] = tag
end

function createHoldShader(color, index)
    local tag = holdSprites[color]
    local shaderTag = 'rgb_' .. tag
    local strumIndex = index + 3
    local strumTag = 'strumLineNotes.members[' .. strumIndex .. ']'

    createInstance(shaderTag, 'shaders.RGBPalette')

    setProperty(shaderTag .. '.r', getProperty(strumTag .. '.rgbShader.r'))
    setProperty(shaderTag .. '.g', getProperty(strumTag .. '.rgbShader.g'))
    setProperty(shaderTag .. '.b', getProperty(strumTag .. '.rgbShader.b'))

    setProperty(tag .. '.shader', instanceArg(shaderTag .. '.shader'), false, true)
end

function setupHolds()
    if holdReady then
        return
    end

    for i, color in ipairs(colors) do
        createHoldSprite(color)
        createHoldShader(color, i)
    end

    holdReady = true
end

function onCountdownStarted()
    setupHolds()
end

function showHold(direction, animation)
    local color = colors[direction + 1]

    if color == nil then
        return
    end

    local tag = holdSprites[color]

    if tag == nil then
        return
    end

    setProperty(tag .. '.visible', true)
    playAnim(tag, animation, true)
end

function hideHold(direction)
    local color = colors[direction + 1]

    if color == nil then
        return
    end

    local tag = holdSprites[color]

    if tag == nil then
        return
    end

    setProperty(tag .. '.visible', false)
end

function hideHolds()
    for _, color in ipairs(colors) do
        local tag = holdSprites[color]

        if tag ~= nil then
            setProperty(tag .. '.visible', false)
        end
    end
end

function goodNoteHit(id, direction, noteType, isSustain)
    if not isSustain then
        return
    end

    local animation = getProperty('notes.members[' .. id .. '].animation.name')

    if animation == nil then
        return
    end

    if stringEndsWith(animation, 'end') then
        showHold(direction, 'end')
    else
        showHold(direction, 'hold')
    end
end

function onNoteMiss(id, direction, noteType, isSustain)
    if direction == nil then
        return
    end

    hideHold(direction)
end

function onUpdatePost()
    if not holdReady then
        return
    end

    for i, color in ipairs(colors) do
        local tag = holdSprites[color]
        local strumIndex = i + 3
        local strumTag = 'strumLineNotes.members[' .. strumIndex .. ']'
        local animation = getProperty(tag .. '.animation.name')
        local strumAlpha = getProperty(strumTag .. '.alpha')

        if animation == 'end' and getProperty(tag .. '.animation.finished') then
            setProperty(tag .. '.visible', false)
            animation = 'hold'
        end

        if getProperty(strumTag .. '.visible') == false or strumAlpha <= 0 then
            setProperty(tag .. '.visible', false)
        end

        if animation == 'end' then
            setProperty(tag .. '.x', getProperty(strumTag .. '.x') + endOffsetX)
            setProperty(tag .. '.y', getProperty(strumTag .. '.y') + endOffsetY)
        else
            setProperty(tag .. '.x', getProperty(strumTag .. '.x') + holdOffsetX)
            setProperty(tag .. '.y', getProperty(strumTag .. '.y') + holdOffsetY)
        end

        setProperty(tag .. '.alpha', strumAlpha)
    end
end

function onPause()
    hideHolds()
end

function onResume()
    hideHolds()
end
