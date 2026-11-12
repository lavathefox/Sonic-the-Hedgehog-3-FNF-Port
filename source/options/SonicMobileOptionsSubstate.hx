package options;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.util.FlxColor;

import backend.ClientPrefs;
import backend.MobileControls;
import backend.MusicBeatSubstate;
import backend.Paths;

import mobile.AndroidOptions;
import mobile.DeviceUtil;

/** One line of the menu: its name, how to read its value as text, and how to change it. */
typedef MobileOptionEntry =
{
	var label:String; // already translated to the current language
	var getValue:Void->String; // always returns the ENGLISH value; it is translated when drawn
	var change:Int->Void; // +1 = next value, -1 = previous value
}

class SonicMobileOptionsSubstate extends MusicBeatSubstate
{
	// The list shows this many options at once and scrolls when there are more.
	static inline var VISIBLE_ROWS:Int = 4;

	var entries:Array<MobileOptionEntry> = [];
	var selected:Int = 0;
	var firstRow:Int = 0;
	var canSelect:Bool = true;
	var labels:Array<Array<FlxSprite>> = [];
	var values:Array<Array<FlxSprite>> = [];
	var titleSprites:Array<FlxSprite> = [];
	var selectedArrow:FlxSprite;
	var moreUp:FlxSprite;
	var moreDown:FlxSprite;
	var optionsCamera:FlxCamera;
	var letterWidths:Map<String, Float> = new Map();

	var language:String = 'ENGLISH';
	var valueTranslations:Map<String, String> = new Map();

	var optionY:Float = 270;
	var optionSpacing:Float = 90;
	var labelX:Float = 180;
	var valueX:Float = 690;
	var valueWidth:Float = 200;
	var letterScale:Float = 2;
	var letterSpacing:Float = 8;

	override public function create():Void
	{
		super.create();

		// Reads the saved options before the menu shows them.
		AndroidOptions.loadSaved();

		language = getCurrentLanguage();
		buildValueTranslations();

		optionsCamera = new FlxCamera();
		optionsCamera.bgColor.alpha = 0;
		optionsCamera.zoom = 1;
		optionsCamera.scroll.set(0, 0);
		optionsCamera.pixelPerfectRender = true;
		FlxG.cameras.add(optionsCamera, false);

		var background:FlxSprite = new FlxSprite(0, 0);
		background.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.alpha = 0.8;
		background.scrollFactor.set();
		background.cameras = [optionsCamera];
		add(background);

		var title:String = tr('MOBILE OPTIONS', 'OPCOES MOBILE', 'OPCIONES MOVILES');
		createTextSprites(title, titleSprites, (FlxG.width - getTextWidth(title, 3)) / 2, 125, 3);

		selectedArrow = new FlxSprite(115, optionY);
		selectedArrow.loadGraphic(Paths.image('pauseMenuEXE/selectedArrow'));
		selectedArrow.antialiasing = false;
		selectedArrow.scale.set(2, 2);
		selectedArrow.updateHitbox();
		selectedArrow.scrollFactor.set();
		selectedArrow.cameras = [optionsCamera];
		add(selectedArrow);

		buildEntries();

		for (i in 0...entries.length)
			createOption(i);

		moreUp = createMoreArrow(-90);
		moreDown = createMoreArrow(90);

		layoutRows();

		MobileControls.create();
		MobileControls.update();
	}

	// ---- Language ----

	function getCurrentLanguage():String
	{
		var lang:String = StringTools.trim(Std.string(ClientPrefs.data.language).toUpperCase());

		switch (lang)
		{
			case 'PORTUGUESE', 'PORTUGUES', 'PORTUGUÊS', 'PTBR', 'PT-BR', 'PT_BR', 'BRAZILIAN PORTUGUESE':
				return 'PORTUGUESE';

			case 'ESPANOL', 'ESPAÑOL', 'SPANISH', 'ES', 'ES-ES', 'ES_ES':
				return 'ESPANOL';

			default:
				return 'ENGLISH';
		}
	}

	/** Picks the text for the current language. No accents: the HUD letters only exist for A-Z. */
	function tr(en:String, pt:String, es:String):String
	{
		switch (language)
		{
			case 'PORTUGUESE':
				return pt;

			case 'ESPANOL':
				return es;

			default:
				return en;
		}
	}

