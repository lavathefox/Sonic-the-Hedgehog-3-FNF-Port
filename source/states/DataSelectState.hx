package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

import backend.Song;
import backend.Difficulty;
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
	static inline var SECRET_SONG_DIFFICULTY:String = 'Hard';

	// ---- Slots (Sonic 3 style: "No Save" slot + 8 saves, 3 visible at a time) ----
	static inline var SAVE_COUNT:Int = 8;

	/** Slot 0 is the "otherSave" (No Save). Slots 1..SAVE_COUNT are the real saves. */
	static inline var TOTAL_SLOTS:Int = SAVE_COUNT + 1;
	static inline var VISIBLE_SLOTS:Int = 3;

	/** Position of the first slot (the otherSave), in world pixels. */
	var slotStartX:Float = 2;
	var slotY:Float = 36;

	/** Distance between the left edge of one slot and the next one (bigger = more room for otherSave). */
	var slotSpacing:Float = 121;

	/** Width of the visible area where the slots are shown. Anything outside is clipped. */
	var windowLeft:Float = 0;
	var windowRight:Float = 0;

	/** Portrait image of each real save (index 0 = first save, NOT the otherSave). */
	var portraitImages:Array<String> = [
		'aiz_savePortrait',
		'aiz_savePortrait',
		'aiz_savePortrait',
		'aiz_savePortrait',
		'aiz_savePortrait',
		'aiz_savePortrait',
		'aiz_savePortrait',
		'aiz_savePortrait'
	];

	/**
	 * Fixed position (0 = first, 1 = second, 2 = third visible slot) where the arrow and BF stay
	 * while the slots scroll underneath them, like in Sonic 3. The cursor only leaves this
	 * position at the ends of the list, where there is nothing left to scroll.
	 */
	var cursorAnchor:Int = 1;

	/** First visible slot index (target) and the animated scroll (in pixels). */
	var scrollIndex:Int = 0;
	var scrollX:Float = 0;
	var scrollTween:FlxTween;

	/** 1 = otherSave, 2 = first real save, ... Change to 1 to start on the otherSave. */
	var selection:Int = 2;
	var isMoving:Bool = false;
	var doFlicker:Bool = true;
	var confirming:Bool = false;

	var globalTimer:Int = 1;

	var saveLift:Float = 6;
	var moveTime:Float = 0.2;

	var portraitX:Float = 5;
	var portraitY:Float = 5;

	// Arrow on the real saves (dataselectarrow)
	var arrowX:Float = 5;
	var arrowY:Float = -10;

	// ---- otherSave (No Save) ----
	/** Extra offset of the otherSave sprite (relative to the slot position). */
	var otherSaveOffsetX:Float = 0;
	var otherSaveOffsetY:Float = 0;

	/** The otherSave does not lift when selected (the dataArrow takes its place). */
	var otherSaveLift:Float = 0;

	/** noSaveText offset, relative to the otherSave. Y is below it. Adjust to your image sizes. */
	var noSaveTextX:Float = 0;
	var noSaveTextY:Float = 120;

	/** dataArrow offset, relative to the otherSave (0, 0 = exactly the same position). */
	var otherArrowX:Float = 0;
	var otherArrowY:Float = 0;

	// BF on the real saves
	var bfX:Float = 22;
	var bfY:Float = 78;

	/** Extra offset for BF when he is centered on the otherSave (fine tuning, 0 = exact center). */
	var bfOtherOffsetX:Float = 0;
	var bfOtherOffsetY:Float = 0;

	// ---- Secret (FunIsInfinite) ----
	var secretBuffer:String = '';
	var secretActive:Bool = false;

	// Mobile sequence: right, right, up, up, down, down, A
	var mobileCode:Array<String> = ['right', 'right', 'up', 'up', 'down', 'down', 'a'];
	var mobileStep:Int = 0;

	// arrow_Down: +20 on x from the save portrait (adjust Y if needed)
	var arrowDownX:Float = 60;
	var arrowDownY:Float = 75;

	// Distance (in game pixels) BF falls when jumping out of the save
	var bfJumpHeight:Float = 20;
	var bfFallDistance:Float = 300;

	// Pacing of the secret sequence (seconds). Use 0 to run a step instantly.
	var delayReveal:Float = 1;
	var delayConfused:Float = 1.8;
	var delayArrowDown:Float = 2;
	var delayBalanceHead:Float = 2.1;
	var delayLookDown:Float = 2;
	var delayJump:Float = 2;

	var secretTimers:Array<FlxTimer> = [];
	var secretFadeDone:Bool = false;
	var secretCam:FlxCamera;
	var cover:FlxSprite;
	var arrowDown:FlxSprite;

	/** Unscrolled (world) position of every slot. Filled in create(). */
	var savePos:Array<Array<Float>> = [];

	var bg:FlxSprite;
	var text:FlxSprite;
	var arrow:FlxSprite;
	var bfDataSelect:FlxSprite;
	var noSaveText:FlxSprite;

	/** Arrow graphics: normal one (real saves) and the one used on the otherSave. */
	var arrowGraphic:FlxGraphic;
	var otherArrowGraphic:FlxGraphic;
	var arrowIsOther:Bool = false;

	/** saves[0] is the otherSave sprite. portraits[0] is null (the otherSave has no portrait). */
	var saves:Array<FlxSprite> = [];
	var portraits:Array<FlxSprite> = [];

	// On-screen error message (on Android the log is hard to read)
	var errorCam:FlxCamera;
	var errorText:FlxText;

	var bfMissingAnims:Array<String> = [];
	var bfAtlasPrefixes:Map<String, Bool> = new Map();

	override public function create():Void
	{
		super.create();

		FlxG.camera.scroll.set(-320, -220);
		FlxG.camera.zoom = 3;
		FlxG.camera.pixelPerfectRender = true;

		// BG and text are added first and are NEVER touched by the scroll: they stay fixed.
		bg = new FlxSprite(0, 0);
		bg.loadGraphic(Paths.image('dataselect/dataSelect_BG'));
		add(bg);

		text = new FlxSprite(100, 200);
		text.loadGraphic(Paths.image('dataselect/dataSelectText'));
		add(text);

		// Slot positions + visible window
		savePos = [];
		for (i in 0...TOTAL_SLOTS)
		{
			var offX:Float = isOtherSave(i) ? otherSaveOffsetX : 0;
			var offY:Float = isOtherSave(i) ? otherSaveOffsetY : 0;
			savePos.push([slotStartX + i * slotSpacing + offX, slotY + offY]);
		}

		windowLeft = slotStartX - 2;
		windowRight = slotStartX + VISIBLE_SLOTS * slotSpacing - 2;

		createSaveSlots();

		// Start with the scroll already placed for the initial selection (no slide on enter)
		updateScrollTarget();
		scrollX = scrollIndex * slotSpacing;

		createArrow();
		createBfDataSelect();

		updateSelection(true);
		layoutSlots();

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

	/** True if the slot index (0-based) is the "No Save" slot. */
	inline function isOtherSave(index:Int):Bool
	{
		return index == 0;
	}

	function createSaveSlots():Void
	{
		for (i in 0...TOTAL_SLOTS)
		{
			var x:Float = savePos[i][0];
			var y:Float = savePos[i][1];

			if (isOtherSave(i))
			{
				// otherSave (No Save): no portrait, with the noSaveText below it
				var other:FlxSprite = new FlxSprite(x, y);
				other.loadGraphic(Paths.image('dataselect/otherSave'));
				add(other);
				saves.push(other);

				portraits.push(null);

				noSaveText = new FlxSprite(x + noSaveTextX, y + noSaveTextY);
				noSaveText.loadGraphic(Paths.image('dataselect/noSaveText'));
				add(noSaveText);

				continue;
			}

			var save:FlxSprite = new FlxSprite(x, y);
			save.loadGraphic(Paths.image('dataselect/dataselectSave'));
			add(save);
			saves.push(save);

			var portrait:FlxSprite = new FlxSprite(
				x + portraitX,
				y + portraitY
			);

			portrait.loadGraphic(
				Paths.image('dataselect/' + portraitImages[i - 1])
			);

			portrait.visible = false;

			add(portrait);
			portraits.push(portrait);
		}
	}

	function createArrow():Void
	{
		var index:Int = selection - 1;

		arrowGraphic = Paths.image('dataselect/dataselectarrow');
		otherArrowGraphic = Paths.image('dataselect/dataArrow');

		if (otherArrowGraphic == null)
		{
			trace('Data Select: image dataselect/dataArrow not found, using the normal arrow');
			otherArrowGraphic = arrowGraphic;
		}

		arrowIsOther = isOtherSave(index);

		arrow = new FlxSprite(
			arrowTargetX(index),
			arrowTargetY(index)
		);

		arrow.loadGraphic(arrowIsOther ? otherArrowGraphic : arrowGraphic);

		add(arrow);
	}

	/** Swaps the arrow image: dataArrow on the otherSave, dataselectarrow on the real saves. */
	function applyArrowGraphic(index:Int):Void
	{
		var wantOther:Bool = isOtherSave(index);

		if (wantOther == arrowIsOther)
			return;

		arrowIsOther = wantOther;
		arrow.loadGraphic(wantOther ? otherArrowGraphic : arrowGraphic);
	}

	function arrowTargetX(index:Int):Float
	{
		return slotScreenX(index) + (isOtherSave(index) ? otherArrowX : arrowX);
	}

	function arrowTargetY(index:Int):Float
	{
		return savePos[index][1] + (isOtherSave(index) ? otherArrowY : arrowY);
	}

	/**
	 * Final X of BF for a slot. On the otherSave he is centered horizontally on it,
	 * on the real saves he uses the normal bfX offset.
	 */
	function bfTargetX(index:Int):Float
	{
		if (isOtherSave(index))
			return slotScreenX(index) + (saves[index].width - bfDataSelect.width) / 2 + bfOtherOffsetX;

		return slotScreenX(index) + bfX;
	}

	/**
	 * Final Y of BF for a slot. On the otherSave he is centered vertically on it
	 * (taking its lift into account), on the real saves he uses the normal bfY offset.
	 */
	function bfTargetY(index:Int):Float
	{
		if (isOtherSave(index))
			return savePos[index][1] - otherSaveLift + (saves[index].height - bfDataSelect.height) / 2 + bfOtherOffsetY;

		return savePos[index][1] + bfY;
	}

	function createBfDataSelect():Void
	{
		// Final position is set in updateSelection(true), once the atlas size is known
		bfDataSelect = new FlxSprite(0, 0);

		bfDataSelect.frames = Paths.getSparrowAtlas(
			'dataselect/BFDataSelect'
		);

		addBfAnim('idle', 24, true);
		addBfAnim('yeah', 12, false);

		// ---- Secret animations ----
		addBfAnim('looking', 14, true);
		addBfAnim('confusedTransition', 12, false);
		addBfAnim('confused', 12, true);
		addBfAnim('lookAt', 12, false);
		addBfAnim('balanceHead', 12, true);
		addBfAnim('lookDown', 12, false);
		addBfAnim('landing', 12, false);
		addBfAnim('falling', 12, true);

		// If animations are missing, the atlas the game loaded is NOT the XML you edited.
		if (bfMissingAnims.length > 0)
		{
			showError(
				'BFDataSelect atlas is outdated or different!\n'
				+ 'Frames loaded: ' + bfDataSelect.frames.frames.length + '\n'
				+ 'Prefixes found: ' + [for (k in bfAtlasPrefixes.keys()) k].join(', ') + '\n'
				+ 'Missing: ' + bfMissingAnims.join(', ')
				+ inspectBfXmlFiles()
			);
		}

		bfDataSelect.animation.play('idle', true);

		add(bfDataSelect);
	}

	/**
	 * Looks for every BFDataSelect.xml on disk (assets, mods, example_mods) and reports which
	 * ones contain the new animations. Shows which copy is outdated. Desktop/Android file systems only.
	 */
	function inspectBfXmlFiles():String
	{
		#if sys
		var report:String = '\nXML copies on disk:';

		try
		{
			var candidates:Array<String> = [
				'assets/images/dataselect/BFDataSelect.xml',
				'assets/shared/images/dataselect/BFDataSelect.xml',
				'mods/images/dataselect/BFDataSelect.xml',
				'example_mods/images/dataselect/BFDataSelect.xml'
			];

			for (root in ['mods', 'example_mods'])
			{
				if (!FileSystem.exists(root) || !FileSystem.isDirectory(root))
					continue;

				for (dir in FileSystem.readDirectory(root))
					candidates.push(root + '/' + dir + '/images/dataselect/BFDataSelect.xml');
			}

			var found:Int = 0;

			for (path in candidates)
			{
				if (!FileSystem.exists(path))
					continue;

				found++;
				var hasNew:Bool = File.getContent(path).indexOf('looking0000') >= 0;
				report += '\n- ' + path + (hasNew ? '  [OK: has looking]' : '  [OUTDATED: no looking]');
			}

			if (found == 0)
				report += '\n(none found in the tested paths; cwd = ' + Sys.getCwd() + ')';
		}
		catch (e:Dynamic)
		{
			report += '\n(error while scanning: ' + e + ')';
		}

		return report;
		#else
		return '';
		#end
	}

	/**
	 * Registers an animation by prefix. If no frame starts with the exact name, it tries a
	 * case-insensitive match against the atlas (e.g. 'Looking' / 'LOOKING'), and logs the
	 * prefixes that really exist in the XML when nothing matches.
	 */
	function addBfAnim(name:String, fps:Int, loop:Bool):Void
	{
		var prefix:String = null;
		var lower:String = name.toLowerCase();
		var existing:Map<String, Bool> = new Map();

		for (f in bfDataSelect.frames.frames)
		{
			if (f.name == null)
				continue;

			if (f.name.length >= name.length && f.name.substr(0, name.length).toLowerCase() == lower)
			{
				prefix = f.name.substr(0, name.length);
				if (prefix == name)
					break;
			}

			// Name without the trailing frame number, for the log
			var base:String = ~/[0-9]+$/.replace(f.name, '');
			existing.set(base, true);
			bfAtlasPrefixes.set(base, true);
		}

		if (prefix == null)
		{
			trace('Data Select: no frames for "' + name + '". Prefixes in the XML: ' + [for (k in existing.keys()) k].join(', '));
			bfMissingAnims.push(name);
			return;
		}

		bfDataSelect.animation.addByPrefix(name, prefix, fps, loop);
	}

	// =====================================================================
	//  Slot layout / scrolling
	// =====================================================================

	/** X on screen of a slot, using the TARGET scroll (where the scroll will end up). */
	function slotScreenX(index:Int):Float
	{
		return savePos[index][0] - scrollIndex * slotSpacing;
	}

	/**
	 * The list scrolls so the selected slot stays under the cursor anchor. At the start and at the
	 * end of the list the scroll is clamped, so the cursor moves instead. Returns true if it scrolls.
	 */
	function updateScrollTarget():Bool
	{
		var index:Int = selection - 1;
		var old:Int = scrollIndex;

		var anchor:Int = Std.int(Math.max(0, Math.min(VISIBLE_SLOTS - 1, cursorAnchor)));
		var maxScroll:Int = TOTAL_SLOTS - VISIBLE_SLOTS;

		scrollIndex = Std.int(Math.max(0, Math.min(maxScroll, index - anchor)));

		return scrollIndex != old;
	}

	/** Slides the slots (only the slots: BG and text stay where they are). */
	function scrollSlots():Void
	{
		if (scrollTween != null)
			scrollTween.cancel();

		scrollTween = FlxTween.num(
			scrollX,
			scrollIndex * slotSpacing,
			moveTime,
			{ease: FlxEase.quadOut},
			function(value:Float)
			{
				scrollX = value;
			}
		);
	}

	/** Applies the scroll to every slot and clips whatever is outside the visible window. */
	function layoutSlots():Void
	{
		for (i in 0...TOTAL_SLOTS)
		{
			var x:Float = savePos[i][0] - scrollX;

			saves[i].x = x;

			var saveInside:Bool = clipToWindow(saves[i]);
			saves[i].visible = saveInside;

			// The otherSave has no portrait
			if (portraits[i] != null)
			{
				portraits[i].x = x + portraitX;

				var portraitInside:Bool = clipToWindow(portraits[i]);
				portraits[i].visible = (i == selection - 1) && portraitInside;
			}
		}

		// The noSaveText follows the otherSave (slot 0)
		if (noSaveText != null)
		{
			noSaveText.x = savePos[0][0] - scrollX + noSaveTextX;
			noSaveText.visible = clipToWindow(noSaveText);
		}
	}

	/** Crops a sprite to the visible window. Returns false if it is completely outside. */
	function clipToWindow(s:FlxSprite):Bool
	{
		var left:Float = windowLeft - s.x;
		var right:Float = windowRight - s.x;

		if (left <= 0 && right >= s.frameWidth)
		{
			if (s.clipRect != null)
				s.clipRect = null;
			return true;
		}

		var clipLeft:Float = Math.max(0, left);
		var clipWidth:Float = Math.min(s.frameWidth, right) - clipLeft;

		if (clipWidth <= 0)
			return false;

		s.clipRect = new FlxRect(clipLeft, 0, clipWidth, s.frameHeight);
		return true;
	}

	function moveCursor():Void
	{
		var index:Int = selection - 1;

		isMoving = true;

		// If the selection reached the edge of the window, the slots slide instead of the cursor.
		if (updateScrollTarget())
			scrollSlots();

		// dataArrow on the otherSave, dataselectarrow on the real saves
		applyArrowGraphic(index);

		FlxTween.tween(
			arrow,
			{
				x: arrowTargetX(index),
				y: arrowTargetY(index)
			},
			moveTime,
			{
				ease: FlxEase.quadOut
			}
		);

		// BF goes to the center of the otherSave, or back to the normal spot on the real saves
		FlxTween.tween(
			bfDataSelect,
			{
				x: bfTargetX(index),
				y: bfTargetY(index)
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

	function updateSelection(first:Bool):Void
	{
		for (i in 0...TOTAL_SLOTS)
		{
			var y:Float = savePos[i][1];

			if (i == selection - 1)
				y -= isOtherSave(i) ? otherSaveLift : saveLift;

			if (first)
			{
				saves[i].y = y;

				if (portraits[i] != null)
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

				if (portraits[i] != null)
				{
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
		}

		if (first)
		{
			var index:Int = selection - 1;

			applyArrowGraphic(index);

			arrow.x = arrowTargetX(index);
			arrow.y = arrowTargetY(index);

			bfDataSelect.x = bfTargetX(index);
			bfDataSelect.y = bfTargetY(index);
		}
	}

	function selectPrevious():Void
	{
		if (isMoving || confirming)
			return;

		if (selection <= 1)
			return;

		selection--;
		moveCursor();
		updateSelection(false);
	}

	function selectNext():Void
	{
		if (isMoving || confirming)
			return;

		if (selection >= TOTAL_SLOTS)
			return;

		selection++;
		moveCursor();
		updateSelection(false);
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

		// For now the otherSave (No Save) starts the same song as the real saves.
		// Check isOtherSave(selection - 1) here if it should do something different.
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
		if (time <= 0)
		{
			callback();
			return;
		}

		secretTimers.push(new FlxTimer().start(time, function(_:FlxTimer)
		{
			callback();
		}));
	}

	/**
	 * Plays a BF animation; if onFinish is given, it runs when the animation ends.
	 * If the animation does not exist in the atlas (wrong prefix in the XML), the sequence
	 * does NOT stall: a warning is logged and onFinish runs right away.
	 */
	function playBf(name:String, ?onFinish:Void->Void):Void
	{
		bfDataSelect.animation.finishCallback = null;

		if (!bfDataSelect.animation.exists(name))
		{
			trace('Data Select: animation "' + name + '" not found in BFDataSelect (check the prefix in the XML)');

			showError('Missing BF animation: "' + name + '"');

			if (onFinish != null)
				onFinish();

			return;
		}

		// Starts on this very frame (forced restart, first frame shown right away)
		bfDataSelect.animation.play(name, true);
		bfDataSelect.animation.curAnim.paused = false;

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
		secretFadeDone = false;
		confirming = true;
		isMoving = true;
		doFlicker = false;

		// 1) Flashes (secret) -> 2s -> fade out
		SonicFadeTransition.finishCallback = onSecretFadeOutDone;
		openSubState(new SonicFadeTransition(0.5, false, true));
	}

	function onSecretFadeOutDone():Void
	{
		// Runs only once, even if the transition calls the callback again.
		if (secretFadeDone)
			return;

		secretFadeDone = true;
		SonicFadeTransition.finishCallback = null;

		// The screen is fully covered. Put a black cover on its own camera above
		// everything, so closing the substate does not "flash" the screen.
		try
		{
			arrow.visible = false;

			secretCam = new FlxCamera();
			secretCam.bgColor = FlxColor.TRANSPARENT;
			FlxG.cameras.add(secretCam, false);

			cover = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			cover.scrollFactor.set();
			cover.cameras = [secretCam];
			add(cover);
		}
		catch (e:Dynamic)
		{
			trace('Data Select (secret cover): ' + e);
		}

		// BF starts "looking" right now, while the screen is still covered.
		playBf('looking');

		// The sequence is scheduled BEFORE closing the substate, so an error while
		// closing it can never stop the rest of the sequence.
		wait(delayReveal, revealSecret);

		// Close the substate on the next frames (not from inside its own update).
		wait(0.05, function()
		{
			try
			{
				if (subState != null)
					closeSubState();
			}
			catch (e:Dynamic)
			{
				trace('Data Select (closeSubState): ' + e);
			}
		});
	}

	function revealSecret():Void
	{
		// 2) 1s after the fade out: swap the BG, reveal the screen and BF does "looking"
		try
		{
			var majinBg = Paths.image('dataselect/dataSelect_BGMajin');
			if (majinBg != null)
				bg.loadGraphic(majinBg);
			else
				trace('Data Select: image dataselect/dataSelect_BGMajin not found');
		}
		catch (e:Dynamic)
		{
			trace('Data Select (BGMajin): ' + e);
		}

		if (cover != null)
		{
			FlxTween.tween(cover, {alpha: 0}, 0.5, {
				ease: FlxEase.sineOut,
				onComplete: function(_:FlxTween)
				{
					cover.visible = false;
				}
			});
		}

		// 3) 1.8s later: confusedTransition -> (ends) -> confused
		wait(delayConfused, function()
		{
			playBf('confusedTransition', function()
			{
				playBf('confused');

				// 4) 2s later: arrow_Down fades in
				wait(delayArrowDown, showArrowDown);
			});
		});
	}

	function showArrowDown():Void
	{
		// The otherSave has no portrait, so use the slot sprite as the reference in that case
		var reference:FlxSprite = portraits[selection - 1];
		if (reference == null)
			reference = saves[selection - 1];

		arrowDown = new FlxSprite(
			reference.x + arrowDownX,
			reference.y + arrowDownY
		);
		var arrowDownGraphic = Paths.image('dataselect/arrow_Down');
		if (arrowDownGraphic != null)
			arrowDown.loadGraphic(arrowDownGraphic);
		else
			trace('Data Select: image dataselect/arrow_Down not found');
		arrowDown.alpha = 0;
		add(arrowDown);

		FlxTween.tween(arrowDown, {alpha: 1}, 0.5, {
			ease: FlxEase.sineOut,
			onComplete: function(_:FlxTween)
			{
				// 5) After the arrow appears: lookAt
				playBf('lookAt');

				// 6) 2.1s later: balanceHead
				wait(delayBalanceHead, function()
				{
					playBf('balanceHead');

					// 7) 2s later: lookDown -> (ends) -> landing
					wait(delayLookDown, function()
					{
						playBf('lookDown', function()
						{
							playBf('landing');

							// 8) 2s later: falling + jumps out of the save portrait
							wait(delayJump, bfJumpOut);
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
						startLevel(SECRET_SONG_ID, SECRET_SONG_DIFFICULTY);
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
	function loadChart(songId:String, fileId:String, errors:Array<String>):Bool
	{
		// 1) Psych's own loader (assets + mods)
		try
		{
			PlayState.SONG = Song.getChart(fileId, songId);
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
			Paths.json(songId + '/' + fileId),
			'example_mods/data/' + songId + '/' + fileId + '.json',
			'mods/Sonic the Hedgehog 3 (FNF Port)/data/' + songId + '/' + fileId + '.json',
			'mods/data/' + songId + '/' + fileId + '.json',
			'mods/' + songId + '/data/' + fileId + '.json'
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

					PlayState.SONG = Song.parseJSON(File.getContent(full), fileId);
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

		errors.push('No ' + fileId + '.json file found in any of the tested paths');
		#else
		try
		{
			PlayState.SONG = Song.loadFromJson(fileId, songId);
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

	function startLevel(songId:String, ?difficulty:String):Void
	{
		var errors:Array<String> = [];
		var fileId:String = songId;

		// A specific difficulty (e.g. 'Hard') loads songId-hard.json and sets the difficulty for PlayState.
		if (difficulty != null)
		{
			Difficulty.resetList();

			var index:Int = Difficulty.list.indexOf(difficulty);
			if (index < 0)
			{
				Difficulty.list.push(difficulty);
				index = Difficulty.list.length - 1;
			}

			PlayState.storyDifficulty = index;
			fileId = songId + Difficulty.getFilePath(index);
		}

		// Never enter PlayState without a valid SONG: a null SONG is what closed the app.
		if (!loadChart(songId, fileId, errors))
		{
			failToStart('Could not load the chart "' + fileId + '".\n\n' + errors.join('\n'));
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

		// Keeps the slots in sync with the scroll tween (BG and text are not affected)
		layoutSlots();

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

		if (scrollTween != null)
		{
			scrollTween.cancel();
			scrollTween = null;
		}

		#if android
		if (MobileControls.isAttachedTo(this))
			MobileControls.removeFromState(this);
		#end

		super.destroy();
	}
}
