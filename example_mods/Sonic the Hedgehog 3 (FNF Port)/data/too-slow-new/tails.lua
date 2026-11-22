player = 'tails'
camerafollowplayer = true

hitboxheight = 30
hitboxwidth = 18

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

slopefactor = 0.125
rollslopeuphill = 0.078125
rollslopedownhill = 0.3125

spinrev = 0

rolldecelerationspeed = 0.125
rollfrictionspeed = 0.0234375

curstate = 'normal'

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

prejumptimer = 0

colalpha = 0
hascollisionsystem = true
skidlimit = 4
hasgravity = true
canshield = true

isflying = false
flytimer = 0
isgliding = false
canglide = false
ishidden = false
toggledDebugMenu = false
camOffsetTimer = camOffsetTimer or 0

local radiusH = hitboxheight / 2
local radiusW = hitboxwidth / 2
local spread = radiusW - 1
local spriteDrop = 9
local wallRadius = 10
local fallSpeed = 2.5
local lockFrames = 30

local loopX = 1666
local loopGroundY = 179
local loopRadius = 200 * 0.497
local loopMinSpeed = 4

local posX, posY = 0, 0
local angleDeg = 0
local visualAngle = 0
local pathLayer = 0
local controlLock = 0
local footA, footB = false, false
local ready = false

local loopPhase = 0
local loopDir = 1
local loopArmed = true
local prevX = 0

local inp = {}
local jumpFrames = {5, 1, 2, 5, 3, 5, 4, 5}

function round(num)
    return math.floor(num + 0.5)
end

local function signum(n)
    if n > 0 then return 1 end
    if n < 0 then return -1 end
    return 0
end

local function wrapAngle(deg)
    while deg > 180 do deg = deg - 360 end
    while deg <= -180 do deg = deg + 360 end
    return deg
end

local function modeDir(deg)
    local a = math.abs(deg)
    if a <= 45 then return 0, 1 end
    if a >= 135 then return 0, -1 end
    if deg > 0 then return 1, 0 end
    return -1, 0
end

local function held(name)
    return getPropertyFromClass('flixel.FlxG', 'keys.pressed.' .. name) == true
end

local function hit(name)
    return getPropertyFromClass('flixel.FlxG', 'keys.justPressed.' .. name) == true
end

local function released(name)
    return getPropertyFromClass('flixel.FlxG', 'keys.justReleased.' .. name) == true
end

local function readInput()
    inp.left = held('LEFT')
    inp.right = held('RIGHT')
    inp.up = held('UP')
    inp.down = held('DOWN')
    inp.space = held('SPACE')
    inp.spaceHit = hit('SPACE')
    inp.downRel = released('DOWN')
    inp.upRel = released('UP')
end

local function curName()
    return getProperty(player .. '.animation.curAnim.name')
end

local function edgeOf(c, d)
    return c + d * radiusH - (d < 0 and 1 or 0)
end

local function senseFeet(dx, dy, reach)
    callOnScripts('terrainFeet', {edgeOf(posX, dx), edgeOf(posY, dy), spread, reach, pathLayer, dx, dy})
end

local function senseWall(dx, dy, reach)
    callOnScripts('terrainProbe', {posX, posY, dx, dy, reach, pathLayer})
end

local function wallContact(wx, wy, reach)
    senseWall(wx, wy, reach)

    if terrainFound ~= true or terrainDist > wallRadius then
        return false
    end

    if wx ~= 0 then
        posX = terrainHitX - wx * wallRadius
    else
        posY = terrainHitY - wy * wallRadius
    end

    if wx < 0 then
        wallonleft = true
    elseif wx > 0 then
        wallonright = true
    end

    return true
end

local function snapTo(dx, dy)
    if dy > 0 then
        posY = terrainHitY - radiusH
    elseif dy < 0 then
        posY = terrainHitY + 1 + radiusH
    elseif dx > 0 then
        posX = terrainHitX - radiusH
    else
        posX = terrainHitX + 1 + radiusH
    end
end

local function leaveGround()
    local rad = math.rad(angleDeg)
    local gs = Xspeed
    Xspeed = gs * math.cos(rad)
    Yspeed = -gs * math.sin(rad)
    isonground = false
    angleDeg = 0
    footA, footB = false, false
end

local function doJump()
    local rad = math.rad(angleDeg)
    local gs = Xspeed
    Xspeed = gs * math.cos(rad) - jumpforce * math.sin(rad)
    Yspeed = -gs * math.sin(rad) - jumpforce * math.cos(rad)

    isonground = false
    isjumping = true
    isskiddingleft = false
    isskiddingright = false
    angleDeg = 0

    if curstate == 'roll' then
        curstate = 'normal'
    end

    playSound('jump', 1, 'tailsjump')