	/**
	 * Translates the value names that come from AndroidOptions (ON, OFF, LOW, HIGH...).
	 * A name that is not in the list is shown as it is, so nothing breaks if AndroidOptions has others.
	 */
	function buildValueTranslations():Void
	{
		valueTranslations = new Map();

		if (language == 'ENGLISH')
			return;

		var pt:Bool = language == 'PORTUGUESE';

		// [english, portuguese, spanish]
		var words:Array<Array<String>> = [
			['ON', 'SIM', 'SI'],
			['OFF', 'NAO', 'NO'],
			['AUTO', 'AUTO', 'AUTO'],
			['NONE', 'NENHUM', 'NINGUNO'],
			['LOW', 'BAIXO', 'BAJO'],
			['MEDIUM', 'MEDIO', 'MEDIO'],
			['HIGH', 'ALTO', 'ALTO'],
			['SMALL', 'PEQUENO', 'PEQUENO'],
			['NORMAL', 'NORMAL', 'NORMAL'],
			['LARGE', 'GRANDE', 'GRANDE'],
			['BIG', 'GRANDE', 'GRANDE'],
			['DEFAULT', 'PADRAO', 'DEFECTO'],
			['FULL', 'TOTAL', 'TOTAL'],
			['MAX', 'MAXIMO', 'MAXIMO'],
			['MIN', 'MINIMO', 'MINIMO'],
			['LIGHT', 'LEVE', 'LEVE'],
			['SOFT', 'SUAVE', 'SUAVE'],
			['STRONG', 'FORTE', 'FUERTE'],
			['WEAK', 'FRACO', 'DEBIL'],
			['CLASSIC', 'CLASSICO', 'CLASICO'],
			['MODERN', 'MODERNO', 'MODERNO'],
			['SIMPLE', 'SIMPLES', 'SIMPLE'],
			['BAR', 'BARRA', 'BARRA'],
			['BARS', 'BARRAS', 'BARRAS'],
			['GLOW', 'BRILHO', 'BRILLO'],
			['SOLID', 'SOLIDO', 'SOLIDO'],
			['OUTLINE', 'CONTORNO', 'CONTORNO'],
			['GRADIENT', 'GRADIENTE', 'GRADIENTE'],
			['DARK', 'ESCURO', 'OSCURO'],
			['BRIGHT', 'CLARO', 'BRILLANTE']
		];

		for (word in words)
			valueTranslations.set(word[0], pt ? word[1] : word[2]);
	}

	function translateValue(value:String):String
	{
		var translated:String = valueTranslations.get(value.toUpperCase());
		return translated != null ? translated : value;
	}

	// ---- The options ----

