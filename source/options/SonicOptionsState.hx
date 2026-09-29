package options;

import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
	var categories:Array<String> = [
		'Preferences',
		'Gameplay',
		'Controls',
		'Graphics',
		'Visuals'
	];

	var curSelected:Int = 0;
	var canSelect:Bool = true;
	var isMoving:Bool = false;

	var categoryY:Float = 155;
	var spacing:Float = 22;

	var bg:FlxSprite;
	var optionsSelect:FlxSprite;

	var grpCategories:FlxTypedGroup<FlxText>;
	var selectorLeft:FlxText;
	var selectorRight:FlxText;

	public static var onPlayState:Bool = false;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Options Menu', null);
		#end

    FlxG.camera.scroll.set(-320, -223);

    FlxG.camera.zoom = 3;
    FlxG.camera.pixelPerfectRender = true;

		bg = new FlxSprite(0, 0).loadGraphic(Paths.image('dataselect/dataSelect_BG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		optionsSelect = new FlxSprite(50, 180).loadGraphic(Paths.image('dataselect/options/options_Select'));
		optionsSelect.antialiasing = ClientPrefs.data.antialiasing;
		add(optionsSelect);

		grpCategories = new FlxTypedGroup<FlxText>();
		add(grpCategories);

		createCategoryTexts();
		createCursor();
		changeSelection(0);

		if(FlxG.sound.music == null || !FlxG.sound.music.playing || FlxG.sound.music.assetPath != Paths.music('DataSelect'))
			FlxG.sound.playMusic(Paths.music('DataSelect'), 1, true);

		super.create();
	}

	function createCategoryTexts()
	{
		for (i in 0...categories.length)
		{
			var category:FlxText = new FlxText(65, categoryY + (i * spacing), 1200, categories[i]);
			category.setFormat(Paths.font('vcr.ttf'), 27, FlxColor.WHITE, LEFT);
			category.antialiasing = ClientPrefs.data.antialiasing;
			category.ID = i;
			grpCategories.add(category);
		}
	}

	function createCursor()
	{
		selectorLeft = new FlxText(45, categoryY, 30, '<');
		selectorLeft.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, LEFT);
		selectorLeft.antialiasing = ClientPrefs.data.antialiasing;
		add(selectorLeft);

		selectorRight = new FlxText(0, categoryY, 30, '>');
		selectorRight.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, LEFT);
		selectorRight.antialiasing = ClientPrefs.data.antialiasing;
		add(selectorRight);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(!canSelect || isMoving)
			return;

		if(controls.UI_UP_P)
			changeSelection(-1);
		else if(controls.UI_DOWN_P)
			changeSelection(1);
		else if(controls.ACCEPT)
			openCategory();
		else if(controls.BACK)
			backToPreviousState();
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, categories.length - 1);

		var targetY:Float = categoryY + (curSelected * spacing);

		FlxTween.cancelTweensOf(selectorLeft);
		FlxTween.cancelTweensOf(selectorRight);

		FlxTween.tween(selectorLeft, {y: targetY}, 0.15, {ease: FlxEase.quadOut});
		FlxTween.tween(selectorRight, {y: targetY}, 0.15, {ease: FlxEase.quadOut});

		for (i in 0...grpCategories.length)
		{
			var category:FlxText = grpCategories.members[i];
			if(category == null)
				continue;

			category.alpha = i == curSelected ? 1 : 0.6;
		}

		if(grpCategories.members[curSelected] != null)
			selectorRight.x = grpCategories.members[curSelected].x + grpCategories.members[curSelected].width + 10;

		FlxG.sound.play(Paths.sound('dataselectswitch'));

		isMoving = true;

		new FlxTimer().start(0.15, function(timer:FlxTimer)
		{
			isMoving = false;
		});
	}

	function openCategory()
	{
		var category:String = categories[curSelected];

		FlxG.sound.play(Paths.sound('confirmMenu'));

		switch(category)
		{
			case 'Preferences':
				openSubState(new PreferencesSettingsSubState());

			case 'Gameplay':
				openSubState(new GameplaySettingsSubState());

			case 'Controls':
				openSubState(new ControlsSubState());

			case 'Graphics':
				openSubState(new GraphicsSettingsSubState());

			case 'Visuals':
				openSubState(new VisualsSettingsSubState());
		}
	}

	function backToPreviousState()
	{
		canSelect = false;

		FlxG.sound.play(Paths.sound('cancelMenu'));

		if(onPlayState)
		{
			StageData.loadDirectory(PlayState.SONG);
			LoadingState.loadAndSwitchState(new PlayState());
			FlxG.sound.music.volume = 0;
		}
		else
		{
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	override function closeSubState()
	{
		super.closeSubState();

		ClientPrefs.saveSettings();

		canSelect = true;
		isMoving = false;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Options Menu', null);
		#end
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}

class PreferencesSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('preferences_menu', 'Preferences');
		rpcTitle = 'Preferences Menu';

		var option:Option = new Option('Downscroll',
			'If checked, notes go Down instead of Up.',
			'downScroll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys while there are no notes able to be hit.",
			'ghostTapping',
			BOOL);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			BOOL);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights.",
			'flashing',
			BOOL);
		addOption(option);

		super();
	}
}
