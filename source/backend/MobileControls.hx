package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.touch.FlxTouch;
import flixel.util.FlxColor;

class MobileControls extends FlxGroup
{
	public static var instance:MobileControls;

	public static var enabled:Bool = true;
	public static var visibleControls:Bool = true;

	public static var leftPressed:Bool = false;
	public static var downPressed:Bool = false;
	public static var upPressed:Bool = false;
	public static var rightPressed:Bool = false;

	public static var acceptPressed:Bool = false;
	public static var backPressed:Bool = false;
	public static var pausePressed:Bool = false;

	private var leftButton:FlxSprite;
	private var downButton:FlxSprite;
	private var upButton:FlxSprite;
	private var rightButton:FlxSprite;

	private var acceptButton:FlxSprite;
	private var backButton:FlxSprite;
	private var pauseButton:FlxSprite;

	private var buttonSize:Int = 96;
	private var buttonSpacing:Int = 12;
	private var margin:Int = 24;

	public function new()
	{
		super();

		instance = this;

		scrollFactor.set();
		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

		createControls();
		updateLayout();
	}

	private function createControls():Void
	{
		leftButton = createButton('mobileLeft');
		downButton = createButton('mobileDown');
		upButton = createButton('mobileUp');
		rightButton = createButton('mobileRight');

		acceptButton = createButton('mobileAccept');
		backButton = createButton('mobileBack');
		pauseButton = createButton('mobilePause');

		add(leftButton);
		add(downButton);
		add(upButton);
		add(rightButton);

		add(acceptButton);
		add(backButton);
		add(pauseButton);

		leftButton.alpha = 0.55;
		downButton.alpha = 0.55;
		upButton.alpha = 0.55;
		rightButton.alpha = 0.55;

		acceptButton.alpha = 0.55;
		backButton.alpha = 0.55;
		pauseButton.alpha = 0.55;
	}

	private function createButton(tag:String):FlxSprite
	{
		var button = new FlxSprite();
		button.ID = 0;
		button.makeGraphic(buttonSize, buttonSize, FlxColor.WHITE);
		button.scrollFactor.set();
		button.alpha = 0.55;
		button.antialiasing = false;
		return button;
	}

	private function updateLayout():Void
	{
		var screenWidth:Float = FlxG.width;
		var screenHeight:Float = FlxG.height;

		var arrowsX:Float = margin;
		var arrowsY:Float = screenHeight - buttonSize - margin;

		leftButton.setPosition(arrowsX, arrowsY);
		downButton.setPosition(arrowsX + buttonSize + buttonSpacing, arrowsY);
		upButton.setPosition(arrowsX + (buttonSize + buttonSpacing) * 2, arrowsY);
		rightButton.setPosition(arrowsX + (buttonSize + buttonSpacing) * 3, arrowsY);

		var menuX:Float = screenWidth - buttonSize - margin;

		pauseButton.setPosition(menuX, margin);

		acceptButton.setPosition(screenWidth - (buttonSize * 2) - margin - buttonSpacing, screenHeight - buttonSize - margin);
		backButton.setPosition(screenWidth - buttonSize - margin, screenHeight - buttonSize - margin);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if(!enabled)
		{
			resetButtons();
			return;
		}

		if(FlxG.width <= 0 || FlxG.height <= 0)
			return;

		updateLayout();
		updateTouchInput();
		updateButtonVisibility();
	}

	private function updateTouchInput():Void
	{
		resetButtons();

		for(touch in FlxG.touches.list)
		{
			if(touch == null)
				continue;

			var x:Float = touch.screenX;
			var y:Float = touch.screenY;

			if(isInside(touch, leftButton))
				leftPressed = true;

			if(isInside(touch, downButton))
				downPressed = true;

			if(isInside(touch, upButton))
				upPressed = true;

			if(isInside(touch, rightButton))
				rightPressed = true;

			if(isInside(touch, acceptButton))
				acceptPressed = true;

			if(isInside(touch, backButton))
				backPressed = true;

			if(isInside(touch, pauseButton))
				pausePressed = true;
		}

		updateButtonAlpha(leftButton, leftPressed);
		updateButtonAlpha(downButton, downPressed);
		updateButtonAlpha(upButton, upPressed);
		updateButtonAlpha(rightButton, rightPressed);

		updateButtonAlpha(acceptButton, acceptPressed);
		updateButtonAlpha(backButton, backPressed);
		updateButtonAlpha(pauseButton, pausePressed);
	}

	private function isInside(touch:FlxTouch, button:FlxSprite):Bool
	{
		return touch.screenX >= button.x &&
			touch.screenX <= button.x + button.width &&
			touch.screenY >= button.y &&
			touch.screenY <= button.y + button.height;
	}

	private function updateButtonAlpha(button:FlxSprite, pressed:Bool):Void
	{
		button.alpha = pressed ? 0.9 : 0.55;
	}

	private function resetButtons():Void
	{
		leftPressed = false;
		downPressed = false;
		upPressed = false;
		rightPressed = false;

		acceptPressed = false;
		backPressed = false;
		pausePressed = false;
	}

	private function updateButtonVisibility():Void
	{
		var value:Float = visibleControls ? 1 : 0;

		leftButton.visible = visibleControls;
		downButton.visible = visibleControls;
		upButton.visible = visibleControls;
		rightButton.visible = visibleControls;

		acceptButton.visible = visibleControls;
		backButton.visible = visibleControls;
		pauseButton.visible = visibleControls;
	}

	public static function isMobile():Bool
	{
		#if android
		return true;
		#elseif ios
		return true;
		#else
		return false;
		#end
	}

	public static function isAndroid():Bool
	{
		#if android
		return true;
		#else
		return false;
		#end
	}

	public static function isIOS():Bool
	{
		#if ios
		return true;
		#else
		return false;
		#end
	}

	public static function setControlsVisible(value:Bool):Void
	{
		visibleControls = value;

		if(instance != null)
			instance.updateButtonVisibility();
	}

	public static function setControlsEnabled(value:Bool):Void
	{
		enabled = value;

		if(!value && instance != null)
			instance.resetButtons();
	}

	public static function toggleFullscreen():Void
	{
		FlxG.fullscreen = !FlxG.fullscreen;
	}

	public static function setFullscreen(value:Bool):Void
	{
		FlxG.fullscreen = value;
	}

	public static function getScreenWidth():Int
	{
		return FlxG.width;
	}

	public static function getScreenHeight():Int
	{
		return FlxG.height;
	}

	public static function resizeControls():Void
	{
		if(instance != null)
			instance.updateLayout();
	}

	public static function isLeftPressed():Bool
	{
		return leftPressed;
	}

	public static function isDownPressed():Bool
	{
		return downPressed;
	}

	public static function isUpPressed():Bool
	{
		return upPressed;
	}

	public static function isRightPressed():Bool
	{
		return rightPressed;
	}

	public static function isAcceptPressed():Bool
	{
		return acceptPressed;
	}

	public static function isBackPressed():Bool
	{
		return backPressed;
	}

	public static function isPausePressed():Bool
	{
		return pausePressed;
	}
}
