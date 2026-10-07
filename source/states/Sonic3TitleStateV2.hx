package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;

import backend.MusicBeatState;
import backend.Paths;
import backend.MobileControls;

import options.Sonic3Options;

#if DISCORD_ALLOWED
import backend.Discord;
#end

class Sonic3TitleStateV2 extends MusicBeatState
{
	var LANGUAGE:String = 'PORTUGUESE';

	var canPressStart:Bool = false;
	var selectedStart:Bool = false;
	var segaFinished:Bool = false;

	var menuSelection:Int = 1;

	var PLAYER_Y:Float = 196;
	var OPTIONS_Y:Float = 206;

	var titleBg:FlxSprite;
	var titleBgDay:FlxSprite;
	var titleBgSunset:FlxSprite;
	var titleBgNight:FlxSprite;
	var titleBgDawn:FlxSprite;

	var titleBgNightNew:FlxSprite;
	var titleBgNightCrescent:FlxSprite;
	var titleBgNightQuarter:FlxSprite;
	var titleBgNightWaxingGibbous:FlxSprite;
	var titleBgNightLastQuarter:FlxSprite;
	var titleBgNightWaningCrescent:FlxSprite;
	var titleBgNightWaningGibbous:FlxSprite;

	var sonic:FlxSprite;
	var title:FlxSprite;
	var copyright:FlxSprite;

	var player:FlxSprite;
	var options:FlxSprite;
	var selectedIcon:FlxSprite;

	var blueFade:FlxSprite;
	var blackFade:FlxSprite;

	var segaIntro:FlxSprite;

	override public function create():Void
	{
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(
			'In the Title Screen',
			'Sonic the Hedgehog 3 FNF Port'
		);
		#end

		FlxG.camera.scroll.set(-320, -223);
		FlxG.camera.zoom = 3;
		FlxG.camera.pixelPerfectRender = true;

		createBackgrounds();
		createSprites();
		createFades();
		createSegaIntro();

		setupVisibility();
		setupTimeBackground();

		FlxG.camera.pixelPerfectRender = true;

		FlxG.sound.play(Paths.sound('segaOpening'));

		#if android
		MobileControls.create();
		MobileControls.setEnabled(false);
		MobileControls.setVisible(false);
		#end

		FlxTween.tween(
			blueFade,
			{alpha: 0},
			0.6,
			{
				ease: FlxEase.sineOut
			}
		);

		FlxTween.tween(
			blackFade,
			{alpha: 0},
			0.5,
			{
				ease: FlxEase.sineOut
			}
		);

		new FlxTimer().start(2.9, function(timer:FlxTimer)
		{
			playSegaIntro();
		});
	}

	function createBackgrounds():Void
	{
		titleBg = createAnimatedSprite(
			'titlescreen3/titleBg',
			'titleIdle',
			12,
			true
		);

		titleBgDay = createAnimatedSprite(
			'titlescreen3/titleBg',
			'titleIdle',
			12,
			true
		);

		titleBgSunset = createAnimatedSprite(
			'titlescreen3/titleBgSunset',
			'titleIdle',
			12,
			true
		);

		titleBgNight = createAnimatedSprite(
			'titlescreen3/titleBgNight',
			'titleIdle',
			12,
			true
		);

		titleBgDawn = createAnimatedSprite(
			'titlescreen3/titleBgDawn',
			'titleIdle',
			12,
			true
		);

		titleBgNightNew = createAnimatedSprite(
			'titlescreen3/titleBgNightNew',
			'titleBg',
			12,
			true
		);

		titleBgNightCrescent = createAnimatedSprite(
			'titlescreen3/titleBgNightCrescent',
			'titleBg',
			12,
			true
		);

		titleBgNightQuarter = createAnimatedSprite(
			'titlescreen3/titleBgNightQuarter',
			'titleBg',
			12,
			true
		);

		titleBgNightWaxingGibbous = createAnimatedSprite(
			'titlescreen3/titleBgNightWaxingGibbous',
			'titleIdle',
			12,
			true
		);

		titleBgNightLastQuarter = createAnimatedSprite(
			'titlescreen3/titleBgNightLastQuarter',
			'titleIdle',
			12,
			true
		);

		titleBgNightWaningCrescent = createAnimatedSprite(
			'titlescreen3/titleBgNightWaningCrescent',
			'titleIdle',
			12,
			true
		);

		titleBgNightWaningGibbous = createAnimatedSprite(
			'titlescreen3/titleBgNightWaningGibbous',
			'titleIdle',
			12,
			true
		);

		add(titleBg);
		add(titleBgDay);
		add(titleBgSunset);
		add(titleBgNight);
		add(titleBgDawn);

		add(titleBgNightNew);
		add(titleBgNightCrescent);
		add(titleBgNightQuarter);
		add(titleBgNightWaxingGibbous);
		add(titleBgNightLastQuarter);
		add(titleBgNightWaningCrescent);
		add(titleBgNightWaningGibbous);
	}

