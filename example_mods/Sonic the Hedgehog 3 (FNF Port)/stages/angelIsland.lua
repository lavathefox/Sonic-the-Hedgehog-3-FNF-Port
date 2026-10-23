local fireDefaultY = 800

local function createAnimatedStageSprite(tag, image, x, y, prefix, fps, loop, front, spriteType)
	makeAnimatedLuaSprite(tag, image, x, y, spriteType or 'sparrow')
	addAnimationByPrefix(tag, 'idle', prefix or 'idle', fps or 24, loop ~= false)
	objectPlayAnimation(tag, 'idle', true)
	addLuaSprite(tag, front == true)
end

local function setStageLayerAlpha(tag, alpha)
	if luaSpriteExists(tag) then
		setProperty(tag .. '.alpha', alpha)
	end
end

function onCreate()
	-- Background base
	makeLuaSprite('bg', 'angelstage/water_bg', 0, -20)
	setScrollFactor('bg', 1, 1)
	addLuaSprite('bg', false)

	-- Normal Angel Island layers
	createAnimatedStageSprite('ground', 'angelstage/AIZFloorNormal', 0, -20, 'idle', 24, true, true, 'sparrow')
	createAnimatedStageSprite('bgFire', 'angelstage/aizBGFire', 70, 100, 'idle', 24, true, false, 'sparrow')
	createAnimatedStageSprite('groundFire', 'angelstage/AIZFloorFire', 0, -20, 'idle', 24, true, false, 'sparrow')

	setStageLayerAlpha('bgFire', 0)
	setStageLayerAlpha('groundFire', 0)

	-- Fire effect
	createAnimatedStageSprite('fire', 'fire', 0, fireDefaultY, 'fireloop', 24, true, true, 'sparrow')
	setScrollFactor('fire', 1, 1)
	scaleObject('fire', 1.5, 1.5)
	setProperty('fire.alpha', 0)

	-- Sonic Faker. Explicit Sparrow atlas mode helps avoid auto-detection
	-- differences when loading mod atlases on Android.
	makeAnimatedLuaSprite('sonic', 'characters/sonicFaker', 12254, 507, 'sparrow')
	addAnimationByPrefix('sonic', 'look', 'look', 11, false)
	addAnimationByPrefix('sonic', 'idle', 'idle', 1, false)
	setProperty('sonic.flipX', true)
	objectPlayAnimation('sonic', 'idle', true)
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

	if luaSpriteExists('ground') then
		setObjectOrder('ground', getObjectOrder('dadGroup') - 1)
	end

	triggerEvent('Camera Follow Pos', '412.75', '821.25')
	runHaxeCode('FlxG.camera.pixelPerfectRender = true;')
end

function onStepHit()
	if curStep == 536 then
		setStageLayerAlpha('fire', 1)
	elseif curStep == 537 then
		doTweenY('fireUp', 'fire', -10, 0.9, 'quadOut')
	elseif curStep == 543 then
		setStageLayerAlpha('bg', 0)
		setStageLayerAlpha('ground', 0)
		setStageLayerAlpha('bgFire', 1)
		setStageLayerAlpha('groundFire', 1)
		doTweenY('fireDown', 'fire', 1500, 0.9, 'quadInOut')
	elseif curStep == 642 then
		doTweenAlpha('fireOut', 'fire', 0, 1, 'linear')
	end
end