end

local function landOnFloor()
    snapTo(0, 1)

    local deg = wrapAngle(terrainDeg)
    angleDeg = deg

    if math.abs(deg) >= 22.5 then
        local factor = math.abs(deg) < 45 and 0.5 or 1
        if math.abs(Xspeed) <= Yspeed then
            Xspeed = -signum(math.sin(math.rad(deg))) * Yspeed * factor
        end
    end

    Yspeed = 0
    isonground = true
    isjumping = false
    isflying = false
    flytimer = 0
    canglide = true

    stopSound('tailsfly')
    stopSound('tailsflytired')
end

local function slopePull()
    local s = math.sin(math.rad(angleDeg))

    if curstate == 'roll' then
        local f = (signum(Xspeed) == signum(s)) and rollslopeuphill or rollslopedownhill
        Xspeed = Xspeed - f * s
    elseif Xspeed ~= 0 or math.abs(s) >= 0.05078125 then
        Xspeed = Xspeed - slopefactor * s
    end
end

local function groundInput()
    if not cantakeinputs or isspindashing then return end

    local dir = (inp.right and 1 or 0) - (inp.left and 1 or 0)

    if curstate == 'normal' then
        if controlLock > 0 then return end

        if dir < 0 then
            if Xspeed > 0 then
                Xspeed = Xspeed - decelerationspeed
                if Xspeed <= 0 then Xspeed = -0.5 end
            elseif Xspeed > -topspeed then
                Xspeed = math.max(Xspeed - accelerationspeed, -topspeed)
            end
        elseif dir > 0 then
            if Xspeed < 0 then
                Xspeed = Xspeed + decelerationspeed
                if Xspeed >= 0 then Xspeed = 0.5 end
            elseif Xspeed < topspeed then
                Xspeed = math.min(Xspeed + accelerationspeed, topspeed)
            end
        else
            Xspeed = Xspeed - math.min(math.abs(Xspeed), frictionspeed) * signum(Xspeed)
        end
    else
        if dir < 0 and Xspeed > 0 then
            Xspeed = math.max(Xspeed - rolldecelerationspeed, 0)
        elseif dir > 0 and Xspeed < 0 then
            Xspeed = math.min(Xspeed + rolldecelerationspeed, 0)
        end
        Xspeed = Xspeed - math.min(math.abs(Xspeed), rollfrictionspeed) * signum(Xspeed)

        if Xspeed == 0 then
            curstate = 'normal'
        end
    end
end

local function startRoll()
    if cantakeinputs and canroll and inp.down and curstate == 'normal' and not isspindashing and math.abs(Xspeed) >= 1 then
        curstate = 'roll'
        playSound('roll', 1, 'roll')
    end
end

local function spindashStep()
    if not isspindashing then return end

    Xspeed = 0
    curstate = 'normal'

    if inp.down then
        if inp.spaceHit then
            playAnim(player, 'spindash', true)
            if luaSoundExists('spindash') then
                stopSound('spindash')
            end
            playSound('spindash1', 0.8, 'spindash')
            setSoundPitch('spindash', 1 + spinrev / 8)

            spinrev = math.min(spinrev + 2, 8)
        end
        if spinrev > 0 then
            spinrev = spinrev - 0.125
        end
    elseif inp.downRel then
        Xspeed = 8 + spinrev / 1.5
        stopSound('spindash')
        playSound('spindashrelease', 1, 'spindashrelease')

        if getProperty(player .. '.flipX') == true then
            Xspeed = -Xspeed
        end

        isspindashing = false
        curstate = 'roll'
        spinrev = 0
    end
end

