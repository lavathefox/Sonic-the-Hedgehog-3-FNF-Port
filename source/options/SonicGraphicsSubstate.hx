package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;

import backend.MusicBeatSubstate;
import backend.Paths;
import backend.ClientPrefs;
import backend.MobileControls;

import objects.Character;

class SonicGraphicsSubstate extends MusicBeatSubstate
{
	var options:Array<String> = [];

	var curSelected:Int = 0;
	var canSelect:Bool = true;
	var isMoving:Bool = false;
	var closing:Bool = false;

	var optionSprites:Array<Array<FlxSprite>> = [];
	var checkboxes:Array<FlxSprite> = [];

	var selectedArrow:FlxSprite;
	var boyfriend:Character;

	var optionsCamera:FlxCamera;

	var optionY:Float = 128;
	var checkBoxY:Float = 198;
	var optionSpacing:Float = 68;

	var optionX:Float = 450;
	var checkboxX:Float = 220;

	var letterScale:Float = 3;
	var letterSpacing:Float = 4;

	var cursorX:Float = 155;
	var cursorTweenTime:Float = 0.15;

	var antialiasingOption:Int = 1;

	var framerateValueSprites:Array<FlxSprite> = [];
	var framerateValueX:Float = 720;

	override public function create():Void
	{
		super.create();

		closing = false;
		canSelect = true;
		isMoving = false;

		updateOptionsLanguage();

		createOptionsCamera();
		createBoyfriend();
		createOptions();
		createCursor();
		updateFramerateValue();

		updateSelection(false);

		MobileControls.create();
		MobileControls.addToState(this);
	}

	function getCurrentLanguage():String
	{
		var language:String = Std.string(ClientPrefs.data.language);

		language = language.toUpperCase();
		language = StringTools.trim(language);

		switch (language)
		{
			case 'PORTUGUESE', 'PORTUGUES', 'PORTUGUÊS', 'PTBR', 'PT-BR', 'PT_BR', 'BRAZILIAN PORTUGUESE':
				return 'PORTUGUESE';

			case 'ESPANOL', 'ESPAÑOL', 'SPANISH', 'ES', 'ES-ES', 'ES_ES':
				return 'ESPANOL';

			default:
				return 'ENGLISH';
		}
	}

	function updateOptionsLanguage():Void
	{
		switch (getCurrentLanguage())
		{
			case 'PORTUGUESE':
				options = [
					'BAIXA QUALIDADE',
					'ANTI-ALIASING',
					'SHADERS',
					'CACHE DA GPU',
					'FRAMERATE'
				];

			case 'ESPANOL':
				options = [
					'BAJA CALIDAD',
					'ANTI-ALIASING',
					'SHADERS',
					'CACHE DE GPU',
					'FRAMERATE'
				];

			default:
				options = [
					'LOW QUALITY',
					'ANTI-ALIASING',
					'SHADERS',
					'GPU CACHING',
					'FRAMERATE'
				];
		}
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
		if (sprite != null && optionsCamera != null)
			sprite.cameras = [optionsCamera];
	}

	function createBoyfriend():Void
	{
		boyfriend = new Character(540, 170, 'bf', true);

		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();

		boyfriend.animation.finishCallback = function(name:String)
		{
			if (boyfriend != null && !closing)
				boyfriend.dance();
		};

		boyfriend.visible = curSelected == antialiasingOption;
		boyfriend.antialiasing = ClientPrefs.data.antialiasing;
		boyfriend.scrollFactor.set();

		add(boyfriend);
		setOptionsCamera(boyfriend);
	}

	function getLetterPath(character:String):String
	{
		var upper:String = character.toUpperCase();

		if (upper == ':')
			return 'hud/letershud/colon2';

		if (upper == '-')
			return 'hud/letershud/minus';

		return 'hud/letershud/' + upper;
	}

	function getLetterWidth(character:String):Float
	{
		var temp:FlxSprite = new FlxSprite();

		temp.loadGraphic(Paths.image(getLetterPath(character)));
		temp.antialiasing = false;
		temp.scale.set(letterScale, letterScale);
		temp.updateHitbox();

		return temp.width;
	}

	function getOptionWidth(text:String):Float
	{
		var totalWidth:Float = 0;

		text = text.toUpperCase();

		for (i in 0...text.length)
		{
			var character:String = text.charAt(i);

			if (character == ' ')
				totalWidth += letterSpacing;
			else
				totalWidth += getLetterWidth(character);
		}

		return totalWidth;
	}

