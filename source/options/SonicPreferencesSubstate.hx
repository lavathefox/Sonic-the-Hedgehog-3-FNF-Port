package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
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

typedef SonicOption =
{
	var name:String;
	var key:String;
	var type:String;
	var values:Array<String>;
	var defaultValue:String;
	var action:String;
}

class SonicPreferencesSubstate extends MusicBeatSubstate
{
	var options:Array<SonicOption> = [];

	var curSelected:Int = 0;

	var labelSprites:Array<Array<FlxSprite>> = [];
	var valueSprites:Array<Array<FlxSprite>> = [];
	var rowY:Array<Float> = [];

	var selectedArrow:FlxSprite;

	var optionY:Float = 40;
	var optionSpacing:Float = 19;
	var optionX:Float = 117;
	var valueX:Float = 250;

	var letterScale:Float = 1;
	var letterSpacing:Float = 4;

	var cursorX:Float = 17;
	var cursorTweenTime:Float = 0.15;
	var scrollSpeed:Float = 14;

	var letterCache:Map<String, FlxGraphic> = new Map();
	var widthCache:Map<String, Float> = new Map();
	var luaCache:Map<String, String> = new Map();

	var settingsDirty:Bool = false;

	override public function create():Void
	{
		super.create();

		createOptions();
		createCursor();
		updateRows(0, true);

		MobileControls.setVisible(true);
		MobileControls.setEnabled(true);
	}

