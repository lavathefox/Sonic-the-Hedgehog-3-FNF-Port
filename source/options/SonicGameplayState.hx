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

typedef GameplayOption =
{
	var variable:String; // field name inside ClientPrefs.data
	var isNumber:Bool; // false = checkbox, true = numeric value
	var min:Float;
	var max:Float;
	var step:Float; // change per press (in displayed units)
	var mult:Float; // displayed value = saved value * mult (e.g. 0.6 -> 60)
	var en:String;
	var pt:String;
	var es:String;
}

class SonicGameplayState extends MusicBeatSubstate
{
	var data:Array<GameplayOption> = [];

	var curSelected:Int = 0;
	var canSelect:Bool = true;
	var isMoving:Bool = false;
	var closing:Bool = false;

	var optionSprites:Array<Array<FlxSprite>> = [];
	var checkboxes:Array<FlxSprite> = []; // indexed by row (null on numeric rows)
	var valueSprites:Array<Array<FlxSprite>> = []; // indexed by row (empty on checkbox rows)

	var selectedArrow:FlxSprite;
	var optionsCamera:FlxCamera;

	var optionY:Float = 128;
	var optionSpacing:Float = 68;
	var checkboxOffsetY:Float = -18.4;

	var optionX:Float = 450;
	var checkboxX:Float = 220;
	var valueX:Float = 900;

	var letterScale:Float = 3;
	var letterSpacing:Float = 4;

	var cursorX:Float = 155;
	var cursorTweenTime:Float = 0.15;

	// Camera scroll for when there are more options than fit on screen
	var scrollStartRow:Int = 4;

	override public function create():Void
	{
		super.create();

		closing = false;
		canSelect = true;
		isMoving = false;

		buildOptionList();

		createOptionsCamera();
		createOptions();
		createCursor();

		updateSelection(false);

		MobileControls.create();
		MobileControls.addToState(this);
	}

	// ------------------------------------------------------------
	// OPTION LIST  (to add a new one, just add another line)
	// ------------------------------------------------------------

	function check(variable:String, en:String, pt:String, es:String):GameplayOption
	{
		return {
			variable: variable,
			isNumber: false,
			min: 0,
			max: 0,
			step: 0,
			mult: 1,
			en: en,
			pt: pt,
			es: es
		};
	}

	function number(variable:String, min:Float, max:Float, step:Float, mult:Float, en:String, pt:String, es:String):GameplayOption
	{
		return {
			variable: variable,
			isNumber: true,
			min: min,
			max: max,
			step: step,
			mult: mult,
			en: en,
			pt: pt,
			es: es
		};
	}

	function buildOptionList():Void
	{
		data = [
			check('downScroll', 'DOWNSCROLL', 'DOWNSCROLL', 'DOWNSCROLL'),
			check('middleScroll', 'MIDDLESCROLL', 'MIDDLESCROLL', 'MIDDLESCROLL'),
			check('opponentStrums', 'OPPONENT STRUMS', 'NOTAS DO OPONENTE', 'NOTAS DEL OPONENTE'),
			check('ghostTapping', 'GHOST TAPPING', 'GHOST TAPPING', 'GHOST TAPPING'),
			check('noReset', 'DISABLE RESET', 'SEM BOTAO RESET', 'SIN BOTON RESET'),
			check('hideHud', 'HIDE HUD', 'ESCONDER HUD', 'OCULTAR HUD'),
			check('flashing', 'FLASHING LIGHTS', 'LUZES PISCANTES', 'LUCES PARPADEANTES'),
			check('camZooms', 'CAMERA ZOOMS', 'ZOOM DA CAMERA', 'ZOOM DE CAMARA'),
			check('scoreZoom', 'SCORE ZOOM', 'ZOOM DO SCORE', 'ZOOM DEL SCORE'),
			check('comboStacking', 'COMBO STACKING', 'ACUMULAR COMBO', 'ACUMULAR COMBO'),
			check('autoPause', 'AUTO PAUSE', 'PAUSA AUTOMATICA', 'PAUSA AUTOMATICA'),
			number('hitsoundVolume', 0, 100, 10, 100, 'HITSOUND VOLUME', 'VOLUME HITSOUND', 'VOLUMEN HITSOUND'),
			number('splashAlpha', 0, 100, 10, 100, 'SPLASH OPACITY', 'OPACIDADE SPLASH', 'OPACIDAD SPLASH'),
			number('ratingOffset', -30, 30, 1, 1, 'RATING OFFSET', 'OFFSET DO RATING', 'OFFSET DEL RATING'),
			number('noteOffset', -500, 500, 5, 1, 'NOTE OFFSET', 'OFFSET DAS NOTAS', 'OFFSET DE NOTAS')
		];
	}