local function groundStep()
    if cantakeinputs and inp.spaceHit and inp.down and not isspindashing and Xspeed == 0 then
        isspindashing = true
    end

    if cantakeinputs and inp.spaceHit and canjump and not inp.down and not isspindashing then
        doJump()
        return
    end

    if not isspindashing then
        slopePull()
    end

    startRoll()
    groundInput()
    spindashStep()

    local rad = math.rad(angleDeg)
    local vx = Xspeed * math.cos(rad)
    local vy = -Xspeed * math.sin(rad)
    Yspeed = vy

    if canmove then
        posX = posX + vx
        posY = posY + vy
    end

    if not hascollisionsystem then return end

    local dx, dy = modeDir(angleDeg)

    local sgn = signum(Xspeed)
    if sgn == 0 and cantakeinputs and controlLock == 0 and curstate == 'normal' and not isspindashing then
        sgn = (inp.right and 1 or 0) - (inp.left and 1 or 0)
    end

    if sgn ~= 0 then
        local wx, wy = dy * sgn, -dx * sgn
        if wallContact(wx, wy, wallRadius + math.ceil(math.abs(Xspeed)) + 2) then
            Xspeed = 0
        end
    end

    senseFeet(dx, dy, 16)

    local tolerance = math.min(math.abs(Xspeed) + 4, 14)

    if terrainFound == true and terrainDist <= tolerance then
        snapTo(dx, dy)
        angleDeg = wrapAngle(terrainDeg)
        footA = terrainDistA < 6
        footB = terrainDistB < 6
    else
        leaveGround()
        return
    end

    if math.abs(Xspeed) < fallSpeed and math.abs(angleDeg) >= 45 then
        controlLock = lockFrames
        if math.abs(angleDeg) >= 90 then
            leaveGround()
        end
    end
end

local function shieldStep()
    if inp.spaceHit and canshield and isjumping then
        canshield = false
        makeAnimatedLuaSprite('instashield', 'instashield', getProperty(player .. '.x'), getProperty(player .. '.y'))
        addAnimationByPrefix('instashield', 'instashield', 'instashield', 34, false)
        addLuaSprite('instashield')
        setObjectOrder('instashield', getObjectOrder(player) + 1)
        playSound('instashield')
    end
end

local function airStep()
    if cantakeinputs then
        local dir = (inp.right and 1 or 0) - (inp.left and 1 or 0)

        if dir < 0 and Xspeed > -topspeed then
            Xspeed = math.max(Xspeed - airaccelerationspeed, -topspeed)
        elseif dir > 0 and Xspeed < topspeed then
            Xspeed = math.min(Xspeed + airaccelerationspeed, topspeed)
        end

        if isjumping and not inp.space and Yspeed < -4 then
            Yspeed = -4
        end

        shieldStep()
    end

    if Yspeed < 0 and Yspeed > -4 then
        local t = Xspeed / 0.125
        t = t >= 0 and math.floor(t) or math.ceil(t)
        Xspeed = Xspeed - t / 256
    end

    if canmove then
        posX = posX + Xspeed
        posY = posY + Yspeed

        if hasgravity then
            Yspeed = math.min(Yspeed + gravityforce, 16)
        end
    end

    if not hascollisionsystem then return end

    if Xspeed ~= 0 then
        local dir = signum(Xspeed)
        if wallContact(dir, 0, wallRadius + math.ceil(math.abs(Xspeed)) + 2) then
            Xspeed = 0
        end
    end

    if Yspeed < 0 then
        senseFeet(0, -1, 16)
        if terrainFound == true and terrainDist <= 0 then
            snapTo(0, -1)
            Yspeed = 0
            roofontop = true
        end
    else
        senseFeet(0, 1, math.min(40, math.max(16, math.ceil(Yspeed) + 4)))
        if terrainFound == true and terrainDist <= 0 then
            landOnFloor()
        end
    end
end

local function updateLoopLayer()
    local bottom = posY + radiusH

    if loopPhase == 0 then
        if not loopArmed then
            if math.abs(posX - loopX) > loopRadius + 30 then
                loopArmed = true
            end
        elseif isonground and math.abs(bottom - loopGroundY) <= 18 then
            if prevX < loopX and posX >= loopX and Xspeed >= loopMinSpeed then
                pathLayer, loopPhase, loopDir = 1, 1, 1
            elseif prevX > loopX and posX <= loopX and Xspeed <= -loopMinSpeed then
                pathLayer, loopPhase, loopDir = 1, 1, -1
            end
        end
    else
        if loopPhase == 1 and bottom < loopGroundY - 60 then
            loopPhase = 2
        end

        local past = (posX - loopX) * loopDir < 0
        local finished = loopPhase == 2 and past and bottom > loopGroundY - 35
        local lost = math.abs(posX - loopX) > loopRadius + 60

        if finished or lost then
            pathLayer, loopPhase = 0, 0
            loopArmed = false
        end
    end

    prevX = posX
end

