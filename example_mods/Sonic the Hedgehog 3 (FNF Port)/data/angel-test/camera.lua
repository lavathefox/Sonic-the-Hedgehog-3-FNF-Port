player = 'tails'
camerafollowplayer = true
showcolcam = 0

tailsIsOnGround = false

camOffset = 0
camOffsetGoal = 0
camOffsetTimer = 0

levelCamXLimitLeft = 11
levelCamXLimitRight = 17240-636
levelCamYLimitUp = 0
levelCamYLimitDown = 1384

camCanGoLeft = true
camCanGoRight = true
camCanGoUp = true
camCanGoDown = true

camGoBackToPosSpeed = 4

forcecameradebug = false

function onCreatePost()

	makeLuaSprite(player..'focuspoint', '', getProperty(player..'.x')+23, getProperty(player..'.y')+23)
	makeGraphic(player..'focuspoint', 1, 1, 'FF7700')
	setProperty(player..'focuspoint.alpha', showcolcam)
	addLuaSprite(player..'focuspoint', true)

	makeLuaSprite('leftCam', '', getProperty(player..'focuspoint.x')-16, getProperty(player..'focuspoint.y')-32)
	makeGraphic('leftCam', 1, 65, 'FFFFFF')
	setProperty('leftCam.alpha', showcolcam)
	addLuaSprite('leftCam', true)

	makeLuaSprite('rightCam', '', getProperty(player..'focuspoint.x'), getProperty(player..'focuspoint.y')-32)
	makeGraphic('rightCam', 1, 65, 'FFFFFF')
	setProperty('rightCam.alpha', showcolcam)
	addLuaSprite('rightCam', true)

	makeLuaSprite('topCam', '', getProperty(player..'focuspoint.x')-16, getProperty(player..'focuspoint.y')-32)
	makeGraphic('topCam', 17, 1, 'FFFFFF')
	setProperty('topCam.alpha', showcolcam)
	addLuaSprite('topCam', true)

	makeLuaSprite('bottomCam', '', getProperty(player..'focuspoint.x')-16, getProperty(player..'focuspoint.y')+32)
	makeGraphic('bottomCam', 17, 1, 'FFFFFF')
	setProperty('bottomCam.alpha', showcolcam)
	addLuaSprite('bottomCam', true)

	makeLuaSprite('middleCam', '', getProperty(player..'focuspoint.x')-16, getProperty(player..'focuspoint.y'))
	makeGraphic('middleCam', 17, 1, '00FF00')
	setProperty('middleCam.alpha', showcolcam)
	addLuaSprite('middleCam', true)

	makeLuaSprite('leftXTRCam', '', getProperty('camFollow.x')-10, getProperty('camFollow.y'))
	makeGraphic('leftXTRCam', 1, 224, '0000FF')
	setProperty('leftXTRCam.alpha', showcolcam)
	addLuaSprite('leftXTRCam', true)

	makeLuaSprite('rightXTRCam', '', getProperty('camFollow.x')-10, getProperty('camFollow.y'))
	makeGraphic('rightXTRCam', 1, 224, '0000FF')
	setProperty('rightXTRCam.alpha', showcolcam)
	addLuaSprite('rightXTRCam', true)

	makeLuaSprite('upXTRCam', '', getProperty('camFollow.x')-10, getProperty('camFollow.y'))
	makeGraphic('upXTRCam', 320, 1, '0000FF')
	setProperty('upXTRCam.alpha', showcolcam)
	addLuaSprite('upXTRCam', true)

	makeLuaSprite('downXTRCam', '', getProperty('camFollow.x')-10, getProperty('camFollow.y'))
	makeGraphic('downXTRCam', 320, 1, '0000FF')
	setProperty('downXTRCam.alpha', showcolcam)
	addLuaSprite('downXTRCam', true)


end