	function getCurrentLanguage():String
	{
		var language:String = Std.string(ClientPrefs.data.language);

		language = StringTools.trim(language.toUpperCase());

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

	function getOptionName(index:Int):String
	{
		var opt:GameplayOption = data[index];

		switch (getCurrentLanguage())
		{
			case 'PORTUGUESE':
				return opt.pt;

			case 'ESPANOL':
				return opt.es;

			default:
				return opt.en;
		}
	}

	// ------------------------------------------------------------
	// READING / WRITING PREFS
	// ------------------------------------------------------------

	function getBool(index:Int):Bool
	{
		return Reflect.getProperty(ClientPrefs.data, data[index].variable) == true;
	}

	function getDisplayValue(index:Int):Int
	{
		var raw:Dynamic = Reflect.getProperty(ClientPrefs.data, data[index].variable);

		if (raw == null)
			return 0;

		return Math.round(cast(raw, Float) * data[index].mult);
	}

	function setDisplayValue(index:Int, value:Int):Void
	{
		var opt:GameplayOption = data[index];

		if (opt.mult == 1)
			Reflect.setProperty(ClientPrefs.data, opt.variable, value);
		else
			Reflect.setProperty(ClientPrefs.data, opt.variable, value / opt.mult);
	}

	// ------------------------------------------------------------
	// CREATION
	// ------------------------------------------------------------

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
		temp.scale.set(letterScale, letterScale);
		temp.updateHitbox();

		var w:Float = temp.width;
		temp.destroy();

		return w;
	}

	function getTextWidth(text:String):Float
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

		var offsetX:Float = -getTextWidth(text) / 2;

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

			add(letter);
			setOptionsCamera(letter);

			optionSprites[index].push(letter);