local function placeSprites()
    if isonground and math.abs(angleDeg) >= 22.5 then
        visualAngle = angleDeg
    else
        visualAngle = 0
    end

    local rad = math.rad(visualAngle)
    local sx = posX - math.sin(rad) * spriteDrop
    local sy = posY - math.cos(rad) * spriteDrop

    setProperty(player .. '.x', sx - getProperty(player .. '.width') / 2)
    setProperty(player .. '.y', sy - getProperty(player .. '.height') / 2)
    setProperty(player .. '.angle', -visualAngle)

    setProperty(player .. 'mainhitbox.x', posX - radiusW)
    setProperty(player .. 'mainhitbox.y', posY - radiusH)
end

local function updateShield()
    if luaSpriteExists('instashield') then
        setProperty('instashield.x', getProperty(player .. '.x'))
        setProperty('instashield.y', getProperty(player .. '.y') + 9)
        setProperty('instashield.flipX', getProperty(player .. '.flipX') == true)

        if getProperty('instashield.animation.curAnim.finished') then
            removeLuaSprite('instashield')
        end
    end

    if not canshield and isonground then
        canshield = true
    end
end

local function updateLook()
    if not cantakeinputs then return end

    if inp.up then
        if isonground and Xspeed == 0 and Yspeed == 0 then
            islookingup = true
            islookingdown = false
            idletimer = 0
            camOffsetTimer = math.min(camOffsetTimer + 1, 60)
        end
    elseif islookingup then
        islookingup = false
    end

    if inp.down then
        if isonground and Xspeed == 0 and Yspeed == 0 then
            islookingdown = true
            islookingup = false
            idletimer = 0
            if not ishidden then
                camOffsetTimer = math.min(camOffsetTimer + 1, 60)
            end
        end
    elseif islookingdown then
        islookingdown = false
    end

    if inp.downRel or inp.upRel or Xspeed ~= 0 or isspindashing then
        camOffsetTimer = 0
    end
end

