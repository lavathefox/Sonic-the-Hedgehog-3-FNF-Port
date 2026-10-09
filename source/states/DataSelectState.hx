package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

import backend.Song;
import backend.Paths;
import backend.MobileControls;

class DataSelectState extends MusicBeatState
{
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

	function startLevel():Void
	{
		PlayState.SONG = Song.loadFromJson(
			'angel-test',
			'angel-test'
		);

		LoadingState.loadAndSwitchState(
			new PlayState()
		);
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
