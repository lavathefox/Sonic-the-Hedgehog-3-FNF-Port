local songStarted = false

-- true = shows all collisions (magenta/cyan) and the loop track, for debugging. false = everything invisible.
local showCollisions = false
local countdownBlocked = true

local levelCamXLimitLeft = 0
local levelCamXLimitRight = 17240

-- Uphill ramp (SAME values in the Tails script)
local rampStartX = 189
local rampEndX = 240
local platformEndX = 552
local rampStartY = 232   -- ground height
local rampEndY = 215     -- upper platform height

-- Descent 1 (col9): downhill from the hill to the ground where the loop starts
local descentStartX = 1522
local descentLength = 154
local descentStartY = 148
local descentEndY = 180

-- Descent 2 (col12): the descent continues after the loop
local descent2StartX = descentStartX + 194
local descent2Length = 154
local descent2StartY = descentEndY
local descent2EndY = 250

-- Platform (col14): 32px above the end of the second descent (Tails has to jump)
local col14X = 1980
local col14Y = 215

-- col16: ground after descent 3 (YOUR values). Ramp 3 ends exactly at the height of its top.
local col16X = 2123
local col16Y = 245
local col16Width = 460

-- Descent 3 (col15): SAME values in the Tails script
-- Ends at x=2170, where it meets the top of col16
local descent3StartX = 2051
local descent3Length = 119
local descent3StartY = 212
local descent3EndY = col16Y
local col14Width = descent3StartX - col14X

-- col17: quarter pipe style curve (starts at the end of col16, rises to the right)
-- SAME values in the Tails script
local col17Radius = 117      -- curve radius
local col17ArcDeg = 70       -- how much of the curve to use (90 = full quarter pipe, but too steep for Tails)
local col17Segments = 26     -- only affects the debug visual
local col17X = 2437
local col17FloorY = col16Y
local col17CenterX = math.floor(col17X + col17Radius * math.sin(math.rad(col17ArcDeg)) + 0.5)
local col17CenterY = col17FloorY - col17Radius
local col17EndX = math.floor(col17X + col17Radius * math.sin(math.rad(col17ArcDeg)) + 0.5)
local col17EndY = math.floor(col17CenterY + col17Radius * math.cos(math.rad(col17ArcDeg)) + 0.5)

-- col18: flat platform at the top of the curve
local col18X = 2665
local col18Y = 180
local col18Width = 400

-- col19: flat platform after col18
local col19X = 2867
local col19Y = 180
local col19Width = 340

-- col20: flat platform after col19
local col20X = 3007
local col20Y = 119
local col20Width = 340

-- col21: short flat platform after col20
local col21X = 3257
local col21Y = 176
local col21Width = 340

-- Descent 4 (col22): descent after col21 (SAME values in the Tails script)
local descent4StartX = col21X + 80   -- 3337, where col21 ends
local descent4Length = 120
local descent4StartY = col21Y
local descent4EndY = 240

-- col23: flat platform at the end of descent 4
local col23X = descent4StartX + descent4Length
local col23Y = descent4EndY
local col23Width = 340

local descentThickness = 20

-- Slope geometry (thin rectangle rotated around its center)
local function slopeGeom(startX, length, startY, endY)
    local dx, dy = length, endY - startY
    return math.sqrt(dx * dx + dy * dy), startX + dx / 2, startY + dy / 2, math.deg(math.atan2(dy, dx))
end
local descentLen, descentCenterX, descentCenterY, descentAngle = slopeGeom(descentStartX, descentLength, descentStartY, descentEndY)
local descent2Len, descent2CenterX, descent2CenterY, descent2Angle = slopeGeom(descent2StartX, descent2Length, descent2StartY, descent2EndY)
local descent3Len, descent3CenterX, descent3CenterY, descent3Angle = slopeGeom(descent3StartX, descent3Length, descent3StartY, descent3EndY)
local descent4Len, descent4CenterX, descent4CenterY, descent4Angle = slopeGeom(descent4StartX, descent4Length, descent4StartY, descent4EndY)

local sonicLoopCenterX = 1666      -- where the descent ends (same as the Tails script)
local sonicLoopGroundY = 179       -- same as the Tails script
local sonicLoopScale = 0.497       -- loop size (1 = original). SAME value in the Tails script
local sonicLoopRadius = 200 * sonicLoopScale

