package backend;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;

class MobileControls
{
	#if android
	public static var isAndroid:Bool = true;
	#else
	public static var isAndroid:Bool = false;
	#end

	public static var enabled:Bool = true;
	public static var visible:Bool = true;

	public static var upPressed:Bool = false;
	public static var downPressed:Bool = false;
	public static var leftPressed:Bool = false;
	public static var rightPressed:Bool = false;

	public static var aPressed:Bool = false;
	public static var bPressed:Bool = false;

	public static var upJustPressed:Bool = false;
	public static var downJustPressed:Bool = false;
	public static var leftJustPressed:Bool = false;
	public static var rightJustPressed:Bool = false;

	public static var aJustPressed:Bool = false;
	public static var bJustPressed:Bool = false;

	public static var arrows:FlxSprite;
	public static var buttonA:FlxSprite;
	public static var buttonB:FlxSprite;

	static var mobileCamera:FlxCamera;

	static var arrowX:Float = 80;
	static var arrowY:Float = 500;

	static var buttonAX:Float = 1030;
	static var buttonAY:Float = 500;

	static var buttonBX:Float = 900;
	static var buttonBY:Float = 560;

	static var arrowScale:Float = 3;
	static var buttonScale:Float = 3;

	static var initialized:Bool = false;
	static var currentState:Dynamic = null;

	static var touchUp:Bool = false;
	static var touchDown:Bool = false;
	static var touchLeft:Bool = false;
	static var touchRight:Bool = false;
	static var touchA:Bool = false;
	static var touchB:Bool = false;

	static var previousUp:Bool = false;
	static var previousDown:Bool = false;
	static var previousLeft:Bool = false;
	static var previousRight:Bool = false;

	static var previousA:Bool = false;
	static var previousB:Bool = false;

	public static function create():Void
	{
		#if android
		if (initialized)
			return;

		initialized = true;

		clearPressed();

		createCamera();
		createArrows();
		createButtons();

		setVisible(visible);
		#else
		initialized = false;
		#end
	}

	#if android
	static function createCamera():Void
	{
		mobileCamera = new FlxCamera();
		mobileCamera.bgColor.alpha = 0;
		mobileCamera.scroll.set(0, 0);
		mobileCamera.zoom = 1;

		FlxG.cameras.add(mobileCamera, false);
	}

	static function createArrows():Void
	{
		arrows = new FlxSprite(arrowX, arrowY);
		arrows.frames = Paths.getSparrowAtlas('mobileControls/controlsArrows');

		arrows.animation.addByPrefix('idle', 'idle', 24, false);
		arrows.animation.addByPrefix('leftClick', 'leftClick', 24, false);
		arrows.animation.addByPrefix('downClick', 'downClick', 24, false);
		arrows.animation.addByPrefix('rightClick', 'rightClick', 24, false);
		arrows.animation.addByPrefix('upClick', 'upClick', 24, false);

		arrows.animation.play('idle');
		arrows.antialiasing = false;
		arrows.scale.set(arrowScale, arrowScale);
		arrows.updateHitbox();
		arrows.scrollFactor.set();
		arrows.cameras = [mobileCamera];
	}

	static function createButtons():Void
	{
		buttonA = new FlxSprite(buttonAX, buttonAY);
		buttonA.loadGraphic(Paths.image('mobileControls/buttomA'));
		buttonA.antialiasing = false;
		buttonA.scale.set(buttonScale, buttonScale);
		buttonA.updateHitbox();
		buttonA.scrollFactor.set();
		buttonA.cameras = [mobileCamera];

		buttonB = new FlxSprite(buttonBX, buttonBY);
		buttonB.loadGraphic(Paths.image('mobileControls/buttomB'));
		buttonB.antialiasing = false;
		buttonB.scale.set(buttonScale, buttonScale);
		buttonB.updateHitbox();
		buttonB.scrollFactor.set();
		buttonB.cameras = [mobileCamera];
	}
	#end

	public static function addToState(state:Dynamic):Void
	{
		#if android
		if (!initialized)
			create();

		if (state == null || !initialized)
			return;

		if (currentState == state)
		{
			setVisible(visible);
			return;
		}

		if (currentState != null)
			removeFromState(currentState);

		currentState = state;

		if (arrows != null && !state.members.contains(arrows))
			state.add(arrows);

		if (buttonA != null && !state.members.contains(buttonA))
			state.add(buttonA);

		if (buttonB != null && !state.members.contains(buttonB))
			state.add(buttonB);

		setVisible(visible);
		#end
	}

	public static function removeFromState(state:Dynamic):Void
	{
		#if android
		if (state == null)
			return;

		if (arrows != null && state.members.contains(arrows))
			state.remove(arrows, false);

		if (buttonA != null && state.members.contains(buttonA))
			state.remove(buttonA, false);

		if (buttonB != null && state.members.contains(buttonB))
			state.remove(buttonB, false);

		if (currentState == state)
			currentState = null;
		#end
	}