	function createAnimatedSprite(path:String, prefix:String, fps:Int, loop:Bool):FlxSprite
	{
		var sprite:FlxSprite = new FlxSprite(0, 0);

		sprite.frames = Paths.getSparrowAtlas(path);

		sprite.animation.addByPrefix(
			'idle',
			prefix,
			fps,
			loop
		);

		sprite.animation.play('idle');
		sprite.antialiasing = false;

		return sprite;
	}

	function createSprites():Void
	{
		sonic = new FlxSprite(0, -7);

		sonic.frames = Paths.getSparrowAtlas(
			'titlescreen3/sonicTitleScreen'
		);

		sonic.animation.addByPrefix(
			'finger',
			'sonicFinger',
			12,
			true
		);

		sonic.animation.addByPrefix(
			'wink',
			'sonicWink',
			12,
			false
		);

		sonic.animation.play('finger');

		add(sonic);

		title = new FlxSprite(0, 260);

		title.loadGraphic(
			Paths.image('titlescreen3/FNFPortTitle')
		);

		title.antialiasing = false;

		add(title);

		copyright = new FlxSprite(0, 7);

		copyright.loadGraphic(
			Paths.image('titlescreen3/copyright')
		);

		copyright.antialiasing = false;

		add(copyright);

		selectedIcon = new FlxSprite(80, PLAYER_Y);

		selectedIcon.loadGraphic(
			Paths.image('titlescreen3/selectedIcon')
		);

		selectedIcon.antialiasing = false;

		add(selectedIcon);

		createPlayerSprite();
		createOptionsSprite();
	}

	function createPlayerSprite():Void
	{
		player = new FlxSprite(108, PLAYER_Y);

		player.frames = Paths.getSparrowAtlas(
			getPlayerLanguageSprite()
		);

		player.animation.addByPrefix(
			'idle',
			'1PlayerNot',
			12,
			true
		);

		player.animation.addByPrefix(
			'select',
			'1PlayerSelect',
			24,
			false
		);

		player.animation.play('select');
		player.antialiasing = false;

		add(player);
	}

	function createOptionsSprite():Void
	{
		options = new FlxSprite(108, OPTIONS_Y);

		options.frames = Paths.getSparrowAtlas(
			getOptionsLanguageSprite()
		);

		options.animation.addByPrefix(
			'idle',
			'OptionsNot',
			12,
			true
		);

		options.animation.addByPrefix(
			'select',
			'OptionsSelect',
			24,
			false
		);

		options.animation.play('idle');
		options.antialiasing = false;

		add(options);
	}

	function getPlayerLanguageSprite():String
	{
		switch (LANGUAGE)
		{
			case 'PORTUGUESE':
				return 'titlescreen3/languages/1PlayerPTBR';

			case 'ESPANOL':
				return 'titlescreen3/languages/1PlayerES';

			default:
				return 'titlescreen3/languages/1Player';
		}
	}

	function getOptionsLanguageSprite():String
	{
		switch (LANGUAGE)
		{
			case 'PORTUGUESE':
				return 'titlescreen3/languages/OptionsPTBR';

			case 'ESPANOL':
				return 'titlescreen3/languages/OptionsES';

			default:
				return 'titlescreen3/languages/Options';
		}
	}

