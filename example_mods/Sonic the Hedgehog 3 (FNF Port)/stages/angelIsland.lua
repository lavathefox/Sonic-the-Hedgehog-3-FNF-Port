local fireDefaultY = 0

function onCreate()

	makeLuaSprite('bg', 'angelstage/water_bg', 0, -20)
	addLuaSprite('bg', false)

	makeAnimatedLuaSprite('ground', 'angelstage/AIZFloorNormal', 0, -20)
	addAnimationByPrefix('ground', 'idle', 'idle', 24, true)
	playAnim('ground', 'idle')
	addLuaSprite('ground', true)

	makeAnimatedLuaSprite('bgFire', 'angelstage/aizBGFire', 70, 100)
	addAnimationByPrefix('bgFire', 'idle', 'idle', 24, true)
	playAnim('bgFire', 'idle')
	setProperty('bgFire.alpha', 0)
	addLuaSprite('bgFire', false)

	makeAnimatedLuaSprite('groundFire', 'angelstage/AIZFloorFire', 0, -20)
	addAnimationByPrefix('groundFire', 'idle', 'idle', 24, true)
	playAnim('groundFire', 'idle')
	setProperty('groundFire.alpha', 0)
	addLuaSprite('groundFire', false)

	makeAnimatedLuaSprite('fire', 'fire', 0, 800)
	addAnimationByPrefix('fire', 'loop', 'fireloop', 24, true)
	objectPlayAnimation('fire', 'loop', true)
	setScrollFactor('fire', 1, 1)
	setProperty('fire.alpha', 0)
	scaleObject('fire', 1.5, 1.5)
	addLuaSprite('fire', true)

	fireDefaultY = getProperty('fire.y')

	makeAnimatedLuaSprite('sonic', 'characters/sonicFaker', 12254, 507)

	addAnimationByPrefix('sonic', 'look', 'look', 11, false)
	addAnimationByPrefix('sonic', 'idle', 'idle', 1, false)

	setProperty('sonic.flipX', true)

	playAnim('sonic', 'idle')

	addLuaSprite('sonic', true)

end

function onCreatePost()

	setProperty('dad.visible', true)

	setProperty('cameraSpeed', 120)

	setProperty('scoreTxt.alpha', 0)
	setProperty('botplayTxt.visible', false)
	setProperty('healthBar.alpha', 0)
	setProperty('healthBarBG.alpha', 0)

	setProperty('showRating', false)
	setProperty('showComboNum', false)

	setProperty('iconP1.alpha', 0)
	setProperty('iconP2.alpha', 0)

	setObjectOrder('ground', getObjectOrder('dadGroup') - 1)

	triggerEvent('Camera Follow Pos', '412.75', '821.25')

	runHaxeCode("FlxG.camera.pixelPerfectRender = true;")

end

function onStepHit()
    if curStep == 536 then
        setProperty('fire.alpha', 1)
    end

    if curStep == 537 then
        doTweenY('fireUp', 'fire', -10, 0.9, 'quadOut')
    end

		if curStep == 543 then
				setProperty('bg.alpha', 0)
				setProperty('ground.alpha', 0)

				setProperty('bgFire.alpha', 1)
				setProperty('groundFire.alpha', 1)

				doTweenY('fireDown', 'fire', 1500, 0.9, 'quadInOut')
		end

		if curStep == 642 then
				doTweenAlpha('fireOut', 'fire', 0, 1, 'linear')
		end
end
