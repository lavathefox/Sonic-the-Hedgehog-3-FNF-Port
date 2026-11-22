local stageMode = 'normal'

local allowRuntimeSwitch = true

local showCollisions = true
local countdownBlocked = true

local fireDefaultY = 800

local worldWidth = 17240
local camLimitLeft = 0
local camLimitRight = 17240

local rampStartX = 189
local rampEndX = 240
local rampStartY = 232
local rampEndY = 215
local platformEndX = 582

local descentStartX = 1522
local descentLength = 154
local descentStartY = 148
local descentEndY = 180

local descent2StartX = descentStartX + 194
local descent2Length = 154
local descent2StartY = descentEndY
local descent2EndY = 250

local col14X = 1980
local col14Y = 215

local col16X = 2123
local col16Y = 245

local descent3StartX = 2051
local descent3Length = 119
local descent3StartY = 212
local descent3EndY = col16Y

local curveRadius = 117
local curveArcDeg = 70
local curveSegments = 26
local curveX = 2437
local curveStartX = math.floor(curveX + curveRadius * math.sin(math.rad(curveArcDeg)) + 0.5)
local curveCenterY = col16Y - curveRadius
local curveEndX = curveStartX + math.floor(curveRadius * math.sin(math.rad(curveArcDeg)))

local col18X, col18Y = 2665, 180
local col19X, col19Y = 2867, 180
local col20X, col20Y = 3007, 119
local col21X, col21Y = 3257, 176

local descent4StartX = col21X + 80
local descent4Length = 120
local descent4StartY = col21Y
local descent4EndY = 240

local col23X = descent4StartX + descent4Length
local col23Y = 243
local col23Width = 340

local loopX = 1666
local loopGroundY = 179
local loopScale = 0.497
local loopRadius = 200 * loopScale
local loopThickness = 16
local loopCenterY = loopGroundY - loopRadius

local groundDepth = 192
local killFloorY = 3000

local islandTag = 'AgenIsland'
local islandX = 0
local islandY = -123

local ringsFile = 'data/rings_angelisland.txt'
local ringImagePrefixes = {'angelstage/rings', 'rings'}
local ringIdleAnim = 'ringIdle'
local ringEffectAnim = 'ringEffect'
local ringIdleFps = 12
local ringEffectFps = 24
local ringScale = 1
local ringSpawnRange = 1500
local ringDespawnRange = 2200
local ringSpawnsPerFrame = 2

local fakerTag = 'sonicFaker'
local fakerImage = 'characters/sonicFaker'
local fakerIdleAnim = 'idle'
local fakerLookAnim = 'look'
local fakerFps = 24
local fakerX = 3571
local fakerY = 148
local fakerOffsetY = 0
local cutsceneTriggerX = 3497
local musicPitchDropTime = 3
local cameraDriftX = 90
local cameraDriftTime = 3
local lookToSongDelay = 2
local normalCameraSpeed = 120

local lockFlags = {'cantakeinputs', 'canmove', 'canjump', 'canroll'}
local hideTailsOnSongStart = true
local bfPosX = nil
local bfPosY = nil
local bfOffset = {-17, -45}
local dadOffset = {0, 0}
local debugPositions = false

local bgFps = 12
local bgMinZoom = 0.7
local bgOrderStart = 0
local bgLockY = true
local bgMode = 'inverted'

local bgLayersNormal = {
    {animated = true,  anim = 'aizIdle', tile = true, order = 1, scale = 0.1, x = 0, y = 200, scrollX = 0.00, scrollY = 0.00, drift = 0},
    {animated = true,  anim = 'aizIdle', tile = true, order = 2, scale = 1, x = 0, y = 120, scrollX = 0.04, scrollY = 0.02, drift = -8},
    {animated = false,                   tile = true, order = 3, scale = 1, x = 0, y = 235, scrollX = 0.12, scrollY = 0.05, drift = 0},
    {animated = false,                   tile = true, order = 4, scale = 1, x = 0, y = 266, scrollX = 0.25, scrollY = 0.10, drift = 0},
    {animated = false,                   tile = true, order = 5, scale = 1, x = 0, y = islandY, scrollX = 0.45, scrollY = 0.20, drift = 0},
    {animated = false,                   tile = true, order = 6, scale = 1, x = 0, y = islandY, scrollX = 0.70, scrollY = 0.35, drift = 0},
}

local bgLayersInverted = {
    {animated = true,  anim = 'aizIdle', tile = true, order = 6, scale = 1, x = 0, y = 215, scrollX = 0.60, scrollY = 0.35, drift = 0},
    {animated = true,  anim = 'aizIdle', tile = true, order = 5, scale = 1, x = 0, y = 220, scrollX = 0.45, scrollY = 0.20, drift = 0},
    {animated = false,                   tile = true, order = 4, scale = 1, x = 0, y = 220, scrollX = 0.42, scrollY = 0.10, drift = 0},
    {animated = false,                   tile = true, order = 3, scale = 1, x = 0, y = 220, scrollX = 0.37, scrollY = 0.05, drift = 0},
    {animated = false,                   tile = true, order = 2, scale = 1, x = 0, y = 220, scrollX = 0.30, scrollY = 0.02, drift = 0},
    {animated = false,                   tile = true, order = 1, scale = 1, x = 0, y = 223, scrollX = 0.29, scrollY = 0.00, drift = 0},
}

