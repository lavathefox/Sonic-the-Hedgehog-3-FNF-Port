package backend;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import backend.ClientPrefs;
import mobile.HitBox;
import objects.Hitbox;
import mobile.AndroidOptions;
import mobile.DeviceUtil;
import mobile.TouchCursor;

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
	public static var pauseButton:FlxSprite;
	public static var gameplayHitbox:Hitbox;
		public static var hitboxArrows:HitBox;
	public static var hitboxA:HitBox;
	public static var hitboxB:HitBox;
	public static var pauseJustPressed:Bool = false;

	static var mobileCamera:FlxCamera;

	static var arrowX:Float = 80;
	static var arrowY:Float = 500;

	static var buttonAX:Float = 830;
	static var buttonAY:Float = 500;

	static var buttonBX:Float = 700;
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
	static var touchPause:Bool = false;
	static var previousPause:Bool = false;

	static var fadeTimer:Float = 0;
	static var fadeDuration:Float = 0.45;

	// Multiplies the alpha of the arrows and the A/B buttons (the CONTROLS OPACITY option).
	static var controlsOpacity:Float = 1;

	// Images used by the controls (keys for Paths.image / Paths.getSparrowAtlas).
	static inline var ARROWS_IMAGE:String = 'mobileControls/controlsArrows';
	static inline var BUTTON_A_IMAGE:String = 'mobileControls/buttomA';
	static inline var BUTTON_B_IMAGE:String = 'mobileControls/buttomB';
	static final PAUSE_IMAGES:Array<String> = [
		'mobile/pauseButton',
		'mobile/pausebutton',
		'mobile/PauseButton'
	];

	// False while the pause button is showing the drawn fallback icon instead of the real image.
	static var pauseImageLoaded:Bool = false;

	public static function create():Void
	{
		#if android
		if (initialized)
		{
			ensureCamera();
			ensureGraphics();
			setVisible(visible);
			return;
		}

		initialized = true;
		clearPressed();

		// The saved mobile options must be read before anything uses them.
		AndroidOptions.loadSaved();

		createCamera();
		createGameplayHitbox();
		createArrows();
		createButtons();
		createHitboxes();
		createPauseButton();
		AndroidOptions.apply();

		// The touch cursor covers the whole game, on every screen (not only the ones with controls).
		TouchCursor.install();

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

	static function ensureCamera():Void
	{
		// State transitions can remove the old camera from FlxG.cameras.
		// Recreate it instead of re-registering a possibly stale camera.
		if (mobileCamera == null || FlxG.cameras.list.indexOf(mobileCamera) == -1)
			createCamera();

		if (arrows != null)
			arrows.cameras = [mobileCamera];

		if (buttonA != null)
			buttonA.cameras = [mobileCamera];

		if (buttonB != null)
			buttonB.cameras = [mobileCamera];
		if (hitboxArrows != null) hitboxArrows.cameras = [mobileCamera];
		if (hitboxA != null) hitboxA.cameras = [mobileCamera];
		if (hitboxB != null) hitboxB.cameras = [mobileCamera];
		if (pauseButton != null) pauseButton.cameras = [mobileCamera];
		if (gameplayHitbox != null) gameplayHitbox.cameras = [mobileCamera];
	}

	/**
	 * Keeps a graphic out of Paths' memory cleanup. These sprites live in static variables,
	 * longer than any single state, so Paths must never treat their images as unused.
	 */
	static function protect(graphic:FlxGraphic):Void
	{
		if (graphic != null && graphic.key != null)
			Paths.excludeAsset(graphic.key);
	}

	/** False when the sprite has no image, or when its image was destroyed (the sprite then shows the Flixel placeholder cube). */
	static function graphicUsable(sprite:FlxSprite):Bool
	{
		return sprite != null && sprite.graphic != null && sprite.graphic.bitmap != null;
	}

	/** Loads the images of any control whose image is missing or was destroyed. Safe to call as often as needed. */
	static function ensureGraphics():Void
	{
		if (arrows != null && !graphicUsable(arrows))
		{
			loadArrowsGraphic();
			arrows.updateHitbox();
		}

		if (buttonA != null && !graphicUsable(buttonA))
		{
			loadButtonGraphic(buttonA, BUTTON_A_IMAGE);
			buttonA.updateHitbox();
		}

		if (buttonB != null && !graphicUsable(buttonB))
		{
			loadButtonGraphic(buttonB, BUTTON_B_IMAGE);
			buttonB.updateHitbox();
		}

		// Also retries when the real pause image was not available the first time.
		if (pauseButton != null && (!pauseImageLoaded || !graphicUsable(pauseButton)))
			loadPauseGraphic();
	}

	// Lane options (style, opacity) the current gameplay hitbox was built with.
	static var laneSignature:String = '';

	static function createGameplayHitbox():Void
	{
		AndroidOptions.applyLaneSettings();
		Hitbox.invisible = false;
		// No dead strip at the top: only the pause button area is excluded (see isReservedTouch).
		Hitbox.ignoreTop = 0;

		// Where the touch lanes start and end horizontally, in game pixels (the game is 959 wide).
		// 0 = the screen edge. Example: marginLeft = 120 starts the lanes 120 pixels from the left edge.
		Hitbox.marginLeft = -50;
		Hitbox.marginRight = -50;
		gameplayHitbox = new Hitbox();
		gameplayHitbox.cameras = [mobileCamera];
		laneSignature = AndroidOptions.laneSignature();
	}

	/** Builds the gameplay hitbox again when the lane options changed since it was created. */
	static function refreshGameplayHitbox():Void
	{
		if (gameplayHitbox != null && laneSignature == AndroidOptions.laneSignature())
			return;

		if (gameplayHitbox != null)
		{
			gameplayHitbox.destroy();
			gameplayHitbox = null;
		}

		createGameplayHitbox();
	}

	static function loadArrowsGraphic():Void
	{
		arrows.frames = Paths.getSparrowAtlas(ARROWS_IMAGE);
		protect(arrows.graphic);

		arrows.animation.addByPrefix('idle', 'idle', 24, false);
		arrows.animation.addByPrefix('leftClick', 'leftClick', 24, false);
		arrows.animation.addByPrefix('downClick', 'downClick', 24, false);
		arrows.animation.addByPrefix('rightClick', 'rightClick', 24, false);
		arrows.animation.addByPrefix('upClick', 'upClick', 24, false);

		arrows.animation.play('idle');
	}

	static function loadButtonGraphic(button:FlxSprite, image:String):Void
	{
		var graphic:FlxGraphic = Paths.image(image);

		if (graphic == null)
		{
			trace('MOBILE CONTROLS ERROR: ' + image + ' could not be loaded.');
			return;
		}

		button.loadGraphic(graphic);
		protect(graphic);
	}

	static function createArrows():Void
	{
		arrows = new FlxSprite(arrowX, arrowY);

		loadArrowsGraphic();

		arrows.antialiasing = false;
		arrows.scale.set(arrowScale, arrowScale);
		arrows.updateHitbox();

		arrows.scrollFactor.set();
		arrows.cameras = [mobileCamera];
	}

	static function createButtons():Void
	{
		buttonA = new FlxSprite(buttonAX, buttonAY);

		loadButtonGraphic(buttonA, BUTTON_A_IMAGE);

		buttonA.antialiasing = false;
		buttonA.scale.set(buttonScale, buttonScale);
		buttonA.updateHitbox();

		buttonA.scrollFactor.set();
		buttonA.cameras = [mobileCamera];

		buttonB = new FlxSprite(buttonBX, buttonBY);

		loadButtonGraphic(buttonB, BUTTON_B_IMAGE);

		buttonB.antialiasing = false;
		buttonB.scale.set(buttonScale, buttonScale);
		buttonB.updateHitbox();

		buttonB.scrollFactor.set();
		buttonB.cameras = [mobileCamera];
	}

	static function createHitboxes():Void
	{
		hitboxArrows = new HitBox(arrowX, arrowY, arrows.width, arrows.height, 'arrows');
		hitboxArrows.cameras = [mobileCamera];

		hitboxA = new HitBox(buttonAX, buttonAY, buttonA.width, buttonA.height, 'buttonA');
		hitboxA.cameras = [mobileCamera];

		hitboxB = new HitBox(buttonBX, buttonBY, buttonB.width, buttonB.height, 'buttonB');
		hitboxB.cameras = [mobileCamera];

		applyMobileOptions();
	}

	/**
	 * Loads the pause icon (the common filename spellings are tried). If no image can be loaded,
	 * a simple pause icon is drawn in code, so the button never shows the Flixel placeholder cube.
	 */
	static function loadPauseGraphic():Void
	{
		var pauseGraphic:FlxGraphic = null;

		for (imagePath in PAUSE_IMAGES)
		{
			try
			{
				var candidate:FlxGraphic = Paths.image(imagePath);

				if (candidate != null && candidate.bitmap != null)
				{
					pauseGraphic = candidate;
					break;
				}
			}
			catch (e:Dynamic) {}
		}

		if (pauseGraphic != null)
		{
			pauseButton.loadGraphic(pauseGraphic);
			protect(pauseGraphic);
			pauseImageLoaded = true;
		}
		else
		{
			trace('MOBILE PAUSE BUTTON ERROR: images/mobile/pauseButton.png was not found or could not be loaded.');
			Paths.reportAssetProblem('IMAGE', 'mobile/pauseButton', 'pause button image missing or unreadable; a drawn icon is used instead');
			drawFallbackPauseIcon();
			pauseImageLoaded = false;
		}

		pauseButton.setGraphicSize(56, 56);
		pauseButton.updateHitbox();
		pauseButton.antialiasing = false;
	}

	/** A rounded dark square with two white bars. */
	static function drawFallbackPauseIcon():Void
	{
		pauseButton.makeGraphic(56, 56, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(pauseButton, 0, 0, 56, 56, 12, 12, 0xAA000000);
		FlxSpriteUtil.drawRect(pauseButton, 18, 14, 8, 28, FlxColor.WHITE);
		FlxSpriteUtil.drawRect(pauseButton, 32, 14, 8, 28, FlxColor.WHITE);
	}

	static function createPauseButton():Void
	{
		pauseButton = new FlxSprite(FlxG.width - 80, 24);

		loadPauseGraphic();

		pauseButton.scrollFactor.set();
		pauseButton.cameras = [mobileCamera];
		applyMobileOptions();
	}

	/** One vibration pulse when a control or a hitbox lane was just touched (VIBRATION option). */
	static function vibrateOnPress():Void
	{
		if (AndroidOptions.vibrationMs() <= 0)
			return;

		var pressed:Bool = upJustPressed || downJustPressed || leftJustPressed || rightJustPressed
			|| aJustPressed || bJustPressed || pauseJustPressed;

		for (lane in 0...Hitbox.LANES)
		{
			if (Hitbox.justPressed(lane))
				pressed = true;
		}

		if (pressed)
			DeviceUtil.tap();
	}

	#end

	public static function addToState(state:Dynamic):Void
	{
		#if android
		if (!initialized)
			create();

		if (state == null || !initialized)
			return;

		// The images may have been cleaned from memory since the controls were created.
		ensureGraphics();

		if (currentState == state)
		{
			setVisible(visible);
			return;
		}

		if (currentState != null)
			removeFromState(currentState);

		currentState = state;

		if (Std.isOfType(state, states.PlayState))
			refreshGameplayHitbox();

		if (Std.isOfType(state, states.PlayState) && gameplayHitbox != null && !state.members.contains(gameplayHitbox))
			state.add(gameplayHitbox);

		if (arrows != null && !state.members.contains(arrows))
			state.add(arrows);

		if (buttonA != null && !state.members.contains(buttonA))
			state.add(buttonA);

		if (buttonB != null && !state.members.contains(buttonB))
			state.add(buttonB);
		if (hitboxArrows != null && !state.members.contains(hitboxArrows)) state.add(hitboxArrows);
		if (hitboxA != null && !state.members.contains(hitboxA)) state.add(hitboxA);
		if (hitboxB != null && !state.members.contains(hitboxB)) state.add(hitboxB);
		if (Std.isOfType(state, states.PlayState) && pauseButton != null)
		{
			if (!state.members.contains(pauseButton)) state.add(pauseButton);
		}

		setVisible(visible);
		applyMobileOptions();
		#end
	}

	public static function removeFromState(state:Dynamic):Void
	{
		#if android
		if (state == null)
			return;

		if (gameplayHitbox != null && state.members.contains(gameplayHitbox))
			state.remove(gameplayHitbox, false);

		if (arrows != null && state.members.contains(arrows))
			state.remove(arrows, false);

		if (buttonA != null && state.members.contains(buttonA))
			state.remove(buttonA, false);

		if (buttonB != null && state.members.contains(buttonB)) state.remove(buttonB, false);
		if (hitboxArrows != null && state.members.contains(hitboxArrows)) state.remove(hitboxArrows, false);
		if (hitboxA != null && state.members.contains(hitboxA)) state.remove(hitboxA, false);
		if (hitboxB != null && state.members.contains(hitboxB)) state.remove(hitboxB, false);
		if (pauseButton != null && state.members.contains(pauseButton)) state.remove(pauseButton, false);

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
		touchPause = false;

		for (touch in FlxG.touches.list)
		{
			if (touch == null || !touch.pressed)
				continue;

			checkArrowTouch(touch);
			checkButtonTouch(touch);
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
		pauseJustPressed = touchPause && !previousPause;

		previousUp = upPressed;
		previousDown = downPressed;
		previousLeft = leftPressed;
		previousRight = rightPressed;

		previousA = aPressed;
		previousB = bPressed;
		previousPause = touchPause;

		vibrateOnPress();

		updateAnimation();

		if (fadeTimer > 0)
		{
			fadeTimer -= FlxG.elapsed;

			var progress:Float = 1 - Math.max(0, fadeTimer) / fadeDuration;
			var alpha:Float = FlxEase.quadOut(progress);

			if (arrows != null)
				arrows.alpha = alpha * controlsOpacity;

			if (buttonA != null)
				buttonA.alpha = alpha * controlsOpacity;

			if (buttonB != null)
				buttonB.alpha = alpha * controlsOpacity;
		}
		#end
	}

	#if android
	static function getTouchPosition(touch:Dynamic):Dynamic
	{
		if (touch == null || mobileCamera == null)
			return null;

		return touch.getScreenPosition(mobileCamera);
	}

	static function isPointInside(pointX:Float, pointY:Float, sprite:FlxSprite):Bool
	{
		if (sprite == null || !sprite.visible)
			return false;

		return pointX >= sprite.x &&
			pointX <= sprite.x + sprite.width &&
			pointY >= sprite.y &&
			pointY <= sprite.y + sprite.height;
	}

	/** The pause button's area, a bit bigger than the icon so a thumb does not miss it or hit a lane by mistake. */
	static function isPointInsidePause(pointX:Float, pointY:Float):Bool
	{
		if (pauseButton == null || !pauseButton.visible)
			return false;

		var padding:Float = 12;

		return pointX >= pauseButton.x - padding &&
			pointX <= pauseButton.x + pauseButton.width + padding &&
			pointY >= pauseButton.y - padding &&
			pointY <= pauseButton.y + pauseButton.height + padding;
	}

	static function checkArrowTouch(touch:Dynamic):Void
	{
		if (arrows == null || !arrows.visible || mobileCamera == null)
			return;

		var point:Dynamic = getTouchPosition(touch);

		if (point == null)
			return;

		var pointX:Float = point.x;
		var pointY:Float = point.y;

		// Keep the arrow artwork where it is, but extend only the Left/Right
		// touch zones horizontally so they are easier to press on a 959x670 screen.
		var sideTouchPadding:Float = 42;
		var left:Float = arrows.x - sideTouchPadding;
		var right:Float = arrows.x + arrows.width + sideTouchPadding;
		var top:Float = arrows.y;
		var bottom:Float = arrows.y + arrows.height;

		if (pointX < left || pointX > right || pointY < top || pointY > bottom)
			return;

		var centerX:Float = arrows.x + arrows.width / 2;
		var centerY:Float = arrows.y + arrows.height / 2;

		var relativeX:Float = pointX - centerX;
		var relativeY:Float = pointY - centerY;

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

	static function checkButtonTouch(touch:Dynamic):Void
	{
		if (mobileCamera == null)
			return;

		var point:Dynamic = getTouchPosition(touch);

		if (point == null)
			return;

		var pointX:Float = point.x;
		var pointY:Float = point.y;

		if (buttonA != null && buttonA.visible && hitboxA != null &&
			hitboxA.containsPoint(pointX, pointY))
		{
			touchA = true;
		}

		if (buttonB != null && buttonB.visible && hitboxB != null && hitboxB.containsPoint(pointX, pointY)) touchB = true;
		if (isPointInsidePause(pointX, pointY)) touchPause = true;
	}

	public static function isReservedTouch(touch:Dynamic):Bool
	{
		#if android
		var point:Dynamic = getTouchPosition(touch);
		if (point == null)
			return false;

		var x:Float = point.x;
		var y:Float = point.y;

		if (arrows != null && arrows.visible && hitboxArrows != null && hitboxArrows.containsPoint(x, y))
			return true;
		if (buttonA != null && buttonA.visible && hitboxA != null && hitboxA.containsPoint(x, y))
			return true;
		if (buttonB != null && buttonB.visible && hitboxB != null && hitboxB.containsPoint(x, y))
			return true;
		if (isPointInsidePause(x, y))
			return true;
		#end
		return false;
	}

	static function updateAnimation():Void
	{
		if (arrows == null)
			return;

		if (upPressed)
			arrows.animation.play('upClick', true);
		else if (downPressed)
			arrows.animation.play('downClick', true);
		else if (leftPressed)
			arrows.animation.play('leftClick', true);
		else if (rightPressed)
			arrows.animation.play('rightClick', true);
		else
			arrows.animation.play('idle', true);
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
		pauseJustPressed = false;
	}

	static function clearPressed():Void
	{
		upPressed = false;
		downPressed = false;
		leftPressed = false;
		rightPressed = false;

		aPressed = false;
		bPressed = false;

		upJustPressed = false;
		downJustPressed = false;
		leftJustPressed = false;
		rightJustPressed = false;

		aJustPressed = false;
		bJustPressed = false;

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
		// During a song only the touch lanes (gameplay hitbox) are used: the arrows and the
		// A/B buttons are hidden, which also means they no longer take touches there.
		var showControls:Bool = value && !Std.isOfType(currentState, states.PlayState);

		if (arrows != null)
			arrows.visible = showControls;

		if (buttonA != null)
			buttonA.visible = showControls;

		if (buttonB != null)
			buttonB.visible = showControls;

		applyMobileOptions();
		if (value)
			fadeIn();
		#end
	}

	public static function fadeIn(duration:Float = 0.45):Void
	{
		#if android
		fadeDuration = Math.max(0.01, duration);
		fadeTimer = fadeDuration;

		if (arrows != null)
			arrows.alpha = 0;

		if (buttonA != null)
			buttonA.alpha = 0;

		if (buttonB != null)
			buttonB.alpha = 0;
		#end
	}
	public static function setAlpha(value:Float):Void
	{
		#if android
		if (arrows != null)
			arrows.alpha = value * controlsOpacity;

		if (buttonA != null)
			buttonA.alpha = value * controlsOpacity;

		if (buttonB != null)
			buttonB.alpha = value * controlsOpacity;
		#end
	}

	/** CONTROLS OPACITY option: how visible the arrows and the A/B buttons are (0.1 to 1). */
	public static function setControlsOpacity(value:Float):Void
	{
		controlsOpacity = Math.max(0.1, Math.min(1, value));

		#if android
		// While the fade-in runs, update() already uses the new value; otherwise apply it now.
		if (fadeTimer <= 0)
			setAlpha(1);
		#end
	}

	public static function applyMobileOptions():Void
	{
		#if android
		var inSong:Bool = Std.isOfType(currentState, states.PlayState);
		var showAreas:Bool = ClientPrefs.data.mobileShowHitbox && visible;

		// SHOW HITBOX shows the touch areas: outside songs the boxes of the arrows and A/B buttons...
		for (box in [hitboxArrows, hitboxA, hitboxB])
			if (box != null) box.visible = showAreas && !inSong;

		// ...and during songs the touch lanes stay faintly visible.
		Hitbox.showIdle = showAreas && inSong;

		// SHOW PAUSE BUTTON (mobilePauseButton) was saved by the options menu but never read here.
		var showPause:Bool = ClientPrefs.data.mobilePauseButton && Std.isOfType(currentState, states.PlayState) && visible;
		if (pauseButton != null) pauseButton.visible = showPause;
		#end
	}

	public static function isAttachedTo(state:Dynamic):Bool
	{
		#if android
		return initialized && currentState == state;
		#else
		return false;
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
		if (hitboxArrows != null) hitboxArrows.setBounds(arrowX, arrowY, arrows != null ? arrows.width : hitboxArrows.width, arrows != null ? arrows.height : hitboxArrows.height);

		if (buttonA != null)
		{
			buttonA.x = buttonAX;
			buttonA.y = buttonAY;
		}
		if (hitboxA != null) hitboxA.setBounds(buttonAX, buttonAY, buttonA != null ? buttonA.width : hitboxA.width, buttonA != null ? buttonA.height : hitboxA.height);

		if (buttonB != null)
		{
			buttonB.x = buttonBX;
			buttonB.y = buttonBY;
		}
		if (hitboxB != null) hitboxB.setBounds(buttonBX, buttonBY, buttonB != null ? buttonB.width : hitboxB.width, buttonB != null ? buttonB.height : hitboxB.height);
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
			if (hitboxArrows != null) hitboxArrows.setBounds(arrows.x, arrows.y, arrows.width, arrows.height);
		}

		if (buttonA != null)
		{
			buttonA.scale.set(buttonScale, buttonScale);
			buttonA.updateHitbox();
			if (hitboxA != null) hitboxA.setBounds(buttonA.x, buttonA.y, buttonA.width, buttonA.height);
		}

		if (buttonB != null)
		{
			buttonB.scale.set(buttonScale, buttonScale);
			buttonB.updateHitbox();
			if (hitboxB != null) hitboxB.setBounds(buttonB.x, buttonB.y, buttonB.width, buttonB.height);
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

		if (gameplayHitbox != null)
		{
			gameplayHitbox.destroy();
			gameplayHitbox = null;
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
