package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;

import backend.MusicBeatState;
import backend.ClientPrefs;

/**
 * LoadingScreen (Psych Engine 1.0.4)
 *
 * Custom look for the song loading. The real loading work is still done by
 * LoadingState (threads + cache), this state only shows its progress.
 *
 * Sprites in  mods/<your mod>/images/loadingSprites/  (or assets/shared/images/loadingSprites/)
 *   - loadingNORMAL   -> background for any song
 *   - loadingCD       -> background for the "uncontrolled-infinity" song
 *   - loadingHUD      -> frame / HUD on top of the background
 *   - loadingProgress -> progress bar (revealed according to the loaded %)
 *   - loadingTravel   -> animated sprite ("loadIdle" animation) that travels along the bar
 *                        (needs loadingTravel.xml with the "loadIdle" prefix)
 *
 * The HUD and the progress bar share the same x/y and the same scale (they sit on top of each other).
 * The status text (left) and the percentage (right) share the same line, right below the bar.
 * If a sprite is missing, a simple placeholder is used so the screen never crashes.
 *
 * Usage:
 *     LoadingState.prepareToSong();                       // starts the real preloading (optional)
 *     LoadingState.loadAndSwitchState(new PlayState());   // redirects to this screen
 */
@:access(states.LoadingState)
class LoadingScreen extends MusicBeatState
{
	// ================= CONFIGURATION (adjust to your sprites) =================
	static inline var FOLDER:String = 'loadingSprites/';
	static inline var CD_SONG:String = 'uncontrolled-infinity';

	static inline var TRAVEL_ANIM:String = 'loadIdle';
	static inline var TRAVEL_FPS:Int = 24;

	// scale applied to BOTH the HUD and the progress bar (1 = original size)
	static inline var UI_SCALE:Float = 1.1;
	// position of the HUD + progress bar, top-left corner (null = centered on the screen)
	static var UI_X:Null<Float> = null;
	static var UI_Y:Null<Float> = null;
	// fine offset applied to both (moves the HUD and the bar together)
	static var UI_OFFSET_X:Float = 0;
	static var UI_OFFSET_Y:Float = 0;

	// fine offset of the travelling sprite (relative to the top of the bar)
	static var TRAVEL_OFFSET_X:Float = 0;
	static var TRAVEL_OFFSET_Y:Float = -10;
	// true = travel sprite moves along with the bar; false = stays still
	static var TRAVEL_FOLLOWS_BAR:Bool = true;

	// text line (status on the left, percentage on the right), placed right below the bar
	static inline var TEXT_SIZE:Int = 28;
	static var TEXT_OFFSET_X:Float = 0; // moves the whole line horizontally
	static var TEXT_OFFSET_Y:Float = 10; // distance from the bottom of the bar
	static inline var STATUS_WIDTH_RATIO:Float = 0.75; // part of the bar width used by the status text
	static inline var MAX_STATUS_CHARS:Int = 40; // longer task names are cut with "..."

	static inline var MIN_TIME:Float = 0.6; // minimum time when there is nothing to load
	static inline var END_DELAY:Float = 0.5;
	static inline var BAR_SPEED:Float = 10; // higher = the bar catches up faster
	static inline var FADE_IN_TIME:Float = 0.25;
	// =========================================================================

	var bg:FlxSprite;
	var hud:FlxSprite;
	var progress:FlxSprite;
	var travel:FlxSprite;

	var statusText:FlxText;
	var percentText:FlxText;
	var songText:FlxText;

	var target:FlxState;
	var stopMusic:Bool;

	var timer:Float = 0;
	var minTime:Float = 0;

	var targetPercent:Float = 0;
	var shownPercent:Float = 0;
	var lastClipWidth:Float = -1;
	var finished:Bool = false;
	var leaving:Bool = false;
	var endTimer:Float = 0;

	var songName:String;

