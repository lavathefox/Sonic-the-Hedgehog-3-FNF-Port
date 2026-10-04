showcol = false

levelCamXLimitLeft = 40
levelCamXLimitRight = 17240

speedLimit = 6
soundpitchout = false

local pitchStarted = false
local endingStarted = false
local sonicLookStarted = false
local songStarted = false

local endingCamX = 0
local endingCamY = 0

local collisionTag = 'greenHillAct1_ColissionCollision'

function onCreate()

	makeLuaSprite('bg', 'angelstage/water_bg', 0, -330)
	addLuaSprite('bg', false)

	makeAnimatedLuaSprite('ground', 'angelstage/AIZFloorNormal', -1, -310)
	addAnimationByPrefix('ground', 'idle', 'idle', 24, true)
	playAnim('ground', 'idle')
	addLuaSprite('ground', false)

	-- ============================================================
	-- GREEN HILL COLLISION MASK
	-- ============================================================

	-- This sprite is only for visualizing the collision image.
	-- The actual collision is handled by CollisionFunctions.hx.
	makeLuaSprite('greenHillAct1_Colission', 'angelstage/greenHillAct1_Colission', 0, 0)
	setProperty('greenHillAct1_Colission.alpha', showcol and 0.35 or 0)
	addLuaSprite('greenHillAct1_Colission', true)

	-- Create the collision mask from the white collision image.
	--
	-- White = solid collision
	-- Transparent = no collision
	--
	-- The image itself determines the terrain shape.
	createCollisionMask(
		collisionTag,
		'angelstage/greenHillAct1_Colission',
		0,
		0,
		'floor',
		'FFFFFF',
		20,
		showcol
	)

	-- ============================================================
	-- SONIC / TAILS NPC
	-- ============================================================

	makeAnimatedLuaSprite('sonic', 'characters/sonicFaker', 12254, 507)

	addAnimationByPrefix('sonic', 'look', 'look', 11, false)
	addAnimationByPrefix('sonic', 'idle', 'idle', 1, false)

	setProperty('sonic.flipX', true)

	playAnim('sonic', 'idle')

	addLuaSprite('sonic', true)

end

function onCreatePost()

	setProperty('dad.visible', true)
	setProperty('boyfriend.visible', false)

	setProperty('cameraSpeed', 120)

	setProperty('scoreTxt.alpha', 0)
	setProperty('botplayTxt.visible', false)

	setProperty('healthBar.alpha', 0)
	setProperty('healthBarBG.alpha', 0)

	setProperty('showRating', false)
	setProperty('showComboNum', false)

	setProperty('iconP1.alpha', 0)
	setProperty('iconP2.alpha', 0)

	setOnScripts('levelCamXLimitLeft', levelCamXLimitLeft)
	setOnScripts('levelCamXLimitRight', levelCamXLimitRight)

	-- Stage world limits.
	runHaxeCode([[
		FlxG.worldBounds.set(0, 0, 17240, 3000);
		FlxG.camera.pixelPerfectRender = true;
	]])

	playMusic('angelisland', 1, true)

end

function onUpdate()

	local tailsX = getProperty('tails.x')

	-- ============================================================
	-- SPEED LIMIT
	-- ============================================================

	if tailsX >= 3308 and speedLimit ~= 55 then

		setOnScripts('topspeed', 55)

		speedLimit = 55

	end

	-- ============================================================
	-- MUSIC PITCH OUT
	-- ============================================================

	if tailsX >= 11445
	and not pitchStarted then

		pitchStarted = true
		soundpitchout = true

	end

	-- ============================================================
	-- ENDING
	-- ============================================================

	if tailsX >= 12134
	and not endingStarted then

		endingStarted = true

		setOnScripts('topspeed', 0)

		speedLimit = 0

		endingCamX = getProperty('camFollow.x') + 10
		endingCamY = getProperty('camFollow.y')

		setOnScripts('Xspeed', 0)
		setOnScripts('cantakeinputs', false)
		setOnScripts('cangoidle', true)

		setOnScripts('curstate', 'normal')
		setOnScripts('isrolling', false)
		setOnScripts('isflying', false)

		setProperty('isCameraOnForcedPos', true)

		doTweenX(
			'endingCameraMove',
			'camFollow',
			endingCamX,
			0.9,
			'quadOut'
		)

		runTimer('sonicLook', 2.2)

	end

	-- ============================================================
	-- MUSIC PITCH
	-- ============================================================

	if soundpitchout then

		local hillPitch = getPropertyFromClass(
			'flixel.FlxG',
			'sound.music.pitch'
		)

		if hillPitch > 0.005 then

			setPropertyFromClass(
				'flixel.FlxG',
				'sound.music.pitch',
				hillPitch - 0.005
			)

		else

			setPropertyFromClass(
				'flixel.FlxG',
				'sound.music.pitch',
				0
			)

			soundpitchout = false

		end
	end

	-- ============================================================
	-- COLLISION DEBUG SPRITE
	-- ============================================================

	if luaSpriteExists('greenHillAct1_Colission') then

		if showcol then
			setProperty('greenHillAct1_Colission.alpha', 0.35)
		else
			setProperty('greenHillAct1_Colission.alpha', 0)
		end

	end

end

function onTimerCompleted(tag)

	if tag == 'sonicLook' then

		sonicLookStarted = true

		objectPlayAnimation('sonic', 'look', true)

		runTimer('startSong', 1.2)

	elseif tag == 'startSong' then

		if not songStarted then

			songStarted = true

			setProperty('isCameraOnForcedPos', false)

			startCountdown()

		end

	end

end

function onStartCountdown()

	if not songStarted then
		return Function_Stop
	end

	return Function_Continue

end
