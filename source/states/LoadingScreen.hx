package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;

import haxe.Json;
import openfl.utils.Assets;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

import backend.MusicBeatState;
import backend.ClientPrefs;
import backend.StageData;
import objects.Character;

/**
 * One step of the loading process.
 * weight = how "heavy" the step is (heavier steps move the bar more).
 */
typedef LoadTask =
{
	var label:String;
	var run:Void->Void;
	var weight:Float;
}

/**
 * LoadingScreen (Psych Engine 1.0.4)
 *
 * Sprites in  mods/<your mod>/images/loadingSprites/  (or assets/shared/images/loadingSprites/)
 *   - loadingNORMAL   -> background for any song
 *   - loadingCD       -> background for the "uncontrolled-infinity" song
 *   - loadingHUD      -> frame / HUD on top of the background
 *   - loadingProgress -> progress bar (revealed according to the loaded %)
 *   - loadingTravel   -> animated sprite ("loadIdle" animation) that travels along the bar
 *                        (needs loadingTravel.xml with the "loadIdle" prefix)
 *
 * If a sprite is missing, a simple placeholder is used so the screen never crashes.
 *
 * Usage (instead of LoadingState.loadAndSwitchState(new PlayState())):
 *     // after PlayState.SONG = Song.loadFromJson(...)
 *     LoadingScreen.go();
 */
class LoadingScreen extends MusicBeatState
{
	// ================= CONFIGURATION (adjust to your sprites) =================
	static inline var FOLDER:String = 'loadingSprites/';
	static inline var CD_SONG:String = 'uncontrolled-infinity';

	static inline var TRAVEL_ANIM:String = 'loadIdle';
	static inline var TRAVEL_FPS:Int = 24;

	// progress bar position (null = centered at the bottom)
	static var PROGRESS_X:Null<Float> = null;
	static var PROGRESS_Y:Null<Float> = null;
	// fine offset of the travelling sprite (relative to the top of the bar)
	static var TRAVEL_OFFSET_X:Float = 0;
	static var TRAVEL_OFFSET_Y:Float = -10;
	// true = travel sprite moves along with the bar; false = stays still
	static var TRAVEL_FOLLOWS_BAR:Bool = true;

	// distance of the percentage text from the bottom of the bar
	static inline var PERCENT_OFFSET_Y:Float = 10;

	static inline var MIN_TIME_PER_TASK:Float = 0.05; // gives time to read the text
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

	var tasks:Array<LoadTask> = [];
	var taskIndex:Int = 0;
	var taskTimer:Float = 0;
	var labelShown:Bool = false; // true = label already drawn, task runs on the next tick

	var totalWeight:Float = 0;
	var doneWeight:Float = 0;
	var errorCount:Int = 0;

	var targetPercent:Float = 0;
	var shownPercent:Float = 0;
	var lastClipWidth:Float = -1;
	var finished:Bool = false;
	var leaving:Bool = false;
	var endTimer:Float = 0;

	var songName:String;

	public static function go():Void
	{
		MusicBeatState.skipLoading = true; // avoids MusicBeatState sending us back here (infinite loop)
		MusicBeatState.switchState(new LoadingScreen());
	}

	override function create()
	{
		songName = Paths.formatToSongPath(PlayState.SONG != null ? PlayState.SONG.song : '');

		if (FlxG.sound.music != null)
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

		// ---------- progress bar ----------
		progress = new FlxSprite();
		if (!loadImage(progress, FOLDER + 'loadingProgress'))
			progress.makeGraphic(600, 24, 0xFFFFC800);
		progress.antialiasing = aa;
		progress.x = (PROGRESS_X != null) ? PROGRESS_X : (FlxG.width - progress.width) / 2;
		progress.y = (PROGRESS_Y != null) ? PROGRESS_Y : FlxG.height - progress.height - 60;
		applyBarClip(0);
		add(progress);

		// ---------- HUD (on top of the bar) ----------
		hud = new FlxSprite();
		if (!loadImage(hud, FOLDER + 'loadingHUD'))
			hud.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		hud.antialiasing = aa;
		hud.screenCenter();
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
		statusText = makeText(progress.x, progress.y - 40, progress.width, 'Starting...', 24, LEFT);
		// big percentage, centered right below the bar
		percentText = makeText(0, progress.y + progress.height + PERCENT_OFFSET_Y, FlxG.width, 'Loading... 0%', 40, CENTER);
		add(songText);
		add(statusText);
		add(percentText);

		buildTasks();

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
		t.antialiasing = ClientPrefs.data.antialiasing;
		return t;
	}

	function addTask(label:String, weight:Float, run:Void->Void):Void
	{
		tasks.push({label: label, run: run, weight: weight});
		totalWeight += weight;
	}