	function createOption(text:String, index:Int):Void
	{
		text = text.toUpperCase();

		var totalWidth:Float = getOptionWidth(text);
		var offsetX:Float = -totalWidth / 2;

		optionSprites[index] = [];

		for (i in 0...text.length)
		{
			var character:String = text.charAt(i);

			if (character == ' ')
			{
				offsetX += letterSpacing;
				continue;
			}

			var letter:FlxSprite = new FlxSprite(optionX + offsetX, optionY + (index * optionSpacing));

			letter.loadGraphic(Paths.image(getLetterPath(character)));
			letter.antialiasing = false;
			letter.scale.set(letterScale, letterScale);
			letter.updateHitbox();
			letter.scrollFactor.set();

			add(letter);
			setOptionsCamera(letter);

			optionSprites[index].push(letter);

			offsetX += letter.width;
		}
	}

	function createOptions():Void
	{
		for (i in 0...options.length)
		{
			if (i < 4)
				createCheckBox(i);

			createOption(options[i], i);
		}
	}

	function createCheckBox(index:Int):Void
	{
		var checkbox:FlxSprite = new FlxSprite(checkboxX, checkBoxY + ((index - 1.3) * optionSpacing));

		checkbox.frames = Paths.getSparrowAtlas('dataselect/options/sonicCheckBox');

		checkbox.animation.addByPrefix('clickOff', 'clickOff', 24, false);
		checkbox.animation.addByPrefix('clickOn', 'clickOn', 24, false);

		checkbox.animation.play(getOptionValue(index) ? 'clickOn' : 'clickOff');

		checkbox.antialiasing = false;
		checkbox.scale.set(3, 3);
		checkbox.updateHitbox();
		checkbox.scrollFactor.set();

		add(checkbox);
		setOptionsCamera(checkbox);

		checkboxes.push(checkbox);
	}

	function createCursor():Void
	{
		selectedArrow = new FlxSprite(cursorX, optionY);

		selectedArrow.loadGraphic(Paths.image('pauseMenuEXE/selectedArrow'));

		selectedArrow.antialiasing = false;
		selectedArrow.scale.set(3, 3);
		selectedArrow.updateHitbox();
		selectedArrow.scrollFactor.set();

		add(selectedArrow);
		setOptionsCamera(selectedArrow);
	}

	function getOptionValue(index:Int):Bool
	{
		switch (index)
		{
			case 0:
				return ClientPrefs.data.lowQuality;

			case 1:
				return ClientPrefs.data.antialiasing;

			case 2:
				return ClientPrefs.data.shaders;

			case 3:
				return ClientPrefs.data.cacheOnGPU;
		}

		return false;
	}

	function changeSelection(change:Int = 0):Void
	{
		if (isMoving || !canSelect || closing)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		FlxG.sound.play(Paths.sound('dataselectswitch'));

		updateSelection(true);
	}

	function updateSelection(playTween:Bool = true):Void
	{
		if (selectedArrow == null || closing)
			return;

		var targetY:Float = optionY + (curSelected * optionSpacing);

		if (playTween)
		{
			isMoving = true;

			FlxTween.cancelTweensOf(selectedArrow);

			FlxTween.tween(selectedArrow, {x: cursorX, y: targetY}, cursorTweenTime, {
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween)
				{
					if (!closing)
						isMoving = false;
				}
			});
		}
		else
		{
			selectedArrow.x = cursorX;
			selectedArrow.y = targetY;
		}

		if (boyfriend != null)
			boyfriend.visible = curSelected == antialiasingOption;