local fireAnim = 'idle'
local bgLayersFire = {
    {source = 6, flipY = true, animated = true, anim = fireAnim, tile = true, order = 9, scale = 1, x = 0, y = 190, scrollX = 0.60, scrollY = 0.35, drift = 0},
    {source = 7, flipY = true, animated = true, anim = fireAnim, tile = true, order = 8, scale = 1, x = 0, y = 190, scrollX = 0.54, scrollY = 0.30, drift = 0},
    {source = 8, flipY = true, animated = true,  anim = fireAnim, tile = true, order = 7, scale = 1, x = 0, y = 190, scrollX = 0.48, scrollY = 0.25, drift = 0},
    {animated = true,  anim = fireAnim, tile = true, order = 6, scale = 1, x = 0, y = 420, scrollX = 0.42, scrollY = 0.20, drift = 0},
    {animated = true,  anim = fireAnim, tile = true, order = 5, scale = 1, x = 0, y = 433, scrollX = 0.36, scrollY = 0.15, drift = 0},
    {animated = true,  anim = fireAnim, tile = true, order = 4, scale = 1, x = 0, y = -4, scrollX = 0.30, scrollY = 0.10, drift = 0},
    {animated = true,  anim = fireAnim, tile = true, order = 3, scale = 1, x = 0, y = -4, scrollX = 0.22, scrollY = 0.06, drift = 0},
    {animated = true,  anim = fireAnim, tile = true, order = 2, scale = 1, x = 0, y = -4, scrollX = 0.14, scrollY = 0.03, drift = 0},
    {animated = true,  anim = fireAnim, tile = true, order = 1, scale = 0.6, x = 0, y = 114, scrollX = 0.06, scrollY = 0.00, drift = 0},
}

local profiles = {
    normal = {
        island = {image = 'angelstage/AngelIslandAct', anim = 'aizIdle', fps = 12, offsetX = 0, offsetY = 0},
        bgPrefixes = {'angelstage/bg', 'angelstage/bg/bg'},
        bgLayers = (bgMode == 'inverted') and bgLayersInverted or bgLayersNormal,
        bgInverted = (bgMode == 'inverted'),
    },
    fire = {
        island = {image = 'angelstage/AngelIslandFire', anim = 'fireIdle', fps = 12, offsetX = 0, offsetY = 0},
        bgPrefixes = {'angelstage/fireBG/bg', 'angelstage/fireBG/bg/bg'},
        bgLayers = bgLayersFire,
        bgInverted = true,
    },
}

local profile = nil
local bgLayers = nil
local bgPrefixes = nil
local bgInverted = true
local bgState = {}
local bgTags = {}

local collisionsVisible = showCollisions
local blockTags = {}
local debugTags = {}

local pieces = {}
local heights = {}
local angles = {}
local walls = {}

local ringData = {}
local ringImage = nil
local ringW, ringH = 16, 16

local cutscene = {state = 'waiting', clock = 0, pitchTime = 0, pitchDone = false, camDone = false}
local fakerFinalY = 0
local forced = nil

local function setStageLayerAlpha(tag, alpha)
	if luaSpriteExists(tag) then
		setProperty(tag .. '.alpha', alpha)
	end
end