	override public function update(elapsed:Float):Void
	{
		MobileControls.update();

		super.update(elapsed);

		if (options.length <= 0)
			return;

		updateRows(elapsed, false);

		if (controls.UI_UP_P || MobileControls.upJustPressed)
		{
			changeOption(-1);
		}
		else if (controls.UI_DOWN_P || MobileControls.downJustPressed)
		{
			changeOption(1);
		}
		else if (controls.UI_LEFT_P || MobileControls.leftJustPressed)
		{
			changeValue(-1);
		}
		else if (controls.UI_RIGHT_P || MobileControls.rightJustPressed)
		{
			changeValue(1);
		}
		else if (FlxG.mouse.wheel != 0)
		{
			changeOption(-FlxG.mouse.wheel);
		}
		else if (controls.ACCEPT || MobileControls.aJustPressed)
		{
			acceptOption();
		}
		else if (controls.BACK || MobileControls.bJustPressed)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MobileControls.setVisible(false);
			saveIfDirty();
			close();
		}
	}

	override function destroy():Void
	{
		if (selectedArrow != null)
			FlxTween.cancelTweensOf(selectedArrow);

		saveIfDirty();

		labelSprites = [];
		valueSprites = [];
		rowY = [];
		letterCache.clear();
		widthCache.clear();
		luaCache.clear();
		selectedArrow = null;

		super.destroy();
	}

	function makeOption(name:String, key:String, type:String, values:Array<String>, defaultValue:String, action:String = ''):SonicOption
	{
		return {
			name: name,
			key: key,
			type: type,
			values: values,
			defaultValue: defaultValue,
			action: action
		};
	}

	function createOptions():Void
	{
		options = [
			makeOption('Title Card Styles', 'sonicTitleCardStyle', 'string', ['DEFAULT', 'SONIC CD'], 'DEFAULT', 'preview'),
			makeOption('Title Card Speed', 'sonicTitleCardSpeed', 'string', ['SLOW', 'NORMAL', 'FAST'], 'NORMAL'),
			makeOption('HUD Styles', 'sonicHUDStyle', 'string', ['DEFAULT', 'SONIC 1/CD', 'SONIC 2'], 'DEFAULT'),
			makeOption('Time Format', 'sonicTimeFormat', 'string', ['MM:SS', 'MM:SS:MS'], 'MM:SS'),
			makeOption('Show Score', 'sonicShowScore', 'bool', ['OFF', 'ON'], 'ON'),
			makeOption('Show Lives', 'sonicShowLives', 'bool', ['OFF', 'ON'], 'ON'),
			makeOption('Ring Blink', 'sonicRingBlink', 'bool', ['OFF', 'ON'], 'ON'),
			makeOption('Reset Options', '', 'string', [''], '', 'reset')
		];

		labelSprites = [];
		valueSprites = [];
		rowY = [];

		for (i in 0...options.length)
		{
			rowY[i] = optionY + (i - curSelected) * optionSpacing;

			labelSprites[i] = buildText(options[i].name, optionX, rowY[i]);
			valueSprites[i] = buildText(getCurrentValueText(i), valueX, rowY[i]);
		}
	}

	function createCursor():Void
	{
		selectedArrow = new FlxSprite(cursorX, optionY);

		var graphic:FlxGraphic = Paths.image('pauseMenuEXE/selectedArrow');

		if (graphic != null)
			selectedArrow.loadGraphic(graphic);
		else
			selectedArrow.makeGraphic(8, 8, 0xFFFFFFFF);

		selectedArrow.scale.set(1, 1);
		selectedArrow.updateHitbox();
		selectedArrow.antialiasing = false;

		add(selectedArrow);
	}

	function getLetterPath(char:String):String
	{
		switch (char.toUpperCase())
		{
			case ':':
				return 'hud/letershud/colon2';
			case '/':
				return 'hud/letershud/slash';
			default:
				return 'hud/letershud/' + char.toUpperCase();
		}
	}

	function getLetterGraphic(char:String):FlxGraphic
	{
		char = char.toUpperCase();

		if (letterCache.exists(char))
			return letterCache.get(char);

		var graphic:FlxGraphic = Paths.image(getLetterPath(char));

		letterCache.set(char, graphic);
		return graphic;
	}

	function getLetterWidth(char:String):Float
	{
		char = char.toUpperCase();

		if (widthCache.exists(char))
			return widthCache.get(char);

		var graphic:FlxGraphic = getLetterGraphic(char);
		var w:Float = (graphic != null) ? graphic.width * letterScale : 0;

		widthCache.set(char, w);
		return w;
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

	function buildText(text:String, centerX:Float, y:Float):Array<FlxSprite>
	{
		var sprites:Array<FlxSprite> = [];

		text = text.toUpperCase();

		var offsetX:Float = -getTextWidth(text) / 2;

		for (i in 0...text.length)
		{
			var char:String = text.charAt(i);

			if (char == ' ')
			{
				offsetX += letterSpacing;
				continue;
			}

			var graphic:FlxGraphic = getLetterGraphic(char);

			if (graphic == null)
				continue;

			var letter:FlxSprite = new FlxSprite(centerX + offsetX, y);
			letter.loadGraphic(graphic);
			letter.scale.set(letterScale, letterScale);
			letter.updateHitbox();
			letter.antialiasing = false;

			add(letter);
			sprites.push(letter);

			offsetX += letter.width;
		}

		return sprites;
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

	function getRawValue(option:SonicOption):String
	{
		if (option.key == '')
			return '';

		var value:Dynamic = Reflect.getProperty(ClientPrefs.data, option.key);

		if (option.type == 'bool')
		{
			if (value == null)
				return option.defaultValue;

			return (value == true) ? 'ON' : 'OFF';
		}

		if (value == null || Std.string(value) == '')
			return option.defaultValue;

		return Std.string(value);
	}

	function setRawValue(option:SonicOption, value:String):Void
	{
		if (option.key == '')
			return;

		if (option.type == 'bool')
			Reflect.setProperty(ClientPrefs.data, option.key, value == 'ON');
		else
			Reflect.setProperty(ClientPrefs.data, option.key, value);

		settingsDirty = true;
	}

	function saveIfDirty():Void
	{
		if (!settingsDirty)
			return;

		ClientPrefs.saveSettings();
		settingsDirty = false;
	}

	function getCurrentValueIndex(index:Int):Int
	{
		if (index < 0 || index >= options.length)
			return 0;

		var option:SonicOption = options[index];
		var current:String = getRawValue(option);
		var found:Int = option.values.indexOf(current);

		if (found >= 0)
			return found;

		var def:Int = option.values.indexOf(option.defaultValue);
		return def >= 0 ? def : 0;
	}

	function getCurrentValueText(index:Int):String
	{
		if (index < 0 || index >= options.length)
			return '';

		var values:Array<String> = options[index].values;

		if (values.length <= 0)
			return '';

		return values[getCurrentValueIndex(index)];
	}

	function refreshValue(index:Int):Void
	{
		if (index < 0 || index >= valueSprites.length)
			return;

		destroySprites(valueSprites[index]);
		valueSprites[index] = buildText(getCurrentValueText(index), valueX, rowY[index]);

		applyRowVisuals(index);
	}

	function applyRowVisuals(i:Int):Void
	{
		var selected:Bool = (i == curSelected);
		var alpha:Float = selected ? 1 : 0.6;
		var onScreen:Bool = rowY[i] > -optionSpacing && rowY[i] < FlxG.height;
		var y:Float = rowY[i];

		for (letter in labelSprites[i])
		{
			letter.y = y;
			letter.alpha = alpha;
			letter.visible = onScreen;
		}

		for (letter in valueSprites[i])
		{
			letter.y = y;
			letter.alpha = alpha;
			letter.visible = onScreen;
		}
	}

	function updateRows(elapsed:Float, snap:Bool):Void
	{
		for (i in 0...options.length)
		{
			var target:Float = optionY + (i - curSelected) * optionSpacing;

			if (snap)
				rowY[i] = target;
			else
				rowY[i] = FlxMath.lerp(rowY[i], target, FlxMath.bound(elapsed * scrollSpeed, 0, 1));

			applyRowVisuals(i);
		}
	}

	function nudgeCursor():Void
	{
		if (selectedArrow == null)
			return;

		FlxTween.cancelTweensOf(selectedArrow);

		selectedArrow.x = cursorX - 4;
		FlxTween.tween(selectedArrow, {x: cursorX}, cursorTweenTime, {
			ease: FlxEase.quadOut
		});
	}

	function changeOption(change:Int):Void
	{
		if (options.length <= 0 || change == 0)
			return;

		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		else if (curSelected >= options.length)
			curSelected = 0;

		FlxG.sound.play(Paths.sound('dataselectswitch'));

		nudgeCursor();
	}

	function changeValue(change:Int):Void
	{
		var index:Int = curSelected;

		if (index < 0 || index >= options.length)
			return;

		var option:SonicOption = options[index];

		if (option.values.length <= 1)
			return;

		var next:Int = FlxMath.wrap(getCurrentValueIndex(index) + change, 0, option.values.length - 1);

		setRawValue(option, option.values[next]);
		refreshValue(index);

		FlxG.sound.play(Paths.sound('dataselectswitch'));
	}

	function acceptOption():Void
	{
		var option:SonicOption = options[curSelected];

		FlxG.sound.play(Paths.sound('confirmMenu'));

		switch (option.action)
		{
			case 'preview':
				applyTitleCardStyle();

			case 'reset':
				resetAllOptions();

			default:
				changeValue(1);
		}
	}

	function resetAllOptions():Void
	{
		for (i in 0...options.length)
		{
			var option:SonicOption = options[i];

			if (option.key == '')
				continue;

			setRawValue(option, option.defaultValue);
			refreshValue(i);
		}

		saveIfDirty();
	}

	function findLuaRecursive(directory:String, fileName:String):String
	{
		#if MODS_ALLOWED
		if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory))
			return '';

		try
		{
			for (file in FileSystem.readDirectory(directory))
			{
				var path:String = directory + '/' + file;

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
			trace('Erro ao ler pasta "' + directory + '": ' + e);
		}
		#end

		return '';
	}

	function findLuaFile(fileName:String):String
	{
		if (luaCache.exists(fileName))
			return luaCache.get(fileName);

		var result:String = '';

		#if MODS_ALLOWED
		var searchDirectories:Array<String> = [];

		var sharedPath:String = Paths.getSharedPath();

		if (sharedPath != null && sharedPath != '')
			searchDirectories.push(sharedPath);

		var currentMod:String = Mods.currentModDirectory;

		if (currentMod != null && currentMod != '')
		{
			var currentModPath:String = Paths.mods(currentMod + '/');

			if (currentModPath != null && currentModPath != '')
				searchDirectories.push(currentModPath);
		}

		for (directory in searchDirectories)
		{
			result = findLuaRecursive(directory, fileName);

			if (result != '')
				break;
		}
		#end

		luaCache.set(fileName, result);
		return result;
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
		var style:String = getRawValue(options[curSelected]);
		var scriptPath:String = findTitleCardScript(style);

		if (scriptPath != '')
			trace('Sonic Title Card: ' + style + ' -> ' + scriptPath);
		else
			trace('Sonic Title Card: Script not found for ' + style);
	}
}