function onUpdatePost()

	if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.SPACE') and tailsIsOnGround then	-- just making sure they understand we jumped
		tailsIsOnGround = false
	end

	if getPropertyFromClass('flixel.FlxG', 'keys.pressed.UP') and getProperty('tails.animation.curAnim.name') == 'up'
	or getPropertyFromClass('flixel.FlxG', 'keys.pressed.DOWN') and getProperty('tails.animation.curAnim.name') == 'down'
	then
		camOffsetTimer = camOffsetTimer+1
		if camOffsetTimer > 120 then
			camOffsetTimer = 120
		end
	else
		camOffsetTimer = 0
	end
	if getPropertyFromClass('flixel.FlxG', 'keys.justReleased.UP') or getPropertyFromClass('flixel.FlxG', 'keys.justReleased.DOWN') then
		camOffsetTimer = 0
	end

	if camOffsetTimer == 120 then
		if getProperty('tails.animation.curAnim.name') == 'up' then
			if camOffsetGoal < 104 then
				camOffsetGoal = camOffsetGoal+2
			end
		elseif getProperty('tails.animation.curAnim.name') == 'down' then
			if camOffsetGoal > -88 then
				camOffsetGoal = camOffsetGoal-2
			end
		end
	elseif camOffsetTimer ~= 120 and camOffsetGoal ~= 0 then
		if camOffsetGoal < 0 then
			camOffsetGoal = camOffsetGoal+2
		elseif camOffsetGoal > 0 then
			camOffsetGoal = camOffsetGoal-2
		end
	end

	setProperty('tailsfocuspoint.x', getProperty('tails.x')+24)
	setProperty('tailsfocuspoint.y', getProperty('tails.y')-36)

	if getProperty('tailsfocuspoint.y') < getProperty('topCam.y') and camCanGoUp then
		setProperty('topCam.y', getProperty('tailsfocuspoint.y'))

		setProperty('bottomCam.y', getProperty('tailsfocuspoint.y')+64)
		setProperty('rightCam.y', getProperty('tailsfocuspoint.y'))
		setProperty('leftCam.y', getProperty('tailsfocuspoint.y'))

		setProperty('middleCam.y', getProperty('tailsfocuspoint.y')+32)
	end
	if getProperty('tailsfocuspoint.y') > getProperty('bottomCam.y') and camCanGoDown then
		setProperty('bottomCam.y', getProperty('tailsfocuspoint.y'))

		setProperty('topCam.y', getProperty('tailsfocuspoint.y')-64)
		setProperty('rightCam.y', getProperty('tailsfocuspoint.y')-64)
		setProperty('leftCam.y', getProperty('tailsfocuspoint.y')-64)

		setProperty('middleCam.y', getProperty('tailsfocuspoint.y')-32)
	end
	if getProperty('tailsfocuspoint.x') < getProperty('leftCam.x') and camCanGoLeft then
			setProperty('leftCam.x', getProperty('tailsfocuspoint.x'))

			setProperty('topCam.x', getProperty('tailsfocuspoint.x'))
			setProperty('rightCam.x', getProperty('tailsfocuspoint.x')+16)
			setProperty('bottomCam.x', getProperty('tailsfocuspoint.x'))

			setProperty('middleCam.x', getProperty('tailsfocuspoint.x'))
	end
	if getProperty('tailsfocuspoint.x') > getProperty('rightCam.x') and camCanGoRight then
		setProperty('rightCam.x', getProperty('tailsfocuspoint.x'))

		setProperty('topCam.x', getProperty('tailsfocuspoint.x')-16)
		setProperty('leftCam.x', getProperty('tailsfocuspoint.x')-16)
		setProperty('bottomCam.x', getProperty('tailsfocuspoint.x')-16)

		setProperty('middleCam.x', getProperty('tailsfocuspoint.x')-16)
	end

	setProperty('upXTRCam.x', getProperty('middleCam.x')-144)
	setProperty('upXTRCam.y', getProperty('middleCam.y')-96)

	setProperty('downXTRCam.x', getProperty('middleCam.x')-144)
	setProperty('downXTRCam.y', getProperty('middleCam.y')+128)

	setProperty('rightXTRCam.x', getProperty('middleCam.x')-144)
	setProperty('rightXTRCam.y', getProperty('middleCam.y')-96)

	setProperty('leftXTRCam.x', getProperty('middleCam.x')+176)
	setProperty('leftXTRCam.y', getProperty('middleCam.y')-96)

	if getProperty('leftXTRCam.x')-320 <= levelCamXLimitLeft then
		camCanGoLeft = false
		if getProperty('leftXTRCam.x')-320 < levelCamXLimitLeft then
			setProperty('middleCam.x', levelCamXLimitLeft+144)
		end
	else
		camCanGoLeft = true
	end

	if getProperty('rightXTRCam.x')-320 >= levelCamXLimitRight then
		camCanGoRight = false
		if getProperty('rightXTRCam.x')-320 > levelCamXLimitRight then
			setProperty('middleCam.x', levelCamXLimitRight+320+160-16)
		end
	else
		camCanGoRight = true
	end
	if getProperty('upXTRCam.y') < levelCamYLimitUp then
		camCanGoUp = false
		if getProperty('upXTRCam.y') < levelCamYLimitUp then
			setProperty('middleCam.y', levelCamYLimitUp+96)
		end
	else
		camCanGoUp = true
	end

	if getProperty('downXTRCam.y')+224 >= levelCamYLimitDown+224 then
		camCanGoDown = false
		if getProperty('downXTRCam.y')+224 > levelCamYLimitDown+224 then
			setProperty('middleCam.y', levelCamYLimitDown-128)
		end
	else
		camCanGoDown = true
	end

	camOffset = camOffsetGoal
	if getProperty('downXTRCam.y')-camOffset > levelCamYLimitDown then
		camOffset = camOffset-(levelCamYLimitDown-getProperty('downXTRCam.y')+camOffset)
	end

	if camerafollowplayer then
		setProperty('camFollow.x', getProperty('middleCam.x')+16)
		setProperty('camFollow.y', getProperty('middleCam.y')+16-camOffset)
	end

	if tailsIsOnGround and math.abs(getProperty('middleCam.y')) ~= getProperty('tailsfocuspoint.y') then
		if getProperty('middleCam.y') > getProperty('tailsfocuspoint.y') and camCanGoUp then
			setProperty('middleCam.y', getProperty('middleCam.y')-camGoBackToPosSpeed)

			setProperty('topCam.y', getProperty('topCam.y')-camGoBackToPosSpeed)
			setProperty('bottomCam.y', getProperty('bottomCam.y')-camGoBackToPosSpeed)
			setProperty('rightCam.y', getProperty('rightCam.y')-camGoBackToPosSpeed)
			setProperty('leftCam.y', getProperty('leftCam.y')-camGoBackToPosSpeed)
			if getProperty('middleCam.y') < getProperty('tailsfocuspoint.y') then
				setProperty('middleCam.y', getProperty('tailsfocuspoint.y'))
			end

		elseif getProperty('middleCam.y') < getProperty('tailsfocuspoint.y') and camCanGoDown then
			setProperty('middleCam.y', getProperty('middleCam.y')+camGoBackToPosSpeed)

			setProperty('topCam.y', getProperty('topCam.y')+camGoBackToPosSpeed)
			setProperty('bottomCam.y', getProperty('bottomCam.y')+camGoBackToPosSpeed)
			setProperty('rightCam.y', getProperty('rightCam.y')+camGoBackToPosSpeed)
			setProperty('leftCam.y', getProperty('leftCam.y')+camGoBackToPosSpeed)

			if getProperty('middleCam.y') > getProperty('tailsfocuspoint.y') then
				setProperty('middleCam.y', getProperty('tailsfocuspoint.y'))
			end
		end
	end
end
