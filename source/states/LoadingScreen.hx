package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import backend.MusicBeatState;
import backend.ClientPrefs;
import backend.StageData;
import objects.Character;

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
	// =========================================================================

	var bg:FlxSprite;
	var hud:FlxSprite;
	var progress:FlxSprite;
	var travel:FlxSprite;

	var statusText:FlxText;
	var percentText:FlxText;
	var songText:FlxText;

	var tasks:Array<{label:String, run:Void->Void}> = [];
	var taskIndex:Int = 0;
	var taskTimer:Float = 0;

	var targetPercent:Float = 0;
	var shownPercent:Float = 0;
	var finished:Bool = false;
	var leaving:Bool = false;
	var endTimer:Float = 0;

	var songName:String;

	public static function go():Void
	{
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
		bg = new FlxSprite().loadGraphic(Paths.image(FOLDER + bgKey));
		bg.antialiasing = aa;
		bg.setGraphicSize(FlxG.width);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		// ---------- progress bar ----------
		progress = new FlxSprite().loadGraphic(Paths.image(FOLDER + 'loadingProgress'));
		progress.antialiasing = aa;
		progress.x = (PROGRESS_X != null) ? PROGRESS_X : (FlxG.width - progress.width) / 2;
		progress.y = (PROGRESS_Y != null) ? PROGRESS_Y : FlxG.height - progress.height - 60;
		progress.clipRect = new FlxRect(0, 0, 0, progress.frameHeight);
		add(progress);

		// ---------- HUD (on top of the bar) ----------
		hud = new FlxSprite().loadGraphic(Paths.image(FOLDER + 'loadingHUD'));
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
		else
		{
			// no atlas: use as a static image
			travel.loadGraphic(Paths.image(travelKey));
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
		super.create();
	}

	function makeText(x:Float, y:Float, w:Float, text:String, size:Int, align:FlxTextAlign):FlxText
	{
		var t = new FlxText(x, y, w, text, size);
		t.setFormat(Paths.font('vcr.ttf'), size, FlxColor.WHITE, align, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		t.borderSize = 2;
		t.antialiasing = ClientPrefs.data.antialiasing;
		return t;
	}

	// ====================== LIST OF THINGS TO LOAD ======================
	function buildTasks():Void
	{
		var song = PlayState.SONG;
		if (song == null)
		{
			tasks.push({label: 'Nothing to load', run: function() {}});
			return;
		}

		// Notes
		var skin:String = (song.arrowSkin != null && song.arrowSkin.length > 0) ? song.arrowSkin : 'noteSkins/NOTE_assets';
		tasks.push({label: 'Loading notes (' + skin + ')', run: function() safe(function() Paths.image(skin))});

		var splash:String = (song.splashSkin != null && song.splashSkin.length > 0) ? song.splashSkin : 'noteSplashes/noteSplashes';
		tasks.push({label: 'Loading splashes', run: function() safe(function() Paths.image(splash))});

		// Characters (player1 = BF, player2 = opponent, gfVersion = GF)
		for (c in [song.player1, song.player2, song.gfVersion])
		{
			if (c == null || c.length < 1) continue;
			var charName:String = c;
			tasks.push({label: 'Loading character: ' + charName, run: function() safe(function()
			{
				var file = Character.getCharacterFile(charName);
				if (file != null && file.image != null) Paths.image(file.image);
			})});
		}

		// Stage
		if (song.stage != null && song.stage.length > 0)
		{
			var stageName:String = song.stage;
			tasks.push({label: 'Loading stage: ' + stageName, run: function() safe(function() StageData.getStageFile(stageName))});
		}

		// UI sounds
		tasks.push({label: 'Loading sounds', run: function() safe(function()
		{
			Paths.sound('missnote1');
			Paths.sound('missnote2');
			Paths.sound('missnote3');
		})});

		// Music
		var sName:String = Paths.formatToSongPath(song.song);
		tasks.push({label: 'Loading instrumental', run: function() safe(function() Paths.inst(sName))});
		if (song.needsVoices)
		{
			tasks.push({label: 'Loading vocals', run: function() safe(function()
			{
				Paths.voices(sName);
				Paths.voices(sName, 'Player');
				Paths.voices(sName, 'Opponent');
			})});
		}

		// Last step
		tasks.push({label: 'Finishing up', run: function() {}});
	}

	// an error in one asset must not freeze the loading screen
	inline function safe(f:Void->Dynamic):Void
	{
		try { f(); }
		catch (e:Dynamic) { trace('[LoadingScreen] error: ' + e); }
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
				taskTimer = 0;
				if (taskIndex < tasks.length)
				{
					var t = tasks[taskIndex];
					statusText.text = t.label + '...';
					t.run();
					taskIndex++;
					targetPercent = taskIndex / tasks.length;
				}
				if (taskIndex >= tasks.length)
				{
					finished = true;
					targetPercent = 1;
				}
			}
		}

		// smooth the bar
		shownPercent = FlxMath.lerp(shownPercent, targetPercent, FlxMath.bound(elapsed * 10, 0, 1));
		if (Math.abs(shownPercent - targetPercent) < 0.002) shownPercent = targetPercent;

		var w:Float = progress.frameWidth * shownPercent;
		progress.clipRect = new FlxRect(0, 0, w, progress.frameHeight);
		updateTravelPosition(shownPercent);
		percentText.text = 'Loading... ' + Math.floor(shownPercent * 100) + '%';

		if (finished && shownPercent >= 1 && !leaving)
		{
			statusText.text = 'Done!';
			endTimer += elapsed;
			if (endTimer >= END_DELAY)
			{
				leaving = true;
				MusicBeatState.switchState(new PlayState());
			}
		}
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