	function buildEntries():Void
	{
		entries = [
			boolEntry(tr('SHOW HITBOX', 'MOSTRAR HITBOX', 'MOSTRAR HITBOX'),
				function() return ClientPrefs.data.mobileShowHitbox,
				function(value:Bool) { ClientPrefs.data.mobileShowHitbox = value; }),

			boolEntry(tr('SHOW PAUSE BUTTON', 'BOTAO DE PAUSE', 'BOTON DE PAUSA'),
				function() return ClientPrefs.data.mobilePauseButton,
				function(value:Bool) { ClientPrefs.data.mobilePauseButton = value; }),

			// Draws a ring where each finger touches the screen.
			boolEntry(tr('TOUCH CURSOR', 'CURSOR DE TOQUE', 'CURSOR TACTIL'),
				function() return ClientPrefs.data.mobileTouchCursor,
				function(value:Bool) { ClientPrefs.data.mobileTouchCursor = value; }),

			// How visible the arrows and the A/B buttons are.
			listEntry(tr('CONTROLS OPACITY', 'OPACIDADE BOTOES', 'OPACIDAD BOTONES'), AndroidOptions.OPACITY_NAMES,
				function() return ClientPrefs.data.mobileControlsOpacity,
				function(value:Int) { ClientPrefs.data.mobileControlsOpacity = value; }),

			// A short vibration when a control or a lane is touched.
			listEntry(tr('VIBRATION', 'VIBRACAO', 'VIBRACION'), AndroidOptions.VIBRATION_NAMES,
				function() return ClientPrefs.data.mobileVibration,
				function(value:Int)
				{
					ClientPrefs.data.mobileVibration = value;
					DeviceUtil.tap(); // lets the player feel the new strength right away
				}),

			// Stops the screen from turning off while the game is open.
			boolEntry(tr('KEEP SCREEN ON', 'MANTER TELA LIGADA', 'PANTALLA ENCENDIDA'),
				function() return ClientPrefs.data.mobileKeepScreenOn,
				function(value:Bool) { ClientPrefs.data.mobileKeepScreenOn = value; }),

			// Look of the touch lanes used during songs (applies on the next song).
			listEntry(tr('LANE STYLE', 'ESTILO DAS LANES', 'ESTILO DE LANES'), AndroidOptions.LANE_STYLE_NAMES,
				function() return ClientPrefs.data.mobileLaneStyle,
				function(value:Int) { ClientPrefs.data.mobileLaneStyle = value; }),

			// How bright a lane flashes when it is touched (applies on the next song).
			listEntry(tr('LANE OPACITY', 'OPACIDADE LANES', 'OPACIDAD LANES'), AndroidOptions.LANE_OPACITY_NAMES,
				function() return ClientPrefs.data.mobileLaneOpacity,
				function(value:Int) { ClientPrefs.data.mobileLaneOpacity = value; }),

			// Size of the on-screen arrows and A/B buttons.
			listEntry(tr('CONTROLS SIZE', 'TAMANHO BOTOES', 'TAMANO BOTONES'), AndroidOptions.CONTROLS_SIZE_NAMES,
				function() return ClientPrefs.data.mobileControlsSize,
				function(value:Int) { ClientPrefs.data.mobileControlsSize = value; }),

			// Swaps the sides: arrows on the right, A/B buttons on the left.
			boolEntry(tr('LEFT HANDED', 'MODO CANHOTO', 'MODO ZURDO'),
				function() return ClientPrefs.data.mobileLeftHanded,
				function(value:Bool) { ClientPrefs.data.mobileLeftHanded = value; }),

			// Screen brightness while the game is open. AUTO = the phone decides.
			listEntry(tr('BRIGHTNESS', 'BRILHO', 'BRILLO'), AndroidOptions.BRIGHTNESS_NAMES,
				function() return ClientPrefs.data.mobileBrightness,
				function(value:Int) { ClientPrefs.data.mobileBrightness = value; }),

			// ---- New options ----

			// FPS counter in the corner. Uses the normal showFPS pref that already exists.
			boolEntry(tr('SHOW FPS', 'MOSTRAR FPS', 'MOSTRAR FPS'),
				function() return ClientPrefs.data.showFPS,
				function(value:Bool) { ClientPrefs.data.showFPS = value; }),

			// Size of the ring drawn by TOUCH CURSOR.
			listEntry(tr('TOUCH CURSOR SIZE', 'TAMANHO CURSOR', 'TAMANO CURSOR'), AndroidOptions.TOUCH_CURSOR_SIZE_NAMES,
				function() return ClientPrefs.data.mobileTouchCursorSize,
				function(value:Int) { ClientPrefs.data.mobileTouchCursorSize = value; }),

			// A vibration when a note is missed.
			boolEntry(tr('VIBRATE ON MISS', 'VIBRAR AO ERRAR', 'VIBRAR AL FALLAR'),
				function() return ClientPrefs.data.mobileVibrateOnMiss,
				function(value:Bool)
				{
					ClientPrefs.data.mobileVibrateOnMiss = value;
					if (value)
						DeviceUtil.tap();
				}),

			// The A and B buttons trade places.
			boolEntry(tr('SWAP A AND B', 'TROCAR A E B', 'INTERCAMBIAR A Y B'),
				function() return ClientPrefs.data.mobileSwapAB,
				function(value:Bool) { ClientPrefs.data.mobileSwapAB = value; }),

			// Hides the Android status and navigation bars while the game is open.
			boolEntry(tr('IMMERSIVE MODE', 'MODO IMERSIVO', 'MODO INMERSIVO'),
				function() return ClientPrefs.data.mobileImmersive,
				function(value:Bool) { ClientPrefs.data.mobileImmersive = value; }),

			// Turns off heavy effects to save battery on weak phones.
			boolEntry(tr('BATTERY SAVER', 'ECONOMIA BATERIA', 'AHORRO BATERIA'),
				function() return ClientPrefs.data.mobileBatterySaver,
				function(value:Bool) { ClientPrefs.data.mobileBatterySaver = value; })
		];
	}