-- Scenery
local islandTag = 'AgenIsland'
local islandImage = 'angelstage/AngelIslandAct'   -- images/angelstage/AngelIslandAct.png (+ .xml)
local islandAnim = 'aizIdle'      -- animation name (prefix in the XML)
local islandFps = 12              -- animation speed
local islandX = 0
local islandY = -123

-- Backgrounds (Sonic 3 style parallax): images/angelstage/bg1.png ... bg6.png (+ .xml for the animated ones)
-- All of them are behind the scenery. 'normal' mode: bg1 farthest back, bg6 closest (see bgMode below).
-- The script tries each prefix below, in order, and uses the first one where the file exists.
-- Final image path = prefix .. number (e.g. 'angelstage/bg' .. 1 = images/angelstage/bg1.png)
local bgImagePrefixes = {'angelstage/bg', 'angelstage/bg/bg'}
local bgFps = 12              -- animation speed of the animated backgrounds
local bgMinZoom = 0.7          -- lowest camera zoom of the stage (smaller zoom = wider view). Only as many copies as needed are created
local bgOrderStart = 0         -- object index where the bg block starts (0 = behind everything; the scenery is added later and goes on top)
local bgLockY = true            -- true = the bgs ignore vertical camera movement (jumps, camera offsets, etc.) and always stay at the same screen y
                              -- (applies to BOTH modes; the y of each layer then becomes its screen position). false = uses scrollY normally

-- Mode (each mode has its OWN table below, with independent x, y, scale, parallax, drift, etc.):
--   'normal'   = bg1 is the farthest back ... bg6 is the closest to the scenery (uses bgLayersNormal)
--   'inverted' = bg6 is the farthest back ... bg1 is the closest to the scenery (uses bgLayersInverted)
local bgMode = 'inverted'

-- Per layer (same fields in both tables):
--   x, y       = position when the camera is at scroll 0 (y = islandY lines it up with the scenery)
--   scrollX/Y  = parallax factor: 0 = glued to the screen, 1 = moves with the stage. Farther = smaller
--                (scrollY is ignored while bgLockY = true)
--   drift      = automatic horizontal speed in px/second (negative = left); needs tile = true
--   scale      = size of the image (1 = original). Applied from the top-left corner, so x/y stay the same
--   order      = stacking order of the bgs (setObjectOrder): smaller = farther back. Equal values fall back to the bg number
--   tile       = repeats the image horizontally so it never runs out (the image should be seamless)
--   animated   = uses the .xml with the 'anim' prefix
-- The index of each entry is the bg number (1st entry = bg1, ... 6th entry = bg6).

-- NORMAL mode: bg1 farthest back -> bg6 closest
local bgLayersNormal = {
    {animated = true,  anim = 'aizIdle', tile = true, order = 1, scale = 0.1, x = 0, y = 200, scrollX = 0.00, scrollY = 0.00, drift = 0},    -- bg1: sky (static on screen)
    {animated = true,  anim = 'aizIdle', tile = true, order = 2, scale = 1, x = 0, y = 120, scrollX = 0.04, scrollY = 0.02, drift = -8},   -- bg2: clouds (slow drift)
    {animated = false,                   tile = true, order = 3, scale = 1, x = 0, y = 235, scrollX = 0.12, scrollY = 0.05, drift = 0},    -- bg3
    {animated = false,                   tile = true, order = 4, scale = 1, x = 0, y = 266, scrollX = 0.25, scrollY = 0.10, drift = 0},    -- bg4
    {animated = false,                   tile = true, order = 5, scale = 1, x = 0, y = islandY, scrollX = 0.45, scrollY = 0.20, drift = 0},    -- bg5
    {animated = false,                   tile = true, order = 6, scale = 1, x = 0, y = islandY, scrollX = 0.70, scrollY = 0.35, drift = 0},    -- bg6: closest to the scenery
}