		updateCheckBoxes();
	}

	function updateCheckBoxes():Void
	{
		if (closing)
			return;

		for (i in 0...checkboxes.length)
		{
			var checkbox:FlxSprite = checkboxes[i];

			if (checkbox == null)
				continue;

			checkbox.animation.play(getOptionValue(i) ? 'clickOn' : 'clickOff');
		}
	}

	function getNumberPath(character:String):String
	{
		return 'hud/letershud/' + character;
	}

	function getNumberWidth(character:String):Float
	{
		var temp:FlxSprite = new FlxSprite();

		temp.loadGraphic(Paths.image(getNumberPath(character)));
		temp.antialiasing = false;
		temp.scale.set(letterScale, letterScale);
		temp.updateHitbox();

		return temp.width;
	}

	function updateFramerateValue():Void
	{
		if (closing)
			return;

		var text:String = Std.string(ClientPrefs.data.framerate);
		var totalWidth:Float = 0;

		for (i in 0...text.length)
			totalWidth += getNumberWidth(text.charAt(i));

		var offsetX:Float = -totalWidth / 2;

		while (framerateValueSprites.length < text.length)
		{
			var newLetter:FlxSprite = new FlxSprite();

			newLetter.antialiasing = false;
			newLetter.scale.set(letterScale, letterScale);
			newLetter.scrollFactor.set();

			add(newLetter);
			setOptionsCamera(newLetter);

			framerateValueSprites.push(newLetter);
		}

		while (framerateValueSprites.length > text.length)
		{
			var oldLetter:FlxSprite = framerateValueSprites.pop();

			if (oldLetter != null)
			{
				remove(oldLetter, true);
				oldLetter.destroy();
			}
		}

		for (i in 0...text.length)
		{
			var character:String = text.charAt(i);
			var letter:FlxSprite = framerateValueSprites[i];

			letter.loadGraphic(Paths.image(getNumberPath(character)));
			letter.antialiasing = false;
			letter.scale.set(letterScale, letterScale);
			letter.updateHitbox();

			letter.x = framerateValueX + offsetX;
			letter.y = optionY + (4 * optionSpacing);

			offsetX += letter.width;
		}
	}

	function changeFramerate(change:Int):Void
	{
		if (closing)
			return;

		var newFramerate:Int = ClientPrefs.data.framerate + change;

		newFramerate = Std.int(FlxMath.bound(newFramerate, 60, 240));

		if (newFramerate == ClientPrefs.data.framerate)
			return;

		ClientPrefs.data.framerate = newFramerate;

		FlxG.updateFramerate = newFramerate;
		FlxG.drawFramerate = newFramerate;

		updateFramerateValue();

		ClientPrefs.saveSettings();

		FlxG.sound.play(Paths.sound('confirmMenu'));
	}

	function toggleCurrentOption():Void
	{
		if (closing || curSelected == 4)
			return;

		switch (curSelected)
		{
			case 0:
				ClientPrefs.data.lowQuality = !ClientPrefs.data.lowQuality;

			case 1:
				ClientPrefs.data.antialiasing = !ClientPrefs.data.antialiasing;
				onChangeAntiAliasing();

			case 2:
				ClientPrefs.data.shaders = !ClientPrefs.data.shaders;

			case 3:
				ClientPrefs.data.cacheOnGPU = !ClientPrefs.data.cacheOnGPU;
		}

		updateCheckBoxes();

		ClientPrefs.saveSettings();

		FlxG.sound.play(Paths.sound('confirmMenu'));
	}

	function onChangeAntiAliasing():Void
	{
		for (member in members)
		{
			var sprite:FlxSprite = cast member;

			if (sprite != null)
				sprite.antialiasing = ClientPrefs.data.antialiasing;
		}

		if (boyfriend != null)
			boyfriend.antialiasing = ClientPrefs.data.antialiasing;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		MobileControls.update();

		if (!canSelect || isMoving || closing)
			return;

		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W || MobileControls.upJustPressed)
		{
			changeSelection(-1);
		}
		else if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S || MobileControls.downJustPressed)
		{
			changeSelection(1);
		}
		else if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A || MobileControls.leftJustPressed)
		{
			if (curSelected == 4)
				changeFramerate(-10);
		}
		else if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D || MobileControls.rightJustPressed)
		{
			if (curSelected == 4)
				changeFramerate(10);
		}
		else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z || MobileControls.aJustPressed)
		{
			toggleCurrentOption();
		}
		else if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE || MobileControls.bJustPressed)
		{
			closeGraphics();
		}
	}

	function restoreParentOptions():Void
	{
		var parent:Dynamic = FlxG.state;

		if (parent == null)
			return;

		if (Reflect.hasField(parent, 'canSelect'))
			Reflect.setField(parent, 'canSelect', true);

		if (Reflect.hasField(parent, 'isMoving'))
			Reflect.setField(parent, 'isMoving', false);
	}

	function closeGraphics():Void
	{
		if (!canSelect || closing)
			return;

		closing = true;
		canSelect = false;
		isMoving = false;

		FlxTween.cancelTweensOf(selectedArrow);

		ClientPrefs.saveSettings();

		FlxG.sound.play(Paths.sound('cancelMenu'));

		restoreParentOptions();


		close();
	}

	override function destroy():Void
	{
		closing = true;
		canSelect = false;
		isMoving = false;

		if (selectedArrow != null)
			FlxTween.cancelTweensOf(selectedArrow);

		for (letter in framerateValueSprites)
		{
			if (letter != null)
			{
				remove(letter, true);
				letter.destroy();
			}
		}

		framerateValueSprites = [];

		MobileControls.removeFromState(this);

		ClientPrefs.saveSettings();

		if (optionsCamera != null)
		{
			FlxG.cameras.remove(optionsCamera, true);
			optionsCamera = null;
		}

		super.destroy();
	}
}