	function setLanguage(language:String):Void
	{
		if (language != 'PORTUGUESE'
			&& language != 'ENGLISH'
			&& language != 'ESPANOL')
		{
			return;
		}

		LANGUAGE = language;

		var playerX:Float = player.x;
		var playerY:Float = player.y;
		var playerAlpha:Float = player.alpha;
		var playerVisible:Bool = player.visible;

		remove(player, true);

		player = new FlxSprite(playerX, playerY);

		player.frames = Paths.getSparrowAtlas(
			getPlayerLanguageSprite()
		);

		player.animation.addByPrefix(
			'idle',
			'1PlayerNot',
			12,
			true
		);

		player.animation.addByPrefix(
			'select',
			'1PlayerSelect',
			24,
			false
		);

		player.animation.play(
			menuSelection == 1 ? 'select' : 'idle'
		);

		player.alpha = playerAlpha;
		player.visible = playerVisible;
		player.antialiasing = false;

		add(player);

		var optionsX:Float = options.x;
		var optionsY:Float = options.y;
		var optionsAlpha:Float = options.alpha;
		var optionsVisible:Bool = options.visible;

		remove(options, true);

		options = new FlxSprite(optionsX, optionsY);

		options.frames = Paths.getSparrowAtlas(
			getOptionsLanguageSprite()
		);

		options.animation.addByPrefix(
			'idle',
			'OptionsNot',
			12,
			true
		);

		options.animation.addByPrefix(
			'select',
			'OptionsSelect',
			24,
			false
		);

		options.animation.play(
			menuSelection == 2 ? 'select' : 'idle'
		);

		options.alpha = optionsAlpha;
		options.visible = optionsVisible;
		options.antialiasing = false;

		add(options);
	}

	function createFades():Void
	{
		blueFade = new FlxSprite(0, 0);

		blueFade.makeGraphic(
			FlxG.width,
			FlxG.height,
			FlxColor.fromRGB(0, 38, 255)
		);

		blueFade.scrollFactor.set();
		blueFade.cameras = [FlxG.camera];

		add(blueFade);

		blackFade = new FlxSprite(0, 0);

		blackFade.makeGraphic(
			FlxG.width,
			FlxG.height,
			FlxColor.BLACK
		);

		blackFade.scrollFactor.set();
		blackFade.cameras = [FlxG.camera];

		add(blackFade);
	}

	function createSegaIntro():Void
	{
		segaIntro = new FlxSprite(0, 0);

		segaIntro.frames = Paths.getSparrowAtlas(
			'titlescreen3/segaIntro'
		);

		segaIntro.animation.addByPrefix(
			'intro',
			'segaIntro',
			10,
			false
		);

		segaIntro.animation.play('intro');
		segaIntro.animation.pause();
		segaIntro.antialiasing = false;

		add(segaIntro);
	}

	function setupVisibility():Void
	{
		titleBg.alpha = 0;
		title.alpha = 0;
		sonic.alpha = 0;
		player.alpha = 0;
		options.alpha = 0;
		selectedIcon.alpha = 0;
		copyright.alpha = 0;

		titleBgDay.visible = false;
		titleBgSunset.visible = false;
		titleBgDawn.visible = false;

		titleBgNightNew.visible = false;
		titleBgNightCrescent.visible = false;
		titleBgNightQuarter.visible = false;
		titleBgNight.visible = false;
		titleBgNightWaxingGibbous.visible = false;
		titleBgNightWaningGibbous.visible = false;
		titleBgNightLastQuarter.visible = false;
		titleBgNightWaningCrescent.visible = false;

		segaIntro.alpha = 1;
		blueFade.alpha = 1;
		blackFade.alpha = 1;
	}

	function setupTimeBackground():Void
	{
		var now:Date = Date.now();

		var hour:Int = now.getHours();
		var minute:Int = now.getMinutes();

		var total:Int = hour * 60 + minute;

		if (total >= 330 && total < 360)
		{
			titleBgDawn.visible = true;
		}
		else if (total >= 360 && total < 1050)
		{
			titleBgDay.visible = true;
		}
		else if (total >= 1050 && total < 1110)
		{
			titleBgSunset.visible = true;
		}
		else
		{
			setMoonBackground(getMoonBackground());
		}
	}

