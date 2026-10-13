package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import backend.ClientPrefs;
import backend.MobileControls;
import backend.MusicBeatSubstate;
import backend.Paths;

class SonicMobileOptionsSubstate extends MusicBeatSubstate
{
	var selected:Int = 0;
	var canSelect:Bool = true;
	var labels:Array<FlxText> = [];
	var values:Array<FlxText> = [];
	var selectedArrow:FlxSprite;

	override public function create():Void
	{
		super.create();

		var background:FlxSprite = new FlxSprite(0, 0);
		background.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0));
		background.alpha = 0.8;
		background.scrollFactor.set();
		add(background);

		var title:FlxText = new FlxText(0, 70, FlxG.width, 'MOBILE OPTIONS', 32);
		title.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
		title.scrollFactor.set();
		add(title);

		selectedArrow = new FlxSprite(115, 190);
		selectedArrow.loadGraphic(Paths.image('pauseMenuEXE/selectedArrow'));
		selectedArrow.antialiasing = false;
		selectedArrow.scale.set(2, 2);
		selectedArrow.updateHitbox();
		selectedArrow.scrollFactor.set();
		add(selectedArrow);

		createOption('SHOW HITBOX', 0);
		createOption('SHOW PAUSE BUTTON', 1);
		updateValues();

		MobileControls.create();
		MobileControls.update();
	}

	function createOption(label:String, index:Int):Void
	{
		var y:Float = 190 + index * 90;
		var option:FlxText = new FlxText(165, y, 540, label, 24);
		option.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, LEFT);
		option.scrollFactor.set();
		add(option);
		labels.push(option);

		var value:FlxText = new FlxText(720, y, 180, '', 24);
		value.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER);
		value.scrollFactor.set();
		add(value);
		values.push(value);
	}

	function updateValues():Void
	{
		values[0].text = ClientPrefs.data.mobileShowHitbox ? 'ON' : 'OFF';
		values[1].text = ClientPrefs.data.mobilePauseButton ? 'ON' : 'OFF';
		selectedArrow.y = 190 + selected * 90;
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

	override function destroy():Void
	{
		ClientPrefs.saveSettings();
		super.destroy();
	}
}
