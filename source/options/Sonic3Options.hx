package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

import backend.ClientPrefs;
import backend.MusicBeatState;
import backend.Paths;
import backend.MobileControls;

import states.Sonic3TitleStateV2;

class Sonic3Options extends MusicBeatState
{
	var categorySelection:Int = 1;
	var canSelect:Bool = true;
	var isMoving:Bool = false;
	var subStateOpen:Bool = false;

	var categories:Array<String> = [];

	var categoryY:Float = 40;
	var categorySpacing:Float = 19;
	var categoryX:Float = 167;

	var letterScale:Float = 1;
	var letterSpacing:Float = 4;

	var cursorX:Float = 97;
	var cursorTweenTime:Float = 0.15;

	var categorySprites:Array<Array<FlxSprite>> = [];
	var selectedArrow:FlxSprite;
	var optionsSelect:FlxSprite;

	override public function create():Void
	{
		super.create();

		FlxG.camera.scroll.set(-320, -223);
		FlxG.camera.zoom = 3;
		FlxG.camera.pixelPerfectRender = true;

		var bg:FlxSprite = new FlxSprite(0, 0);
		bg.loadGraphic(Paths.image('dataselect/dataSelect_BG'));
		bg.antialiasing = false;
		add(bg);

		updateCategories();

		createOptionsSelect();
		createCategories();
		createCursor();
		updateCategoryCursor();

		MobileControls.create();
		MobileControls.addToState(this);
		MobileControls.setEnabled(true);
		MobileControls.setVisible(true);

		FlxG.sound.playMusic(Paths.music('DataSelect'), 1, true);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		MobileControls.update();

		if (!canSelect || subStateOpen)
			return;

		if (isMoving)
			return;

		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W || MobileControls.upJustPressed)
		{
			changeCategory(-1);
		}
		else if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S || MobileControls.downJustPressed)
		{
			changeCategory(1);
		}
		else if (FlxG.keys.justPressed.ENTER ||
			FlxG.keys.justPressed.SPACE ||
			FlxG.keys.justPressed.Z ||
			MobileControls.aJustPressed)
		{
			selectCategory();
		}
		else if (FlxG.keys.justPressed.ESCAPE ||
			FlxG.keys.justPressed.BACKSPACE ||
			MobileControls.bJustPressed)
		{
			exitToTitle();
		}
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

	function updateCategories():Void
	{
		switch (getCurrentLanguage())
		{
			case 'PORTUGUESE':
				categories = [
					'Preferencias',
					'Jogabilidade',
					'Controles',
					'Graficos',
					'Visuais',
					'Idiomas'
				];

			case 'ESPANOL':
				categories = [
					'Preferencias',
					'Jugabilidad',
					'Controles',
					'Graficos',
					'Visuales',
					'Idiomas'
				];

			default:
				categories = [
					'Preferences',
					'Gameplay',
					'Controls',
					'Graphics',
					'Visuals',
					'Languages'
				];
		}
	}

	function getOptionsSelectPath():String
	{
		switch (getCurrentLanguage())
		{
			case 'PORTUGUESE':
				return 'dataselect/options/optionsPTBR_Select';

			case 'ESPANOL':
				return 'dataselect/options/optionsES_Select';

			default:
				return 'dataselect/options/options_Select';
		}
	}

	function createOptionsSelect():Void
	{
		optionsSelect = new FlxSprite(40, 180);
		optionsSelect.loadGraphic(Paths.image(getOptionsSelectPath()));
		optionsSelect.antialiasing = false;
		add(optionsSelect);
	}

	function refreshOptionsSelect():Void
	{
		if (optionsSelect == null)
			return;

		optionsSelect.loadGraphic(Paths.image(getOptionsSelectPath()));
		optionsSelect.antialiasing = false;
		optionsSelect.x = 40;
		optionsSelect.y = 180;
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

	function getCategoryWidth(text:String):Float
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

	function createCategory(text:String, categoryIndex:Int):Void
	{
		text = text.toUpperCase();

		var totalWidth:Float = getCategoryWidth(text);
		var offsetX:Float = -totalWidth / 2;
		var sprites:Array<FlxSprite> = [];
		var y:Float = categoryY + (categoryIndex - 1) * categorySpacing;

		for (i in 0...text.length)
		{
			var char:String = text.charAt(i);

			if (char == ' ')
			{
				offsetX += letterSpacing;
				continue;
			}

			var letter:FlxSprite = new FlxSprite(categoryX + offsetX, y);
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

		categorySprites[categoryIndex - 1] = sprites;
	}

	function createCategories():Void
	{
		categorySprites = [];

		for (i in 0...categories.length)
			createCategory(categories[i], i + 1);
	}

	function clearCategories():Void
	{
		for (category in categorySprites)
		{
			if (category == null)
				continue;

			for (letter in category)
			{
				if (letter != null)
				{
					remove(letter, true);
					letter.destroy();
				}
			}
		}

		categorySprites = [];
	}

	function refreshCategories():Void
	{
		clearCategories();

		updateCategories();
		createCategories();
		refreshOptionsSelect();
		updateCategoryCursor();
	}

	function createCursor():Void
	{
		selectedArrow = new FlxSprite(cursorX, categoryY);
		selectedArrow.loadGraphic(Paths.image('pauseMenuEXE/selectedArrow'));
		selectedArrow.scale.set(1, 1);
		selectedArrow.updateHitbox();
		selectedArrow.antialiasing = false;

		add(selectedArrow);
	}

	function updateCategoryCursor():Void
	{
		if (selectedArrow == null)
			return;

		selectedArrow.y = categoryY + (categorySelection - 1) * categorySpacing;
	}

	function changeCategory(change:Int):Void
	{
		if (isMoving || !canSelect || subStateOpen)
			return;

		categorySelection += change;

		if (categorySelection < 1)
			categorySelection = categories.length;
		else if (categorySelection > categories.length)
			categorySelection = 1;

		FlxG.sound.play(Paths.sound('dataselectswitch'));

		var y:Float = categoryY + (categorySelection - 1) * categorySpacing;

		isMoving = true;

		FlxTween.cancelTweensOf(selectedArrow);

		FlxTween.tween(selectedArrow, {y: y}, cursorTweenTime, {
			ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween)
			{
				if (!subStateOpen)
					isMoving = false;
			}
		});
	}

	function selectCategory():Void
	{
		if (isMoving || !canSelect || subStateOpen)
			return;

		switch (categorySelection)
		{
			case 1:
				openPreferences();

			case 3:
				openControls();

			case 4:
				openGraphics();

			case 6:
				openLanguage();
		}
	}

	function openPreferences():Void
	{
		if (subStateOpen)
			return;

		FlxG.sound.play(Paths.sound('confirmMenu'));

		subStateOpen = true;
		canSelect = false;
		isMoving = false;

		FlxTween.cancelTweensOf(selectedArrow);
		hideCategories();

		openSubState(new options.SonicPreferencesSubstate());
	}

	function openControls():Void
	{
		if (subStateOpen)
			return;

		FlxG.sound.play(Paths.sound('confirmMenu'));

		subStateOpen = true;
		canSelect = false;
		isMoving = false;

		FlxTween.cancelTweensOf(selectedArrow);
		hideCategories();

		openSubState(new options.SonicControlsSubstate());
	}

	function openGraphics():Void
	{
		if (subStateOpen)
			return;

		FlxG.sound.play(Paths.sound('confirmMenu'));

		subStateOpen = true;
		canSelect = false;
		isMoving = false;

		FlxTween.cancelTweensOf(selectedArrow);
		hideCategories();

		openSubState(new options.SonicGraphicsSubstate());
	}

	function openLanguage():Void
	{
		if (subStateOpen)
			return;

		FlxG.sound.play(Paths.sound('confirmMenu'));

		subStateOpen = true;
		canSelect = false;
		isMoving = false;

		FlxTween.cancelTweensOf(selectedArrow);
		hideCategories();

		openSubState(new options.SonicLanguageSubstate());
	}

	function hideCategories():Void
	{
		for (category in categorySprites)
		{
			if (category == null)
				continue;

			for (letter in category)
			{
				if (letter != null)
					letter.visible = false;
			}
		}

		if (selectedArrow != null)
			selectedArrow.visible = false;

		if (optionsSelect != null)
			optionsSelect.visible = false;
	}

	function showCategories():Void
	{
		for (category in categorySprites)
		{
			if (category == null)
				continue;

			for (letter in category)
			{
				if (letter != null)
				{
					letter.visible = true;
					letter.alpha = 1;
				}
			}
		}

		if (selectedArrow != null)
		{
			selectedArrow.visible = true;
			selectedArrow.alpha = 1;
		}

		if (optionsSelect != null)
		{
			optionsSelect.visible = true;
			optionsSelect.alpha = 1;
		}

		MobileControls.setEnabled(true);
		MobileControls.setVisible(true);

		updateCategoryCursor();
	}

	override public function closeSubState():Void
	{
		super.closeSubState();

		if (!subStateOpen)
			return;

		subStateOpen = false;
		canSelect = true;
		isMoving = false;

		refreshCategories();
		showCategories();
	}

	function exitToTitle():Void
	{
		if (subStateOpen || !canSelect)
			return;

		canSelect = false;
		isMoving = false;

		FlxTween.cancelTweensOf(selectedArrow);

		FlxG.sound.play(Paths.sound('cancelMenu'));

		new FlxTimer().start(0.2, function(timer:FlxTimer)
		{
			MobileControls.setVisible(false);
			MobileControls.setEnabled(false);
			MusicBeatState.switchState(new Sonic3TitleStateV2());
		});
	}

	override public function destroy():Void
	{
		FlxTween.cancelTweensOf(selectedArrow);

		if (MobileControls.isAttachedTo(this))
			MobileControls.removeFromState(this);

		super.destroy();
	}
}