	function getMoonBackground():String
	{
		var now:Float = Date.now().getTime() / 1000;

		var knownNewMoon:Float = 947182440;
		var lunarCycle:Float = 29.530588853;

		var moonAge:Float =
			((now - knownNewMoon) / 86400) % lunarCycle;

		if (moonAge < 3.69 || moonAge >= 27.68)
			return 'titleBgNightNew';

		if (moonAge < 9.22)
			return 'titleBgNightQuarter';

		if (moonAge < 12.91)
			return 'titleBgNightWaxingGibbous';

		if (moonAge < 16.61)
			return 'titleBgNight';

		if (moonAge < 20.30)
			return 'titleBgNightWaningGibbous';

		if (moonAge < 23.99)
			return 'titleBgNightLastQuarter';

		return 'titleBgNightWaningCrescent';
	}

	function setMoonBackground(name:String):Void
	{
		switch (name)
		{
			case 'titleBgNightNew':
				titleBgNightNew.visible = true;

			case 'titleBgNightQuarter':
				titleBgNightQuarter.visible = true;

			case 'titleBgNightWaxingGibbous':
				titleBgNightWaxingGibbous.visible = true;

			case 'titleBgNight':
				titleBgNight.visible = true;

			case 'titleBgNightWaningGibbous':
				titleBgNightWaningGibbous.visible = true;

			case 'titleBgNightLastQuarter':
				titleBgNightLastQuarter.visible = true;

			case 'titleBgNightWaningCrescent':
				titleBgNightWaningCrescent.visible = true;

			case 'titleBgNightCrescent':
				titleBgNightCrescent.visible = true;
		}
	}

	function playSegaIntro():Void
	{
		segaIntro.animation.play('intro', true);

		FlxG.sound.playMusic(
			Paths.music('TitleScreenSonic3'),
			1,
			true
		);

		new FlxTimer().start(0.01, function(timer:FlxTimer)
		{
			checkSegaIntro();
		});
	}

	function checkSegaIntro():Void
	{
		if (segaIntro.animation.finished)
		{
			segaFinished = true;

			new FlxTimer().start(0.197, function(timer:FlxTimer)
			{
				startTitle();
			});
		}
		else
		{
			new FlxTimer().start(0.01, function(timer:FlxTimer)
			{
				checkSegaIntro();
			});
		}
	}

	function startTitle():Void
	{
		titleBg.alpha = 1;
		title.alpha = 1;
		sonic.alpha = 1;
		copyright.alpha = 1;

		segaIntro.alpha = 0;

		new FlxTimer().start(0.05, function(timer:FlxTimer)
		{
			logoIntro();
		});
	}

