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
colnumber = 24
hascollisionsystem = true
skidlimit = 4
hasgravity = true
canshield = true

local function signum(number)	-- Just a lil function to help with signs
	if number > 0 then
		return 1
	elseif number < 0 then
		return -1
	else
		return 0
	end
end

function round(num)
    return math.floor(num + 0.5)
end

function onCreate()
	setOnScripts('camPlayerName', player)

	makeAnimatedLuaSprite(player, 'characters/NewBoyfriendSheet', 111, 90)

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

function updateForcedIdle()

	if cangoidle
	and not cantakeinputs
	and Xspeed == 0
	and Yspeed == 0
	and isonground
	and not isjumping
	and not isflying
	and not isspindashing then

		if getProperty(player..'.animation.curAnim.name') ~= 'idle' then

			playAnim(player, 'idle', true)

		end

		idletimer = 0
		isidle = true

	else

		isidle = false

	end

end

function onUpdate()

	setProperty(player..'mainhitbox.x', getMidpointX(player)-hitboxwidth+(hitboxwidth/2))
	setProperty(player..'mainhitbox.y', getMidpointY(player)-(hitboxheight/2)+9)
	setProperty(player..'wallrightoverhitbox.x', getProperty(player..'mainhitbox.x')+hitboxwidth+Xspeed)
	setProperty(player..'wallrightoverhitbox.y', getProperty(player..'mainhitbox.y'))
	setProperty(player..'wallleftoverhitbox.x',getProperty(player..'mainhitbox.x')-1+Xspeed)
	setProperty(player..'wallleftoverhitbox.y',getProperty(player..'mainhitbox.y'))
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

	if hascollisionsystem then
	for i=0,24 do
		if objectsOverlap('tailsmainhitbox', 'col'..i) then
			isonground = true
			if Yspeed > 0 then
				Yspeed = 0
				if isonground == false then
					curstate = 'normal'
				end
				isjumping = false
				isonground = true
				isflying = false
				flytimer = 0
				stopSound('tailsfly')
				stopSound('tailsflytired')
			end
			if not objectsOverlap('tailsroofoverhitbox', 'col'..i) then
				setProperty('tails.y', getProperty('col'..i..'.y')-48)
				setProperty(player..'.y', getProperty(player..'.y')+Yspeed)
				setProperty(player..'mainhitbox.x', getMidpointX(player)-hitboxwidth+(hitboxwidth/2))
				setProperty(player..'mainhitbox.y', getMidpointY(player)-(hitboxheight/2)+9)
				setProperty(player..'wallrightoverhitbox.x', getProperty(player..'mainhitbox.x')+hitboxwidth+Xspeed)
				setProperty(player..'wallrightoverhitbox.y', getProperty(player..'mainhitbox.y'))
				setProperty(player..'wallleftoverhitbox.x',getProperty(player..'mainhitbox.x')-1+Xspeed)
				setProperty(player..'wallleftoverhitbox.y',getProperty(player..'mainhitbox.y'))
			end
		end
		if objectsOverlap('tailsroofoverhitbox', 'col'..i) then
			if Yspeed < 0 then
				Yspeed = 0
				setProperty('tails.y', getProperty('col'..i..'.y')+getProperty('col'..i..'.height')-18)
			end
		end
	end
	for i=0,colnumber do
		if objectsOverlap('tailswallleftoverhitbox', 'col'..i) then
			if Xspeed < 0 then
				Xspeed = 0
				setProperty('tails.x', getProperty('col'..i..'.x')+getProperty('col'..i..'.width')-15)
				wallonleft = true
				break
			else
				wallonleft = false
			end
		else
			if wallonleft then
				wallonleft = false
			end
		end
	end
	for i=0,colnumber do
		if objectsOverlap('tailswallrightoverhitbox', 'col'..i) then
			if Xspeed > 0 then
				Xspeed = 0
				setProperty('tails.x', getProperty('col'..i..'.x')-hitboxwidth-15)
				wallonright = true
				break
			else
				wallonright = false
			end
		else
			if wallonright then
				wallonright = false
			end
		end
	end
	for i=0,colnumber do
		if objectsOverlap('tailsfloorchecker', 'col'..i) then
			isonground = true
			break
		else
			isonground = false
		end
	end
	for i=0,colnumber do
		if objectsOverlap('tailsfloorchecker1', 'col'..i) then
			FC1check = true
			break
		else
			FC1check = false
		end
	end
	for i=0,colnumber do
		if objectsOverlap('tailsfloorchecker2', 'col'..i) then
			FC2check = true
			break
		else
			FC2check = false
		end
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
				makeAnimatedLuaSprite('instashield', 'instashield', getProperty('tails.x'), getProperty('tails.y'))
				addAnimationByPrefix('instashield', 'instashield', 'instashield', 34, false)
				addLuaSprite('instashield')
				setObjectOrder('instashield', getObjectOrder('tails')+1)
				playSound('instashield')
			end
		end
	end

	if luaSpriteExists('instashield') then
		setProperty('instashield.x', getProperty('tails.x'))
		setProperty('instashield.y', getProperty('tails.y')+9)
		if getProperty('tails.flipX') then
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
			if not getPropertyFromClass('flixel.FlxG', 'keys.pressed.RIGHT') and not getPropertyFromClass('flixel.FlxG', 'keys.pressed.LEFT') and not cantakeinputs == false then
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

	updateForcedIdle()

	-- Animation system

	curAnim = getProperty(player..'.animation.curAnim.name')

	if hasanimationsystem then
	 if Xspeed == 0 and Yspeed == 0 and not isflying and not isjumping and not isspindashing and FC1check and FC2check and cangoidle and cantakeinputs and not islookingup and not islookingdown then
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
				if getProperty('tails.flipX') then
					playAnim(player, 'balanceR')
				elseif not getProperty('tails.flipX') then
					playAnim(player, 'balanceL')
				end
			elseif FC1check == false and FC2check == true and not isspindashing and not islookingdown and not islookingup then
				if getProperty('tails.flipX') then
					playAnim(player, 'balanceL')
				elseif not getProperty('tails.flipX') then
					playAnim(player, 'balanceR')
				end
			end
		else
			if idletimer ~= 0 then
				idletimer = 0
			end
		end

		if islookingdown == true and not isjumping and not isflying and not isspindashing and getProperty('tails.animation.curAnim.name') ~= 'down' then
			playAnim(player, 'down', true)
		elseif islookingup == true and not isjumping and not isflying and getProperty('tails.animation.curAnim.name') ~= 'up' then
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
			elseif math.abs(Xspeed) > 6 then
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
			if getProperty('tails.animation.curAnim.name') ~= 'skidding' then
				playAnim(player, 'skidding')
			end
			if Xspeed <= 0 or getPropertyFromClass('flixel.FlxG', 'keys.pressed.RIGHT') or not isonground and curstate == 'normal' then
				isskiddingleft = false
				animTPIndice = 0
			end
		elseif isskiddingright and not isjumping then
			animTPIndice = -256
			if getProperty('tails.animation.curAnim.name') ~= 'skidding' then
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
		debugPrint('Xpos: '..getProperty('tails.x'))
		debugPrint('Ypos: '..getProperty('tails.y'))

	end
	setOnScripts('SpeedX', Xspeed)
	setOnScripts('SpeedY', Yspeed)
	setOnScripts('tailsIsOnGround', isonground)
end