local function addBlock(tag, x, y, w, h, color)
    makeLuaSprite(tag, '', x, y)
    makeGraphic(tag, w, h, color)
    setProperty(tag .. '.alpha', showCollisions and 0.6 or 0)
    addLuaSprite(tag, false)
    blockTags[#blockTags + 1] = tag
end

local function addDebugLine(tag, cx, cy, length, thickness, angle, color)
    makeLuaSprite(tag, '', cx - length / 2, cy - thickness / 2)
    makeGraphic(tag, math.ceil(length) + 1, thickness, color)
    setProperty(tag .. '.alpha', showCollisions and 0.8 or 0)
    setProperty(tag .. '.angle', angle)
    addLuaSprite(tag, false)
    debugTags[#debugTags + 1] = tag
end

local function addFlat(x1, x2, y)
    pieces[#pieces + 1] = {kind = 'flat', x1 = x1, x2 = x2, y1 = y, y2 = y}
end

local function addSlope(x1, x2, y1, y2)
    pieces[#pieces + 1] = {kind = 'slope', x1 = x1, x2 = x2, y1 = y1, y2 = y2}
end

local function addArc(cx, cy, r, deg)
    pieces[#pieces + 1] = {kind = 'arc', cx = cx, cy = cy, r = r, deg = deg}
end

local function buildTerrain()
    addFlat(10, rampStartX, rampStartY)
    addSlope(rampStartX, rampEndX, rampStartY, rampEndY)
    addFlat(rampEndX, platformEndX, 216)
    addFlat(692, 827, 245)
    addFlat(827, 956, 182)
    addFlat(956, descentStartX, 153)
    addSlope(descentStartX, descentStartX + descentLength, descentStartY, descentEndY)
    addFlat(descentStartX + descentLength, descent2StartX, descentEndY)
    addSlope(descent2StartX, descent2StartX + descent2Length, descent2StartY, descent2EndY)
    addFlat(descent2StartX + descent2Length, col14X, descent2EndY)
    addFlat(col14X, descent3StartX, col14Y)
    addSlope(descent3StartX, descent3StartX + descent3Length, descent3StartY, descent3EndY)
    addFlat(descent3StartX + descent3Length, curveStartX, col16Y)
    addArc(curveStartX, curveCenterY, curveRadius, curveArcDeg)
    addFlat(col18X, col18X + 100, col18Y)
    addFlat(col19X, col20X, col19Y)
    addFlat(col20X, col21X, col20Y)
    addFlat(col21X, descent4StartX, col21Y)
    addSlope(descent4StartX, descent4StartX + descent4Length, descent4StartY, descent4EndY)
    addFlat(col23X, col23X + col23Width, col23Y)

    for _, p in ipairs(pieces) do
        if p.kind == 'arc' then
            local last = p.cx + math.floor(p.r * math.sin(math.rad(p.deg)))
            for x = p.cx, last - 1 do
                local dx = x + 0.5 - p.cx
                heights[x] = math.floor(p.cy + math.sqrt(p.r * p.r - dx * dx) + 0.5)
            end
        else
            local span = p.x2 - p.x1
            for x = p.x1, p.x2 - 1 do
                local t = (x + 0.5 - p.x1) / span
                heights[x] = math.floor(p.y1 + (p.y2 - p.y1) * t + 0.5)
            end
        end
    end

    for x = 5, 14 do walls[x] = true end
    for x = 9000, 9009 do walls[x] = true end
    for x = 17230, 17239 do walls[x] = true end

    for x = 0, worldWidth do
        local a, b = heights[x - 3], heights[x + 3]
        if a and b and math.abs(b - a) <= 18 then
            angles[x] = math.deg(math.atan2(a - b, 6))
        else
            angles[x] = 0
        end
    end
end

local function solidKind(x, y, layer)
    if y >= killFloorY and y < killFloorY + 20 then return 4 end
    if walls[x] and y >= 0 and y < 256 then return 3 end

    local h = heights[x]
    if h and y >= h and y < h + groundDepth then return 1 end

    if layer == 1 then
        local dx = x + 0.5 - loopX
        local dy = y + 0.5 - loopCenterY
        local d = math.sqrt(dx * dx + dy * dy)
        if d >= loopRadius and d <= loopRadius + loopThickness then return 2 end
    end

    return 0
end

local function surfaceDeg(kind, x, y)
    if kind == 1 then
        return angles[x] or 0
    end

    if kind == 2 then
        local dx = loopX - (x + 0.5)
        local dy = loopCenterY - (y + 0.5)
        local d = math.sqrt(dx * dx + dy * dy)
        if d == 0 then return 0 end
        return math.deg(math.atan2(-dx / d, -dy / d))
    end

    return 0
end

local function angleByte(deg)
    return math.floor(256 - deg * 256 / 360 + 0.5) % 256
end

local function probe(x, y, dx, dy, reach, layer)
    x, y = math.floor(x), math.floor(y)
    reach = reach or 16

    local here = solidKind(x, y, layer)

    if here ~= 0 then
        local lastKind = here
        for i = 1, reach do
            local px, py = x - dx * i, y - dy * i
            local k = solidKind(px, py, layer)
            if k == 0 then
                return -(i - 1), x - dx * (i - 1), y - dy * (i - 1), lastKind
            end
            lastKind = k
        end
        return -reach, x, y, 0
    end

    for i = 1, reach do
        local px, py = x + dx * i, y + dy * i
        local k = solidKind(px, py, layer)
        if k ~= 0 then
            return i, px, py, k
        end
    end

    return reach, x, y, 0
end

local function publish(dist, hitX, hitY, kind)
    local deg = surfaceDeg(kind, hitX, hitY)
    setOnScripts('terrainDist', dist)
    setOnScripts('terrainHitX', hitX)
    setOnScripts('terrainHitY', hitY)
    setOnScripts('terrainKind', kind)
    setOnScripts('terrainFound', kind ~= 0)
    setOnScripts('terrainDeg', deg)
    setOnScripts('terrainAngle', angleByte(deg))
end

function terrainProbe(x, y, dx, dy, reach, layer)
    publish(probe(x, y, dx, dy, reach, layer))
end

function terrainFloor(x, y, reach, layer)
    publish(probe(x, y, 0, 1, reach, layer))
end

function terrainCeiling(x, y, reach, layer)
    publish(probe(x, y, 0, -1, reach, layer))
end

function terrainWall(x, y, dir, reach, layer)
    publish(probe(x, y, dir, 0, reach, layer))
end

function terrainFeet(x, y, radius, reach, layer, dx, dy)
    dx, dy = dx or 0, dy or 1
    local px, py = dy, -dx

    local d1, x1, y1, k1 = probe(x - px * radius, y - py * radius, dx, dy, reach, layer)
    local d2, x2, y2, k2 = probe(x + px * radius, y + py * radius, dx, dy, reach, layer)

    setOnScripts('terrainDistA', d1)
    setOnScripts('terrainDistB', d2)

    local useFirst = true
    if k1 == 0 then
        useFirst = k2 == 0
    elseif k2 ~= 0 then
        useFirst = d1 <= d2
    end

    if useFirst then
        publish(d1, x1, y1, k1)
    else
        publish(d2, x2, y2, k2)
    end
end

function terrainSolidAt(x, y, layer)
    local kind = solidKind(math.floor(x), math.floor(y), layer)
    setOnScripts('terrainKind', kind)
    setOnScripts('terrainFound', kind ~= 0)
end

function terrainGroundY(x)
    local h = heights[math.floor(x)]
    setOnScripts('terrainHitY', h or killFloorY)
    setOnScripts('terrainFound', h ~= nil)
end

local function slopeGeom(startX, length, startY, endY)
    local dx, dy = length, endY - startY
    return math.sqrt(dx * dx + dy * dy), startX + dx / 2, startY + dy / 2, math.deg(math.atan2(dy, dx))
end

local function buildTerrainDebug()
    local n = 0

    for _, p in ipairs(pieces) do
        n = n + 1
        local tag = 'terrain' .. string.format('%02d', n)

        if p.kind == 'flat' then
            addDebugLine(tag, (p.x1 + p.x2) / 2, p.y1, p.x2 - p.x1, 4, 0, 'FF00FF')
        elseif p.kind == 'slope' then
            local len, cx, cy, angle = slopeGeom(p.x1, p.x2 - p.x1, p.y1, p.y2)
            addDebugLine(tag, cx, cy, len, 4, angle, '00FFFF')
        else
            for i = 0, curveSegments - 1 do
                local a1 = math.rad(p.deg * i / curveSegments)
                local a2 = math.rad(p.deg * (i + 1) / curveSegments)
                local x1 = p.cx + p.r * math.sin(a1)
                local y1 = p.cy + p.r * math.cos(a1)
                local x2 = p.cx + p.r * math.sin(a2)
                local y2 = p.cy + p.r * math.cos(a2)
                local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
                addDebugLine(tag .. 's' .. i, (x1 + x2) / 2, (y1 + y2) / 2, len, 4,
                    math.deg(math.atan2(y2 - y1, x2 - x1)), '00FFFF')
            end
        end
    end

    local count = 32
    local width = math.ceil((math.pi * 2 * loopRadius / count) * 1.07)
    for i = 0, count - 1 do
        local a = (math.pi * 2 * i) / count
        local mid = loopRadius + loopThickness / 2
        addDebugLine('loopTrack' .. i, loopX + math.sin(a) * mid, loopCenterY + math.cos(a) * mid,
            width, loopThickness, -math.deg(a), 'FF00FF')
    end
end

local function buildBlocks()
    addBlock('col1', 10, 232, 552, 192, 'FF00FF')
    addBlock('col2', 5, 0, 10, 256, '00FFFF')
    addBlock('col3', 17230, 0, 10, 256, '00FFFF')
    addBlock('col5', rampEndX, 216, 342, 20, 'FF00FF')
    addBlock('col6', 692, 245, 170, 20, 'FF00FF')
    addBlock('col7', 827, 182, 1000, 192, 'FF00FF')
    addBlock('col8', 956, 153, 590, 256, '00FFFF')
    addBlock('col10', descentStartX + descentLength, descentEndY,
        descent2StartX - (descentStartX + descentLength), 192, 'FF00FF')
    addBlock('col13', descent2StartX + descent2Length, descent2EndY,
        col14X - (descent2StartX + descent2Length), 192, 'FF00FF')
    addBlock('col14', col14X, col14Y, descent3StartX - col14X, 192, 'FF00FF')
    addBlock('col16', col16X, col16Y, 470, 192, 'FF00FF')
    addBlock('col18', col18X, col18Y, 100, 192, 'FF00FF')
    addBlock('col19', col19X, col19Y, 340, 192, 'FF00FF')
    addBlock('col20', col20X, col20Y, 249, 192, 'FF00FF')
    addBlock('col21', col21X, col21Y, 80, 192, 'FF00FF')
    addBlock('col23', col23X, col23Y, col23Width, 192, 'FF00FF')
    addBlock('col11', 0, killFloorY, worldWidth, 20, '00FFFF')
    addBlock('col24', 9000, 0, 10, 256, '00FFFF')
end

local function setCollisionsVisible(visible)
    collisionsVisible = visible

    for _, tag in ipairs(blockTags) do
        setProperty(tag .. '.alpha', visible and 0.6 or 0)
    end

    for _, tag in ipairs(debugTags) do
        setProperty(tag .. '.alpha', visible and 0.8 or 0)
    end
end

local function findBgImage(i)
    for _, prefix in ipairs(bgPrefixes) do
        if checkFileExists('images/' .. prefix .. i .. '.png') then
            return prefix .. i
        end
    end
    return nil
end

local function makeBgSprite(tag, image, layer, scrollX, scrollY)
    if layer.animated then
        makeAnimatedLuaSprite(tag, image, layer.x, layer.y)
        addAnimationByPrefix(tag, layer.anim, layer.anim, bgFps, true)
        playAnim(tag, layer.anim, true)
    else
        makeLuaSprite(tag, image, layer.x, layer.y)
    end

    scaleLuaSprite(tag, layer.scale, layer.scale)
    if layer.flipX then setProperty(tag .. '.flipX', true) end
    if layer.flipY then setProperty(tag .. '.flipY', true) end
    setScrollFactor(tag, scrollX, scrollY)
    setProperty(tag .. '.antialiasing', false)
    addLuaSprite(tag, false)
end

local function applyBgOrder()
    local list = {}
    for i, layer in ipairs(bgLayers) do
        if bgTags[i] then
            list[#list + 1] = {i = i, order = layer.order or i}
        end
    end

    table.sort(list, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return a.i < b.i
    end)

    local idx = bgOrderStart
    for _, entry in ipairs(list) do
        for _, tag in ipairs(bgTags[entry.i]) do
            setObjectOrder(tag, idx)
            idx = idx + 1
        end
    end
end

local function createBackgrounds()
    local count = #bgLayers

    for n = 1, count do
        local i = bgInverted and (count + 1 - n) or n
        local layer = bgLayers[i]
        local scrollX = layer.scrollX
        local scrollY = bgLockY and 0 or layer.scrollY
        local image = findBgImage(layer.source or i)

        if image == nil then
            debugPrint('[Stage] image not found for bg' .. i .. ' (' .. stageMode .. ')')
        else
            local tag = 'bg' .. i
            local tags = {tag}
            makeBgSprite(tag, image, layer, scrollX, scrollY)
            bgTags[i] = tags

            if layer.tile then
                local width = math.floor(getProperty(tag .. '.width'))
                if width > 0 then
                    local copies = math.ceil((1280 / bgMinZoom) / width) + 1
                    for k = 2, copies do
                        local copyTag = tag .. '_t' .. k
                        makeBgSprite(copyTag, image, layer, scrollX, scrollY)
                        tags[#tags + 1] = copyTag
                    end
                    bgState[i] = {tags = tags, width = width, offset = 0, scrollX = scrollX}
                end
            end
        end
    end

    applyBgOrder()
end

local function destroyBackgrounds()
    for _, tags in pairs(bgTags) do
        for _, tag in ipairs(tags) do
            removeLuaSprite(tag, true)
        end
    end

    bgTags = {}
    bgState = {}
end

local function updateBackgrounds(elapsed)
    local camX = getProperty('camGame.scroll.x')

    for i, layer in ipairs(bgLayers) do
        local st = bgState[i]
        if st then
            if layer.drift ~= 0 then
                st.offset = (st.offset + layer.drift * elapsed) % st.width
            end

            local base = layer.x + st.offset
            local firstX = math.floor((camX * st.scrollX - base) / st.width) * st.width + base

            for k, tag in ipairs(st.tags) do
                setProperty(tag .. '.x', math.floor(firstX + (k - 1) * st.width + 0.5))
            end
        end
    end
end

local function createIsland()
    local cfg = profile.island

    if not checkFileExists('images/' .. cfg.image .. '.png') then
        debugPrint('[Stage] island image not found: ' .. cfg.image)
        return
    end

    makeAnimatedLuaSprite(islandTag, cfg.image, islandX + cfg.offsetX, islandY + cfg.offsetY)
    addAnimationByPrefix(islandTag, cfg.anim, cfg.anim, cfg.fps, true)
    playAnim(islandTag, cfg.anim, true)
    addLuaSprite(islandTag, false)
end

local function placeIslandAboveBackgrounds()
    if not luaSpriteExists(islandTag) then return end

    local count = 0
    for _, tags in pairs(bgTags) do
        count = count + #tags
    end

    setObjectOrder(islandTag, bgOrderStart + count)
end

local function applyProfile(mode)
    if profiles[mode] == nil then
        debugPrint('[Stage] unknown stageMode "' .. tostring(mode) .. '", falling back to normal')
        mode = 'normal'
    end

    stageMode = mode
    profile = profiles[mode]
    bgLayers = profile.bgLayers
    bgPrefixes = profile.bgPrefixes
    bgInverted = profile.bgInverted
end

local function buildLook()
    createBackgrounds()
    createIsland()
    placeIslandAboveBackgrounds()
end

local function switchStageMode()
    destroyBackgrounds()

    if luaSpriteExists(islandTag) then
        removeLuaSprite(islandTag, true)
    end

    applyProfile(stageMode == 'fire' and 'normal' or 'fire')
    buildLook()

    debugPrint('[Stage] mode switched to: ' .. stageMode)
end

local function firstExisting(list)
    for _, path in ipairs(list) do
        if checkFileExists('images/' .. path .. '.png') then
            return path
        end
    end
    return nil
end

local function buildRingSprite(tag)
    makeAnimatedLuaSprite(tag, ringImage, 0, 0)
    addAnimationByPrefix(tag, ringIdleAnim, ringIdleAnim, ringIdleFps, true)
    addAnimationByPrefix(tag, ringEffectAnim, ringEffectAnim, ringEffectFps, false)
    playAnim(tag, ringIdleAnim, true)
    scaleLuaSprite(tag, ringScale, ringScale)
    setProperty(tag .. '.antialiasing', false)
end

local function spawnRing(r)
    r.tag = 'ringpick' .. r.id
    buildRingSprite(r.tag)
    setProperty(r.tag .. '.x', r.cx - ringW / 2)
    setProperty(r.tag .. '.y', r.cy - ringH / 2)
    addLuaSprite(r.tag, false)

    if luaSpriteExists('tails') then
        setObjectOrder(r.tag, getObjectOrder('tails'))
    end

    r.spawned = true
end

local function despawnRing(r)
    removeLuaSprite(r.tag, true)
    r.spawned = false
end

local function createRings()
    ringImage = firstExisting(ringImagePrefixes)
    if ringImage == nil then
        debugPrint('[Stage] ring image not found')
        return
    end

    local text = getTextFromFile(ringsFile)
    if type(text) ~= 'string' or text == '' then
        debugPrint('[Stage] ' .. ringsFile .. ' not found or empty')
        return
    end

    buildRingSprite('ringprobe')
    ringW = getProperty('ringprobe.width')
    ringH = getProperty('ringprobe.height')
    removeLuaSprite('ringprobe', true)

    local n = 0
    for x, y in string.gmatch(text, '(%-?[%d%.]+),(%-?[%d%.]+)') do
        n = n + 1
        ringData[n] = {id = n, cx = islandX + tonumber(x), cy = islandY + tonumber(y), spawned = false, state = 0}
    end

    debugPrint('[Stage] rings loaded: ' .. n)
end

local function updateRings()
    if #ringData == 0 or not luaSpriteExists('tailsmainhitbox') then return end

    local viewX = getProperty('camGame.scroll.x') + 640
    local px = getProperty('tailsmainhitbox.x')
    local py = getProperty('tailsmainhitbox.y')
    local pw = getProperty('tailsmainhitbox.width')
    local ph = getProperty('tailsmainhitbox.height')
    local spawnedNow = 0

    for i = #ringData, 1, -1 do
        local r = ringData[i]
        local dist = math.abs(r.cx - viewX)

        if r.state == 0 then
            if not r.spawned then
                if dist <= ringSpawnRange and spawnedNow < ringSpawnsPerFrame then
                    spawnRing(r)
                    spawnedNow = spawnedNow + 1
                end
            elseif dist > ringDespawnRange then
                despawnRing(r)
            else
                local rx = r.cx - ringW / 2
                local ry = r.cy - ringH / 2
                if px < rx + ringW and px + pw > rx and py < ry + ringH and py + ph > ry then
                    r.state = 1
                    playAnim(r.tag, ringEffectAnim, true)
                    playSound('ring')
                    callOnScripts('onRingCollected', {1})
                end
            end
        elseif getProperty(r.tag .. '.animation.curAnim.finished') then
            removeLuaSprite(r.tag, true)
            table.remove(ringData, i)
        end
    end
end

local function createFaker()
    makeAnimatedLuaSprite(fakerTag, fakerImage, fakerX, 0)
    addAnimationByPrefix(fakerTag, fakerIdleAnim, fakerIdleAnim, fakerFps, true)
    addAnimationByPrefix(fakerTag, fakerLookAnim, fakerLookAnim, fakerFps, false)
    playAnim(fakerTag, fakerIdleAnim, true)
    setProperty(fakerTag .. '.antialiasing', false)

    if fakerY ~= nil then
        fakerFinalY = fakerY
    else
        fakerFinalY = col23Y - getProperty(fakerTag .. '.height') + fakerOffsetY
    end

    setProperty(fakerTag .. '.y', fakerFinalY)
    addLuaSprite(fakerTag, false)
end

local function getPlayerX()
    if luaSpriteExists('tailsmainhitbox') then
        return getProperty('tailsmainhitbox.x')
    end
    if luaSpriteExists('tails') then
        return getProperty('tails.x')
    end
    return nil
end

local function setMusicPitch(pitch)
    setPropertyFromClass('flixel.FlxG', 'sound.music.pitch', pitch)
end

local function setCameraFrozen(frozen)
    runHaxeCode([[
        try { game.freezeCamera = ]] .. (frozen and 'true' or 'false') .. [[; } catch (e:Dynamic) {}
    ]])
    setProperty('cameraSpeed', frozen and 0 or normalCameraSpeed)
end

local function lockTails()
    for _, name in ipairs(lockFlags) do
        setOnScripts(name, false)
    end
end

local function applyForcedPositions()
    if forced == nil then return end

    if forced.bfX ~= nil then
        setProperty('boyfriend.x', forced.bfX)
        setProperty('boyfriend.y', forced.bfY)
    end

    setProperty('dad.x', forced.dadX)
    setProperty('dad.y', forced.dadY)
end

local function installPositionLock()
    local bf = forced.bfX ~= nil and string.format('%.3f, %.3f', forced.bfX, forced.bfY) or 'null, null'

    runHaxeCode([[
        try {
            var old = game.variables.get('fakerLockFn');
            if (old != null) FlxG.signals.postUpdate.remove(old);
        } catch (e:Dynamic) {}

        var pos = []] .. bf .. [[, ]] .. string.format('%.3f, %.3f', forced.dadX, forced.dadY) .. [[];
        var lockFn = function() {
            try {
                if (pos[0] != null) {
                    game.boyfriend.x = pos[0];
                    game.boyfriend.y = pos[1];
                }
                game.dad.x = pos[2];
                game.dad.y = pos[3];
            } catch (e:Dynamic) {}
        };
        game.variables.set('fakerLockFn', lockFn);
        FlxG.signals.postUpdate.add(lockFn);
    ]])
end

local function placeCharacters()
    local src = nil
    if luaSpriteExists('tails') then
        src = 'tails'
    elseif luaSpriteExists('tailsmainhitbox') then
        src = 'tailsmainhitbox'
    end

    forced = {
        dadX = getProperty(fakerTag .. '.x') + dadOffset[1],
        dadY = getProperty(fakerTag .. '.y') + dadOffset[2]
    }

    local bx, by = bfPosX, bfPosY
    if src ~= nil then
        if bx == nil then bx = getProperty(src .. '.x') end
        if by == nil then by = getProperty(src .. '.y') end
    end

    if bx ~= nil and by ~= nil then
        forced.bfX = bx + bfOffset[1]
        forced.bfY = by + bfOffset[2]
        setProperty('boyfriendGroup.x', forced.bfX)
        setProperty('boyfriendGroup.y', forced.bfY)
    end

    if hideTailsOnSongStart and src == 'tails' then
        setProperty('tails.visible', false)
    end

    setProperty('dadGroup.x', forced.dadX)
    setProperty('dadGroup.y', forced.dadY)

    applyForcedPositions()
    installPositionLock()

    setProperty('boyfriend.visible', true)
    setProperty('dad.visible', true)

    if debugPositions then
        debugPrint('[Faker] song start: tails ' .. tostring(getProperty('tails.x')) .. ',' .. tostring(getProperty('tails.y')) ..
            ' | boyfriend ' .. tostring(getProperty('boyfriend.x')) .. ',' .. tostring(getProperty('boyfriend.y')))
        runTimer('fakerDebug', 1)
    end
end

local function startCutscene()
    cutscene.state = 'slowing'
    cutscene.clock = 0
    lockTails()

    setOnScripts('cutsceneActive', true)
    setOnScripts('camerafollowplayer', false)

    setCameraFrozen(true)
    doTweenX('fakerCamDrift', 'camGame.scroll', getProperty('camGame.scroll.x') + cameraDriftX, cameraDriftTime, 'sineInOut')
end

local function startLook()
    cutscene.state = 'looking'
    playAnim(fakerTag, fakerLookAnim, true)
    runTimer('fakerStartSong', lookToSongDelay)
end

local function startSongNow()
    cutscene.state = 'done'

    setProperty(fakerTag .. '.visible', false)
    placeCharacters()
    lockTails()

    setOnScripts('cutsceneActive', false)
    setOnScripts('camerafollowplayer', true)
    setCameraFrozen(false)

    countdownBlocked = false
    setProperty('skipCountdown', true)
    startCountdown()
end

local function updateCutscene(elapsed)
    if cutscene.state == 'waiting' then
        local px = getPlayerX()
        if px ~= nil and px >= cutsceneTriggerX then
            startCutscene()
        end
    elseif cutscene.state == 'slowing' then
        cutscene.clock = cutscene.clock + elapsed

        setOnScripts('Xspeed', 0)
        lockTails()

        if not cutscene.pitchDone then
            cutscene.pitchTime = cutscene.pitchTime + elapsed
            local pitch = math.max(0, 1 - cutscene.pitchTime / musicPitchDropTime)

            if pitch <= 0.03 then
                cutscene.pitchDone = true
                runHaxeCode([[
                    try {
                        if (FlxG.sound.music != null) {
                            FlxG.sound.music.stop();
                            FlxG.sound.music.pitch = 1;
                        }
                    } catch (e:Dynamic) {}
                ]])
            else
                setMusicPitch(pitch)
            end
        end

        if cutscene.clock > math.max(musicPitchDropTime, cameraDriftTime) + 1 then
            cutscene.camDone = true
        end

        if cutscene.pitchDone and cutscene.camDone then
            startLook()
        end
    elseif cutscene.state == 'looking' then
        setOnScripts('Xspeed', 0)
        lockTails()
    elseif cutscene.state == 'done' then
        lockTails()
        applyForcedPositions()
    end
end

function onEvent(name, value1, value2)
    if name == 'Change Character' then
        applyForcedPositions()
    end
end

function onUpdatePost(elapsed)
    applyForcedPositions()
end

function onTweenCompleted(tag)
    if tag == 'fakerCamDrift' then
        cutscene.camDone = true
    end
end

function onTimerCompleted(tag)
    if tag == 'fakerStartSong' and cutscene.state == 'looking' then
        startSongNow()
    elseif tag == 'fakerDebug' then
        debugPrint('[Faker] 1s later: tails ' .. tostring(getProperty('tails.x')) .. ',' .. tostring(getProperty('tails.y')) ..
            ' | boyfriend ' .. tostring(getProperty('boyfriend.x')) .. ',' .. tostring(getProperty('boyfriend.y')))
    end
end

function onDestroy()
    runHaxeCode([[
        try {
            var f = game.variables.get('fakerLockFn');
            if (f != null) FlxG.signals.postUpdate.remove(f);
        } catch (e:Dynamic) {}
    ]])
end

local function createFire()
    local image = firstExisting({'fire', 'angelstage/fire'})

    if image == nil then
        debugPrint('[Stage] fire image not found')
        return
    end

    makeAnimatedLuaSprite('fire', image, 3300, fireDefaultY)
    addAnimationByPrefix('fire', 'fireloop', 'fireloop', 24, true)
    playAnim('fire', 'fireloop', true)
    setScrollFactor('fire', 1, 1)
    scaleObject('fire', 1.5, 1.5)
    setProperty('fire.antialiasing', false)
    setProperty('fire.alpha', 0)
    addLuaSprite('fire', true)
end

function onCreate()
    applyProfile(stageMode)
    buildLook()

    createFire()

    buildTerrain()
    buildBlocks()
    buildTerrainDebug()

    createFaker()
    createRings()
end

function onStartCountdown()
    if countdownBlocked then
        return Function_Stop
    end

    return Function_Continue
end

function onCreatePost()
    setProperty('dadGroup.x', fakerX)
    setProperty('dadGroup.y', fakerFinalY)
    setProperty('dad.visible', false)
    setProperty('boyfriend.visible', false)

    setProperty('cameraSpeed', normalCameraSpeed)

    setProperty('scoreTxt.alpha', 0)
    setProperty('botplayTxt.visible', false)

    setProperty('healthBar.alpha', 0)
    setProperty('healthBar.bg.alpha', 0)

    setProperty('showRating', false)
    setProperty('showComboNum', false)

    setProperty('iconP1.alpha', 0)
    setProperty('iconP2.alpha', 0)

    setOnScripts('levelCamXLimitLeft', camLimitLeft)
    setOnScripts('levelCamXLimitRight', camLimitRight)
    setOnScripts('cutsceneActive', false)

    runHaxeCode([[
        FlxG.worldBounds.set(0, -400, 17240, 3400);
        try { FlxG.camera.pixelPerfectRender = true; } catch (e:Dynamic) {}
    ]])

    playMusic('angelisland', 1, true)
end

function onUpdate(elapsed)
    updateBackgrounds(elapsed)
    updateRings()
    updateCutscene(elapsed)

    if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.F2') then
        setCollisionsVisible(not collisionsVisible)
    end

    if allowRuntimeSwitch and getPropertyFromClass('flixel.FlxG', 'keys.justPressed.F3') then
        switchStageMode()
    end
end

function onStepHit()
	if curStep == 536 then
		if luaSpriteExists('fire') then
			setProperty('fire.alpha', 1)
			playAnim('fire', 'fireloop', true)
		end
	elseif curStep == 537 then
		doTweenY('fireUp', 'fire', -10, 0.2, 'quadOut')
	elseif curStep == 543 then
		switchStageMode()
		doTweenY('fireDown', 'fire', 1500, 0.9, 'quadInOut')
  end
end