	function logoIntro():Void
	{
		FlxTween.tween(
			title,
			{y: 10},
			0.39,
			{
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween)
				{
					logoDrop();
				}
			}
		);
	}

	function logoDrop():Void
	{
		FlxTween.tween(
			title,
			{y: 12},
			0.12,
			{
				ease: FlxEase.quadIn,
				onComplete: function(tween:FlxTween)
				{
					logoBounce();
				}
			}
		);
	}

	function logoBounce():Void
	{
		FlxTween.tween(
			title,
			{y: 18},
			0.13,
			{
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween)
				{
					logoSettle();
				}
			}
		);
	}

	function logoSettle():Void
	{
		FlxTween.tween(
			title,
			{y: -3},
			0.15,
			{
				ease: FlxEase.quadInOut,
				onComplete: function(tween:FlxTween)
				{
					showMenu();
				}
			}
		);
	}

	function showMenu():Void
	{
		player.alpha = 1;
		options.alpha = 1;
		selectedIcon.alpha = 1;

		player.animation.play('select', true);
		options.animation.play('idle', true);

		selectedIcon.y = PLAYER_Y;

		#if android
		MobileControls.addToState(this);
		MobileControls.setEnabled(true);
		MobileControls.setVisible(true);
		#end

		new FlxTimer().start(0.05, function(timer:FlxTimer)
		{
			playFinger();
		});
	}

	function playFinger():Void
	{
		sonic.animation.play('finger', true);

		new FlxTimer().start(1.2, function(timer:FlxTimer)
		{
			playWink();
		});
	}

	function playWink():Void
	{
		sonic.animation.play('wink', false);

		new FlxTimer().start(0.1, function(timer:FlxTimer)
		{
			canPressStart = true;
		});

		new FlxTimer().start(1.3, function(timer:FlxTimer)
		{
			playFinger();
		});
	}

	function updateMenuSelection():Void
	{
		if (menuSelection == 1)
		{
			player.animation.play('select', true);
			options.animation.play('idle', true);

			selectedIcon.y = PLAYER_Y;
		}
		else
		{
			player.animation.play('idle', true);
			options.animation.play('select', true);

			selectedIcon.y = OPTIONS_Y;
		}

		FlxG.sound.play(
			Paths.sound('dataselectswitch')
		);
	}

	function changeMenuSelection(change:Int):Void
	{
		if (!canPressStart || selectedStart)
			return;

		menuSelection += change;

		if (menuSelection < 1)
			menuSelection = 2;
		else if (menuSelection > 2)
			menuSelection = 1;

		updateMenuSelection();
	}

	function selectMenu():Void
	{
		if (selectedStart || !canPressStart)
			return;

		if (menuSelection == 1)
		{
			selectedStart = true;
			canPressStart = false;

			#if android
			MobileControls.setEnabled(false);
			#end

			FlxG.sound.play(
				Paths.sound('confirmMenu')
			);

			player.animation.play('select', false);

			FlxTween.tween(
				blackFade,
				{alpha: 1},
				0.5,
				{
					ease: FlxEase.sineIn
				}
			);

			FlxTween.tween(
				blueFade,
				{alpha: 1},
				0.6,
				{
					ease: FlxEase.sineIn
				}
			);

			new FlxTimer().start(0.6, function(timer:FlxTimer)
			{
				goDataSelect();
			});
		}
		else if (menuSelection == 2)
		{
			canPressStart = false;

			#if android
			#end

			FlxG.sound.play(
				Paths.sound('confirmMenu')
			);

			MusicBeatState.switchState(
				new Sonic3Options()
			);
		}
	}

	function goDataSelect():Void
	{
		#if android
		MobileControls.removeFromState(this);
		#end

		MusicBeatState.switchState(
			new DataSelectState()
		);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if android
		MobileControls.update();
		#end

		if (!segaFinished)
			return;

		if (!canPressStart || selectedStart)
			return;

		var moveUp:Bool = false;
		var moveDown:Bool = false;
		var confirm:Bool = false;
		var back:Bool = false;

		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W)
			moveUp = true;

		if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S)
			moveDown = true;

		if (
			FlxG.keys.justPressed.ENTER
			|| FlxG.keys.justPressed.SPACE
			|| FlxG.keys.justPressed.Z
		)
		{
			confirm = true;
		}

		if (
			FlxG.keys.justPressed.ESCAPE
			|| FlxG.keys.justPressed.X
		)
		{
			back = true;
		}

		#if android
		if (MobileControls.upJustPressed)
			moveUp = true;

		if (MobileControls.downJustPressed)
			moveDown = true;

		if (MobileControls.aJustPressed)
			confirm = true;

		if (MobileControls.bJustPressed)
			back = true;
		#end

		if (moveUp)
			changeMenuSelection(-1);
		else if (moveDown)
			changeMenuSelection(1);

		if (confirm)
			selectMenu();

		if (back)
		{
			#if android
			MobileControls.setEnabled(false);
			MobileControls.removeFromState(this);
			#end
		}
	}

	override public function destroy():Void
	{
		#if android
		MobileControls.removeFromState(this);
		MobileControls.setEnabled(false);
		#end

		super.destroy();
	}
}
