package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

import backend.Song;
import backend.Paths;
import backend.MobileControls;
import backend.StageData;
import backend.SonicFadeTransition;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class DataSelectState extends MusicBeatState
{
	static inline var SONG_ID:String = 'too-slow';
	static inline var SECRET_SONG_ID:String = 'uncontrolled-infinity';

	var selection:Int = 1;
	var isMoving:Bool = false;
	var doFlicker:Bool = true;
	var confirming:Bool = false;

	var globalTimer:Int = 1;

	var saveLift:Float = 6;
	var moveTime:Float = 0.2;

	var portraitX:Float = 5;
	var portraitY:Float = 5;

	var arrowX:Float = 5;
	var arrowY:Float = -10;

	var bfX:Float = 22;
	var bfY:Float = 78;

	// ---- Secret (FunIsInfinite) ----
	var secretBuffer:String = '';
	var secretActive:Bool = false;

	// Mobile sequence: right, right, up, up, down, down, A
	var mobileCode:Array<String> = ['right', 'right', 'up', 'up', 'down', 'down', 'a'];
	var mobileStep:Int = 0;

	// arrow_Down: +20 on x from the save portrait (adjust Y if needed)
	var arrowDownX:Float = 20;
	var arrowDownY:Float = -15;

	// Distance (in game pixels) BF falls when jumping out of the save
	var bfJumpHeight:Float = 20;
	var bfFallDistance:Float = 300;

	var secretTimers:Array<FlxTimer> = [];
	var secretCam:FlxCamera;
	var cover:FlxSprite;
	var arrowDown:FlxSprite;

	var savePos:Array<Array<Float>> = [
		[2, 36],
		[114, 36],
		[226, 36]
	];

	var bg:FlxSprite;
	var text:FlxSprite;
	var arrow:FlxSprite;
	var bfDataSelect:FlxSprite;

	var saves:Array<FlxSprite> = [];
	var portraits:Array<FlxSprite> = [];

	// On-screen error message (on Android the log is hard to read)
	var errorCam:FlxCamera;
	var errorText:FlxText;

	override public function create():Void
	{
		super.create();

		FlxG.camera.scroll.set(-320, -220);
		FlxG.camera.zoom = 3;
		FlxG.camera.pixelPerfectRender = true;

		bg = new FlxSprite(0, 0);
		bg.loadGraphic(Paths.image('dataselect/dataSelect_BG'));
		add(bg);

		text = new FlxSprite(100, 200);
		text.loadGraphic(Paths.image('dataselect/dataSelectText'));
		add(text);

		createSaveSlots();
		createArrow();
		createBfDataSelect();

		updateSelection(true);

		#if android
		MobileControls.create();
		MobileControls.addToState(this);
		MobileControls.setEnabled(true);
		MobileControls.setVisible(true);
		#end

		FlxG.sound.playMusic(
			Paths.music('DataSelect'),
			1,
			true
		);
	}

	function createSaveSlots():Void
	{
		for (i in 0...savePos.length)
		{
			var x:Float = savePos[i][0];
			var y:Float = savePos[i][1];

			var save:FlxSprite = new FlxSprite(x, y);
			save.loadGraphic(Paths.image('dataselect/dataselectSave'));
			add(save);
			saves.push(save);

			var portrait:FlxSprite = new FlxSprite(
				x + portraitX,
				y + portraitY
			);

			portrait.loadGraphic(
				Paths.image('dataselect/aiz_savePortrait')
			);

			portrait.visible = false;

			add(portrait);
			portraits.push(portrait);
		}
	}

	function createArrow():Void
	{
		var index:Int = selection - 1;

		arrow = new FlxSprite(
			savePos[index][0] + arrowX,
			savePos[index][1] + arrowY
		);

		arrow.loadGraphic(
			Paths.image('dataselect/dataselectarrow')
		);

		add(arrow);
	}

	function createBfDataSelect():Void
	{
		var index:Int = selection - 1;

		bfDataSelect = new FlxSprite(
			savePos[index][0] + bfX,
			savePos[index][1] + bfY
		);

		bfDataSelect.frames = Paths.getSparrowAtlas(
			'dataselect/BFDataSelect'
		);

		bfDataSelect.animation.addByPrefix('idle', 'idle', 24, true);
		bfDataSelect.animation.addByPrefix('yeah', 'yeah', 12, false);

		// ---- Secret animations ----
		bfDataSelect.animation.addByPrefix('looking', 'looking', 24, false);
		bfDataSelect.animation.addByPrefix('confusedTransition', 'confusedTransition', 24, false);
		bfDataSelect.animation.addByPrefix('confused', 'confused', 24, true);
		bfDataSelect.animation.addByPrefix('lookAt', 'lookAt', 24, false);
		bfDataSelect.animation.addByPrefix('balanceHead', 'balanceHead', 24, true);
		bfDataSelect.animation.addByPrefix('lookDown', 'lookDown', 24, false);
		bfDataSelect.animation.addByPrefix('landing', 'landing', 24, false);
		bfDataSelect.animation.addByPrefix('falling', 'falling', 24, true);

		bfDataSelect.animation.play('idle', true);

		add(bfDataSelect);
	}

	function moveCursor():Void
	{
		var index:Int = selection - 1;

		isMoving = true;

		FlxTween.tween(
			arrow,
			{
				x: savePos[index][0] + arrowX
			},
			moveTime,
			{
				ease: FlxEase.quadOut
			}
		);

		FlxTween.tween(
			bfDataSelect,
			{
				x: savePos[index][0] + bfX
			},
			moveTime,
			{
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween)
				{
					if (!confirming)
						isMoving = false;
				}
			}
		);

		FlxG.sound.play(
			Paths.sound('dataselectswitch')
		);
	}

	function updatePortrait():Void
	{
		for (i in 0...portraits.length)
		{
			portraits[i].visible = (i == selection - 1);
		}
	}

	function updateSelection(first:Bool):Void
	{
		for (i in 0...savePos.length)
		{
			var x:Float = savePos[i][0];
			var y:Float = savePos[i][1];

			if (i == selection - 1)
				y -= saveLift;

			if (first)
			{
				saves[i].x = x;
				saves[i].y = y;

				portraits[i].x = x + portraitX;
				portraits[i].y = y + portraitY;
			}
			else
			{
				FlxTween.tween(
					saves[i],
					{
						y: y
					},
					moveTime,
					{
						ease: FlxEase.quadOut
					}
				);

				FlxTween.tween(
					portraits[i],
					{
						y: y + portraitY
					},
					moveTime,
					{
						ease: FlxEase.quadOut
					}
				);
			}
		}

		if (first)
		{
			var index:Int = selection - 1;

			arrow.x = savePos[index][0] + arrowX;
			arrow.y = savePos[index][1] + arrowY;

			bfDataSelect.x = savePos[index][0] + bfX;
			bfDataSelect.y = savePos[index][1] + bfY;
		}

		updatePortrait();
	}

	function selectPrevious():Void
	{
		if (isMoving || confirming)
			return;

		selection--;

		if (selection > 0)
		{
			moveCursor();
			updateSelection(false);
		}
		else
		{
			selection = 1;
		}
	}

	function selectNext():Void
	{
		if (isMoving || confirming)
			return;

		selection++;

		if (selection <= savePos.length)
		{
			moveCursor();
			updateSelection(false);
		}
		else
		{
			selection = savePos.length;
		}
	}

	function confirmSelection():Void
	{
		if (confirming)
			return;

		confirming = true;
		isMoving = true;
		doFlicker = false;

		arrow.visible = true;

		FlxG.sound.play(
			Paths.sound('confirmMenu')
		);

		bfDataSelect.animation.play('yeah', true);

		bfDataSelect.animation.finishCallback = function(name:String)
		{
			if (name == 'yeah')
				startLevel(SONG_ID);
		};
	}

	// =====================================================================
	//  SECRET: FunIsInfinite
	// =====================================================================

	/** Schedules an action (automatically cancelled in destroy). */
	function wait(time:Float, callback:Void->Void):Void
	{
		secretTimers.push(new FlxTimer().start(time, function(_:FlxTimer)
		{
			callback();
		}));
	}

	/** Plays a BF animation; if onFinish is given, it runs when the animation ends. */
	function playBf(name:String, ?onFinish:Void->Void):Void
	{
		bfDataSelect.animation.finishCallback = null;
		bfDataSelect.animation.play(name, true);

		if (onFinish != null)
		{
			bfDataSelect.animation.finishCallback = function(finished:String)
			{
				if (finished != name)
					return;

				bfDataSelect.animation.finishCallback = null;
				onFinish();
			};
		}
	}

	function checkSecretCode():Void
	{
		if (!FlxG.keys.justPressed.ANY)
			return;

		var key:Int = FlxG.keys.firstJustPressed();
		if (key == -1)
			return;

		var name:String = FlxKey.toStringMap.get(key);
		if (name == null || name.length != 1)
			return;

		var code:String = SonicFadeTransition.SECRET_CODE.toUpperCase();

		secretBuffer += name;
		if (secretBuffer.length > code.length)
			secretBuffer = secretBuffer.substr(secretBuffer.length - code.length);

		if (secretBuffer == code)
			startSecret();
	}

	/** Detects right, right, up, up, down, down, A. Returns true when completed. */
	function checkMobileCode():Bool
	{
		var pressed:String = null;

		if (MobileControls.rightJustPressed)
			pressed = 'right';
		else if (MobileControls.leftJustPressed)
			pressed = 'left';
		else if (MobileControls.upJustPressed)
			pressed = 'up';
		else if (MobileControls.downJustPressed)
			pressed = 'down';
		else if (MobileControls.aJustPressed)
			pressed = 'a';

		if (pressed == null)
			return false;

		if (pressed == mobileCode[mobileStep])
		{
			mobileStep++;

			if (mobileStep >= mobileCode.length)
			{
				mobileStep = 0;
				startSecret();
				return true;
			}
		}
		else
		{
			// Wrong input: start over (if the button is the first of the sequence, it already counts as 1)
			mobileStep = (pressed == mobileCode[0]) ? 1 : 0;
		}

		return false;
	}

	function startSecret():Void
	{
		// Lock all input during the sequence
		secretActive = true;
		confirming = true;
		isMoving = true;
		doFlicker = false;

		// 1) Flashes (secret) -> 2s -> fade out
		SonicFadeTransition.finishCallback = onSecretFadeOutDone;
		openSubState(new SonicFadeTransition(0.5, false, true));
	}

	function onSecretFadeOutDone():Void
	{
		// The screen is fully covered. I put a black cover on its own camera
		// above everything, close the substate without a "flash" and continue the sequence.
		arrow.visible = false;

		secretCam = new FlxCamera();
		secretCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(secretCam, false);

		cover = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		cover.scrollFactor.set();
		cover.cameras = [secretCam];
		add(cover);

		closeSubState();

		// 2) 1s after the fade out: swap the BG, reveal the screen and BF does "looking"
		wait(1, function()
		{
			bg.loadGraphic(Paths.image('dataselect/dataSelect_BGMajin'));

			FlxTween.tween(cover, {alpha: 0}, 0.5, {
				ease: FlxEase.sineOut,
				onComplete: function(_:FlxTween)
				{
					cover.visible = false;
				}
			});

			playBf('looking');

			// 3) 1.8s later: confusedTransition -> (ends) -> confused
			wait(1.8, function()
			{
				playBf('confusedTransition', function()
				{
					playBf('confused');

					// 4) 2s later: arrow_Down fades in
					wait(2, showArrowDown);
				});
			});
		});
	}

	function showArrowDown():Void
	{
		var portrait:FlxSprite = portraits[selection - 1];

		arrowDown = new FlxSprite(
			portrait.x + arrowDownX,
			portrait.y + arrowDownY
		);
		arrowDown.loadGraphic(Paths.image('dataselect/arrow_Down'));
		arrowDown.alpha = 0;
		add(arrowDown);

		FlxTween.tween(arrowDown, {alpha: 1}, 0.5, {
			ease: FlxEase.sineOut,
			onComplete: function(_:FlxTween)
			{
				// 5) After the arrow appears: lookAt
				playBf('lookAt');

				// 6) 2.1s later: balanceHead
				wait(2.1, function()
				{
					playBf('balanceHead');

					// 7) 2s later: lookDown -> (ends) -> landing
					wait(2, function()
					{
						playBf('lookDown', function()
						{
							playBf('landing');

							// 8) 2s later: falling + jumps out of the save portrait
							wait(2, bfJumpOut);
						});
					});
				});
			}
		});
	}

	function bfJumpOut():Void
	{
		playBf('falling');

		FlxTween.tween(arrowDown, {alpha: 0}, 0.3);

		var startY:Float = bfDataSelect.y;

		// Little hop up...
		FlxTween.tween(bfDataSelect, {y: startY - bfJumpHeight}, 0.25, {
			ease: FlxEase.quadOut,
			onComplete: function(_:FlxTween)
			{
				// ...and falls off the screen
				FlxTween.tween(bfDataSelect, {y: startY + bfFallDistance}, 0.7, {
					ease: FlxEase.quadIn,
					onComplete: function(_:FlxTween)
					{
						// 9) Start the song
						startLevel(SECRET_SONG_ID);
					}
				});
			}
		});
	}

	// =====================================================================
	//  Chart / song start
	// =====================================================================

	/**
	 * Loads the given chart into PlayState.SONG.
	 * Works the same on every platform (including Android) and NEVER
	 * lets an exception escape: it returns false if loading fails.
	 */
	function loadChart(songId:String, errors:Array<String>):Bool
	{
		// 1) Psych's own loader (assets + mods)
		try
		{
			PlayState.SONG = Song.getChart(songId, songId);
			if (PlayState.SONG != null)
			{
				Song.loadedSongName = songId;
				StageData.loadDirectory(PlayState.SONG);
				return true;
			}
			errors.push('Song.getChart returned null');
		}
		catch (e:Dynamic)
		{
			errors.push('Song.getChart: ' + e);
		}

		// 2) Manual paths (only on platforms with a file system)
		#if sys
		var paths:Array<String> = [
			Paths.json(songId + '/' + songId),
			'example_mods/data/' + songId + '/' + songId + '.json',
			'mods/Sonic the Hedgehog 3 (FNF Port)/data/' + songId + '/' + songId + '.json',
			'mods/data/' + songId + '/' + songId + '.json',
			'mods/' + songId + '/data/' + songId + '.json'
		];

		// On Android the working directory may not be the expected root,
		// so also try with Sys.getCwd() prepended.
		var roots:Array<String> = ['', Sys.getCwd()];

		for (root in roots)
		{
			for (p in paths)
			{
				var full:String = root + p;
				try
				{
					if (!FileSystem.exists(full))
						continue;

					PlayState.SONG = Song.parseJSON(File.getContent(full), songId);
					if (PlayState.SONG != null)
					{
						Song.chartPath = full;
						Song.loadedSongName = songId;
						StageData.loadDirectory(PlayState.SONG);
						return true;
					}
				}
				catch (e:Dynamic)
				{
					errors.push(full + ': ' + e);
				}
			}
		}

		errors.push('No ' + songId + '.json file found in any of the tested paths');
		#else
		try
		{
			PlayState.SONG = Song.loadFromJson(songId, songId);
			if (PlayState.SONG != null)
				return true;
		}
		catch (e:Dynamic)
		{
			errors.push('Song.loadFromJson: ' + e);
		}
		#end

		PlayState.SONG = null;
		return false;
	}

	function startLevel(songId:String):Void
	{
		var errors:Array<String> = [];

		// Never enter PlayState without a valid SONG: a null SONG is what closed the app.
		if (!loadChart(songId, errors))
		{
			failToStart('Could not load the chart "' + songId + '".\n\n' + errors.join('\n'));
			return;
		}

		try
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.fadeOut(0.4, 0);

			LoadingState.prepareToSong();
			LoadingState.loadAndSwitchState(new PlayState(), true);
		}
		catch (e:Dynamic)
		{
			failToStart('Error while opening PlayState:\n' + e);
		}
	}

	function failToStart(message:String):Void
	{
		trace('Data Select: ' + message);
		FlxG.log.error('Data Select: ' + message);

		// Restore everything so the player can try again
		bfDataSelect.animation.finishCallback = null;
		bfDataSelect.animation.play('idle', true);
		confirming = false;
		isMoving = false;
		doFlicker = true;

		showError(message);
	}

	function showError(message:String):Void
	{
		if (errorCam == null)
		{
			errorCam = new FlxCamera();
			errorCam.bgColor = FlxColor.TRANSPARENT;
			FlxG.cameras.add(errorCam, false);
		}

		if (errorText == null)
		{
			errorText = new FlxText(10, 10, FlxG.width - 20, '', 20);
			errorText.color = FlxColor.RED;
			errorText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			errorText.cameras = [errorCam];
			add(errorText);
		}

		errorText.text = message;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if android
		MobileControls.update();
		#end

		globalTimer++;

		if (globalTimer >= 60)
			globalTimer = 0;

		if (doFlicker && globalTimer % 4 == 0)
			arrow.visible = !arrow.visible;

		// Secret code (only before confirming a save or starting the secret)
		if (!confirming && !secretActive)
		{
			checkSecretCode();

			// If the mobile sequence completes, A must not confirm the save
			if (!secretActive && checkMobileCode())
				return;
		}

		if (isMoving || confirming)
			return;

		if (FlxG.keys.justPressed.LEFT || MobileControls.leftJustPressed)
		{
			selectPrevious();
		}
		else if (FlxG.keys.justPressed.RIGHT || MobileControls.rightJustPressed)
		{
			selectNext();
		}

		if (FlxG.keys.justPressed.ENTER || MobileControls.aJustPressed)
			confirmSelection();
	}

	override public function destroy():Void
	{
		for (t in secretTimers)
			if (t != null)
				t.cancel();
		secretTimers = [];

		#if android
		if (MobileControls.isAttachedTo(this))
			MobileControls.removeFromState(this);
		#end

		super.destroy();
	}
}
