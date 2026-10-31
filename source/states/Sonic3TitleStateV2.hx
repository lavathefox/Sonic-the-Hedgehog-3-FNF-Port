package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;

import backend.ClientPrefs;
import backend.MusicBeatState;
import backend.Paths;
import backend.MobileControls;

import options.Sonic3Options;

#if DISCORD_ALLOWED
import backend.Discord;
#end

class Sonic3TitleStateV2 extends MusicBeatState
{
	// Current language: 'ENGLISH', 'PORTUGUESE' or 'ESPANOL'. Read from the saved options in create().
	var LANGUAGE:String = 'ENGLISH';

	var canPressStart:Bool = false;
	var selectedStart:Bool = false;
	var segaFinished:Bool = false;

	var menuSelection:Int = 1;

	var PLAYER_Y:Float = 196;
	var OPTIONS_Y:Float = 206;

	// ---- Time of day (minutes since midnight) ----
	static inline var DAWN_START:Int = 330; // 05:30
	static inline var DAY_START:Int = 360; // 06:00
	static inline var SUNSET_START:Int = 1050; // 17:30
	static inline var NIGHT_START:Int = 1110; // 18:30

	// The base layer is always drawn; the others are shown one at a time depending on the time.
	var titleBg:FlxSprite;
	var titleBgDay:FlxSprite;
	var titleBgSunset:FlxSprite;
	var titleBgNight:FlxSprite; // full moon
	var titleBgDawn:FlxSprite;

	// Night backgrounds by moon phase, found by name (see getMoonBackground).
	var moonBackgrounds:Map<String, FlxSprite> = new Map();

	var sonic:FlxSprite;
	var title:FlxSprite;
	var copyright:FlxSprite;

	var player:FlxSprite;
	var options:FlxSprite;
	var selectedIcon:FlxSprite;

	var blueFade:FlxSprite;
	var blackFade:FlxSprite;

	var segaIntro:FlxSprite;

	// ---- Logo drop (tweak these numbers to change the animation) ----
	// Positions are in game pixels; the screen is 320x224.
	static inline var LOGO_APEX_Y:Float = -27; // highest point, reached at the end of the entrance
	static inline var LOGO_REST_Y:Float = -3; // where the logo comes to rest
	static inline var LOGO_GRAVITY:Float = 0.21875; // pixels per frame squared, like a 60 Hz console
	static inline var LOGO_BOUNCE_DAMPING:Float = 0.45; // speed kept after each bounce (0 = no bounce)
	static inline var LOGO_MIN_BOUNCE_SPEED:Float = 0.5; // below this speed the logo stops bouncing
	static inline var LOGO_STEP:Float = 1 / 60; // the drop is simulated in 60 Hz steps
	static inline var LOGO_MAX_ELAPSED:Float = 0.1; // a long frame never makes the drop run too many steps

	var logoFalling:Bool = false;
	var logoY:Float = 0;
	var logoVelocity:Float = 0;
	var logoStepTimer:Float = 0;

