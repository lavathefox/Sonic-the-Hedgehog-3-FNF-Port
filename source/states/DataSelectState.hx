package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

import backend.Song;
import backend.Paths;
import backend.MobileControls;
import backend.StageData;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class DataSelectState extends MusicBeatState
{
	static inline var SONG_ID:String = 'too-slow';

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

	var savePos:Array<Array<Float>> = [
		[2, 36],
		[114, 36],
		[226, 36]
	];

	var bg:FlxSprite;
	var text:FlxSprite;
	var arrow:FlxSprite;
	var bfDataSelect:FlxSprite;

	var blueFade:FlxSprite;
	var blackFade:FlxSprite;

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

		blueFade = new FlxSprite(0, 0);
		blueFade.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 38, 255));
		blueFade.scrollFactor.set(0, 0);
		blueFade.alpha = 0;
		add(blueFade);

		blackFade = new FlxSprite(0, 0);
		blackFade.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackFade.scrollFactor.set(0, 0);
		blackFade.alpha = 0;
		add(blackFade);

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

		bfDataSelect.animation.addByPrefix(
			'idle',
			'idle',
			24,
			true
		);

		bfDataSelect.animation.addByPrefix(
			'yeah',
			'yeah',
			12,
			false
		);

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
				startFade();
		};
	}

	function startFade():Void
	{
		blueFade.alpha = 0;
		blackFade.alpha = 0;

		FlxTween.tween(
			blueFade,
			{
				alpha: 1
			},
			0.5,
			{
				ease: FlxEase.sineIn,
				onComplete: function(tween:FlxTween)
				{
					FlxTween.tween(
						blackFade,
						{
							alpha: 1
						},
						0.6,
						{
							ease: FlxEase.sineIn,
							onComplete: function(tween:FlxTween)
							{
								startLevel();
							}
						}
					);
				}
			}
		);
	}

	/**
	 * Loads the Too Slow chart into PlayState.SONG.
	 * Works the same on every platform (including Android) and NEVER
	 * lets an exception escape: it returns false if loading fails.
	 */
	function loadChart(errors:Array<String>):Bool
	{
		// 1) Psych's own loader (assets + mods)
		try
		{
			PlayState.SONG = Song.getChart(SONG_ID, SONG_ID);
			if (PlayState.SONG != null)
			{
				Song.loadedSongName = SONG_ID;
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
			Paths.json(SONG_ID + '/' + SONG_ID),
			'example_mods/data/too-slow/too-slow.json',
			'mods/Sonic the Hedgehog 3 (FNF Port)/data/too-slow/too-slow.json',
			'mods/data/too-slow/too-slow.json',
			'mods/too-slow/data/too-slow.json'
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

					PlayState.SONG = Song.parseJSON(File.getContent(full), SONG_ID);
					if (PlayState.SONG != null)
					{
						Song.chartPath = full;
						Song.loadedSongName = SONG_ID;
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

		errors.push('No too-slow.json file found in any of the tested paths');
		#else
		try
		{
			PlayState.SONG = Song.loadFromJson(SONG_ID, SONG_ID);
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

	function startLevel():Void
	{
		var errors:Array<String> = [];

		// Never enter PlayState without a valid SONG: a null SONG is what closed the app.
		if (!loadChart(errors))
		{
			failToStart('Could not load the Too Slow chart.\n\n' + errors.join('\n'));
			return;
		}

        try
       {
        if (FlxG.sound.music != null)
        FlxG.sound.music.stop();

        LoadingState.prepareToSong(); // <<< adicione
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
		blueFade.alpha = 0;
		blackFade.alpha = 0;
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
		#if android
		if (MobileControls.isAttachedTo(this))
			MobileControls.removeFromState(this);
		#end

		super.destroy();
	}
}