local function updateAnimation()
    if not hasanimationsystem then return end

    FC1check = isonground and footA
    FC2check = isonground and footB

    local pushing = isonground and curstate == 'normal' and not isspindashing
        and ((wallonleft and inp.left) or (wallonright and inp.right))

    local standing = Xspeed == 0 and Yspeed == 0 and not isflying and not isjumping and not isspindashing

    if standing and not pushing and FC1check and FC2check and cangoidle and not islookingup and not islookingdown then
        if curName() ~= 'idle' and idletimer < 60 and idletimer > 0 then
            playAnim(player, 'idle')
            animTPIndice = 0
            if curstate == 'roll' then
                curstate = 'normal'
            end
        end

        if idletimer < 260 then
            idletimer = idletimer + 1
        end

        if idletimer == 240 then
            playAnim(player, 'idleloop2', false)
        elseif idletimer == 260 then
            playAnim(player, 'idleloop1', false)
        end
    elseif Xspeed == 0 and isonground and not pushing and FC1check ~= FC2check and not isspindashing and not inp.down
        and not islookingdown and not islookingup then
        local facingLeft = getProperty(player .. '.flipX') == true

        if FC1check then
            playAnim(player, facingLeft and 'balanceR' or 'balanceL')
        else
            playAnim(player, facingLeft and 'balanceL' or 'balanceR')
        end
    elseif idletimer ~= 0 then
        idletimer = 0
    end

    if islookingdown and not isjumping and not isflying and not isspindashing and curName() ~= 'down' then
        playAnim(player, 'down', true)
    elseif islookingup and not isjumping and not isflying and curName() ~= 'up' then
        playAnim(player, 'up', false)
    end

    local speed = math.abs(Xspeed)

    if Xspeed ~= 0 and not isjumping and not wallonleft and not wallonright and not isflying
        and not isspindashing and curstate == 'normal' then
        curRunFrame = curRunFrame + 0.9

        if curRunFrame > math.max(0, 8 - speed) then
            curRunFrame = 0
            animTPIndice = animTPIndice + 1
            if animTPIndice < 0 then animTPIndice = 0 end
        end

        if speed < 6 then
            playAnim(player, 'walk' .. (animTPIndice % 8 + 1))
        else
            playAnim(player, 'run' .. (animTPIndice % 4 + 1))
        end
    end

    if pushing then
        setProperty(player .. '.flipX', wallonleft == true)
        islookingup = false
        islookingdown = false
        playAnim(player, 'push')
    end

    if (isjumping and not isflying and not isspindashing) or curstate == 'roll' then
        curJumpFrame = curJumpFrame + 1

        if speed < 3 then
            if curJumpFrame > math.max(0, 5 - speed) then
                curJumpFrame = 0
                animTPIndice = animTPIndice + 1
                if animTPIndice < 0 then animTPIndice = 0 end
            end
            playAnim(player, 'jump' .. (animTPIndice % 5 + 1))
        else
            if curJumpFrame > math.max(0, 5 - speed) then
                curJumpFrame = 0
                animTPIndice = animTPIndice + 1
                if animTPIndice < 0 then animTPIndice = 0 end
            end
            playAnim(player, 'jump' .. jumpFrames[animTPIndice % 8 + 1])
        end
    end

    if inp.left and Xspeed >= skidlimit and isonground and curstate == 'normal' then
        isskiddingleft = true
    elseif inp.right and Xspeed <= -skidlimit and isonground and curstate == 'normal' then
        isskiddingright = true
    end

    if isskiddingleft and not isjumping then
        animTPIndice = -256
        if curName() ~= 'skidding' then
            playAnim(player, 'skidding')
        end
        if Xspeed <= 0 or inp.right or not isonground then
            isskiddingleft = false
            animTPIndice = 0
        end
    elseif isskiddingright and not isjumping then
        animTPIndice = -256
        if curName() ~= 'skidding' then
            playAnim(player, 'skidding')
        end
        if Xspeed >= 0 or inp.left or not isonground then
            isskiddingright = false
            animTPIndice = 0
        end
    elseif isjumping and animTPIndice < 0 then
        animTPIndice = 0
        isskiddingleft = false
        isskiddingright = false
    end

    if isskiddingright or isskiddingleft then
        if not luaSoundExists('skid') then
            playSound('skid', 1, 'skid')
        end
    end

    if Xspeed < 0 then
        setProperty(player .. '.flipX', true)
    elseif Xspeed > 0 then
        setProperty(player .. '.flipX', false)
    end
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
    for i = 1, 8 do
        addAnimationByIndices(player, 'walk' .. i, 'walk', {i - 1})
    end

    for i = 1, 4 do
        addAnimationByIndices(player, 'run' .. i, 'run', {i - 1})
    end

    addAnimationByPrefix(player, 'skidding', 'skid', 18, false)

    addAnimationByPrefix(player, 'balanceR', 'balanceR', 10, true)
    addAnimationByPrefix(player, 'balanceL', 'balanceL', 10, true)

    for i = 1, 5 do
        addAnimationByIndices(player, 'jump' .. i, 'jump', {i - 1})
    end

    addAnimationByPrefix(player, 'spindash', 'spindash', 32, true)
    addAnimationByPrefix(player, 'push', 'push', 4, true)
    addAnimationByPrefix(player, 'dies', 'dies', 1, false)

    addLuaSprite(player)

    posX = getMidpointX(player)
    posY = getMidpointY(player) + spriteDrop
    prevX = posX

    makeLuaSprite(player .. 'mainhitbox', '', posX - radiusW, posY - radiusH)
    makeGraphic(player .. 'mainhitbox', hitboxwidth, hitboxheight, 'FFFF84')
    setProperty(player .. 'mainhitbox.alpha', colalpha)
    addLuaSprite(player .. 'mainhitbox', true)

    ready = true
end

function onUpdate(elapsed)
    if not ready then return end

    readInput()

    wallonleft = false
    wallonright = false
    roofontop = false

    if controlLock > 0 then
        controlLock = controlLock - 1
    end

    if isonground then
        groundStep()
    else
        airStep()
    end

    updateLoopLayer()
    updateLook()
    updateShield()
    updateAnimation()
    placeSprites()
end

function onUpdatePost()
    if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.W') then
        toggledDebugMenu = not toggledDebugMenu
    end

    if toggledDebugMenu then
        debugPrint('\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n')
        debugPrint('Xspeed: ' .. Xspeed)
        debugPrint('Yspeed: ' .. Yspeed)
        debugPrint('Current state: ' .. curstate)
        debugPrint('Is on ground: ' .. tostring(isonground))
        debugPrint('Is jumping: ' .. tostring(isjumping))
        debugPrint('Ground angle: ' .. string.format('%.1f', angleDeg))
        debugPrint('Path layer: ' .. pathLayer .. ' (loop phase ' .. loopPhase .. ')')
        debugPrint('Control lock: ' .. controlLock)
        debugPrint('Xpos: ' .. posX)
        debugPrint('Ypos: ' .. posY)
        debugPrint('Feet Y: ' .. (posY + radiusH))
        debugPrint('Sensors A/B: ' .. tostring(footA) .. ' / ' .. tostring(footB))
    end

    setOnScripts('SpeedX', Xspeed)
    setOnScripts('SpeedY', Yspeed)
    setOnScripts('tailsIsOnGround', isonground)
end
