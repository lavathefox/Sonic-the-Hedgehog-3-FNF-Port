package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.display.BlendMode;

import backend.MusicBeatState;
import backend.ClientPrefs;
import backend.Difficulty;

@:access(states.LoadingState)
class LoadingScreen extends MusicBeatState
{
	static inline var FOLDER:String = 'loadingSprites/';
	static inline var DEFAULT_BG:String = 'loadingNORMAL';

	static var SONG_BG:Map<String, String> = [
		'uncontrolled-infinity' => 'loadingCD'
	];

	static inline var TRAVEL_ANIM:String = 'loadIdle';
	static inline var TRAVEL_FPS:Int = 24;

	static inline var UI_SCALE:Float = 1.1;

	static var UI_X:Null<Float> = null;
	static var UI_Y:Null<Float> = null;

	static var UI_OFFSET_X:Float = 0;
	static var UI_OFFSET_Y:Float = 0;

	static var TRAVEL_OFFSET_X:Float = 0;
	static var TRAVEL_OFFSET_Y:Float = -10;

	static var TRAVEL_FOLLOWS_BAR:Bool = true;
	static inline var TRAVEL_BOB:Float = 4;
	static inline var TRAVEL_BOB_SPEED:Float = 6;

	static inline var TEXT_SIZE:Int = 28;
	static var TEXT_OFFSET_X:Float = 0;
	static var TEXT_OFFSET_Y:Float = 10;
	static inline var STATUS_WIDTH_RATIO:Float = 0.75;
	static inline var MAX_STATUS_CHARS:Int = 40;
	static inline var INFO_SIZE:Int = 18;

	static inline var BG_ZOOM_BASE:Float = 1.05;
	static inline var BG_ZOOM_AMOUNT:Float = 0.02;
	static inline var BG_ZOOM_SPEED:Float = 0.4;
	static inline var BG_DRIFT:Float = 12;

	static inline var PARTICLE_COUNT:Int = 28;

	static inline var TIP_INTERVAL:Float = 4.5;
	static inline var TIP_FADE:Float = 0.3;
	static inline var TIP_SIZE:Int = 24;
	static inline var TIPS_FILE:String = 'data/loadingTips.txt';
	static var DEFAULT_TIPS:Array<String> = [
		'Hitting notes with better timing gives you a higher rating.',
		'You can tweak your scroll speed in the gameplay settings.',
		'Practice mode lets you learn a song without failing.',
		'Ghost tapping can be toggled in the options menu.',
		'Low on performance? Try disabling some visual options.',
		'Keep your combo going to boost your score.',
		'Every song has its own loading screen if you add one!'
	];

	static inline var MIN_TIME:Float = 0.6;
	static inline var END_DELAY:Float = 0.5;
	static inline var FADE_OUT_TIME:Float = 0.3;
	static inline var BAR_SPEED:Float = 10;
	static inline var FADE_IN_TIME:Float = 0.25;

	var bg:FlxSprite;
	var hud:FlxSprite;
	var progress:FlxSprite;
	var travel:FlxSprite;
	var glow:FlxSprite;
	var flash:FlxSprite;
	var particles:Array<FlxSprite> = [];

	var statusText:FlxText;
	var percentText:FlxText;
	var songText:FlxText;
	var diffText:FlxText;
	var countText:FlxText;
	var timeText:FlxText;
	var tipText:FlxText;

	var target:FlxState;
	var stopMusic:Bool;

	var timer:Float = 0;
	var minTime:Float = 0;

	var targetPercent:Float = 0;
	var shownPercent:Float = 0;
	var lastClipWidth:Float = -1;
	var lastPercentInt:Int = -1;
	var finished:Bool = false;
	var leaving:Bool = false;
	var endTimer:Float = 0;

	var songName:String;

	var bgBaseX:Float = 0;
	var bgCover:Float = 1;

	var tips:Array<String> = [];
	var tipIndex:Int = 0;
	var tipTimer:Float = 0;

	public static function go(?target:FlxState, stopMusic:Bool = false):Void
	{
		if (target == null) target = new PlayState();

		LoadingState._startPool();
		LoadingState.loadNextDirectory();

		MusicBeatState.skipLoading = true;
		MusicBeatState.switchState(new LoadingScreen(target, stopMusic));
	}

	function new(target:FlxState, stopMusic:Bool)
	{
		this.target = target;
		this.stopMusic = stopMusic;
		super();
	}