-- INVERTED mode: bg6 farthest back -> bg1 closest
-- (starting point: same x, y, scale as normal, with the parallax mirrored; edit freely)
local bgLayersInverted = {
    {animated = true,  anim = 'aizIdle', tile = true, order = 6, scale = 1, x = 0, y = 215, scrollX = 0.60, scrollY = 0.35, drift = 0},    -- bg1: closest to the scenery
    {animated = true,  anim = 'aizIdle', tile = true, order = 5, scale = 1, x = 0, y = 220, scrollX = 0.45, scrollY = 0.20, drift = 0},   -- bg2
    {animated = false,                   tile = true, order = 4, scale = 1, x = 0, y = 220, scrollX = 0.42, scrollY = 0.10, drift = 0},    -- bg3
    {animated = false,                   tile = true, order = 3, scale = 1, x = 0, y = 220, scrollX = 0.37, scrollY = 0.05, drift = 0},    -- bg4
    {animated = false,                   tile = true, order = 2, scale = 1, x = 0, y = 220, scrollX = 0.30, scrollY = 0.02, drift = 0},    -- bg5
    {animated = false,                   tile = true, order = 1, scale = 1, x = 0, y = 223, scrollX = 0.29, scrollY = 0.00, drift = 0},    -- bg6: farthest back (static on screen)
}

-- Table used by the selected mode
local bgLayers = (bgMode == 'inverted') and bgLayersInverted or bgLayersNormal
local bgState = {}   -- runtime data of the tiled layers (tags, width, drift offset)
local bgTags = {}    -- sprite tags of each layer (the original and its copies), used to set the stacking order

-- In-game keys: F2 toggles the collision visualization
local collisionsVisible = showCollisions

function createCollision(tag, x, y, width, height, color, alpha, angle)
    makeLuaSprite(tag, '', x, y)
    makeGraphic(tag, width, height, color)
    setProperty(tag .. '.alpha', showCollisions and 0.6 or 0)
    if angle then
        setProperty(tag .. '.angle', angle)
    end
    addLuaSprite(tag, false)
end

function createVisibleLoopTrack()
    local segmentCount = 32
    local segmentWidth = math.ceil((math.pi * 2 * sonicLoopRadius / segmentCount) * 1.07)
    local segmentHeight = 16
    local centerY = sonicLoopGroundY - sonicLoopRadius

    for i = 0, segmentCount - 1 do
        local angle = (math.pi * 2 * i) / segmentCount
        local segmentX = sonicLoopCenterX + math.sin(angle) * sonicLoopRadius - segmentWidth / 2
        local segmentY = centerY + math.cos(angle) * sonicLoopRadius - segmentHeight / 2
        local tag = 'sonicLoopTrack' .. string.format('%02d', i + 1)

        makeLuaSprite(tag, '', segmentX, segmentY)
        makeGraphic(tag, segmentWidth, segmentHeight, 'FF00FF')
        setProperty(tag .. '.alpha', 0)
        setProperty(tag .. '.angle', -math.deg(angle))
        addLuaSprite(tag, false)
    end
end

-- col17 visual (curve): several thin rectangles following the arc
function createCurveTrack()
    for i = 0, col17Segments - 1 do
        local a1 = math.rad(col17ArcDeg * i / col17Segments)
        local a2 = math.rad(col17ArcDeg * (i + 1) / col17Segments)
        local x1 = col17CenterX + col17Radius * math.sin(a1)
        local y1 = col17CenterY + col17Radius * math.cos(a1)
        local x2 = col17CenterX + col17Radius * math.sin(a2)
        local y2 = col17CenterY + col17Radius * math.cos(a2)
        local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
        local thick = 8
        local tag = 'col17seg' .. string.format('%02d', i + 1)

        makeLuaSprite(tag, '', (x1 + x2) / 2 - len / 2, (y1 + y2) / 2 - thick / 2)
        makeGraphic(tag, math.ceil(len) + 1, thick, '00FFFF')
        setProperty(tag .. '.alpha', showCollisions and 0.8 or 0)
        setProperty(tag .. '.angle', math.deg(math.atan2(y2 - y1, x2 - x1)))
        addLuaSprite(tag, false)
    end
end

-- Finds the image of a background trying each prefix (returns nil if none exists)
local function findBgImage(i)
    for _, prefix in ipairs(bgImagePrefixes) do
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
    scaleLuaSprite(tag, layer.scale, layer.scale)   -- also updates the hitbox, so the width used by the tiling is the scaled one
    setScrollFactor(tag, scrollX, scrollY)
    setProperty(tag .. '.antialiasing', false)   -- keeps the pixel art sharp
    addLuaSprite(tag, false)
end

