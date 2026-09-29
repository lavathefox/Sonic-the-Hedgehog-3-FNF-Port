package options;

import backend.ClientPrefs;
import backend.InputFormatter;
import backend.MusicBeatSubstate;
import backend.Paths;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class SonicControlsSubstate extends MusicBeatSubstate
{
	var options:Array<Dynamic> = [
		[true, 'NOTES'],
		[true, 'Left', 'note_left', 'Note Left'],
		[true, 'Down', 'note_down', 'Note Down'],
		[true, 'Up', 'note_up', 'Note Up'],
		[true, 'Right', 'note_right', 'Note Right'],
		[true],
		[true, 'UI'],
		[true, 'Left', 'ui_left', 'UI Left'],
		[true, 'Down', 'ui_down', 'UI Down'],
		[true, 'Up', 'ui_up', 'UI Up'],
		[true, 'Right', 'ui_right', 'UI Right'],
		[true],
		[true, 'Reset', 'reset', 'Reset'],
		[true, 'Accept', 'accept', 'Accept'],
		[true, 'Back', 'back', 'Back'],
		[true, 'Pause', 'pause', 'Pause'],
		[false],
		[false, 'VOLUME'],
		[false, 'Mute', 'volume_mute', 'Volume Mute'],
		[false, 'Up', 'volume_up', 'Volume Up'],
		[false, 'Down', 'volume_down', 'Volume Down'],
		[false],
		[false, 'DEBUG'],
		[false, 'Key 1', 'debug_1', 'Debug Key #1'],
		[false, 'Key 2', 'debug_2', 'Debug Key #2']
	];

	var defaultKey:String = 'Reset to Default Keys';

	var curSelected:Int = 0;
	var curAlt:Bool = false;

	var curOptions:Array<Int> = [];
	var curOptionsValid:Array<Int> = [];

	var lastID:Int = 0;
	var onKeyboardMode:Bool = true;

	var canSelect:Bool = true;
	var isMoving:Bool = false;
	var binding:Bool = false;

	var holdingEsc:Float = 0;
	var holdingBackspace:Float = 0;

	var timeForMoving:Float = 0.1;

	var optionsCamera:FlxCamera;

	var optionSprites:Array<Array<FlxSprite>> = [];
	var bindSprites:Array<Array<FlxSprite>> = [];

	var optionSpriteIDs:Array<Int> = [];
	var bindSpriteIDs:Array<Int> = [];

	var selectedArrow:FlxSprite;
	var controllerSprite:FlxSprite;

	var bindingBackground:FlxSprite;
	var bindingTitle:Array<FlxSprite> = [];
	var bindingInfo:Array<FlxSprite> = [];

	var optionY:Float = 110;
	var optionSpacing:Float = 62;

	var optionX:Float = 400;
	var bindX1:Float = 630;
	var bindX2:Float = 750;

	var cursorX:Float = 220;

	var letterScale:Float = 2;
	var letterSpacing:Float = 4;
	var arrowScale:Float = 2;

	var cursorTweenTime:Float = 0.15;
	var textTweenTime:Float = 0.15;

	var controllerX:Float = 115;
	var controllerY:Float = 55;

	var currentTextOffsetY:Float = 0;
	var textOffsetTween:Dynamic;

	var scrollStartID:Int = 8;

	override public function create():Void
	{
		super.create();

		createOptionsCamera();
		createControllerSprite();

		options.push([true, defaultKey]);

		createTexts();
		createCursor();
		updateSelection(false);
	}

	function createOptionsCamera():Void
	{
		optionsCamera = new FlxCamera();
		optionsCamera.bgColor.alpha = 0;
		optionsCamera.zoom = 1;
		optionsCamera.scroll.set(0, 0);
		optionsCamera.pixelPerfectRender = true;

		FlxG.cameras.add(optionsCamera, false);
	}

	function setOptionsCamera(sprite:FlxSprite):Void
	{
		sprite.cameras = [optionsCamera];
		sprite.scrollFactor.set();
	}

	function getLetterPath(char:String):String
	{
		char = char.toUpperCase();

		if (char == ':')
			return 'hud/letershud/colon2';

		return 'hud/letershud/' + char;
	}

	function getLetterWidth(char:String):Float
	{
		var letter:FlxSprite = new FlxSprite();
		letter.loadGraphic(Paths.image(getLetterPath(char)));
		letter.antialiasing = false;
		letter.scale.set(letterScale, letterScale);
		letter.updateHitbox();

		return letter.width;
	}

	function getTextWidth(text:String):Float
	{
		var total:Float = 0;
		text = text.toUpperCase();

		for (i in 0...text.length)
		{
			var char:String = text.charAt(i);

			if (char == ' ')
				total += letterSpacing;
			else
				total += getLetterWidth(char);
		}

		return total;
	}

	function createText(text:String, x:Float, y:Float, scale:Float):Array<FlxSprite>
	{
		var sprites:Array<FlxSprite> = [];
		text = text.toUpperCase();

		var oldScale:Float = letterScale;
		letterScale = scale;

		var totalWidth:Float = getTextWidth(text);
		var offsetX:Float = -totalWidth / 2;

		for (i in 0...text.length)
		{
			var char:String = text.charAt(i);

			if (char == ' ')
			{
				offsetX += letterSpacing;
				continue;
			}

			var letter:FlxSprite = new FlxSprite(x + offsetX, y);
			letter.loadGraphic(Paths.image(getLetterPath(char)));
			letter.antialiasing = false;
			letter.scale.set(scale, scale);
			letter.updateHitbox();

			setOptionsCamera(letter);
			add(letter);

			sprites.push(letter);
			offsetX += letter.width;
		}

		letterScale = oldScale;

		return sprites;
	}

	function setTextAlpha(sprites:Array<FlxSprite>, alpha:Float):Void
	{
		for (sprite in sprites)
		{
			if (sprite != null)
				sprite.alpha = alpha;
		}
	}

	function destroyText(sprites:Array<FlxSprite>):Void
	{
		for (sprite in sprites)
		{
			if (sprite != null)
				sprite.destroy();
		}
	}

	function createControllerSprite():Void
	{
		controllerSprite = new FlxSprite(controllerX, controllerY);
		controllerSprite.loadGraphic(Paths.image('controllertype'), true, 82, 60);
		controllerSprite.antialiasing = false;
		controllerSprite.animation.add('keyboard', [0], 1, false);
		controllerSprite.animation.add('gamepad', [1], 1, false);
		controllerSprite.animation.play(onKeyboardMode ? 'keyboard' : 'gamepad');
		controllerSprite.scale.set(2, 2);
		controllerSprite.updateHitbox();

		setOptionsCamera(controllerSprite);
		add(controllerSprite);
	}

	function createTexts():Void
	{
		destroyOptionSprites();
		destroyBindSprites();

		curOptions = [];
		curOptionsValid = [];
		optionSpriteIDs = [];
		bindSpriteIDs = [];

		var myID:Int = 0;

		for (i in 0...options.length)
		{
			var option:Array<Dynamic> = options[i];

			if (!onKeyboardMode && !option[0])
				continue;

			if (option.length <= 1)
			{
				myID++;
				continue;
			}

			var isCentered:Bool = option.length < 3;
			var isDefaultKey:Bool = option[1] == defaultKey;
			var text:String = option[1];

			if (isDefaultKey)
				text = 'RESET';

			var optionText:Array<FlxSprite> = createText(text, optionX, optionY + myID * optionSpacing, letterScale);

			optionSprites.push(optionText);
			optionSpriteIDs.push(myID);

			if (!isCentered)
			{
				curOptions.push(i);
				curOptionsValid.push(myID);

				createBinds(option[2], myID);
			}

			lastID = myID;
			myID++;
		}

		currentTextOffsetY = 0;

		updateTextPositions();
	}

	function createBinds(saveKey:String, id:Int):Void
	{
		var firstKey:String = getBindName(saveKey, 0);
		var secondKey:String = getBindName(saveKey, 1);

		var first:Array<FlxSprite> = createText(firstKey, bindX1, optionY + id * optionSpacing, letterScale);
		var second:Array<FlxSprite> = createText(secondKey, bindX2, optionY + id * optionSpacing, letterScale);

		bindSprites.push(first);
		bindSprites.push(second);

		bindSpriteIDs.push(id);
		bindSpriteIDs.push(id);
	}

	function getBindName(saveKey:String, index:Int):String
	{
		if (onKeyboardMode)
		{
			var keys:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(saveKey);

			if (keys == null)
			{
				var defaults:Array<Null<FlxKey>> = ClientPrefs.defaultKeys.get(saveKey);

				if (defaults != null)
					keys = defaults.copy();
			}

			if (keys == null || index >= keys.length)
				return 'NONE';

			var key:Null<FlxKey> = keys[index];

			if (key == null || key == FlxKey.NONE)
				return 'NONE';

			return InputFormatter.getKeyName(key);
		}

		var buttons:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(saveKey);

		if (buttons == null)
		{
			var defaults:Array<Null<FlxGamepadInputID>> = ClientPrefs.defaultButtons.get(saveKey);

			if (defaults != null)
				buttons = defaults.copy();
		}

		if (buttons == null || index >= buttons.length)
			return 'NONE';

		var button:Null<FlxGamepadInputID> = buttons[index];

		if (button == null || button == FlxGamepadInputID.NONE)
			return 'NONE';

		return InputFormatter.getGamepadName(button);
	}

	function destroyOptionSprites():Void
	{
		for (sprites in optionSprites)
			destroyText(sprites);

		optionSprites = [];
	}

	function destroyBindSprites():Void
	{
		for (sprites in bindSprites)
			destroyText(sprites);

		bindSprites = [];
	}

	function updateTextPositions():Void
	{
		if (curOptions.length <= 0)
			return;

		if (curSelected >= curOptionsValid.length)
			curSelected = curOptionsValid.length - 1;

		var selectedID:Int = curOptionsValid[curSelected];

		var targetOffset:Float = 0;

		if (selectedID > scrollStartID)
			targetOffset = -(selectedID - scrollStartID) * optionSpacing;

		moveAllText(targetOffset);

		for (i in 0...optionSprites.length)
		{
			var id:Int = optionSpriteIDs[i];
			var alpha:Float = id == selectedID ? 1 : 0.6;

			setTextAlpha(optionSprites[i], alpha);
		}

		for (i in 0...bindSprites.length)
		{
			var id:Int = bindSpriteIDs[i];
			var alpha:Float = id == selectedID ? 1 : 0.6;

			setTextAlpha(bindSprites[i], alpha);
		}
	}

	function moveAllText(targetOffset:Float):Void
	{
		if (textOffsetTween != null)
		{
			FlxTween.cancelTweensOf(textOffsetTween);
			textOffsetTween = null;
		}

		if (Math.abs(currentTextOffsetY - targetOffset) < 0.01)
		{
			currentTextOffsetY = targetOffset;
			applyTextOffset();
			return;
		}

		var tweenData:Dynamic = {value: currentTextOffsetY};

		textOffsetTween = tweenData;

		FlxTween.tween(tweenData, {value: targetOffset}, textTweenTime, {
			ease: FlxEase.quadOut,
			onUpdate: function(tween:FlxTween)
			{
				currentTextOffsetY = tweenData.value;
				applyTextOffset();
			},
			onComplete: function(tween:FlxTween)
			{
				currentTextOffsetY = targetOffset;
				applyTextOffset();
				textOffsetTween = null;
			}
		});
	}

	function applyTextOffset():Void
	{
		for (i in 0...optionSprites.length)
		{
			var id:Int = optionSpriteIDs[i];

			for (sprite in optionSprites[i])
			{
				if (sprite != null)
					sprite.y = optionY + id * optionSpacing + currentTextOffsetY;
			}
		}

		for (i in 0...bindSprites.length)
		{
			var id:Int = bindSpriteIDs[i];

			for (sprite in bindSprites[i])
			{
				if (sprite != null)
					sprite.y = optionY + id * optionSpacing + currentTextOffsetY;
			}
		}
	}

	function createCursor():Void
	{
		selectedArrow = new FlxSprite(cursorX, optionY);
		selectedArrow.loadGraphic(Paths.image('pauseMenuEXE/selectedArrow'));
		selectedArrow.antialiasing = false;
		selectedArrow.scale.set(arrowScale, arrowScale);
		selectedArrow.updateHitbox();

		setOptionsCamera(selectedArrow);
		add(selectedArrow);
	}

	function updateSelection(playTween:Bool = true):Void
	{
		if (curOptions.length <= 0)
			return;

		if (curSelected >= curOptions.length)
			curSelected = curOptions.length - 1;

		updateTextPositions();

		var selectedID:Int = curOptionsValid[curSelected];
		var targetY:Float = optionY + selectedID * optionSpacing + getTargetTextOffset(selectedID);
		var targetX:Float = curAlt ? cursorX + 300 : cursorX;

		FlxTween.cancelTweensOf(selectedArrow);

		if (playTween)
		{
			isMoving = true;

			FlxTween.tween(selectedArrow, {x: targetX, y: targetY}, cursorTweenTime, {
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween)
				{
					isMoving = false;
				}
			});
		}
		else
		{
			selectedArrow.x = targetX;
			selectedArrow.y = targetY;
		}
	}

	function getTargetTextOffset(selectedID:Int):Float
	{
		if (selectedID > scrollStartID)
			return -(selectedID - scrollStartID) * optionSpacing;

		return 0;
	}

	function changeSelection(change:Int = 0):Void
	{
		if (isMoving || !canSelect || curOptions.length <= 0)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, curOptions.length - 1);

		FlxG.sound.play(Paths.sound('dataselectswitch'));
		updateSelection(true);
	}

	function updateAlt(doSwap:Bool = false):Void
	{
		if (doSwap)
		{
			curAlt = !curAlt;
			FlxG.sound.play(Paths.sound('dataselectswitch'));
		}

		var targetX:Float = curAlt ? cursorX + 300 : cursorX;

		FlxTween.cancelTweensOf(selectedArrow);

		FlxTween.tween(selectedArrow, {x: targetX}, cursorTweenTime, {
			ease: FlxEase.quadOut
		});
	}

	function swapMode():Void
	{
		if (binding)
			return;

		onKeyboardMode = !onKeyboardMode;
		curSelected = 0;
		curAlt = false;
		timeForMoving = 0.1;

		controllerSprite.animation.play(onKeyboardMode ? 'keyboard' : 'gamepad');

		createTexts();
		updateSelection(false);
	}

	function beginBinding():Void
	{
		if (curOptions.length <= 0)
			return;

		var option:Array<Dynamic> = options[curOptions[curSelected]];

		if (option[1] == defaultKey)
		{
			ClientPrefs.resetKeys(!onKeyboardMode);
			ClientPrefs.reloadVolumeKeys();
			ClientPrefs.saveSettings();

			createTexts();

			if (curOptions.length > 0)
				curSelected = Std.int(Math.min(curSelected, curOptions.length - 1));
			else
				curSelected = 0;

			updateSelection(false);

			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		binding = true;
		holdingEsc = 0;
		holdingBackspace = 0;

		ClientPrefs.toggleVolumeKeys(false);

		createBindingScreen(option[3]);

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function createBindingScreen(name:String):Void
	{
		destroyBindingScreen();

		bindingBackground = new FlxSprite(0, 0);
		bindingBackground.makeGraphic(1, 1, FlxColor.BLACK);
		bindingBackground.scale.set(FlxG.width, FlxG.height);
		bindingBackground.updateHitbox();
		bindingBackground.alpha = 0;

		setOptionsCamera(bindingBackground);
		add(bindingBackground);

		FlxTween.tween(bindingBackground, {alpha: 0.65}, 0.35, {
			ease: FlxEase.linear
		});

		bindingTitle = createText('REBINDING', FlxG.width / 2, 170, 3);

		var nameSprites:Array<FlxSprite> = createText(name, FlxG.width / 2, 215, 2);
		bindingTitle = bindingTitle.concat(nameSprites);

		bindingInfo = createText('PRESS A KEY', FlxG.width / 2, 270, 2);

		var secondInfo:Array<FlxSprite> = createText('HOLD ESC CANCEL', FlxG.width / 2, 320, 2);
		bindingInfo = bindingInfo.concat(secondInfo);

		var thirdInfo:Array<FlxSprite> = createText('HOLD BACKSPACE DELETE', FlxG.width / 2, 370, 2);
		bindingInfo = bindingInfo.concat(thirdInfo);
	}

	function destroyBindingScreen():Void
	{
		if (bindingBackground != null)
		{
			bindingBackground.destroy();
			bindingBackground = null;
		}

		destroyText(bindingTitle);
		destroyText(bindingInfo);

		bindingTitle = [];
		bindingInfo = [];
	}

	function closeBinding():Void
	{
		binding = false;
		holdingEsc = 0;
		holdingBackspace = 0;

		destroyBindingScreen();

		ClientPrefs.reloadVolumeKeys();
		ClientPrefs.saveSettings();

		createTexts();
		updateSelection(false);
	}

	function deleteCurrentBind():Void
	{
		if (curOptions.length <= 0)
			return;

		var option:Array<Dynamic> = options[curOptions[curSelected]];
		var altNum:Int = curAlt ? 1 : 0;

		if (onKeyboardMode)
		{
			var keys:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option[2]);

			if (keys != null && altNum < keys.length)
				keys[altNum] = FlxKey.NONE;
		}
		else
		{
			var buttons:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(option[2]);

			if (buttons != null && altNum < buttons.length)
				buttons[altNum] = FlxGamepadInputID.NONE;
		}

		ClientPrefs.clearInvalidKeys(option[2]);
		ClientPrefs.saveSettings();

		FlxG.sound.play(Paths.sound('cancelMenu'));
		closeBinding();
	}

	function setKeyboardBind(key:FlxKey):Void
	{
		if (curOptions.length <= 0)
			return;

		var option:Array<Dynamic> = options[curOptions[curSelected]];
		var saveKey:String = option[2];
		var altNum:Int = curAlt ? 1 : 0;

		var keys:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(saveKey);

		if (keys == null)
		{
			var defaults:Array<Null<FlxKey>> = ClientPrefs.defaultKeys.get(saveKey);

			if (defaults == null)
				return;

			keys = defaults.copy();
			ClientPrefs.keyBinds.set(saveKey, keys);
		}

		while (keys.length < 2)
			keys.push(FlxKey.NONE);

		keys[altNum] = key;

		if (keys[1 - altNum] == key)
			keys[1 - altNum] = FlxKey.NONE;

		ClientPrefs.keyBinds.set(saveKey, keys);

		ClientPrefs.clearInvalidKeys(saveKey);
		ClientPrefs.saveSettings();

		FlxG.sound.play(Paths.sound('confirmMenu'));

		binding = false;
		holdingEsc = 0;
		holdingBackspace = 0;

		destroyBindingScreen();

		ClientPrefs.reloadVolumeKeys();

		createTexts();
		updateSelection(false);
	}

	function setGamepadBind(key:FlxGamepadInputID):Void
	{
		if (curOptions.length <= 0)
			return;

		var option:Array<Dynamic> = options[curOptions[curSelected]];
		var saveKey:String = option[2];
		var altNum:Int = curAlt ? 1 : 0;

		var buttons:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(saveKey);

		if (buttons == null)
		{
			var defaults:Array<Null<FlxGamepadInputID>> = ClientPrefs.defaultButtons.get(saveKey);

			if (defaults == null)
				return;

			buttons = defaults.copy();
			ClientPrefs.gamepadBinds.set(saveKey, buttons);
		}

		while (buttons.length < 2)
			buttons.push(FlxGamepadInputID.NONE);

		buttons[altNum] = key;

		if (buttons[1 - altNum] == key)
			buttons[1 - altNum] = FlxGamepadInputID.NONE;

		ClientPrefs.gamepadBinds.set(saveKey, buttons);

		ClientPrefs.clearInvalidKeys(saveKey);
		ClientPrefs.saveSettings();

		FlxG.sound.play(Paths.sound('confirmMenu'));

		binding = false;
		holdingEsc = 0;
		holdingBackspace = 0;

		destroyBindingScreen();

		ClientPrefs.reloadVolumeKeys();

		createTexts();
		updateSelection(false);
	}

	function setCurrentBind():Void
	{
		if (curOptions.length <= 0)
			return;

		if (onKeyboardMode)
		{
			var keyPressed:Int = FlxG.keys.firstJustPressed();

			if (keyPressed < 0)
				return;

			var newKey:FlxKey = cast keyPressed;

			if (newKey == FlxKey.NONE || newKey == FlxKey.ESCAPE || newKey == FlxKey.BACKSPACE)
				return;

			setKeyboardBind(newKey);
		}
		else
		{
			var keyPressed:FlxGamepadInputID = getPressedGamepadButton();

			if (keyPressed == FlxGamepadInputID.NONE || keyPressed == FlxGamepadInputID.BACK || keyPressed == FlxGamepadInputID.B)
				return;

			setGamepadBind(keyPressed);
		}
	}

	function getPressedGamepadButton():FlxGamepadInputID
	{
		for (i in 0...FlxG.gamepads.numActiveGamepads)
		{
			var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);

			if (gamepad == null)
				continue;

			var pressed:Null<FlxGamepadInputID> = gamepad.firstJustPressedID();

			if (pressed != null)
				return pressed;
		}

		return FlxGamepadInputID.NONE;
	}

	function updateBinding(elapsed:Float):Void
	{
		if (FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(FlxGamepadInputID.B))
		{
			holdingEsc += elapsed;

			if (holdingEsc >= 0.5)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}

			return;
		}

		holdingEsc = 0;

		if (FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(FlxGamepadInputID.BACK))
		{
			holdingBackspace += elapsed;

			if (holdingBackspace >= 0.5)
				deleteCurrentBind();

			return;
		}

		holdingBackspace = 0;

		setCurrentBind();
	}

	override function update(elapsed:Float):Void
	{
		if (timeForMoving > 0)
		{
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			return;
		}

		if (binding)
		{
			updateBinding(elapsed);
			super.update(elapsed);
			return;
		}

		if (!canSelect)
		{
			super.update(elapsed);
			return;
		}

		if (FlxG.keys.justPressed.ESCAPE || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.B))
		{
			closeControls();
			return;
		}

		if (FlxG.keys.justPressed.CONTROL || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.LEFT_SHOULDER) || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.RIGHT_SHOULDER))
		{
			swapMode();
		}
		else if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.DPAD_LEFT) || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.DPAD_RIGHT))
		{
			updateAlt(true);
		}
		else if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.DPAD_UP))
		{
			changeSelection(-1);
		}
		else if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.DPAD_DOWN))
		{
			changeSelection(1);
		}
		else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.A) || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.START))
		{
			beginBinding();
		}

		super.update(elapsed);
	}

	function closeControls():Void
	{
		if (!canSelect)
			return;

		canSelect = false;
		isMoving = false;

		ClientPrefs.saveSettings();

		FlxG.sound.play(Paths.sound('cancelMenu'));
		close();
	}

	override function destroy():Void
	{
		ClientPrefs.saveSettings();
		destroyBindingScreen();

		if (textOffsetTween != null)
		{
			FlxTween.cancelTweensOf(textOffsetTween);
			textOffsetTween = null;
		}

		if (optionsCamera != null)
		{
			FlxG.cameras.remove(optionsCamera, true);
			optionsCamera = null;
		}

		super.destroy();
	}
}