	/** An ON/OFF option. */
	function boolEntry(label:String, getter:Void->Bool, setter:Bool->Void):MobileOptionEntry
	{
		return {
			label: label,
			getValue: function():String return getter() ? 'ON' : 'OFF',
			change: function(direction:Int):Void setter(!getter())
		};
	}

	/** An option that cycles through a list of names. The saved value is the position in the list. */
	function listEntry(label:String, names:Array<String>, getter:Void->Int, setter:Int->Void):MobileOptionEntry
	{
		return {
			label: label,
			getValue: function():String return names[AndroidOptions.clampIndex(getter(), names.length)],
			change: function(direction:Int):Void
			{
				var next:Int = (AndroidOptions.clampIndex(getter(), names.length) + direction + names.length) % names.length;
				setter(next);
			}
		};
	}

	// ---- Text drawn with the HUD letters (letters and spaces only) ----

	function getLetterPath(char:String):String
	{
		return LetterPath.get(char);
	}

	function getLetterWidth(char:String, scale:Float):Float
	{
		var key:String = char.toUpperCase() + '|' + scale;
		var cached:Null<Float> = letterWidths.get(key);

		if (cached != null)
			return cached;

		var letter:FlxSprite = new FlxSprite();
		letter.loadGraphic(Paths.image(getLetterPath(char)));
		letter.antialiasing = false;
		letter.scale.set(scale, scale);
		letter.updateHitbox();

		var width:Float = letter.width;
		letter.destroy();

		letterWidths.set(key, width);
		return width;
	}

	function getTextWidth(text:String, ?scale:Float = -1):Float
	{
		if (scale < 0)
			scale = letterScale;

		var total:Float = 0;
		text = text.toUpperCase();

		for (i in 0...text.length)
		{
			var char:String = text.charAt(i);
			if (char == ' ')
				total += letterSpacing * (scale / letterScale);
			else
				total += getLetterWidth(char, scale);
		}

		return total;
	}

	function createTextSprites(text:String, target:Array<FlxSprite>, startX:Float, y:Float, ?scale:Float = -1):Void
	{
		if (scale < 0)
			scale = letterScale;

		text = text.toUpperCase();
		var offsetX:Float = startX;

		for (i in 0...text.length)
		{
			var char:String = text.charAt(i);

			if (char == ' ')
			{
				offsetX += letterSpacing * (scale / letterScale);
				continue;
			}

			var letter:FlxSprite = new FlxSprite(offsetX, y);
			letter.loadGraphic(Paths.image(getLetterPath(char)));
			letter.scale.set(scale, scale);
			letter.updateHitbox();
			letter.antialiasing = false;
			letter.scrollFactor.set();
			letter.cameras = [optionsCamera];
			add(letter);
			target.push(letter);
			offsetX += letter.width;
		}
	}

