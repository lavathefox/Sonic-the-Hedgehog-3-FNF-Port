player = 'tails'
camerafollowplayer = true

-- hitbox related variables

hitboxheight = 30
hitboxwidth = 18

-- Speeds and gravity variables

Xspeed = 0
Yspeed = 0
accelerationspeed = 0.046875
decelerationspeed = 0.2
frictionspeed = 0.046875
topspeed = 6
topPOSspeed = 10

jumpforce = 6.5
airaccelerationspeed = 0.09375
gravityforce = 0.21875

spinrev = 0

rolldecelerationspeed = 0.125
rollfrictionspeed = 0.0234375

-- Checks variables

curstate = 'normal'	-- 'normal/roll'

isonground = false
isjumping = false
isidle = false
isrolling = false
isspindashing = false

islookingup = false
islookingdown = false

cangoidle = true
cantakeinputs = true
canmove = true
canjump = true
canroll = true

floorunder = false
wallonleft = false
wallonright = false
roofontop = false

-- Animation related variables

hasanimationsystem = true

idletimer = 0

pushframe = 0
walkframe = 0
runframe = 0
sprintframe = 0
rollframe = 0

curRunFrame = 0
curJumpFrame = 0
animTPIndice = 0

isskiddingright = false
isskiddingleft = false

FC1check = false
FC2check = false

-- other stuff

prejumptimer = 0

colalpha = 0
colnumber = 24   -- col1 to col24 (manual stage collisions)
hascollisionsystem = true
skidlimit = 4
hasgravity = true
canshield = true

-- Globals that are read below but were never initialised
isflying = false
flytimer = 0
isgliding = false
canglide = false
ishidden = false
toggledDebugMenu = false
camOffsetTimer = camOffsetTimer or 0

local rampStartX = 189
local rampEndX = 240
local platformEndX = 552

-- colN with N between wallOnlyFirst and wallOnlyLast works ONLY as a WALL. Currently: only col24
local wallOnlyFirst = 24
local wallOnlyLast = 24

-- Steps: on the ground, Tails climbs/descends height differences of up to N pixels without getting stuck or falling
local groundStepHeight = 14
local stepSpeedBonus = 0.5   -- extra step per px/frame of speed (0 = fixed step)
local function stepLimit()
	return groundStepHeight + math.abs(Xspeed) * stepSpeedBonus
end

local rampStartY = 232
local rampEndY = 215
local rampPlayerOffset = 48

-- Descent 1 (col9) -- SAME values as the stage script
local descentStartX = 1522
local descentLength = 154
local descentStartY = 148
local descentEndY = 180

-- Descent 2 (col12)
local descent2StartX = descentStartX + 194
local descent2Length = 154
local descent2StartY = descentEndY
local descent2EndY = 250

-- Platform (col14)
local col14X = 1980
local col14Y = 215

-- Descent 3 (col15)
local descent3StartX = 2051
local descent3Length = 119     -- SAME as the stage: ends at x=2170, at the top of col16
local descent3StartY = 212
local descent3EndY = 245       -- SAME as the stage (= col16Y)
local col14Width = descent3StartX - col14X

-- Descent 4 (col22) -- SAME values as the stage script
local descent4StartX = 3337
local descent4Length = 120
local descent4StartY = 176
local descent4EndY = 240

-- col17: quarter pipe style curve -- SAME values as the stage
local col16Y = 245
local col16Width = 460
local col17Radius = 117
local col17ArcDeg = 70
local col17X = 2547
local col17FloorY = col16Y
local col17CenterX = col17X
local col17CenterY = col17FloorY - col17Radius
local col17EndX = math.floor(col17X + col17Radius * math.sin(math.rad(col17ArcDeg)) + 0.5)
local col17EndY = math.floor(col17CenterY + col17Radius * math.cos(math.rad(col17ArcDeg)) + 0.5)

-- All ramps handled by the physics (their colN does NOT work as a rectangle)
local ramps = {
    {col = 4, x1 = rampStartX,    x2 = rampEndX,                      y1 = rampStartY,    y2 = rampEndY},
    -- beforeX / afterX: flat stretches before/after the ramp where the ramp also holds Tails
    -- ignoreCols: collisions DISABLED while Tails is inside the ramp zone
    {col = 9, x1 = descentStartX, x2 = descentStartX + descentLength, y1 = descentStartY, y2 = descentEndY,
        beforeX = descentStartX - 16, afterX = descent2StartX - 1,
        ignoreCols = {7, 8}},
    {col = 12, x1 = descent2StartX, x2 = descent2StartX + descent2Length, y1 = descent2StartY, y2 = descent2EndY,
        afterX = col14X - 1, zoneEndX = descent3StartX - 1,
        ignoreCols = {7, 8, 10}},
    {col = 15, x1 = descent3StartX, x2 = descent3StartX + descent3Length, y1 = descent3StartY, y2 = descent3EndY,
        beforeX = descent3StartX - 16, afterX = descent3StartX + descent3Length + 4,   -- after that, col16 holds him
        ignoreCols = {}},
    -- Curve (col17): curve = true uses the circle formula instead of a straight line. After it, col18 holds him
    {col = 17, x1 = col17X, x2 = col17EndX, y1 = col17FloorY, y2 = col17EndY, curve = true,
        afterX = col17EndX + 4, ignoreCols = {}},
    -- Descent 4 (col22): after it, col23 takes over as the floor
    {col = 22, x1 = descent4StartX, x2 = descent4StartX + descent4Length, y1 = descent4StartY, y2 = descent4EndY,
        beforeX = descent4StartX - 16, afterX = descent4StartX + descent4Length + 4,
        ignoreCols = {}},
}

local zoneFootX = 0

local function isIgnoredByRamp(i)
    for _, r in ipairs(ramps) do
        if r.ignoreCols and zoneFootX >= r.x1 - 8 and zoneFootX <= (r.zoneEndX or r.afterX) then
            for _, c in ipairs(r.ignoreCols) do
                if c == i then
                    return true
                end
            end
        end
    end
    return false