	public static function go(?target:FlxState, stopMusic:Bool = false):Void
	{
		if (target == null) target = new PlayState();

		// same preparation that LoadingState.getNextState does
		LoadingState._startPool();
		LoadingState.loadNextDirectory();

		MusicBeatState.skipLoading = true; // avoids MusicBeatState sending us back here (infinite loop)
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

		// nothing to load: show the screen for a short time anyway
		if (LoadingState.loadMax <= 0 && LoadingState.initialThreadCompleted)
			minTime = MIN_TIME;

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(0.3, 0);

		var aa:Bool = ClientPrefs.data.antialiasing;

		// ---------- background ----------
		var bgKey:String = (songName == CD_SONG) ? 'loadingCD' : 'loadingNORMAL';
		bg = new FlxSprite();
		if (!loadImage(bg, FOLDER + bgKey))
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.antialiasing = aa;
		// scale so the image always covers the whole screen
		var coverScale:Float = Math.max(FlxG.width / bg.frameWidth, FlxG.height / bg.frameHeight);
		bg.scale.set(coverScale, coverScale);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		// ---------- HUD + progress bar (same scale, same x/y) ----------
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

		// one shared position for both sprites
		hud.x = ((UI_X != null) ? UI_X : (FlxG.width - hud.width) / 2) + UI_OFFSET_X;
		hud.y = ((UI_Y != null) ? UI_Y : (FlxG.height - hud.height) / 2) + UI_OFFSET_Y;
		progress.setPosition(hud.x, hud.y);

		applyBarClip(0);
		add(progress); // bar first, HUD on top of it
		add(hud);

		// ---------- animated sprite ----------
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
			// no atlas and no image: invisible placeholder
			travel.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		}
		travel.antialiasing = aa;
		travel.updateHitbox();
		add(travel);
		updateTravelPosition(0);

		// ---------- texts ----------
		songText = makeText(0, 30, FlxG.width, 'Preparing: ' + (PlayState.SONG != null ? PlayState.SONG.song : '???'), 32, CENTER);

		// status (left) and percentage (right) on the SAME line, aligned with the edges of the bar
		var lineX:Float = progress.x + TEXT_OFFSET_X;
		var lineY:Float = progress.y + progress.height + TEXT_OFFSET_Y;
		var statusW:Float = progress.width * STATUS_WIDTH_RATIO;
		var percentW:Float = progress.width - statusW;

		statusText = makeText(lineX, lineY, statusW, 'Starting...', TEXT_SIZE, LEFT);
		percentText = makeText(lineX + statusW, lineY, percentW, '0%', TEXT_SIZE, RIGHT);

		add(songText);
		add(statusText);
		add(percentText);

		FlxG.camera.fade(FlxColor.BLACK, FADE_IN_TIME, true);
		super.create();
	}

	// loads an image into a sprite; returns false if the file does not exist
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
		t.wordWrap = false; // never break the text into a second line
		t.antialiasing = ClientPrefs.data.antialiasing;
		return t;
	}

	// cuts long names so the status text never runs into the percentage
	function fitStatus(s:String):String
	{
		if (s.length > MAX_STATUS_CHARS)
			return s.substr(0, MAX_STATUS_CHARS - 3) + '...';
		return s;
	}

	// ============================== UPDATE ==============================
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!finished)
		{
			timer += elapsed;

			// must be called every frame: it also moves the finished bitmaps into the cache (main thread only)
			var loadedAll:Bool = LoadingState.checkLoaded();

			if (LoadingState.loadMax > 0)
				targetPercent = Math.min(LoadingState.loaded / LoadingState.loadMax, 1);
			else if (minTime > 0)
				targetPercent = Math.min(timer / minTime, 1);

			var task:String = LoadingState.currentTask;
			statusText.text = (task != null && task.length > 0) ? fitStatus('Loading ' + task + '...') : 'Preparing...';

			if (loadedAll && timer >= minTime)
			{
				finished = true;
				targetPercent = 1;
			}
		}

		// smooth the bar (same speed on any frame rate)
		shownPercent = FlxMath.lerp(shownPercent, targetPercent, 1 - Math.exp(-elapsed * BAR_SPEED));
		if (Math.abs(shownPercent - targetPercent) < 0.002) shownPercent = targetPercent;

		applyBarClip(shownPercent);
		updateTravelPosition(shownPercent);
		percentText.text = Math.floor(shownPercent * 100) + '%';

		if (finished && shownPercent >= 1 && !leaving)
		{
			statusText.text = 'Done!';
			endTimer += elapsed;
			if (endTimer >= END_DELAY)
			{
				leaving = true;
				goToTarget();
			}
		}
	}

	// same ending as LoadingState.onLoad
	function goToTarget():Void
	{
		LoadingState._loaded();

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.camera.visible = false;
		MusicBeatState.skipLoading = true; // go straight to the target (no loop)
		MusicBeatState.switchState(target);
	}

	// only creates a new clip rect when the width really changed
	// (clipRect uses the original frame size, so the scale does not affect it)
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
		travel.x = bx - travel.width / 2 + TRAVEL_OFFSET_X;
		travel.y = progress.y - travel.height + TRAVEL_OFFSET_Y + progress.height;
	}
}