	function destroyTextSprites(sprites:Array<FlxSprite>):Void
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
		sprites.resize(0);
	}

	// ---- Rows, scrolling and selection ----

	function rowY(index:Int):Float
	{
		return optionY + (index - firstRow) * optionSpacing;
	}

	function isRowVisible(index:Int):Bool
	{
		return index >= firstRow && index < firstRow + VISIBLE_ROWS;
	}

	function createOption(index:Int):Void
	{
		var labelSprites:Array<FlxSprite> = [];

		createTextSprites(entries[index].label, labelSprites, labelX, rowY(index));
		labels[index] = labelSprites;
		values[index] = [];
		refreshValue(index);
	}

	function refreshValue(index:Int):Void
	{
		if (index < 0 || index >= values.length)
			return;

		destroyTextSprites(values[index]);

		var value:String = translateValue(entries[index].getValue());
		var startX:Float = valueX + (valueWidth - getTextWidth(value)) / 2;
		createTextSprites(value, values[index], startX, rowY(index));

		for (sprite in values[index])
			sprite.visible = isRowVisible(index);
	}

	/** Places every row according to the scroll position and shows only the visible ones. */
	function layoutRows():Void
	{
		for (i in 0...entries.length)
		{
			var y:Float = rowY(i);
			var visibleRow:Bool = isRowVisible(i);

			for (sprite in labels[i])
			{
				sprite.y = y;
				sprite.visible = visibleRow;
			}

			for (sprite in values[i])
			{
				sprite.y = y;
				sprite.visible = visibleRow;
			}
		}

		selectedArrow.y = rowY(selected);
		moreUp.visible = firstRow > 0;
		moreDown.visible = firstRow + VISIBLE_ROWS < entries.length;
		updateSelectionAlpha();
	}

	function updateSelectionAlpha():Void
	{
		for (i in 0...labels.length)
		{
			if (labels[i] == null || values[i] == null)
				continue;

			var alpha:Float = i == selected ? 1 : 0.55;
			for (sprite in labels[i])
				sprite.alpha = alpha;
			for (sprite in values[i])
				sprite.alpha = alpha;
		}
	}

	/** Small arrows above and below the list, shown when there are more options out of view. */
	function createMoreArrow(angle:Float):FlxSprite
	{
		var arrow:FlxSprite = new FlxSprite(0, 0);
		arrow.loadGraphic(Paths.image('pauseMenuEXE/selectedArrow'));
		arrow.antialiasing = false;
		arrow.scale.set(2, 2);
		arrow.updateHitbox();
		arrow.angle = angle;
		arrow.scrollFactor.set();
		arrow.cameras = [optionsCamera];
		arrow.screenCenter(X);
		arrow.y = angle < 0 ? optionY - 55 : optionY + VISIBLE_ROWS * optionSpacing - 25;
		add(arrow);
		return arrow;
	}

	function changeSelection(change:Int):Void
	{
		selected = (selected + change + entries.length) % entries.length;

		// Scroll the list so the selected row is always on screen.
		if (selected < firstRow)
			firstRow = selected;
		else if (selected >= firstRow + VISIBLE_ROWS)
			firstRow = selected - VISIBLE_ROWS + 1;

		FlxG.sound.play(Paths.sound('dataselectswitch'));
		layoutRows();
	}

	function changeValue(direction:Int):Void
	{
		var entry:MobileOptionEntry = entries[selected];

		if (entry == null)
			return;

		entry.change(direction);

		ClientPrefs.saveSettings();
		AndroidOptions.apply();

		refreshValue(selected);
		updateSelectionAlpha();
		FlxG.sound.play(Paths.sound('confirmMenu'));
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		MobileControls.update();

		if (!canSelect)
			return;

		var up:Bool = FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W || MobileControls.upJustPressed;
		var down:Bool = FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S || MobileControls.downJustPressed;
		var left:Bool = FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A || MobileControls.leftJustPressed;
		var right:Bool = FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D || MobileControls.rightJustPressed;
		var confirm:Bool = FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z || MobileControls.aJustPressed;
		var back:Bool = FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE || MobileControls.bJustPressed;

		if (up)
			changeSelection(-1);
		else if (down)
			changeSelection(1);
		else if (left)
			changeValue(-1);
		else if (right || confirm)
			changeValue(1);
		else if (back)
			closeMobileOptions();
	}

	function closeMobileOptions():Void
	{
		if (!canSelect)
			return;

		canSelect = false;
		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('cancelMenu'));

		var parent:Dynamic = FlxG.state;
		if (parent != null)
		{
			if (Reflect.hasField(parent, 'canSelect'))
				Reflect.setField(parent, 'canSelect', true);
			if (Reflect.hasField(parent, 'isMoving'))
				Reflect.setField(parent, 'isMoving', false);
		}

		close();
	}

	override public function destroy():Void
	{
		ClientPrefs.saveSettings();

		for (sprites in labels)
			destroyTextSprites(sprites);
		for (sprites in values)
			destroyTextSprites(sprites);
		destroyTextSprites(titleSprites);

		letterWidths.clear();

		if (optionsCamera != null)
		{
			FlxG.cameras.remove(optionsCamera, true);
			optionsCamera = null;
		}

		super.destroy();
	}
}