	// reads characters/<name>.json (falls back to the default character, like Character.hx does)
	// and loads every image listed in its "image" field (can be several, separated by commas)
	function preloadCharacterImages(charName:String):Void
	{
		var path:String = Paths.getPath('characters/$charName.json', TEXT);
		#if MODS_ALLOWED
		if (!FileSystem.exists(path))
		#else
		if (!Assets.exists(path))
		#end
			path = Paths.getSharedPath('characters/' + Character.DEFAULT_CHARACTER + '.json');

		#if MODS_ALLOWED
		var json:Dynamic = Json.parse(File.getContent(path));
		#else
		var json:Dynamic = Json.parse(Assets.getText(path));
		#end

		if (json == null || json.image == null) return;

		var images:Array<String> = cast(json.image, String).split(',');
		for (img in images)
			Paths.image(img);
	}

	// ====================== LIST OF THINGS TO LOAD ======================
	function buildTasks():Void
	{
		var song = PlayState.SONG;
		if (song == null)
		{
			addTask('Nothing to load', 1, function() {});
			return;
		}

		// Notes
		var skin:String = (song.arrowSkin != null && song.arrowSkin.length > 0) ? song.arrowSkin : 'noteSkins/NOTE_assets';
		addTask('Loading notes (' + skin + ')', 1, function() { safe(function() { Paths.image(skin); }); });

		var splash:String = (song.splashSkin != null && song.splashSkin.length > 0) ? song.splashSkin : 'noteSplashes/noteSplashes';
		addTask('Loading splashes', 1, function() { safe(function() { Paths.image(splash); }); });

		// Characters (player1 = BF, player2 = opponent, gfVersion = GF)
		for (c in [song.player1, song.player2, song.gfVersion])
		{
			if (c == null || c.length < 1) continue;
			var charName:String = c;
			addTask('Loading character: ' + charName, 2, function() { safe(function() { preloadCharacterImages(charName); }); });
		}

		// Stage
		if (song.stage != null && song.stage.length > 0)
		{
			var stageName:String = song.stage;
			addTask('Loading stage: ' + stageName, 1, function() { safe(function() { StageData.getStageFile(stageName); }); });
		}

		// UI sounds
		addTask('Loading sounds', 1, function()
		{
			safe(function()
			{
				Paths.sound('missnote1');
				Paths.sound('missnote2');
				Paths.sound('missnote3');
			});
		});

		// Music (heavier steps, so the bar moves more here)
		var sName:String = Paths.formatToSongPath(song.song);
		addTask('Loading instrumental', 3, function() { safe(function() { Paths.inst(sName); }); });
		if (song.needsVoices)
		{
			addTask('Loading vocals', 3, function()
			{
				safe(function()
				{
					Paths.voices(sName);
					Paths.voices(sName, 'Player');
					Paths.voices(sName, 'Opponent');
				});
			});
		}

		// Last step
		addTask('Finishing up', 0.5, function() {});
	}

	// an error in one asset must not freeze the loading screen
	function safe(f:Void->Void):Void
	{
		try
		{
			f();
		}
		catch (e:Dynamic)
		{
			errorCount++;
			trace('[LoadingScreen] error #' + errorCount + ': ' + e);
		}
	}

	// ============================== UPDATE ==============================
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// one task at a time (main thread keeps the animation running and avoids threaded texture issues)
		if (!finished)
		{
			taskTimer += elapsed;
			if (taskTimer >= MIN_TIME_PER_TASK)
			{
				if (taskIndex < tasks.length)
				{
					var t = tasks[taskIndex];
					if (!labelShown)
					{
						// tick 1: show the label (it gets drawn this frame)
						statusText.text = t.label + '...';
						labelShown = true;
					}
					else
					{
						// tick 2: now run the task
						t.run();
						doneWeight += t.weight;
						taskIndex++;
						labelShown = false;
						taskTimer = 0;
						targetPercent = (totalWeight > 0) ? Math.min(doneWeight / totalWeight, 1) : 1;
					}
				}

				if (taskIndex >= tasks.length)
				{
					finished = true;
					targetPercent = 1;
				}
			}
		}

		// smooth the bar (same speed on any frame rate)
		shownPercent = FlxMath.lerp(shownPercent, targetPercent, 1 - Math.exp(-elapsed * BAR_SPEED));
		if (Math.abs(shownPercent - targetPercent) < 0.002) shownPercent = targetPercent;

		applyBarClip(shownPercent);
		updateTravelPosition(shownPercent);
		percentText.text = 'Loading... ' + Math.floor(shownPercent * 100) + '%';

		if (finished && shownPercent >= 1 && !leaving)
		{
			statusText.text = 'Done!';
			endTimer += elapsed;
			if (endTimer >= END_DELAY)
			{
				leaving = true;
				MusicBeatState.skipLoading = true; // go straight to PlayState (no loop)
				MusicBeatState.switchState(new PlayState());
			}
		}
	}

	// only creates a new clip rect when the width really changed
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