	override public function create():Void
	{
		super.create();

		LANGUAGE = getCurrentLanguage();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(
			tr('In the Title Screen', 'Na Tela de Título', 'En la Pantalla de Título'),
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

		FlxG.sound.play(Paths.sound('segaOpening'));

		#if android
		MobileControls.create();
		MobileControls.setEnabled(false);
		MobileControls.setVisible(false);
		#end

		FlxTween.tween(blueFade, {alpha: 0}, 0.6, {ease: FlxEase.sineOut});
		FlxTween.tween(blackFade, {alpha: 0}, 0.5, {ease: FlxEase.sineOut});

		new FlxTimer().start(2.9, function(timer:FlxTimer)
		{
			playSegaIntro();
		});
	}

	// ---- Language ----

	function getCurrentLanguage():String
	{
		var language:String = StringTools.trim(Std.string(ClientPrefs.data.language).toUpperCase());

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

	/** Picks the text for the current language. */
	function tr(en:String, pt:String, es:String):String
	{
		switch (LANGUAGE)
		{
			case 'PORTUGUESE':
				return pt;

			case 'ESPANOL':
				return es;

			default:
				return en;
		}
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

	/** Changes the language while the title is open (for example if a language menu is added here later). */
	public function setLanguage(language:String):Void
	{
		if (language != 'PORTUGUESE' && language != 'ENGLISH' && language != 'ESPANOL')
			return;

		LANGUAGE = language;

		var newPlayer:FlxSprite = createMenuSprite(player.x, player.y, getPlayerLanguageSprite(), '1PlayerNot', '1PlayerSelect');
		newPlayer.animation.play(menuSelection == 1 ? 'select' : 'idle');
		replaceMenuSprite(player, newPlayer);
		player = newPlayer;

		var newOptions:FlxSprite = createMenuSprite(options.x, options.y, getOptionsLanguageSprite(), 'OptionsNot', 'OptionsSelect');
		newOptions.animation.play(menuSelection == 2 ? 'select' : 'idle');
		replaceMenuSprite(options, newOptions);
		options = newOptions;
	}

	// ---- Sprites ----

	function addBackground(path:String, prefix:String):FlxSprite
	{
		var sprite:FlxSprite = createAnimatedSprite(path, prefix, 12, true);
		sprite.visible = false;
		add(sprite);
		return sprite;
	}

	function addMoonBackground(name:String, prefix:String):FlxSprite
	{
		var sprite:FlxSprite = addBackground('titlescreen3/' + name, prefix);
		moonBackgrounds.set(name, sprite);
		return sprite;
	}

	function createBackgrounds():Void
	{
		// The order matters: later sprites are drawn on top of earlier ones.
		titleBg = addBackground('titlescreen3/titleBg', 'titleIdle');
		titleBg.visible = true;

		titleBgDay = addBackground('titlescreen3/titleBg', 'titleIdle');
		titleBgSunset = addBackground('titlescreen3/titleBgSunset', 'titleIdle');
		titleBgNight = addMoonBackground('titleBgNight', 'titleIdle');
		titleBgDawn = addBackground('titlescreen3/titleBgDawn', 'titleIdle');

		addMoonBackground('titleBgNightNew', 'titleBg');
		addMoonBackground('titleBgNightCrescent', 'titleBg');
		addMoonBackground('titleBgNightQuarter', 'titleBg');
		addMoonBackground('titleBgNightWaxingGibbous', 'titleIdle');
		addMoonBackground('titleBgNightLastQuarter', 'titleIdle');
		addMoonBackground('titleBgNightWaningCrescent', 'titleIdle');
		addMoonBackground('titleBgNightWaningGibbous', 'titleIdle');
	}

	function createAnimatedSprite(path:String, prefix:String, fps:Int, loop:Bool):FlxSprite
	{
		var sprite:FlxSprite = new FlxSprite(0, 0);

		sprite.frames = Paths.getSparrowAtlas(path);
		sprite.animation.addByPrefix('idle', prefix, fps, loop);
		sprite.animation.play('idle');
		sprite.antialiasing = false;

		return sprite;
	}

	function createSprites():Void
	{
		sonic = new FlxSprite(0, -7);
		sonic.frames = Paths.getSparrowAtlas('titlescreen3/sonicTitleScreen');
		sonic.animation.addByPrefix('finger', 'sonicFinger', 12, true);
		sonic.animation.addByPrefix('wink', 'sonicWink', 12, false);
		sonic.animation.play('finger');
		add(sonic);

		title = new FlxSprite(0, 260);
		title.loadGraphic(Paths.image('titlescreen3/FNFPortTitle'));
		title.antialiasing = false;
		add(title);

		copyright = new FlxSprite(0, 7);
		copyright.loadGraphic(Paths.image('titlescreen3/copyright'));
		copyright.antialiasing = false;
		add(copyright);

		selectedIcon = new FlxSprite(80, PLAYER_Y);
		selectedIcon.loadGraphic(Paths.image('titlescreen3/selectedIcon'));
		selectedIcon.antialiasing = false;
		add(selectedIcon);

		createPlayerSprite();
		createOptionsSprite();
	}

	/** A menu entry ("1 PLAYER" / "OPTIONS") with an idle and a select animation. */
	function createMenuSprite(x:Float, y:Float, path:String, idlePrefix:String, selectPrefix:String):FlxSprite
	{
		var sprite:FlxSprite = new FlxSprite(x, y);

		sprite.frames = Paths.getSparrowAtlas(path);
		sprite.animation.addByPrefix('idle', idlePrefix, 12, true);
		sprite.animation.addByPrefix('select', selectPrefix, 24, false);
		sprite.antialiasing = false;

		return sprite;
	}

	/** Puts the new sprite where the old one was in the draw order, so it never ends up above the fades. */
	function replaceMenuSprite(oldSprite:FlxSprite, newSprite:FlxSprite):Void
	{
		newSprite.alpha = oldSprite.alpha;
		newSprite.visible = oldSprite.visible;

		var index:Int = members.indexOf(oldSprite);

		if (index >= 0)
			insert(index, newSprite);
		else
			add(newSprite);

		remove(oldSprite, true);
		oldSprite.destroy();
	}

	function createPlayerSprite():Void
	{
		player = createMenuSprite(108, PLAYER_Y, getPlayerLanguageSprite(), '1PlayerNot', '1PlayerSelect');
		player.animation.play('select');
		add(player);
	}

	function createOptionsSprite():Void
	{
		options = createMenuSprite(108, OPTIONS_Y, getOptionsLanguageSprite(), 'OptionsNot', 'OptionsSelect');
		options.animation.play('idle');
		add(options);
	}

	function createFades():Void
	{
		blueFade = new FlxSprite(0, 0);
		blueFade.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 38, 255));
		blueFade.scrollFactor.set();
		blueFade.cameras = [FlxG.camera];
		add(blueFade);

		blackFade = new FlxSprite(0, 0);
		blackFade.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackFade.scrollFactor.set();
		blackFade.cameras = [FlxG.camera];
		add(blackFade);
	}

	function createSegaIntro():Void
	{
		segaIntro = new FlxSprite(0, 0);
		segaIntro.frames = Paths.getSparrowAtlas('titlescreen3/segaIntro');
		segaIntro.animation.addByPrefix('intro', 'segaIntro', 10, false);
		segaIntro.animation.play('intro');
		segaIntro.animation.pause();
		segaIntro.antialiasing = false;
		add(segaIntro);
	}

	function setupVisibility():Void
	{
		// Every background except the base layer starts hidden (see addBackground).
		titleBg.alpha = 0;
		title.alpha = 0;
		sonic.alpha = 0;
		player.alpha = 0;
		options.alpha = 0;
		selectedIcon.alpha = 0;
		copyright.alpha = 0;

		segaIntro.alpha = 1;
		blueFade.alpha = 1;
		blackFade.alpha = 1;
	}

	// ---- Background by time of day ----

	function setupTimeBackground():Void
	{
		var now:Date = Date.now();
		var total:Int = now.getHours() * 60 + now.getMinutes();

		if (total >= DAWN_START && total < DAY_START)
			titleBgDawn.visible = true;
		else if (total >= DAY_START && total < SUNSET_START)
			titleBgDay.visible = true;
		else if (total >= SUNSET_START && total < NIGHT_START)
			titleBgSunset.visible = true;
		else
			setMoonBackground(getMoonBackground());
	}

	/** The 8 moon phases, from the age of the moon in days (0 = new moon, about 14.8 = full moon). */
	function getMoonBackground():String
	{
		var now:Float = Date.now().getTime() / 1000;

		var knownNewMoon:Float = 947182440;
		var lunarCycle:Float = 29.530588853;

		var moonAge:Float = ((now - knownNewMoon) / 86400) % lunarCycle;

		if (moonAge < 1.85 || moonAge >= 27.68)
			return 'titleBgNightNew';

		if (moonAge < 7.38)
			return 'titleBgNightCrescent';

		if (moonAge < 11.07)
			return 'titleBgNightQuarter';

		if (moonAge < 14.77)
			return 'titleBgNightWaxingGibbous';

		if (moonAge < 18.46)
			return 'titleBgNight';

		if (moonAge < 22.15)
			return 'titleBgNightWaningGibbous';

		if (moonAge < 25.84)
			return 'titleBgNightLastQuarter';

		return 'titleBgNightWaningCrescent';
	}

	function setMoonBackground(name:String):Void
	{
		var background:FlxSprite = moonBackgrounds.get(name);

		if (background != null)
			background.visible = true;
	}

	// ---- Intro ----

	function playSegaIntro():Void
	{
		// Starts the title when the SEGA animation ends.
		segaIntro.animation.finishCallback = function(name:String)
		{
			segaIntro.animation.finishCallback = null;
			segaFinished = true;

			new FlxTimer().start(0.197, function(timer:FlxTimer)
			{
				startTitle();
			});
		};

		segaIntro.animation.play('intro', true);

		FlxG.sound.playMusic(Paths.music('TitleScreenSonic3'), 1, true);
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
		// The logo flies up from below the screen and slows down until it reaches its highest point.
		FlxTween.tween(title, {y: LOGO_APEX_Y}, 0.39, {
			ease: FlxEase.quadOut,
			onUpdate: function(tween:FlxTween)
			{
				// Move in whole pixels, like the original hardware.
				title.y = Math.round(title.y);
			},
			onComplete: function(tween:FlxTween)
			{
				logoDrop();
			}
		});
	}

	function logoDrop():Void
	{
		// From here the logo falls with gravity, hits its resting place and bounces a couple of times.
		// The movement itself is done by stepLogoDrop(), called from update() in 60 Hz steps.
		logoY = title.y;
		logoVelocity = 0;
		logoStepTimer = 0;
		logoFalling = true;
	}

	function stepLogoDrop():Void
	{
		logoVelocity += LOGO_GRAVITY;
		logoY += logoVelocity;

		if (logoY >= LOGO_REST_Y)
		{
			logoY = LOGO_REST_Y;
			logoVelocity = -logoVelocity * LOGO_BOUNCE_DAMPING;

			if (-logoVelocity < LOGO_MIN_BOUNCE_SPEED)
			{
				// Too slow to bounce again: the logo is at rest.
				logoFalling = false;
				title.y = LOGO_REST_Y;
				showMenu();
				return;
			}
		}

		title.y = Math.round(logoY);
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
			// Once the player has picked "1 PLAYER" the menu stays locked.
			if (!selectedStart)
				canPressStart = true;
		});