			offsetX += letter.width;
		}
	}

	function createOptions():Void
	{
		for (i in 0...data.length)
		{
			checkboxes[i] = null;
			valueSprites[i] = [];

			if (data[i].isNumber)
				updateValue(i);
			else
				createCheckBox(i);

			createOption(getOptionName(i), i);
		}
	}

	function createCheckBox(index:Int):Void
	{
		var checkbox:FlxSprite = new FlxSprite(checkboxX, optionY + (index * optionSpacing) + checkboxOffsetY);

		checkbox.frames = Paths.getSparrowAtlas('dataselect/options/sonicCheckBox');

		checkbox.animation.addByPrefix('clickOff', 'clickOff', 24, false);
		checkbox.animation.addByPrefix('clickOn', 'clickOn', 24, false);

		checkbox.animation.play(getBool(index) ? 'clickOn' : 'clickOff');

		checkbox.antialiasing = false;
		checkbox.scale.set(3, 3);
		checkbox.updateHitbox();

		add(checkbox);
		setOptionsCamera(checkbox);

		checkboxes[index] = checkbox;
	}

	function createCursor():Void
	{
		selectedArrow = new FlxSprite(cursorX, optionY);

		selectedArrow.loadGraphic(Paths.image('pauseMenuEXE/selectedArrow'));

		selectedArrow.antialiasing = false;
		selectedArrow.scale.set(3, 3);
		selectedArrow.updateHitbox();

		add(selectedArrow);
		setOptionsCamera(selectedArrow);
	}

	// ------------------------------------------------------------
	// SELECTION + SCROLL
	// ------------------------------------------------------------

	function changeSelection(change:Int = 0):Void
	{
		if (isMoving || !canSelect || closing)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, data.length - 1);

		FlxG.sound.play(Paths.sound('dataselectswitch'));

		updateSelection(true);
	}

	function getScrollTarget():Float
	{
		var maxScroll:Float = Math.max(0, (data.length - scrollStartRow - 4) * optionSpacing);
		var target:Float = (curSelected - scrollStartRow) * optionSpacing;

		return FlxMath.bound(target, 0, maxScroll);
	}

	function updateSelection(playTween:Bool = true):Void
	{
		if (selectedArrow == null || closing)
			return;

		var targetY:Float = optionY + (curSelected * optionSpacing);
		var scrollY:Float = getScrollTarget();

		if (playTween)
		{
			isMoving = true;

			FlxTween.cancelTweensOf(selectedArrow);
			FlxTween.cancelTweensOf(optionsCamera.scroll);

			FlxTween.tween(optionsCamera.scroll, {y: scrollY}, cursorTweenTime, {ease: FlxEase.quadOut});

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
			optionsCamera.scroll.y = scrollY;
		}

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

			checkbox.animation.play(getBool(i) ? 'clickOn' : 'clickOff');
		}
	}

	// ------------------------------------------------------------
	// NUMERIC VALUES
	// ------------------------------------------------------------

	function updateValue(index:Int):Void
	{
		if (closing)
			return;

		var text:String = Std.string(getDisplayValue(index));
		var totalWidth:Float = 0;

		for (i in 0...text.length)
			totalWidth += getLetterWidth(text.charAt(i));

		var offsetX:Float = -totalWidth / 2;
		var sprites:Array<FlxSprite> = valueSprites[index];

		while (sprites.length < text.length)
		{
			var newLetter:FlxSprite = new FlxSprite();

			newLetter.antialiasing = false;
			newLetter.scale.set(letterScale, letterScale);

			add(newLetter);
			setOptionsCamera(newLetter);

			sprites.push(newLetter);
		}

		while (sprites.length > text.length)
		{
			var oldLetter:FlxSprite = sprites.pop();

			if (oldLetter != null)
			{
				remove(oldLetter, true);
				oldLetter.destroy();
			}
		}

		for (i in 0...text.length)
		{
			var letter:FlxSprite = sprites[i];

			letter.loadGraphic(Paths.image(getLetterPath(text.charAt(i))));
			letter.antialiasing = false;
			letter.scale.set(letterScale, letterScale);
			letter.updateHitbox();

			letter.x = valueX + offsetX;
			letter.y = optionY + (index * optionSpacing);

			offsetX += letter.width;
		}
	}

	function changeValue(direction:Int):Void
	{
		if (closing)
			return;

		var opt:GameplayOption = data[curSelected];

		if (!opt.isNumber)
			return;

		var current:Int = getDisplayValue(curSelected);
		var newValue:Int = Std.int(FlxMath.bound(current + (opt.step * direction), opt.min, opt.max));

		if (newValue == current)
			return;

		setDisplayValue(curSelected, newValue);

		updateValue(curSelected);

		ClientPrefs.saveSettings();

		if (opt.variable == 'hitsoundVolume')
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);
		else
			FlxG.sound.play(Paths.sound('confirmMenu'));
	}

	function toggleCurrentOption():Void
	{
		if (closing || data[curSelected].isNumber)
			return;

		Reflect.setProperty(ClientPrefs.data, data[curSelected].variable, !getBool(curSelected));

		updateCheckBoxes();

		ClientPrefs.saveSettings();

		FlxG.sound.play(Paths.sound('confirmMenu'));
	}

	// ------------------------------------------------------------
	// UPDATE / CLOSE
	// ------------------------------------------------------------

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
			changeValue(-1);
		}
		else if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D || MobileControls.rightJustPressed)
		{
			changeValue(1);
		}
		else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z || MobileControls.aJustPressed)
		{
			toggleCurrentOption();
		}
		else if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE || MobileControls.bJustPressed)
		{
			closeGameplay();
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

	function closeGameplay():Void
	{
		if (!canSelect || closing)
			return;

		closing = true;
		canSelect = false;
		isMoving = false;

		FlxTween.cancelTweensOf(selectedArrow);

		if (optionsCamera != null)
			FlxTween.cancelTweensOf(optionsCamera.scroll);

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

		if (optionsCamera != null)
			FlxTween.cancelTweensOf(optionsCamera.scroll);

		ClientPrefs.saveSettings();

		if (optionsCamera != null)
		{
			FlxG.cameras.remove(optionsCamera, true);
			optionsCamera = null;
		}

		super.destroy();
	}
}