end

local function isRampCol(i)
    for _, r in ipairs(ramps) do
        if r.col == i then
            return true
        end
    end
    return false
end

-- Sonic 1-style loop
local sonicLoopCenterX = 1666
local sonicLoopGroundY = 179
local sonicLoopScale = 0.497        -- SAME value as the stage
local sonicLoopRadius = 200 * sonicLoopScale
local sonicLoopBodyOffset = 24
local sonicLoopMinimumSpeed = 4
local sonicLoopFallSpeed = 2.5
local sonicLoopSlopeFactor = 0.035
local sonicLoopLockFrames = 30
local sonicLoopLockTimer = 0
local sonicLoopTopLaunch = true
local sonicLoopTopZone = 40
local sonicLoopTopHop = 6.5
local sonicLoopTopExitSpeed = 10
local sonicLoopActive = false
local sonicLoopDir = 1
local sonicLoopPrevX = 0
local sonicLoopAngle = 0
local sonicLoopSpeed = 0
local tailsRollAngle = 0
local tailsRollRotationSpeed = 3.6

local function signum(number)
	if number > 0 then
		return 1
	elseif number < 0 then
		return -1
	else
		return 0
	end
end

local function isWallOnly(i)
	return i >= wallOnlyFirst and i <= wallOnlyLast
end

-- colN may not exist (e.g. col17 to col23); skip the missing ones
local colExistsCache = {}
local function colExists(i)
	if colExistsCache[i] == nil then
		colExistsCache[i] = luaSpriteExists('col'..i)
	end
	return colExistsCache[i] and not isIgnoredByRamp(i)
end

-- Collisions never move: the geometry is read once and cached
local colGeomCache = {}
local function colGeom(i)
	local g = colGeomCache[i]
	if g == nil then
		local col = 'col'..i
		g = {x = getProperty(col..'.x'), y = getProperty(col..'.y'),
			w = getProperty(col..'.width'), h = getProperty(col..'.height')}
		colGeomCache[i] = g
	end
	return g
end

local nearX = 0
local nearY = 0
local nearMargin = 64

local function colActive(i)
	if not colExists(i) then
		return false
	end
	local g = colGeom(i)
	return nearX + hitboxwidth + nearMargin >= g.x and nearX - nearMargin <= g.x + g.w
		and nearY + hitboxheight + nearMargin >= g.y and nearY - nearMargin <= g.y + g.h
end

local activeList = {}

