package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import backend.ClientPrefs;
import backend.MobileControls;
import backend.Mods;
import backend.MusicBeatSubstate;
import backend.Paths;

#if MODS_ALLOWED
import sys.FileSystem;
#end

class SonicPreferencesSubstate extends MusicBeatSubstate
{
	var options:Array<String> = [];
	var optionTypes:Array<String> = [];
	var optionValues:Array<Array<String>> = [];

	var curSelected:Int = 1;
	var curValue:Int = 0;

	var optionSprites:Array<Array<FlxSprite>> = [];
	var valueSprites:Array<Array<FlxSprite>> = [];

	var selectedArrow:FlxSprite;

	var optionY:Float = 40;
	var optionSpacing:Float = 19;
	var optionX:Float = 117;

	var valueX:Float = 250;

	var letterScale:Float = 1;
	var letterSpacing:Float = 4;

	var cursorX:Float = 17;
	var cursorTweenTime:Float = 0.15;

	override public function create():Void
	{
		super.create();

		createOptions();
		createCursor();
		updateSelection(false);

		MobileControls.setVisible(true);
		MobileControls.setEnabled(true);
	}

	override public function update(elapsed:Float):Void
	{
		MobileControls.update();

		super.update(elapsed);

		if (options.length <= 0)
			return;

		if (controls.UI_UP_P || MobileControls.upJustPressed)
		{
			changeOption(-1);
			return;
		}
		else if (controls.UI_DOWN_P || MobileControls.downJustPressed)
		{
			changeOption(1);
			return;
		}
		else if (controls.UI_LEFT_P || MobileControls.leftJustPressed)
		{
			changeValue(-1);
			return;
		}
		else if (controls.UI_RIGHT_P || MobileControls.rightJustPressed)
		{
			changeValue(1);
			return;
		}
		else if (controls.ACCEPT || MobileControls.aJustPressed)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));

			if (optionTypes[curSelected - 1] == 'titlecard')
				applyTitleCardStyle();

			return;
		}
		else if (controls.BACK || MobileControls.bJustPressed)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MobileControls.setVisible(false);
			close();
		}
	}

	function createOptions():Void
	{
		options = [
			'Title Card Styles',
			'HUD Styles'
		];

		optionTypes = [
			'titlecard',
			'hud'
		];

		optionValues = [
			[
				'DEFAULT',
				'SONIC CD'
			],
			[
				'DEFAULT'
			]
		];

		optionSprites = [];
		valueSprites = [];

		for (i in 0...options.length)
			createOption(options[i], i + 1);
	}

	function createOption(text:String, optionIndex:Int):Void
	{
		text = text.toUpperCase();

		var totalWidth:Float = getTextWidth(text);
		var offsetX:Float = -totalWidth / 2;

		var sprites:Array<FlxSprite> = [];
		var y:Float = optionY + (optionIndex - 1) * optionSpacing;

		for (i in 0...text.length)
		{
			var char:String = text.charAt(i);

			if (char == ' ')
			{
				offsetX += letterSpacing;
				continue;
			}

			var letter:FlxSprite = new FlxSprite(optionX + offsetX, y);
			letter.loadGraphic(Paths.image(getLetterPath(char)));
			letter.scale.set(letterScale, letterScale);
			letter.updateHitbox();
			letter.antialiasing = false;
			letter.visible = true;
			letter.alpha = 1;

			add(letter);
			sprites.push(letter);

			offsetX += letter.width;
		}

		optionSprites[optionIndex - 1] = sprites;

		createValue(getCurrentValueText(optionIndex - 1), optionIndex);
	}

	function createValue(text:String, optionIndex:Int):Void
	{
		text = text.toUpperCase();

		var totalWidth:Float = getTextWidth(text);
		var offsetX:Float = -totalWidth / 2;

		var sprites:Array<FlxSprite> = [];
		var y:Float = optionY + (optionIndex - 1) * optionSpacing;

		for (i in 0...text.length)
		{
			var char:String = text.charAt(i);

			if (char == ' ')
			{
				offsetX += letterSpacing;
				continue;
			}

			var letter:FlxSprite = new FlxSprite(valueX + offsetX, y);
			letter.loadGraphic(Paths.image(getLetterPath(char)));
			letter.scale.set(letterScale, letterScale);
			letter.updateHitbox();
			letter.antialiasing = false;
			letter.visible = true;
			letter.alpha = 1;

			add(letter);
			sprites.push(letter);

			offsetX += letter.width;
		}

		valueSprites[optionIndex - 1] = sprites;
	}

	function createCursor():Void
	{
		selectedArrow = new FlxSprite(cursorX, optionY);

		selectedArrow.loadGraphic(Paths.image('pauseMenuEXE/selectedArrow'));
		selectedArrow.scale.set(1, 1);
		selectedArrow.updateHitbox();
		selectedArrow.antialiasing = false;

		add(selectedArrow);
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

	function getTitleCardStyle():String
	{
		if (ClientPrefs.data.sonicTitleCardStyle == null || ClientPrefs.data.sonicTitleCardStyle == '')
			return 'DEFAULT';

		return ClientPrefs.data.sonicTitleCardStyle;
	}

	function getHUDStyle():String
	{
		if (ClientPrefs.data.sonicHUDStyle == null || ClientPrefs.data.sonicHUDStyle == '')
			return 'DEFAULT';

		return ClientPrefs.data.sonicHUDStyle;
	}

	function getCurrentValueIndex(index:Int):Int
	{
		if (index < 0 || index >= optionTypes.length)
			return 0;

		var currentValue:String = '';

		switch (optionTypes[index])
		{
			case 'titlecard':
				currentValue = getTitleCardStyle();

			case 'hud':
				currentValue = getHUDStyle();
		}

		for (i in 0...optionValues[index].length)
		{
			if (optionValues[index][i] == currentValue)
				return i;
		}

		return 0;
	}

	function getCurrentValueText(index:Int):String
	{
		if (index < 0 || index >= optionValues.length)
			return '';

		var values:Array<String> = optionValues[index];

		if (values.length <= 0)
			return '';

		var selected:Int = getCurrentValueIndex(index);

		if (selected < 0 || selected >= values.length)
			selected = 0;

		return values[selected];
	}

	function setTitleCardStyle(style:String):Void
	{
		ClientPrefs.data.sonicTitleCardStyle = style;
		ClientPrefs.saveSettings();
	}

	function setHUDStyle(style:String):Void
	{
		ClientPrefs.data.sonicHUDStyle = style;
		ClientPrefs.saveSettings();
	}

	function destroySprites(sprites:Array<FlxSprite>):Void
	{
		if (sprites == null)
			return;

		for (sprite in sprites)
		{
			if (sprite != null)
			{
				remove(sprite, true);
				sprite.destroy();
			}
		}
	}

	function refreshValue(index:Int):Void
	{
		if (index < 0 || index >= valueSprites.length)
			return;

		destroySprites(valueSprites[index]);

		valueSprites[index] = [];

		createValue(getCurrentValueText(index), index + 1);
	}

	function updatePositions():Void
	{
		for (i in 0...optionSprites.length)
		{
			var offset:Int = i - (curSelected - 1);
			var y:Float = optionY + offset * optionSpacing;

			for (letter in optionSprites[i])
			{
				letter.y = y;
				letter.alpha = i == curSelected - 1 ? 1 : 0.6;
			}

			for (letter in valueSprites[i])
			{
				letter.y = y;
				letter.alpha = i == curSelected - 1 ? 1 : 0.6;
			}
		}
	}

	function updateSelection(playTween:Bool):Void
	{
		updatePositions();

		if (selectedArrow == null)
			return;

		var targetY:Float = optionY;

		FlxTween.cancelTweensOf(selectedArrow);

		if (playTween)
		{
			FlxTween.tween(selectedArrow, {y: targetY}, cursorTweenTime, {
				ease: FlxEase.quadOut
			});
		}
		else
		{
			selectedArrow.y = targetY;
		}
	}

	function changeOption(change:Int):Void
	{
		if (options.length <= 0)
			return;

		curSelected += change;

		if (curSelected < 1)
			curSelected = options.length;
		else if (curSelected > options.length)
			curSelected = 1;

		FlxG.sound.play(Paths.sound('dataselectswitch'));

		updateSelection(true);
	}

	function changeValue(change:Int):Void
	{
		var index:Int = curSelected - 1;

		if (index < 0 || index >= optionValues.length)
			return;

		var values:Array<String> = optionValues[index];

		if (values.length <= 1)
			return;

		curValue = getCurrentValueIndex(index);
		curValue = FlxMath.wrap(curValue + change, 0, values.length - 1);

		var selectedValue:String = values[curValue];

		switch (optionTypes[index])
		{
			case 'titlecard':
				setTitleCardStyle(selectedValue);

			case 'hud':
				setHUDStyle(selectedValue);
		}

		refreshValue(index);

		FlxG.sound.play(Paths.sound('dataselectswitch'));
	}

	function findLuaRecursive(directory:String, fileName:String):String
	{
		#if MODS_ALLOWED
		if (!FileSystem.exists(directory))
			return '';

		try
		{
			for (file in FileSystem.readDirectory(directory))
			{
				var path:String = '$directory/$file';

				if (FileSystem.isDirectory(path))
				{
					var found:String = findLuaRecursive(path, fileName);

					if (found != '')
						return found;
				}
				else if (file.toLowerCase() == fileName.toLowerCase())
				{
					return path;
				}
			}
		}
		catch (e:Dynamic)
		{
		}
		#end

		return '';
	}

	function findLuaFile(fileName:String):String
	{
		#if MODS_ALLOWED
		var searchDirectories:Array<String> = [];

		var modsPath:String = Paths.getSharedPath();

		if (modsPath != null && modsPath != '')
			searchDirectories.push(modsPath);

		var currentMod:String = Mods.currentModDirectory;

		if (currentMod != null && currentMod != '')
		{
			var currentModPath:String = Paths.mods('$currentMod/');

			if (currentModPath != null && currentModPath != '')
				searchDirectories.push(currentModPath);
		}

		for (directory in searchDirectories)
		{
			var found:String = findLuaRecursive(directory, fileName);

			if (found != '')
				return found;
		}
		#end

		return '';
	}

	function findTitleCardScript(style:String):String
	{
		switch (style)
		{
			case 'SONIC CD':
				return findLuaFile('sonicCDIntro.lua');

			default:
				return findLuaFile('titlecardtest.lua');
		}
	}

	function applyTitleCardStyle():Void
	{
		var style:String = getTitleCardStyle();
		var scriptPath:String = findTitleCardScript(style);

		if (scriptPath != '')
			trace('Sonic Title Card: ' + style + ' -> ' + scriptPath);
		else
			trace('Sonic Title Card: Script not found for ' + style);
	}

	override function destroy():Void
	{
		FlxTween.cancelTweensOf(selectedArrow);


		for (sprites in optionSprites)
			destroySprites(sprites);

		for (sprites in valueSprites)
			destroySprites(sprites);

		optionSprites = [];
		valueSprites = [];

		if (selectedArrow != null)
		{
			selectedArrow.destroy();
			selectedArrow = null;
		}

		super.destroy();
	}
}