-- Applies setObjectOrder to every bg sprite: layers sorted by 'order', one object index per sprite
local function applyBgOrder()
    local list = {}
    for i, layer in ipairs(bgLayers) do
        if bgTags[i] then
            list[#list + 1] = {i = i, order = layer.order or i}
        end
    end
    table.sort(list, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return a.i < b.i
    end)

    local idx = bgOrderStart
    for _, e in ipairs(list) do
        for _, tag in ipairs(bgTags[e.i]) do
            setObjectOrder(tag, idx)
            idx = idx + 1
        end
    end
end

-- Creates bg1 to bg6 with parallax (and the extra copies of the tiled layers)
function createBackgrounds()
    local count = #bgLayers
    for n = 1, count do
        -- n = draw order (1 = farthest back); i = which bg image goes there
        local i = (bgMode == 'inverted') and (count + 1 - n) or n
        local layer = bgLayers[i]
        local scrollX = layer.scrollX
        local scrollY = bgLockY and 0 or layer.scrollY   -- locked: no vertical movement with the camera
        local image = findBgImage(i)
        if image == nil then
            debugPrint('[Stage] Image not found for bg' .. i .. ' (looked for images/' .. bgImagePrefixes[1] .. i .. '.png and the other prefixes)')
        else
            local tag = 'bg' .. i
            makeBgSprite(tag, image, layer, scrollX, scrollY)
            local tags = {tag}
            bgTags[i] = tags

            if layer.tile then
                -- width = scaled width cut to whole pixels: the copies sit exactly side by side
                -- (no gap, and the overlap is under 1px, so nothing ends up drawn on top of the neighbor)
                local width = math.floor(getProperty(tag .. '.width'))
                if width > 0 then
                    local copies = math.ceil((1280 / bgMinZoom) / width) + 1   -- just enough to cover the view
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

-- Parallax: keeps the copies of each tiled layer covering the visible area, plus the automatic drift
local function updateBackgrounds(elapsed)
    local camX = getProperty('camGame.scroll.x')

    for i, layer in ipairs(bgLayers) do
        local st = bgState[i]
        if st then
            if layer.drift ~= 0 then
                st.offset = (st.offset + layer.drift * elapsed) % st.width
            end

            local base = layer.x + st.offset
            -- first copy: the last one that starts at or before the left edge of what this layer shows
            local firstX = math.floor((camX * st.scrollX - base) / st.width) * st.width + base
            for k, tag in ipairs(st.tags) do
                setProperty(tag .. '.x', math.floor(firstX + (k - 1) * st.width + 0.5))
            end
        end
    end
end

local function setCollisionsVisible(visible)
    collisionsVisible = visible
    local a = visible and 0.6 or 0
    for i = 1, 24 do
        if luaSpriteExists('col' .. i) then
            setProperty('col' .. i .. '.alpha', a)
        end
    end
    for i = 1, col17Segments do
        local tag = 'col17seg' .. string.format('%02d', i)
        if luaSpriteExists(tag) then
            setProperty(tag .. '.alpha', visible and 0.8 or 0)
        end
    end
    for i = 1, 32 do
        local tag = 'sonicLoopTrack' .. string.format('%02d', i)
        if luaSpriteExists(tag) then
            setProperty(tag .. '.alpha', visible and 0.8 or 0)
        end
    end
end

function onCreate()
    -- Backgrounds (added before everything, so they stay behind the scenery)
    createBackgrounds()

    -- Scenery (added first, so it stays behind the collisions and the loop)
    makeAnimatedLuaSprite(islandTag, islandImage, islandX, islandY)
    addAnimationByPrefix(islandTag, islandAnim, islandAnim, islandFps, true)
    playAnim(islandTag, islandAnim, true)
    addLuaSprite(islandTag, false)

    -- Main ground
    createCollision('col1', 10, 232, 552, 192, 'FF00FF', 0)

    -- Left and right limits
    createCollision('col2', 5, 0, 10, 256, '00FFFF', 0)
    createCollision('col3', 17230, 0, 10, 256, '00FFFF', 0)

    -- Uphill ramp
    if showCollisions then
        createCollision('col4', rampStartX, 112, 500, 33, '00FFFF', 0, -30)
    end

    -- Flat platform (loop entry/exit)
    createCollision('col5', rampEndX, 216, 342, 20, 'FF00FF', 1)

    -- col6: thin platform at the same height as col5
    createCollision('col6', 692, 242, 170, 20, 'FF00FF', 1)
    -- col7 / col8: the hill (physics ignores them inside the descent zone)
    createCollision('col7', 827, 182, 1000, 192, 'FF00FF', 0)
    createCollision('col8', 956, 155, 590, 256, '00FFFF', 0)

    -- Descent 1
    if showCollisions then
        createCollision('col9', descentCenterX - descentLen / 2, descentCenterY - descentThickness / 2,
            descentLen, descentThickness, '00FFFF', 0, descentAngle)
    end

    -- Ground between the first and second descent
    createCollision('col10', descentStartX + descentLength, descentEndY,
        descent2StartX - (descentStartX + descentLength), 192, 'FF00FF', 0)

    -- Descent 2
    if showCollisions then
        createCollision('col12', descent2CenterX - descent2Len / 2, descent2CenterY - descentThickness / 2,
            descent2Len, descentThickness, '00FFFF', 0, descent2Angle)
    end

    -- Ground between the second descent and the platform
    createCollision('col13', descent2StartX + descent2Length, descent2EndY,
        col14X - (descent2StartX + descent2Length), 192, 'FF00FF', 0)

    -- Platform
    createCollision('col14', col14X, col14Y, col14Width, 192, 'FF00FF', 0)

    -- Descent 3
    if showCollisions then
        createCollision('col15', descent3CenterX - descent3Len / 2, descent3CenterY - descentThickness / 2,
            descent3Len, descentThickness, '00FFFF', 0, descent3Angle)
    end

    -- Ground at the end of the third descent (fixed: same height as the end of the ramp)
    createCollision('col16', col16X, col16Y, 470, 192, 'FF00FF', 1)

    -- col17: curve (for now just makeGraphic; the physics lives in the Tails script)
    if showCollisions then
        createCurveTrack()
    end

    -- col18: flat platform at the top of the curve
    createCollision('col18', col18X, col18Y, 100, 192, 'FF00FF', 0)

    -- col19: flat platform after col18
    createCollision('col19', col19X, col19Y, col19Width, 192, 'FF00FF', 0)

    -- col20: flat platform after col19
    createCollision('col20', col20X, col20Y, 249, 192, 'FF00FF', 0)

    -- col21: short flat platform after col20
    createCollision('col21', col21X, col21Y, 80, 192, 'FF00FF', 0)

    -- col22: descent 4 (the physics lives in the Tails script, this is only the debug visual)
    if showCollisions then
        createCollision('col22', descent4CenterX - descent4Len / 2, descent4CenterY - descentThickness / 2,
            descent4Len, descentThickness, '00FFFF', 0, descent4Angle)
    end

    -- col23: flat platform at the end of descent 4
    createCollision('col23', col23X, col23Y, col23Width, 192, 'FF00FF', 0)

    -- Safety floor far below
    createCollision('col11', 0, 3000, 17240, 20, '00FFFF', 0)

    -- Wall (only col24 works as a pure wall in the physics)
    createCollision('col24', 9000, 0, 10, 256, '00FFFF', 0)

    -- Sonic 1 style loop visual
    if showCollisions then
        createVisibleLoopTrack()
    end
end

function onStartCountdown()
    if countdownBlocked then
        return Function_Stop
    end

    return Function_Continue
end

function onCreatePost()
    setProperty('dad.visible', true)
    setProperty('boyfriend.visible', false)

    setProperty('cameraSpeed', 120)

    setProperty('scoreTxt.alpha', 0)
    setProperty('botplayTxt.visible', false)

    setProperty('healthBar.alpha', 0)
    setProperty('healthBar.bg.alpha', 0)   -- Psych 1.0: healthBarBG became healthBar.bg

    setProperty('showRating', false)
    setProperty('showComboNum', false)

    setProperty('iconP1.alpha', 0)
    setProperty('iconP2.alpha', 0)

    setOnScripts('levelCamXLimitLeft', levelCamXLimitLeft)
    setOnScripts('levelCamXLimitRight', levelCamXLimitRight)

    runHaxeCode([[
        FlxG.worldBounds.set(0, -400, 17240, 3400);
        try { FlxG.camera.pixelPerfectRender = true; } catch (e:Dynamic) {}
    ]])

    playMusic('angelisland', 1, true)
end

function onUpdate(elapsed)
    updateBackgrounds(elapsed)

    -- F2: toggles the collision visualization
    if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.F2') then
        setCollisionsVisible(not collisionsVisible)
    end
end