	override function create()
	{
		songName = Paths.formatToSongPath(PlayState.SONG != null ? PlayState.SONG.song : '');

		if (LoadingState.loadMax <= 0 && LoadingState.initialThreadCompleted)
			minTime = MIN_TIME;

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(0.3, 0);

		var aa:Bool = ClientPrefs.data.antialiasing;

		bg = new FlxSprite();
		if (!loadImage(bg, FOLDER + pickBackgroundKey()))
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.antialiasing = aa;

		bgCover = Math.max(FlxG.width / bg.frameWidth, FlxG.height / bg.frameHeight);
		bg.scale.set(bgCover * BG_ZOOM_BASE, bgCover * BG_ZOOM_BASE);
		bg.updateHitbox();
		bg.screenCenter();
		bgBaseX = bg.x;
		add(bg);

		var topShade:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, 180, [0xCC000000, 0x00000000]);
		topShade.scrollFactor.set();
		add(topShade);

		var bottomShade:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, 260, [0x00000000, 0xDD000000]);
		bottomShade.y = FlxG.height - bottomShade.height;
		bottomShade.scrollFactor.set();
		add(bottomShade);

		createParticles();

		hud = new FlxSprite();
		if (!loadImage(hud, FOLDER + 'loadingHUD'))
			hud.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		hud.antialiasing = aa;
		hud.scale.set(UI_SCALE, UI_SCALE);
		hud.updateHitbox();

		progress = new FlxSprite();
		if (!loadImage(progress, FOLDER + 'loadingProgress'))
			progress.makeGraphic(600, 24, 0xFFFFC800);
		progress.antialiasing = aa;
		progress.scale.set(UI_SCALE, UI_SCALE);
		progress.updateHitbox();

		hud.x = ((UI_X != null) ? UI_X : (FlxG.width - hud.width) / 2) + UI_OFFSET_X;
		hud.y = ((UI_Y != null) ? UI_Y : (FlxG.height - hud.height) / 2) + UI_OFFSET_Y;
		progress.setPosition(hud.x, hud.y);

		applyBarClip(0);
		add(progress);
		add(hud);

		glow = new FlxSprite();
		glow.loadGraphic(makeGlowGraphic());
		glow.blend = BlendMode.ADD;
		glow.scale.set(2.2, 2.2);
		glow.alpha = 0;
		glow.antialiasing = aa;
		add(glow);

		travel = new FlxSprite();
		var travelKey:String = FOLDER + 'loadingTravel';
		if (Paths.fileExists('images/$travelKey.xml', TEXT))
		{
			travel.frames = Paths.getSparrowAtlas(travelKey);
			travel.animation.addByPrefix(TRAVEL_ANIM, TRAVEL_ANIM, TRAVEL_FPS, true);
			travel.animation.play(TRAVEL_ANIM);
		}
		else if (!loadImage(travel, travelKey))
		{
			travel.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		}
		travel.antialiasing = aa;
		travel.updateHitbox();
		add(travel);
		updateTravelPosition(0);

		songText = makeText(0, 10, FlxG.width, 'Preparing: ' + (PlayState.SONG != null ? PlayState.SONG.song : '???'), 32, CENTER);
		songText.alpha = 0;
		diffText = makeText(0, 52, FlxG.width, getDifficultyLabel(), 22, CENTER);
		diffText.alpha = 0;
		diffText.color = 0xFFFFD966;

		var lineX:Float = progress.x + TEXT_OFFSET_X;
		var lineY:Float = progress.y + progress.height + TEXT_OFFSET_Y;
		var statusW:Float = progress.width * STATUS_WIDTH_RATIO;
		var percentW:Float = progress.width - statusW;

		statusText = makeText(lineX, lineY, statusW, 'Starting', TEXT_SIZE, LEFT);
		percentText = makeText(lineX + statusW, lineY, percentW, '0%', TEXT_SIZE, RIGHT);

		var infoY:Float = lineY + TEXT_SIZE + 8;
		countText = makeText(lineX, infoY, statusW, '', INFO_SIZE, LEFT);
		countText.alpha = 0.8;
		timeText = makeText(lineX + statusW, infoY, percentW, '0.0s', INFO_SIZE, RIGHT);
		timeText.alpha = 0.8;

		loadTips();
		tipText = makeText(40, FlxG.height - 70, FlxG.width - 80, tips[0], TIP_SIZE, CENTER);
		tipText.wordWrap = true;
		tipText.alpha = 0;

		add(songText);
		add(diffText);
		add(statusText);
		add(percentText);
		add(countText);
		add(timeText);
		add(tipText);

		flash = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		flash.alpha = 0;
		add(flash);

		FlxTween.tween(songText, {y: 30, alpha: 1}, 0.5, {ease: FlxEase.quartOut});
		FlxTween.tween(diffText, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.15});
		FlxTween.tween(tipText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.3});

		FlxG.camera.fade(FlxColor.BLACK, FADE_IN_TIME, true);
		super.create();
	}

	function pickBackgroundKey():String
	{
		if (SONG_BG.exists(songName))
			return SONG_BG.get(songName);

		var custom:String = 'loading_' + songName;
		if (songName.length > 0 && Paths.fileExists('images/' + FOLDER + custom + '.png', IMAGE))
			return custom;

		return DEFAULT_BG;
	}

	function getDifficultyLabel():String
	{
		var label:String = Difficulty.getString();
		return (label != null && label.length > 0) ? 'Difficulty: ' + label : '';
	}

	function loadImage(spr:FlxSprite, key:String):Bool
	{
		var graphic = Paths.image(key);
		if (graphic == null)
		{
			trace('[LoadingScreen] missing image: ' + key);
			return false;
		}
		spr.loadGraphic(graphic);
		return true;
	}

	function makeText(x:Float, y:Float, w:Float, text:String, size:Int, align:FlxTextAlign):FlxText
	{
		var t = new FlxText(x, y, w, text, size);
		t.setFormat(Paths.font('vcr.ttf'), size, FlxColor.WHITE, align, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		t.borderSize = 2;
		t.wordWrap = false;
		t.antialiasing = ClientPrefs.data.antialiasing;
		return t;
	}

	function fitStatus(s:String):String
	{
		if (s.length > MAX_STATUS_CHARS)
			return s.substr(0, MAX_STATUS_CHARS - 3) + '...';
		return s;
	}

	function makeGlowGraphic():FlxGraphic
	{
		var size:Int = 64;
		var half:Float = size / 2;
		var bmp:BitmapData = new BitmapData(size, size, true, 0x00000000);
		for (px in 0...size)
		{
			for (py in 0...size)
			{
				var dx:Float = px - half;
				var dy:Float = py - half;
				var d:Float = Math.sqrt(dx * dx + dy * dy) / half;
				var a:Float = Math.max(0, 1 - d);
				a = a * a;
				bmp.setPixel32(px, py, FlxColor.fromRGBFloat(1, 0.85, 0.4, a));
			}
		}
		return FlxGraphic.fromBitmapData(bmp);
	}

	function createParticles():Void
	{
		for (i in 0...PARTICLE_COUNT)
		{
			var size:Int = FlxG.random.int(2, 5);
			var p:FlxSprite = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			p.makeGraphic(size, size, FlxColor.WHITE);
			p.alpha = FlxG.random.float(0.1, 0.4);
			p.velocity.set(FlxG.random.float(-8, 8), -FlxG.random.float(15, 45));
			p.blend = BlendMode.ADD;
			particles.push(p);
			add(p);
		}
	}

	function updateParticles():Void
	{
		for (p in particles)
		{
			if (p.y < -p.height)
			{
				p.y = FlxG.height + FlxG.random.float(0, 40);
				p.x = FlxG.random.float(0, FlxG.width);
			}
			if (p.x < -p.width) p.x = FlxG.width;
			else if (p.x > FlxG.width) p.x = -p.width;
		}
	}

	function loadTips():Void
	{
		if (Paths.fileExists(TIPS_FILE, TEXT))
		{
			var raw:String = Paths.getTextFromFile(TIPS_FILE);
			if (raw != null)
			{
				for (line in raw.split('\n'))
				{
					var clean:String = StringTools.trim(line);
					if (clean.length > 0) tips.push(clean);
				}
			}
		}

		if (tips.length == 0)
			tips = DEFAULT_TIPS.copy();

		FlxG.random.shuffle(tips);
	}

	function nextTip():Void
	{
		if (tips.length <= 1) return;

		FlxTween.cancelTweensOf(tipText);
		FlxTween.tween(tipText, {alpha: 0}, TIP_FADE, {
			ease: FlxEase.quadIn,
			onComplete: function(_)
			{
				tipIndex = (tipIndex + 1) % tips.length;
				tipText.text = tips[tipIndex];
				FlxTween.tween(tipText, {alpha: 1}, TIP_FADE, {ease: FlxEase.quadOut});
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var dt:Float = Math.min(elapsed, 0.1);

		if (!finished)
		{
			timer += elapsed;

			var loadedAll:Bool = LoadingState.checkLoaded();

			if (LoadingState.loadMax > 0)
				targetPercent = Math.min(LoadingState.loaded / LoadingState.loadMax, 1);
			else if (minTime > 0)
				targetPercent = Math.min(timer / minTime, 1);

			var task:String = LoadingState.currentTask;
			var dots:String = ''.lpad('.', Math.floor(timer * 3) % 4);
			statusText.text = (task != null && task.length > 0) ? fitStatus('Loading ' + task) + dots : 'Preparing' + dots;

			countText.text = (LoadingState.loadMax > 0) ? 'Files: ' + LoadingState.loaded + ' / ' + LoadingState.loadMax : '';
			timeText.text = FlxMath.roundDecimal(timer, 1) + 's';

			if (loadedAll && timer >= minTime)
			{
				finished = true;
				targetPercent = 1;
			}
		}

		shownPercent = FlxMath.lerp(shownPercent, targetPercent, 1 - Math.exp(-dt * BAR_SPEED));
		if (Math.abs(shownPercent - targetPercent) < 0.002) shownPercent = targetPercent;

		applyBarClip(shownPercent);
		updateTravelPosition(shownPercent);
		updateGlow();
		updateBackground();
		updateParticles();
		updatePercentText(dt);

		tipTimer += dt;
		if (tipTimer >= TIP_INTERVAL && !leaving)
		{
			tipTimer = 0;
			nextTip();
		}

		if (finished && shownPercent >= 1 && !leaving)
		{
			statusText.text = 'Done!';
			endTimer += elapsed;
			if (endTimer >= END_DELAY)
			{
				leaving = true;
				finishAndLeave();
			}
		}
	}

	function updateBackground():Void
	{
		var z:Float = BG_ZOOM_BASE + Math.sin(timer * BG_ZOOM_SPEED) * BG_ZOOM_AMOUNT;
		bg.scale.set(bgCover * z, bgCover * z);
		bg.x = bgBaseX + Math.sin(timer * BG_ZOOM_SPEED * 0.75) * BG_DRIFT;
	}

	function updatePercentText(dt:Float):Void
	{
		var pct:Int = Math.floor(shownPercent * 100);
		if (pct != lastPercentInt)
		{
			lastPercentInt = pct;
			percentText.text = pct + '%';
			percentText.scale.set(1.18, 1.18);
		}

		var s:Float = FlxMath.lerp(percentText.scale.x, 1, 1 - Math.exp(-dt * 14));
		percentText.scale.set(s, s);
	}

	function updateGlow():Void
	{
		var visible:Bool = shownPercent > 0.01 && shownPercent < 0.999;
		var pulse:Float = 0.55 + Math.sin(timer * 7) * 0.2;
		glow.alpha = FlxMath.lerp(glow.alpha, visible ? pulse : 0, 0.2);
		glow.x = progress.x + progress.width * shownPercent - glow.width / 2;
		glow.y = progress.y + progress.height / 2 - glow.height / 2;
	}

	function finishAndLeave():Void
	{
		flash.alpha = 0.35;
		FlxTween.tween(flash, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
		FlxTween.tween(travel, {alpha: 0}, 0.25);
		FlxTween.tween(glow, {alpha: 0}, 0.25);

		FlxG.camera.fade(FlxColor.BLACK, FADE_OUT_TIME, false, function() goToTarget());
	}

	function goToTarget():Void
	{
		LoadingState._loaded();

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.camera.visible = false;
		MusicBeatState.skipLoading = true;
		MusicBeatState.switchState(target);
	}

	function applyBarClip(pct:Float):Void
	{
		var w:Float = progress.frameWidth * pct;
		if (w == lastClipWidth) return;
		lastClipWidth = w;
		progress.clipRect = new FlxRect(0, 0, w, progress.frameHeight);
	}

	function updateTravelPosition(pct:Float):Void
	{
		var bx:Float = progress.x;
		if (TRAVEL_FOLLOWS_BAR)
			bx += progress.width * pct;

		var bob:Float = (TRAVEL_BOB > 0) ? Math.sin(timer * TRAVEL_BOB_SPEED) * TRAVEL_BOB : 0;
		travel.x = bx - travel.width / 2 + TRAVEL_OFFSET_X;
		travel.y = progress.y - travel.height + TRAVEL_OFFSET_Y + progress.height + bob;
	}

	override function destroy()
	{
		FlxTween.cancelTweensOf(songText);
		FlxTween.cancelTweensOf(diffText);
		FlxTween.cancelTweensOf(tipText);
		FlxTween.cancelTweensOf(flash);
		FlxTween.cancelTweensOf(travel);
		FlxTween.cancelTweensOf(glow);
		super.destroy();
	}
}