-- Builds the list of collisions near Tails
local function buildActiveList()
	activeList = {}
	for i = 1, colnumber do
		if colActive(i) then
			activeList[#activeList + 1] = i
		end
	end
end

function round(num)
    return math.floor(num + 0.5)
end

function onCreate()
	setOnScripts('camPlayerName', player)

	makeAnimatedLuaSprite(player, 'characters/NewBoyfriendSheet', 111, 100)

	addAnimationByPrefix(player, 'idle', 'idle0000', 1, false)

	addAnimationByPrefix(player, 'idleloop2', 'idleloopA', 8, false)
	addAnimationByPrefix(player, 'idleloop1', 'idleloop0', 8, true)

	addAnimationByPrefix(player, 'up', 'up', 10, false)
	addAnimationByPrefix(player, 'down', 'down', 10, false)

	addAnimationByPrefix(player, 'walk', 'walk', 12, true)
	addAnimationByIndices(player, 'walk1', 'walk', {0})
	addAnimationByIndices(player, 'walk2', 'walk', {1})
	addAnimationByIndices(player, 'walk3', 'walk', {2})
	addAnimationByIndices(player, 'walk4', 'walk', {3})
	addAnimationByIndices(player, 'walk5', 'walk', {4})
	addAnimationByIndices(player, 'walk6', 'walk', {5})
	addAnimationByIndices(player, 'walk7', 'walk', {6})
	addAnimationByIndices(player, 'walk8', 'walk', {7})

	addAnimationByIndices(player, 'run1', 'run', {0})
	addAnimationByIndices(player, 'run2', 'run', {1})
	addAnimationByIndices(player, 'run3', 'run', {2})
	addAnimationByIndices(player, 'run4', 'run', {3})

	addAnimationByPrefix(player, 'skidding', 'skid', 18, false)

	addAnimationByPrefix(player, 'balanceR', 'balanceR', 10, true)
	addAnimationByPrefix(player, 'balanceL', 'balanceL', 10, true)

	addAnimationByIndices(player, 'jump1', 'jump', {0})
	addAnimationByIndices(player, 'jump2', 'jump', {1})
	addAnimationByIndices(player, 'jump3', 'jump', {2})
	addAnimationByIndices(player, 'jump4', 'jump', {3})
	addAnimationByIndices(player, 'jump5', 'jump', {4})

	addAnimationByPrefix(player, 'spindash', 'spindash', 32, true)

	addAnimationByPrefix(player, 'push', 'push', 4, true)

	addAnimationByPrefix(player, 'dies', 'dies', 1, false)

	addLuaSprite(player)

	makeLuaSprite(player..'mainhitbox', '', getMidpointX(player)-hitboxwidth+(hitboxwidth/2), getMidpointY(player)-(hitboxheight/2)+9)
	makeGraphic(player..'mainhitbox', hitboxwidth, hitboxheight, 'FFFF84')
	setProperty(player..'mainhitbox.alpha', colalpha)
	addLuaSprite(player..'mainhitbox', true)

	makeLuaSprite(player..'wallleftoverhitbox', '', getProperty(player..'mainhitbox.x')+hitboxwidth, getProperty(player..'mainhitbox.y'))
	makeGraphic(player..'wallleftoverhitbox', 1, hitboxheight-0.5, 'C61AFF')
	setProperty(player..'wallleftoverhitbox.alpha', colalpha)
	addLuaSprite(player..'wallleftoverhitbox', true)

	makeLuaSprite(player..'wallrightoverhitbox', '', getProperty(player..'mainhitbox.x')-1, getProperty(player..'mainhitbox.y'))
	makeGraphic(player..'wallrightoverhitbox', 1,hitboxheight-0.5, '00D9FF')
	setProperty(player..'wallrightoverhitbox.alpha', colalpha)
	addLuaSprite(player..'wallrightoverhitbox', true)

	makeLuaSprite(player..'flooroverhitbox', '', getProperty(player..'mainhitbox.x')-1, getProperty(player..'mainhitbox.y')+hitboxheight-1)
	makeGraphic(player..'flooroverhitbox', hitboxwidth, 1, 'FFD900')
	setProperty(player..'flooroverhitbox.alpha', colalpha)
	addLuaSprite(player..'flooroverhitbox', true)

	makeLuaSprite(player..'roofoverhitbox', '', getProperty(player..'mainhitbox.x'), getProperty(player..'mainhitbox.y')-1)
	makeGraphic(player..'roofoverhitbox', hitboxwidth, 1, 'FF0000')
	setProperty(player..'roofoverhitbox.alpha', colalpha)
	addLuaSprite(player..'roofoverhitbox', true)

	makeLuaSprite(player..'floorchecker', '', getProperty(player..'mainhitbox.x'), getProperty(player..'mainhitbox.y')+hitboxheight-1)
	makeGraphic(player..'floorchecker', hitboxwidth, 1, '1500FF')
	setProperty(player..'floorchecker.alpha', colalpha)
	addLuaSprite(player..'floorchecker', true)

	makeLuaSprite(player..'floorchecker1', '', getProperty(player..'mainhitbox.x'), getProperty(player..'mainhitbox.y')+hitboxheight-1)
	makeGraphic(player..'floorchecker1', 1, 1, 'FFFFFF')
	setProperty(player..'floorchecker1.alpha', colalpha)
	addLuaSprite(player..'floorchecker1', true)

	makeLuaSprite(player..'floorchecker2', '', getProperty(player..'mainhitbox.x')+hitboxwidth-1, getProperty(player..'mainhitbox.y')+hitboxheight-1)
	makeGraphic(player..'floorchecker2', 1, 1, 'FFFFFF')
	setProperty(player..'floorchecker2.alpha', colalpha)
	addLuaSprite(player..'floorchecker2', true)

end

local function containsTag(tbl, tag)
	for _, v in ipairs(tbl) do
		if v == tag then
			return true
		end
	end
	return false
end


local function updateTailsHitboxes()
    setProperty(player..'mainhitbox.x', getMidpointX(player)-hitboxwidth+(hitboxwidth/2))
    setProperty(player..'mainhitbox.y', getMidpointY(player)-(hitboxheight/2)+9)

    setProperty(player..'wallrightoverhitbox.x', getProperty(player..'mainhitbox.x')+hitboxwidth+Xspeed)
    setProperty(player..'wallrightoverhitbox.y', getProperty(player..'mainhitbox.y'))

    setProperty(player..'wallleftoverhitbox.x', getProperty(player..'mainhitbox.x')-1+Xspeed)
    setProperty(player..'wallleftoverhitbox.y', getProperty(player..'mainhitbox.y'))

    setProperty(player..'flooroverhitbox.x', getProperty(player..'mainhitbox.x'))
    setProperty(player..'flooroverhitbox.y', getProperty(player..'mainhitbox.y')+hitboxheight-1+Yspeed)

    setProperty(player..'roofoverhitbox.x', getProperty(player..'mainhitbox.x'))
    setProperty(player..'roofoverhitbox.y', getProperty(player..'mainhitbox.y')-1+Yspeed)

    setProperty(player..'floorchecker.x', getProperty(player..'mainhitbox.x'))
    setProperty(player..'floorchecker.y', getProperty(player..'mainhitbox.y')+hitboxheight)

    setProperty(player..'floorchecker1.x', getProperty(player..'mainhitbox.x'))
    setProperty(player..'floorchecker1.y', getProperty(player..'mainhitbox.y')+hitboxheight)

    setProperty(player..'floorchecker2.x', getProperty(player..'mainhitbox.x')+hitboxwidth-1)
    setProperty(player..'floorchecker2.y', getProperty(player..'mainhitbox.y')+hitboxheight)
end

local function getRampY(worldX, r)
    if r.curve then
        local dx = math.max(0, math.min(worldX - col17CenterX, col17Radius))
        return col17CenterY + math.sqrt(col17Radius * col17Radius - dx * dx)
    end
    local progress = (worldX-r.x1)/(r.x2-r.x1)
    return r.y1+(r.y2-r.y1)*progress
end

local function resolveRamp()
    local hitboxX = getProperty(player..'mainhitbox.x')
    local hitboxBottom = getProperty(player..'mainhitbox.y')+hitboxheight
    local footX = hitboxX+(hitboxwidth/2)

    for _, r in ipairs(ramps) do
        local surfaceY = nil
        local upWindow = 24

        if footX >= r.x1 and footX <= r.x2 then
            surfaceY = getRampY(footX, r)
        elseif r.beforeX and footX >= r.beforeX and footX < r.x1 then
            surfaceY = r.y1
            upWindow = 20
        elseif r.afterX and footX > r.x2 and footX <= r.afterX then
            surfaceY = r.y2
            upWindow = 20
        end

        if surfaceY ~= nil then
            if Yspeed >= 0 and hitboxBottom >= surfaceY-upWindow and hitboxBottom <= surfaceY+32 then
                setProperty(player..'.y', surfaceY-rampPlayerOffset)

                Yspeed = 0
                isonground = true
                isjumping = false
                isflying = false
                flytimer = 0

                stopSound('tailsfly')
                stopSound('tailsflytired')

                return true
            end
        end
    end

    return false
end

local function resolveRampExit()
    local footX = getProperty(player..'mainhitbox.x') + hitboxwidth / 2
    local hitboxBottom = getProperty(player..'mainhitbox.y') + hitboxheight

    if footX >= rampEndX and footX <= platformEndX then
        local platformY = rampEndY

        if Yspeed >= 0 and hitboxBottom >= platformY - 20 and hitboxBottom <= platformY + 32 then
            setProperty(player..'.y', platformY - rampPlayerOffset)

            Yspeed = 0
            isonground = true
            isjumping = false
            isflying = false
            flytimer = 0

            FC1check = true
            FC2check = true

            return true
        end
    end

    return false
end

local function placeTailsOnLoop()
    local a = sonicLoopAngle
    local r = sonicLoopRadius - sonicLoopBodyOffset

    local centerX = sonicLoopCenterX + math.sin(a) * r
    local centerY = (sonicLoopGroundY - sonicLoopRadius) + math.cos(a) * r

    setProperty(player..'.x', centerX - getProperty(player..'.width') / 2)
    setProperty(player..'.y', centerY - getProperty(player..'.height') / 2)

    Xspeed = sonicLoopSpeed * math.cos(a)
    Yspeed = -sonicLoopSpeed * math.sin(a)
end

local function detachFromLoop()
    Xspeed = sonicLoopSpeed * math.cos(sonicLoopAngle)
    Yspeed = -sonicLoopSpeed * math.sin(sonicLoopAngle)

    sonicLoopActive = false
    sonicLoopAngle = 0
    isonground = false
    isjumping = false
    FC1check = false
    FC2check = false

    tailsRollAngle = 0
    setProperty(player..'.angle', 0)

    cantakeinputs = false
    sonicLoopLockTimer = sonicLoopLockFrames
end

local function jumpFromLoop()
    local a = sonicLoopAngle
    local sinA = math.sin(a)
    local cosA = math.cos(a)

    Xspeed = sonicLoopSpeed * cosA - jumpforce * sinA
    Yspeed = -sonicLoopSpeed * sinA - jumpforce * cosA

    sonicLoopActive = false
    sonicLoopAngle = 0
    isonground = false
    isjumping = true
    isskiddingleft = false
    isskiddingright = false
    FC1check = false
    FC2check = false

    if curstate == 'roll' then
        curstate = 'normal'
    end

    tailsRollAngle = 0
    setProperty(player..'.angle', 0)

    playSound('jump', 1, 'tailsjump')
end

local function exitLoopToGround()
    sonicLoopActive = false
    sonicLoopAngle = 0
    sonicLoopPrevX = sonicLoopCenterX

    setProperty(player..'.x', sonicLoopCenterX - getProperty(player..'.width') / 2)
    setProperty(player..'.y', sonicLoopGroundY - rampPlayerOffset)
    tailsRollAngle = 0
    setProperty(player..'.angle', 0)

    Xspeed = sonicLoopSpeed
    Yspeed = 0
    isonground = true
    isjumping = false
    isflying = false
    FC1check = true
    FC2check = true
end

local function launchFromLoopTop()
    placeTailsOnLoop()

    sonicLoopActive = false
    sonicLoopAngle = 0
    sonicLoopPrevX = getMidpointX(player)

    Xspeed = sonicLoopDir * math.max(sonicLoopTopExitSpeed, math.abs(sonicLoopSpeed))
    Yspeed = sonicLoopTopHop

    isonground = false
    isjumping = false
    isflying = false
    FC1check = false
    FC2check = false
    curstate = 'roll'

    tailsRollAngle = 0
    setProperty(player..'.angle', 0)

    playSound('jump', 1, 'tailsjump')
end

local function updateSonicLoop(elapsed)
    if not sonicLoopActive then
        return
    end

    local frameScale = 1
    if elapsed ~= nil and elapsed > 0 then
        frameScale = elapsed * 60
    end

    local sinA = math.sin(sonicLoopAngle)
    local cosA = math.cos(sonicLoopAngle)

    if cosA > -0.7071 then
        sonicLoopSpeed = sonicLoopSpeed - sonicLoopSlopeFactor * sinA * frameScale
    end

    if cosA < 0.7071 and math.abs(sonicLoopSpeed) < sonicLoopFallSpeed then
        detachFromLoop()
        return
    end

    local nextAngle = sonicLoopAngle + (sonicLoopSpeed / sonicLoopRadius) * frameScale

    local progress = nextAngle * sonicLoopDir
    if progress >= math.pi * 2 or progress <= 0 then
        exitLoopToGround()
        return
    end

    sonicLoopAngle = nextAngle

    wallonleft = false
    wallonright = false
    isonground = false
    isjumping = false
    isflying = false
    FC1check = false
    FC2check = false

    placeTailsOnLoop()
end

function onUpdate(elapsed)

    -- Input lock after falling off the loop
    if sonicLoopLockTimer > 0 then
        sonicLoopLockTimer = sonicLoopLockTimer - 1
        if sonicLoopLockTimer == 0 then
            cantakeinputs = true
        end
    end

    -- Inside the loop: the path replaces gravity and collisions, but the animation keeps running
    if sonicLoopActive then
        if cantakeinputs and getPropertyFromClass('flixel.FlxG', 'keys.justPressed.SPACE') then
            local distFromTop = math.abs(sonicLoopAngle * sonicLoopDir - math.pi)
            if sonicLoopTopLaunch and distFromTop <= math.rad(sonicLoopTopZone) then
                launchFromLoopTop()
            else
                jumpFromLoop()
            end
        else
            updateSonicLoop(elapsed)
        end
        updateTailsHitboxes()
        if sonicLoopActive then
            goto tailsAnimation
        end
    end

    -- Loop entrance (the do...end is required because of the goto)
    do
        local loopCheckX = getMidpointX(player)
        local loopAtGround = math.abs(getProperty(player..'.y') - (sonicLoopGroundY - rampPlayerOffset)) <= 18
        local enterDir = 0

        if isonground and loopAtGround then
            if sonicLoopPrevX < sonicLoopCenterX and loopCheckX >= sonicLoopCenterX
                and Xspeed >= sonicLoopMinimumSpeed then
                enterDir = 1
            elseif sonicLoopPrevX > sonicLoopCenterX and loopCheckX <= sonicLoopCenterX
                and Xspeed <= -sonicLoopMinimumSpeed then
                enterDir = -1
            end
        end

        sonicLoopPrevX = loopCheckX

        if enterDir ~= 0 then
            sonicLoopActive = true
            sonicLoopDir = enterDir
            sonicLoopSpeed = Xspeed

            local ratio = (loopCheckX - sonicLoopCenterX) / sonicLoopRadius
            sonicLoopAngle = math.asin(math.max(-1, math.min(1, ratio)))

            updateSonicLoop(elapsed)
            updateTailsHitboxes()
            goto tailsAnimation
        end
    end

	updateTailsHitboxes()

	if hascollisionsystem then
	    local wasOnGround = isonground
	    local stepBestY = nil
	    local stepBestDist = nil
	    isonground = false
	    wallonleft = false
	    wallonright = false
	    FC1check = false
	    FC2check = false

	    nearX = getProperty(player..'mainhitbox.x')
	    nearY = getProperty(player..'mainhitbox.y')
	    zoneFootX = nearX + hitboxwidth / 2

	    -- List of collisions near Tails
	    buildActiveList()

	    -- Ramp collision
	    resolveRamp()
	    resolveRampExit()

	    -- Normal floor and ceiling collisions
	    local hitboxX = nearX
	    local hitboxY = nearY
	    local hitboxBottom = hitboxY+hitboxheight

	    for _, i in ipairs(activeList) do
	        if not isRampCol(i) and not isWallOnly(i) then
	            local col = 'col'..i
	            local g = colGeom(i)
	            local colX = g.x
	            local colY = g.y
	            local colWidth = g.w
	            local colHeight = g.h

	            local horizontalOverlap = hitboxX+hitboxwidth > colX and hitboxX < colX+colWidth

	            -- Landing on top of a platform
	            if horizontalOverlap and Yspeed >= 0 and hitboxBottom <= colY+math.max(Yspeed, 1) and hitboxBottom+math.max(Yspeed, 1) >= colY then
	                setProperty(player..'.y', colY-48)
	                Yspeed = 0
	                isonground = true
	                isjumping = false
	                isflying = false
	                flytimer = 0

	                stopSound('tailsfly')
	                stopSound('tailsflytired')
	            end

	            -- Step: stuck to the ground, follows platforms up to stepLimit() higher or lower
	            if wasOnGround and not isjumping and Yspeed >= 0 and horizontalOverlap then
	                local d = colY-hitboxBottom
	                if d >= -stepLimit() and d <= stepLimit() then
	                    if stepBestDist == nil or math.abs(d) < stepBestDist then
	                        stepBestDist = math.abs(d)
	                        stepBestY = colY
	                    end
	                end
	            end

	            -- Ceiling collision
	            if objectsOverlap(player..'roofoverhitbox', col) and Yspeed < 0 then
	                Yspeed = 0
	                setProperty(player..'.y', colY+colHeight-18)
	            end
	        end
	    end

	    -- Apply the closest step
	    if stepBestY ~= nil then
	        setProperty(player..'.y', stepBestY-48)
	        Yspeed = 0
	        isonground = true
	    end

	    -- Ramp floor checkers
	    local leftFootX = getProperty(player..'floorchecker1.x')
	    local rightFootX = getProperty(player..'floorchecker2.x')
	    local currentBottom = getProperty(player..'mainhitbox.y')+hitboxheight

	    for _, r in ipairs(ramps) do
	        if leftFootX >= r.x1 and leftFootX <= r.x2 then
	            if math.abs(currentBottom-getRampY(leftFootX, r)) <= 18 then
	                FC1check = true
	            end
	        end

	        if rightFootX >= r.x1 and rightFootX <= r.x2 then
	            if math.abs(currentBottom-getRampY(rightFootX, r)) <= 18 then
	                FC2check = true
	            end
	        end
	    end

	    -- Wall collision on the left
	    for _, i in ipairs(activeList) do
	        if not isRampCol(i) then
	            local col = 'col'..i

	            if objectsOverlap(player..'wallleftoverhitbox', col) then
	                local leftBottom = getProperty(player..'mainhitbox.y')+hitboxheight
	                local leftTop = getProperty(col..'.y')
	                local leftStepUp = wasOnGround and not isWallOnly(i) and (leftBottom-leftTop) <= stepLimit()
	                if Xspeed < 0 and not leftStepUp then
	                    Xspeed = 0
	                    setProperty(player..'.x', getProperty(col..'.x')+getProperty(col..'.width')-15)
	                    wallonleft = true
	                    break
	                end
	            end
	        end
	    end

		-- Wall collision on the right
		for _, i in ipairs(activeList) do
		    if not isRampCol(i) then
		        local col = 'col'..i

		        if objectsOverlap(player..'wallrightoverhitbox', col) then
		            local playerBottom = getProperty(player..'mainhitbox.y')+hitboxheight
		            local platformTop = getProperty(col..'.y')

		            -- Don't treat the top of col5 and col6 (straight platforms) as a wall
		            local rightStepUp = wasOnGround and not isWallOnly(i) and (playerBottom-platformTop) <= stepLimit()
		            if ((i ~= 5 and i ~= 6) or playerBottom > platformTop+6) and not rightStepUp then
		                if Xspeed > 0 then
		                    Xspeed = 0
		                    setProperty(player..'.x', getProperty(col..'.x')-hitboxwidth-15)
		                    wallonright = true
		                    break
		                end
		            end
		        end
		    end
		end

	    -- Floor checkers for normal platforms (one pass over the collisions)
	    local fcGround, fcLeft, fcRight = false, false, false
	    for _, i in ipairs(activeList) do
	        if not isRampCol(i) and not isWallOnly(i) then
	            local col = 'col'..i

	            if not fcGround and objectsOverlap(player..'floorchecker', col) then
	                fcGround = true
	            end
	            if not fcLeft and objectsOverlap(player..'floorchecker1', col) then
	                fcLeft = true
	            end
	            if not fcRight and objectsOverlap(player..'floorchecker2', col) then
	                fcRight = true
	            end

	            if fcGround and fcLeft and fcRight then
	                break
	            end
	        end
	    end
	    if fcGround then isonground = true end
	    if fcLeft then FC1check = true end
	    if fcRight then FC2check = true end

	    -- Keep the ramp ground state
	    if resolveRamp() then
	        FC1check = true
	        FC2check = true
	    end
	end


	if canmove == true then
		setProperty(player..'.x', getProperty(player..'.x')+Xspeed)
		setProperty(player..'mainhitbox.x', getMidpointX(player)-hitboxwidth+(hitboxwidth/2))
		--  Gravity
		setProperty(player..'.y', getProperty(player..'.y')+Yspeed)
	end



	-- running
	if cantakeinputs == true then
		if curstate == 'normal' then
			if getPropertyFromClass('flixel.FlxG', 'keys.pressed.LEFT') then
				if Xspeed <= 0 and Xspeed >= -topspeed then
					Xspeed = Xspeed - accelerationspeed
				elseif Xspeed > 0 then
					Xspeed = Xspeed - decelerationspeed
					if Xspeed < 0 then
						Xspeed = 0.2
					end
				end
			end
			if getPropertyFromClass('flixel.FlxG', 'keys.pressed.RIGHT') then
				if Xspeed >= 0 and Xspeed <= topspeed then
					Xspeed = Xspeed + accelerationspeed
				elseif Xspeed < 0 then
					Xspeed = Xspeed + decelerationspeed
					if Xspeed > 0 then
						Xspeed = -0.2
					end
				end
			end
		elseif curstate == 'roll' then
			if getPropertyFromClass('flixel.FlxG', 'keys.pressed.LEFT') then
				if Xspeed > 0 then
					Xspeed = Xspeed - rolldecelerationspeed
				end
			elseif getPropertyFromClass('flixel.FlxG', 'keys.pressed.RIGHT') then
				if Xspeed < 0 then
					Xspeed = Xspeed + rolldecelerationspeed
				end
			end
		end

		if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.DOWN') then -- cancel fly
			if isonground == false and isflying then
				isflying = false
				isjumping = true
			elseif isonground and math.abs(Xspeed) > 1 and canroll then
				if curstate == 'normal' then
					playSound('roll', 1, 'roll')
				end
				curstate = 'roll'
			end
		end

		if getPropertyFromClass('flixel.FlxG', 'keys.pressed.UP') then
			if isonground and Xspeed == 0 and Yspeed == 0 then
				islookingup = true
				islookingdown = false
				if idletimer > 0 then
					idletimer = 0
				end

				if camOffsetTimer < 60 then
					camOffsetTimer = camOffsetTimer + 1
				end

			end
		elseif islookingup == true and not getPropertyFromClass('flixel.FlxG', 'keys.pressed.UP') then
			islookingup = false
		end
		if getPropertyFromClass('flixel.FlxG', 'keys.pressed.DOWN') then
			if isonground and Xspeed == 0 and Yspeed == 0 then
				islookingdown = true
				islookingup = false
				if idletimer > 0 then
					idletimer = 0
				end

				if camOffsetTimer < 60 and not ishidden then
					camOffsetTimer = camOffsetTimer + 1
				end
			end
		elseif islookingdown == true and not getPropertyFromClass('flixel.FlxG', 'keys.pressed.DOWN') then
			islookingdown = false
		end

		if getPropertyFromClass('flixel.FlxG', 'keys.justReleased.DOWN') or getPropertyFromClass('flixel.FlxG', 'keys.justReleased.UP') or Xspeed ~= 0 or isspindashing then
			camOffsetTimer = 0
		end

		if getPropertyFromClass('flixel.FlxG', 'keys.pressed.DOWN') and getPropertyFromClass('flixel.FlxG', 'keys.justPressed.SPACE') and isspindashing == false and Xspeed == 0 and isonground then
			isspindashing = true
		end

		if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.SPACE') then
			if isonground == true and canjump and not getPropertyFromClass('flixel.FlxG', 'keys.pressed.DOWN') and not isgliding then 	-- basic jumping
				Yspeed = -jumpforce
				isjumping = true
				isskiddingright = false
				isskiddingleft = false

				if not isspindashing then
					playSound('jump', 1, 'tailsjump')
				end
				if curstate == 'roll' then
					curstate = 'normal'
				end
				setProperty(player..'.y', getProperty(player..'.y')+Yspeed)
			elseif not isonground and canshield and isjumping then
				canshield = false
				makeAnimatedLuaSprite('instashield', 'instashield', getProperty(player..'.x'), getProperty(player..'.y'))
				addAnimationByPrefix('instashield', 'instashield', 'instashield', 34, false)
				addLuaSprite('instashield')
				setObjectOrder('instashield', getObjectOrder(player)+1)
				playSound('instashield')
			end
		end
	end

	if luaSpriteExists('instashield') then
		setProperty('instashield.x', getProperty(player..'.x'))
		setProperty('instashield.y', getProperty(player..'.y')+9)
		if getProperty(player..'.flipX') then
			setProperty('instashield.flipX', true)
		else
			setProperty('instashield.flipX', false)
		end
		if getProperty('instashield.animation.curAnim.finished') then
			removeLuaSprite('instashield')
		end
	end
	if not canshield and isonground then
		canshield = true
	end

	if canmove == true then

		if curstate == 'normal' then
			if not getPropertyFromClass('flixel.FlxG', 'keys.pressed.RIGHT') and not getPropertyFromClass('flixel.FlxG', 'keys.pressed.LEFT') and cantakeinputs then
				Xspeed = Xspeed - math.min(math.abs(Xspeed), frictionspeed) * signum(Xspeed)
			end
		elseif curstate == 'roll' then
			Xspeed = Xspeed - math.min(math.abs(Xspeed), rollfrictionspeed) * signum(Xspeed)
			if Xspeed == 0 and isonground then
				curstate = 'normal'
			end
		end
		-- Gravity

		if hasgravity then
			if Yspeed < 0 and Yspeed > -4 then
				Xspeed = Xspeed - ((math.floor(Xspeed / 0.125)) / 256)
			end
			if curstate == 'glide' then
				curstate = 'normal'
			end

			Yspeed = Yspeed + gravityforce
			if Yspeed > 16 then
				Yspeed = 16
			end
			if Yspeed > 0 and isonground then
				Yspeed = 0
				canglide = true
			end
		end

		-- Jump hold
		if isjumping == true and not getPropertyFromClass('flixel.FlxG', 'keys.pressed.SPACE') and Yspeed < -4 then
			Yspeed = -4
		end

	end

	::tailsAnimation::

	-- Inside the loop, animations use the ground speed, not the X component
	local realXspeed = Xspeed
	if sonicLoopActive then
		Xspeed = sonicLoopSpeed
	end

	-- Animation system

	curAnim = getProperty(player..'.animation.curAnim.name')

	if hasanimationsystem then
		if Xspeed == 0 and Yspeed == 0 and not isflying and not isjumping and not isspindashing and FC1check and FC2check and cangoidle and not islookingup and not islookingdown then
			if curAnim ~= 'idle' and idletimer < 60 and idletimer > 0 then
				playAnim(player, 'idle')
				animTPIndice = 0
				if curstate == 'roll' then
					curstate = 'normal'
				end
			end
			if idletimer < 260 then
				idletimer = idletimer+1
			end
			if idletimer == 240 then
				playAnim(player, 'idleloop2', false)
			elseif idletimer == 260 then
				playAnim(player, 'idleloop1', false)
			end
		elseif not FC1check and FC2check and Xspeed == 0 or not FC2check and FC1check and Xspeed == 0 and not isspindashing and not getPropertyFromClass('flixel.FlxG', 'keys.pressed.DOWN') then
			if FC1check == true and FC2check == false and not isspindashing and not islookingdown and not islookingup then
				if getProperty(player..'.flipX') then
					playAnim(player, 'balanceR')
				elseif not getProperty(player..'.flipX') then
					playAnim(player, 'balanceL')
				end
			elseif FC1check == false and FC2check == true and not isspindashing and not islookingdown and not islookingup then
				if getProperty(player..'.flipX') then
					playAnim(player, 'balanceL')
				elseif not getProperty(player..'.flipX') then
					playAnim(player, 'balanceR')
				end
			end
		else
			if idletimer ~= 0 then
				idletimer = 0
			end
		end

		if islookingdown == true and not isjumping and not isflying and not isspindashing and getProperty(player..'.animation.curAnim.name') ~= 'down' then
			playAnim(player, 'down', true)
		elseif islookingup == true and not isjumping and not isflying and getProperty(player..'.animation.curAnim.name') ~= 'up' then
			playAnim(player, 'up', false)
		end

		if Xspeed ~= 0 and isjumping == false and not wallonleft and not wallonright and not isflying and not isspindashing and curstate == 'normal' then
			curRunFrame = curRunFrame+0.9
			if curRunFrame > math.max(0, 8-math.abs(Xspeed)) then
				curRunFrame = 0
				animTPIndice = animTPIndice + 1
				if math.abs(Xspeed) < 6 then
					if animTPIndice >= 8 then
						animTPIndice = 0
					end
				elseif math.abs(Xspeed) >= 6 then
					if animTPIndice >= 4 then
						animTPIndice = 0
					end
				end
			end
			if math.abs(Xspeed) < 6 then
				if animTPIndice == 0 then
					playAnim(player, 'walk1')
				elseif animTPIndice == 1 then
					playAnim(player, 'walk2')
				elseif animTPIndice == 2 then
					playAnim(player, 'walk3')
				elseif animTPIndice == 3 then
					playAnim(player, 'walk4')
				elseif animTPIndice == 4 then
					playAnim(player, 'walk5')
				elseif animTPIndice == 5 then
					playAnim(player, 'walk6')
				elseif animTPIndice == 6 then
					playAnim(player, 'walk7')
				elseif animTPIndice == 7 then
					playAnim(player, 'walk8')
				end
			elseif math.abs(Xspeed) >= 6 then
				if animTPIndice == 0 then
					playAnim(player, 'run1')
				elseif animTPIndice == 1 then
					playAnim(player, 'run2')
				elseif animTPIndice == 2 then
					playAnim(player, 'run3')
				elseif animTPIndice == 3 then
					playAnim(player, 'run4')
				end
			end
		end

		-- Pushing
		if wallonleft and getPropertyFromClass('flixel.FlxG', 'keys.pressed.LEFT') and isonground or wallonright and getPropertyFromClass('flixel.FlxG', 'keys.pressed.RIGHT') and isonground then
			playAnim(player, 'push')
		end

		-- jumping
		if isjumping == true and not isflying and not isspindashing or curstate == 'roll' and Xspeed ~= 0 or curstate == 'roll' then
			curJumpFrame = curJumpFrame+1
			if math.abs(Xspeed) < 3 then
				if curJumpFrame > math.max(0, 5-math.abs(Xspeed)) then
					curJumpFrame = 0
					animTPIndice = animTPIndice + 1
					if animTPIndice >= 5 then
						animTPIndice = 0
					end
				end
				if animTPIndice == 0 then
					playAnim(player, 'jump1')
				elseif animTPIndice == 1 then
					playAnim(player, 'jump2')
				elseif animTPIndice == 2 then
					playAnim(player, 'jump3')
				elseif animTPIndice == 3 then
					playAnim(player, 'jump4')
				elseif animTPIndice == 4 then
					playAnim(player, 'jump5')
				end
			elseif math.abs(Xspeed) >= 3 then
				if curJumpFrame > math.max(0, 5-math.abs(Xspeed)) then
					curJumpFrame = 0
					animTPIndice = animTPIndice + 1
					if animTPIndice >= 8 then
						animTPIndice = 0
					end
				end
				if animTPIndice == 0 then
					playAnim(player, 'jump5')
				elseif animTPIndice == 1 then
					playAnim(player, 'jump1')
				elseif animTPIndice == 2 then
					playAnim(player, 'jump2')
				elseif animTPIndice == 3 then
					playAnim(player, 'jump5')
				elseif animTPIndice == 4 then
					playAnim(player, 'jump3')
				elseif animTPIndice == 5 then
					playAnim(player, 'jump5')
				elseif animTPIndice == 6 then
					playAnim(player, 'jump4')
				elseif animTPIndice == 7 then
					playAnim(player, 'jump5')
				end
			end

		end
		if isjumping and isonground and Yspeed >= 0 then
			isjumping = false
		end

		-- skidding
		if getPropertyFromClass('flixel.FlxG', 'keys.pressed.LEFT') and Xspeed >= skidlimit and isonground and curstate == 'normal' then
			isskiddingleft = true
		elseif getPropertyFromClass('flixel.FlxG', 'keys.pressed.RIGHT') and Xspeed <= -skidlimit and isonground and curstate == 'normal' then
			isskiddingright = true
		end
		if isskiddingleft and not isjumping then
			animTPIndice = -256
			if getProperty(player..'.animation.curAnim.name') ~= 'skidding' then
				playAnim(player, 'skidding')
			end
			if Xspeed <= 0 or getPropertyFromClass('flixel.FlxG', 'keys.pressed.RIGHT') or not isonground and curstate == 'normal' then
				isskiddingleft = false
				animTPIndice = 0
			end
		elseif isskiddingright and not isjumping then
			animTPIndice = -256
			if getProperty(player..'.animation.curAnim.name') ~= 'skidding' then
				playAnim(player, 'skidding')
			end
			if Xspeed >= 0 or getPropertyFromClass('flixel.FlxG', 'keys.pressed.LEFT') or not isonground and curstate == 'normal' then
				isskiddingright = false
				animTPIndice = 0
			end
		else
			if isjumping and animTPIndice < 0 then
				animTPIndice = 0
				isskiddingleft = false
				isskiddingright = false
			end
		end
		if isskiddingright or isskiddingleft then
			if luaSoundExists('skid') == false then
				playSound('skid', 1,'skid')
			end
		end

		-- spindash

		if isspindashing then
			Xspeed = 0
			--Yspeed = 0
			if curstate ~= 'normal' then
				curstate = 'normal'
			end
			if getPropertyFromClass('flixel.FlxG', 'keys.pressed.DOWN') then
				if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.SPACE') then
					playAnim(player, 'spindash', true)
					if luaSoundExists('spindash') then
						stopSound('spindash')
					end
					playSound('spindash1', 0.8, 'spindash')
					setSoundPitch('spindash', 1+spinrev/8)

					spinrev = spinrev+2
					if spinrev > 8 then
						spinrev = 8
					end
				end
				if spinrev > 0 then
					spinrev = spinrev - 0.125
				end
			elseif getPropertyFromClass('flixel.FlxG', 'keys.justReleased.DOWN') then
				Xspeed = 8+spinrev/1.5
				stopSound('spindash')
				playSound('spindashrelease', 1, 'spindashrelease')
				if getProperty(player..'.flipX') == true then
					Xspeed = -Xspeed
				end
				isspindashing = false
				curstate = 'roll'
				spinrev = 0
			end

		end
		if Xspeed < 0 then
			setProperty(player..'.flipX', true)
		elseif Xspeed > 0 then
			setProperty(player..'.flipX', false)
		end
	end

	-- Restore the real X component (only if he was inside the loop)
	if sonicLoopActive then
		Xspeed = realXspeed
	end

	-- Visual rotation: the angle only changes inside the loop (following the track).
	if sonicLoopActive then
		setProperty(player..'.angle', -math.deg(sonicLoopAngle))
	else
		tailsRollAngle = 0
		setProperty(player..'.angle', 0)
	end
end

function onUpdatePost()
	if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.W') then
		if toggledDebugMenu then
			toggledDebugMenu = false
		elseif not toggledDebugMenu then
			toggledDebugMenu = true
		end
	end
	if toggledDebugMenu then
		debugPrint('\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n')
		debugPrint('Xspeed: '..Xspeed)
		debugPrint('Yspeed: '..Yspeed)
		debugPrint('Current state: '..curstate)
		if isonground then
			debugPrint('Is on ground: true')
		else
			debugPrint('Is on ground: false')
		end
		if isjumping then
			debugPrint('Is jumping: true')
		else
			debugPrint('Is jumping: false')
		end
		if isflying then
			debugPrint('Is flying: true')
		else
			debugPrint('Is flying: false')
		end
		debugPrint('Xpos: '..getProperty(player..'.x'))
		debugPrint('Ypos: '..getProperty(player..'.y'))
		debugPrint('Foot X: '..(getProperty(player..'mainhitbox.x') + hitboxwidth / 2))
		debugPrint('Feet Y (hitbox bottom): '..(getProperty(player..'mainhitbox.y') + hitboxheight))
		debugPrint('Descent surface Y at foot: '..getRampY(getProperty(player..'mainhitbox.x') + hitboxwidth / 2, ramps[2]))
		debugPrint('Collisions: '..colnumber..' (nearby: '..#activeList..')')

	end
	setOnScripts('SpeedX', Xspeed)
	setOnScripts('SpeedY', Yspeed)
	setOnScripts('tailsIsOnGround', isonground)
end