	public static function update():Void
	{
		#if android
		resetJustPressed();

		if (!enabled)
		{
			clearPressed();
			updateAnimation();
			return;
		}

		if (!initialized)
			return;

		touchUp = false;
		touchDown = false;
		touchLeft = false;
		touchRight = false;

		touchA = false;
		touchB = false;

		for (touch in FlxG.touches.list)
		{
			if (touch == null || !touch.pressed)
				continue;

			checkArrowTouch(touch.screenX, touch.screenY);
			checkButtonTouch(touch.screenX, touch.screenY);
		}

		upPressed = touchUp;
		downPressed = touchDown;
		leftPressed = touchLeft;
		rightPressed = touchRight;

		aPressed = touchA;
		bPressed = touchB;

		upJustPressed = upPressed && !previousUp;
		downJustPressed = downPressed && !previousDown;
		leftJustPressed = leftPressed && !previousLeft;
		rightJustPressed = rightPressed && !previousRight;

		aJustPressed = aPressed && !previousA;
		bJustPressed = bPressed && !previousB;

		previousUp = upPressed;
		previousDown = downPressed;
		previousLeft = leftPressed;
		previousRight = rightPressed;

		previousA = aPressed;
		previousB = bPressed;

		updateAnimation();
		#end
	}

	#if android
	static function checkArrowTouch(x:Float, y:Float):Void
	{
		if (arrows == null || !arrows.visible)
			return;

		var centerX:Float = arrows.x + arrows.width / 2;
		var centerY:Float = arrows.y + arrows.height / 2;

		var relativeX:Float = x - centerX;
		var relativeY:Float = y - centerY;

		if (Math.abs(relativeX) > arrows.width / 2 || Math.abs(relativeY) > arrows.height / 2)
			return;

		if (Math.abs(relativeX) > Math.abs(relativeY))
		{
			if (relativeX < 0)
				touchLeft = true;
			else
				touchRight = true;
		}
		else
		{
			if (relativeY < 0)
				touchUp = true;
			else
				touchDown = true;
		}
	}

	static function checkButtonTouch(x:Float, y:Float):Void
	{
		if (buttonA != null && buttonA.visible)
		{
			if (x >= buttonA.x && x <= buttonA.x + buttonA.width &&
				y >= buttonA.y && y <= buttonA.y + buttonA.height)
			{
				touchA = true;
			}
		}

		if (buttonB != null && buttonB.visible)
		{
			if (x >= buttonB.x && x <= buttonB.x + buttonB.width &&
				y >= buttonB.y && y <= buttonB.y + buttonB.height)
			{
				touchB = true;
			}
		}
	}

	static function updateAnimation():Void
	{
		if (arrows == null)
			return;

		if (upPressed)
		{
			arrows.animation.play('upClick', true);
		}
		else if (downPressed)
		{
			arrows.animation.play('downClick', true);
		}
		else if (leftPressed)
		{
			arrows.animation.play('leftClick', true);
		}
		else if (rightPressed)
		{
			arrows.animation.play('rightClick', true);
		}
		else
		{
			arrows.animation.play('idle', true);
		}
	}
	#end

	static function resetJustPressed():Void
	{
		upJustPressed = false;
		downJustPressed = false;
		leftJustPressed = false;
		rightJustPressed = false;

		aJustPressed = false;
		bJustPressed = false;
	}

	static function clearPressed():Void
	{
		upPressed = false;
		downPressed = false;
		leftPressed = false;
		rightPressed = false;

		aPressed = false;
		bPressed = false;

		previousUp = false;
		previousDown = false;
		previousLeft = false;
		previousRight = false;

		previousA = false;
		previousB = false;

		touchUp = false;
		touchDown = false;
		touchLeft = false;
		touchRight = false;

		touchA = false;
		touchB = false;
	}

	public static function setVisible(value:Bool):Void
	{
		visible = value;

		#if android
		if (arrows != null)
			arrows.visible = value;

		if (buttonA != null)
			buttonA.visible = value;

		if (buttonB != null)
			buttonB.visible = value;
		#end
	}

	public static function setEnabled(value:Bool):Void
	{
		enabled = value;

		if (!value)
			clearPressed();
	}

	public static function setPosition(
		newArrowX:Float,
		newArrowY:Float,
		newButtonAX:Float,
		newButtonAY:Float,
		newButtonBX:Float,
		newButtonBY:Float
	):Void
	{
		arrowX = newArrowX;
		arrowY = newArrowY;

		buttonAX = newButtonAX;
		buttonAY = newButtonAY;

		buttonBX = newButtonBX;
		buttonBY = newButtonBY;

		#if android
		if (arrows != null)
		{
			arrows.x = arrowX;
			arrows.y = arrowY;
		}

		if (buttonA != null)
		{
			buttonA.x = buttonAX;
			buttonA.y = buttonAY;
		}

		if (buttonB != null)
		{
			buttonB.x = buttonBX;
			buttonB.y = buttonBY;
		}
		#end
	}

	public static function setScale(newArrowScale:Float, newButtonScale:Float):Void
	{
		arrowScale = newArrowScale;
		buttonScale = newButtonScale;

		#if android
		if (arrows != null)
		{
			arrows.scale.set(arrowScale, arrowScale);
			arrows.updateHitbox();
		}

		if (buttonA != null)
		{
			buttonA.scale.set(buttonScale, buttonScale);
			buttonA.updateHitbox();
		}

		if (buttonB != null)
		{
			buttonB.scale.set(buttonScale, buttonScale);
			buttonB.updateHitbox();
		}
		#end
	}

	public static function destroy():Void
	{
		enabled = false;
		visible = false;

		clearPressed();

		#if android
		if (arrows != null)
		{
			arrows.destroy();
			arrows = null;
		}

		if (buttonA != null)
		{
			buttonA.destroy();
			buttonA = null;
		}

		if (buttonB != null)
		{
			buttonB.destroy();
			buttonB = null;
		}

		if (mobileCamera != null)
		{
			FlxG.cameras.remove(mobileCamera, true);
			mobileCamera = null;
		}
		#end

		currentState = null;
		initialized = false;
	}
}
