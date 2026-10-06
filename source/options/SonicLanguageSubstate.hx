package options;

import openfl.utils.Assets;

import backend.ClientPrefs;
import backend.Language;
import backend.MobileControls;
import backend.MusicBeatSubstate;
import backend.Paths;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

#if MODS_ALLOWED
import sys.FileSystem;
#end

class SonicLanguageSubstate extends MusicBeatSubstate
{
	var languages:Array<String> = [];
	var displayLanguages:Map<String, String> = [];

	var curSelected:Int = 0;
	var changedLanguage:Bool = false;

	var optionsCamera:FlxCamera;

	var languageSprites:Array<Array<FlxSprite>> = [];
	var selectedArrow:FlxSprite;

	var optionY:Float = 260;
	var optionSpacing:Float = 70;

	var optionX:Float = 440;
	var cursorX:Float = 300;

	var letterScale:Float = 3;
	var letterSpacing:Float = 4;
	var arrowScale:Float = 2;

	var cursorTweenTime:Float = 0.15;

	override public function create():Void
	{
		super.create();

		createOptionsCamera();
		loadLanguages();

		if (languages.length <= 0)
			return;

		findCurrentLanguage();
		createLanguages();
		createCursor();
		updateSelection(false);

		MobileControls.create();
		MobileControls.setVisible(true);
		MobileControls.setEnabled(true);
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

	function loadLanguages():Void
	{
		languages = [];
		displayLanguages = [];

		var defaultLanguage:String = ClientPrefs.defaultData.language;

		if (defaultLanguage == null || defaultLanguage.trim().length <= 0)
			defaultLanguage = ClientPrefs.data.language;

		if (defaultLanguage == null || defaultLanguage.trim().length <= 0)
			defaultLanguage = 'en-US';

		languages.push(defaultLanguage);
		displayLanguages.set(defaultLanguage, Language.defaultLangName);

		var directories:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'data/');

		for (directory in directories)
		{
			for (file in FileSystem.readDirectory(directory))
			{
				if (!file.toLowerCase().endsWith('.lang'))
					continue;

				var langFile:String = file.substring(0, file.length - '.lang'.length).trim();

				if (langFile.length <= 0)
					continue;

				if (!languages.contains(langFile))
					languages.push(langFile);

				if (displayLanguages.exists(langFile))
					continue;

				var path:String = '$directory/$file';
				var txt:String = '';

				#if MODS_ALLOWED
				if (FileSystem.exists(path))
					txt = File.getContent(path);
				#else
				if (Assets.exists(path))
					txt = Assets.getText(path);
				#end

				if (txt == null || txt.trim().length <= 0)
					continue;

				var id:Int = txt.indexOf('\n');

				if (id > 0)
				{
					var name:String = txt.substr(0, id).trim();

					if (name.length > 0 && !name.contains(':'))
						displayLanguages.set(langFile, name);
				}
				else
				{
					var name:String = txt.trim();

					if (name.length > 0 && !name.contains(':'))
						displayLanguages.set(langFile, name);
				}
			}
		}

		// ESPANOL is built into Language.hx, so it does not need an .lang file.
		if (!languages.contains('ESPANOL'))
		{
			languages.push('ESPANOL');
			displayLanguages.set('ESPANOL', 'ESPANOL');
		}

		languages.sort(function(a:String, b:String)
		{
			var nameA:String = displayLanguages.exists(a) ? displayLanguages.get(a) : a;
			var nameB:String = displayLanguages.exists(b) ? displayLanguages.get(b) : b;

			nameA = nameA.toLowerCase();
			nameB = nameB.toLowerCase();

			if (nameA < nameB)
				return -1;

			if (nameA > nameB)
				return 1;

			return 0;
		});
	}

	function findCurrentLanguage():Void
	{
		curSelected = languages.indexOf(ClientPrefs.data.language);

		if (curSelected < 0)
		{
			ClientPrefs.data.language = ClientPrefs.defaultData.language;
			curSelected = languages.indexOf(ClientPrefs.data.language);

			if (curSelected < 0)
				curSelected = 0;
		}
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

		return sprites;
	}

	function createLanguages():Void
	{
		languageSprites = [];

		for (i in 0...languages.length)
		{
			var language:String = languages[i];
			var displayName:String = displayLanguages.exists(language) ? displayLanguages.get(language) : language;

			var sprites:Array<FlxSprite> = createText(
				displayName,
				optionX,
				optionY + i * optionSpacing,
				letterScale
			);

			languageSprites.push(sprites);
		}

		updateLanguagePositions();
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

	function updateLanguagePositions():Void
	{
		for (i in 0...languageSprites.length)
		{
			var offset:Int = i - curSelected;

			for (sprite in languageSprites[i])
			{
				sprite.y = optionY + offset * optionSpacing;
				sprite.alpha = i == curSelected ? 1 : 0.6;
			}
		}
	}

	function updateSelection(playTween:Bool = true):Void
	{
		if (languages.length <= 0 || selectedArrow == null)
			return;

		updateLanguagePositions();

		var targetX:Float = cursorX;
		var targetY:Float = optionY;

		FlxTween.cancelTweensOf(selectedArrow);

		if (playTween)
		{
			FlxTween.tween(selectedArrow, {x: targetX, y: targetY}, cursorTweenTime, {
				ease: FlxEase.quadOut
			});
		}
		else
		{
			selectedArrow.x = targetX;
			selectedArrow.y = targetY;
		}
	}

	function changeSelected(change:Int = 0):Void
	{
		if (languages.length <= 0)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, languages.length - 1);

		updateSelection(true);

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function confirmLanguage():Void
	{
		if (languages.length <= 0)
			return;

		var selectedLanguage:String = languages[curSelected];

		FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);

		if (ClientPrefs.data.language == selectedLanguage)
			return;

		ClientPrefs.data.language = selectedLanguage;
		ClientPrefs.saveSettings();

		Language.reloadPhrases();

		changedLanguage = true;
	}

	override function update(elapsed:Float):Void
	{
		MobileControls.update();

		super.update(elapsed);

		if (languages.length <= 0)
			return;

		var mult:Int = FlxG.keys.pressed.SHIFT ? 4 : 1;

		if (controls.UI_UP_P || MobileControls.upJustPressed)
			changeSelected(-1 * mult);

		if (controls.UI_DOWN_P || MobileControls.downJustPressed)
			changeSelected(1 * mult);

		if (FlxG.mouse.wheel != 0)
			changeSelected(-FlxG.mouse.wheel * mult);

		if (controls.ACCEPT || MobileControls.aJustPressed)
		{
			confirmLanguage();
			return;
		}

		if (controls.BACK || MobileControls.bJustPressed)
		{
			MobileControls.setVisible(false);

			if (changedLanguage)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.resetState();
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				close();
			}
		}
	}

	override function destroy():Void
	{
		FlxTween.cancelTweensOf(selectedArrow);


		for (sprites in languageSprites)
		{
			for (sprite in sprites)
			{
				if (sprite != null)
					sprite.destroy();
			}
		}

		languageSprites = [];

		if (selectedArrow != null)
		{
			selectedArrow.destroy();
			selectedArrow = null;
		}

		if (optionsCamera != null)
		{
			FlxG.cameras.remove(optionsCamera, true);
			optionsCamera = null;
		}

		super.destroy();
	}
}
