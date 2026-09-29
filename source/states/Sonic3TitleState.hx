package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;

import backend.MusicBeatState;
import backend.Paths;

#if DISCORD_ALLOWED
import backend.Discord;
#end

class Sonic3TitleState extends MusicBeatState
{
	var canPressStart:Bool = false;
	var selectedStart:Bool = false;
	var segaFinished:Bool = false;

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

	function createAnimatedSprite(
		path:String,
		prefix:String,
		fps:Int,
		loop:Bool
	):FlxSprite
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

		return sprite;
	}

	function createSprites():Void
	{
		sonic = new FlxSprite(0, 2);
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
			Paths.image('titlescreen3/title')
		);
		add(title);

		copyright = new FlxSprite(0, 7);
		copyright.loadGraphic(
			Paths.image('titlescreen3/copyright')
		);
		add(copyright);

		player = new FlxSprite(108, 196);
		player.frames = Paths.getSparrowAtlas(
			'titlescreen3/1Player'
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

		player.animation.play('idle');

		add(player);
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

		add(segaIntro);
	}

	function setupVisibility():Void
	{
		titleBg.alpha = 0;
		title.alpha = 0;
		sonic.alpha = 0;
		player.alpha = 0;
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
			var moonBg:String = getMoonBackground();

			setMoonBackground(moonBg);
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
			{y: 7},
			0.15,
			{
				ease: FlxEase.quadInOut,
				onComplete: function(tween:FlxTween)
				{
					showPlayer();
				}
			}
		);
	}

	function showPlayer():Void
	{
		player.alpha = 1;
		canPressStart = true;

		player.animation.play('select');

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
		sonic.animation.play('wink', true);

		new FlxTimer().start(0.1, function(timer:FlxTimer)
		{
			playFinger();
		});
	}

	function startGame():Void
	{
		if (!canPressStart || selectedStart)
			return;

		selectedStart = true;
		canPressStart = false;

		FlxG.sound.play(
			Paths.sound('confirmMenu')
		);

		player.animation.play('select', true);

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

	function goDataSelect():Void
	{
		DiscordClient.changePresence(
			'Selecting a Save File',
		);

		MusicBeatState.switchState(
			new DataSelectState()
		);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!segaFinished)
			return;

		if (!canPressStart || selectedStart)
			return;

		if (FlxG.keys.justPressed.ENTER
			|| FlxG.keys.justPressed.SPACE
			|| FlxG.keys.justPressed.Z)
		{
			startGame();
		}
	}
}