		new FlxTimer().start(1.3, function(timer:FlxTimer)
		{
			playFinger();
		});
	}

	// ---- Menu ----

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

		FlxG.sound.play(Paths.sound('dataselectswitch'));
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

			FlxG.sound.play(Paths.sound('confirmMenu'));

			player.animation.play('select', false);

			FlxTween.tween(blackFade, {alpha: 1}, 0.5, {ease: FlxEase.sineIn});
			FlxTween.tween(blueFade, {alpha: 1}, 0.6, {ease: FlxEase.sineIn});

			new FlxTimer().start(0.6, function(timer:FlxTimer)
			{
				goDataSelect();
			});
		}
		else if (menuSelection == 2)
		{
			canPressStart = false;

			FlxG.sound.play(Paths.sound('confirmMenu'));

			MusicBeatState.switchState(new Sonic3Options());
		}
	}

	function goDataSelect():Void
	{
		#if android
		if (MobileControls.isAttachedTo(this))
			MobileControls.removeFromState(this);
		#end

		MusicBeatState.switchState(new DataSelectState());
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Logo drop: simulated in fixed 60 Hz steps so it looks the same at any frame rate.
		if (logoFalling)
		{
			logoStepTimer += Math.min(elapsed, LOGO_MAX_ELAPSED);

			while (logoFalling && logoStepTimer >= LOGO_STEP)
			{
				logoStepTimer -= LOGO_STEP;
				stepLogoDrop();
			}
		}

		#if android
		MobileControls.update();
		#end

		if (!segaFinished)
			return;

		if (!canPressStart || selectedStart)
			return;

		var moveUp:Bool = FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W;
		var moveDown:Bool = FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S;
		var confirm:Bool = FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z;

		#if android
		moveUp = moveUp || MobileControls.upJustPressed;
		moveDown = moveDown || MobileControls.downJustPressed;
		confirm = confirm || MobileControls.aJustPressed;
		#end

		if (moveUp)
			changeMenuSelection(-1);
		else if (moveDown)
			changeMenuSelection(1);

		if (confirm)
			selectMenu();
	}

	override public function destroy():Void
	{
		#if android
		if (MobileControls.isAttachedTo(this))
			MobileControls.removeFromState(this);
		#end

		moonBackgrounds.clear();

		super.destroy();
	}
}
