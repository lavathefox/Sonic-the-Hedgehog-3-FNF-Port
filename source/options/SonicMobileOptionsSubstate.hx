package options;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.util.FlxColor;

import backend.ClientPrefs;
import backend.MobileControls;
import backend.MusicBeatSubstate;
import backend.Paths;

class SonicMobileOptionsSubstate extends MusicBeatSubstate
{
	var selected:Int = 0;
	var canSelect:Bool = true;
	var labels:Array<Array<FlxSprite>> = [];
	var values:Array<Array<FlxSprite>> = [];
	var titleSprites:Array<FlxSprite> = [];
	var selectedArrow:FlxSprite;
	var optionsCamera:FlxCamera;

	var optionY:Float = 270;
	var optionSpacing:Float = 100;
	var labelX:Float = 180;
	var valueX:Float = 690;
	var letterScale:Float = 2;
	var letterSpacing:Float = 8;

	override public function create():Void
	{
		super.create();

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

		createTextSprites('MOBILE OPTIONS', titleSprites, (FlxG.width - getTextWidth('MOBILE OPTIONS', 3)) / 2, 125, 3);

		selectedArrow = new FlxSprite(115, optionY);
		selectedArrow.loadGraphic(Paths.image('pauseMenuEXE/selectedArrow'));
		selectedArrow.antialiasing = false;
		selectedArrow.scale.set(2, 2);
		selectedArrow.updateHitbox();
		selectedArrow.scrollFactor.set();
		selectedArrow.cameras = [optionsCamera];
		add(selectedArrow);

		createOption('SHOW HITBOX', 0);
		createOption('SHOW PAUSE BUTTON', 1);
		updateValues();

		MobileControls.create();
		MobileControls.update();
	}

	function getLetterPath(char:String):String
	{
		char = char.toUpperCase();

		if (char == ':')
			return 'hud/letershud/colon2';

		return 'hud/letershud/' + char;
	}

	function getLetterWidth(char:String, scale:Float):Float
	{
		var letter:FlxSprite = new FlxSprite();
		letter.loadGraphic(Paths.image(getLetterPath(char)));
		letter.antialiasing = false;
		letter.scale.set(scale, scale);
		letter.updateHitbox();
		return letter.width;
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

	function createOption(label:String, index:Int):Void
	{
		var y:Float = optionY + index * optionSpacing;
		var labelSprites:Array<FlxSprite> = [];
		var valueSprites:Array<FlxSprite> = [];

		createTextSprites(label, labelSprites, labelX, y);
		labels[index] = labelSprites;
		values[index] = valueSprites;
		refreshValue(index);
	}

	function refreshValue(index:Int):Void
	{
		if (index < 0 || index >= values.length)
			return;

		destroyTextSprites(values[index]);

		var value:String = '';
		if (index == 0)
			value = ClientPrefs.data.mobileShowHitbox ? 'ON' : 'OFF';
		else
			value = ClientPrefs.data.mobilePauseButton ? 'ON' : 'OFF';

		var startX:Float = valueX + (150 - getTextWidth(value)) / 2;
		createTextSprites(value, values[index], startX, optionY + index * optionSpacing);
	}

	function updateValues():Void
	{
		refreshValue(0);
		refreshValue(1);
		selectedArrow.y = optionY + selected * optionSpacing;
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

	function changeSelection(change:Int):Void
	{
		selected = (selected + change + 2) % 2;
		FlxG.sound.play(Paths.sound('dataselectswitch'));
		updateValues();
	}

	function toggleOption():Void
	{
		if (selected == 0)
			ClientPrefs.data.mobileShowHitbox = !ClientPrefs.data.mobileShowHitbox;
		else
			ClientPrefs.data.mobilePauseButton = !ClientPrefs.data.mobilePauseButton;

		ClientPrefs.saveSettings();
		MobileControls.applyMobileOptions();
		updateValues();
		FlxG.sound.play(Paths.sound('confirmMenu'));
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		MobileControls.update();

		if (!canSelect)
			return;

		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W || MobileControls.upJustPressed)
			changeSelection(-1);
		else if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S || MobileControls.downJustPressed)
			changeSelection(1);
		else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z || MobileControls.aJustPressed)
			toggleOption();
		else if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE || MobileControls.bJustPressed)
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

		if (optionsCamera != null)
		{
			FlxG.cameras.remove(optionsCamera, true);
			optionsCamera = null;
		}

		super.destroy();
	}
}
