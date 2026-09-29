package substates;

import backend.WeekData;
import backend.Highscore;
import backend.Song;
import backend.Mods;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;

import states.StoryMenuState;
import states.FreeplayState;
import states.DataSelectState;
import options.OptionsState;

class SonicPauseSubStateTest extends MusicBeatSubstate
{
	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Quit'];
	var chartMenuItems:Array<String> = ['Leave Charting Mode', 'End Song', 'Toggle Practice Mode', 'Toggle Botplay'];
	var difficultyChoices:Array<String> = [];

	var curSelected:Int = 0;
	var currentPage:Int = 1;
	var totalPages:Int = 1;

	var inDifficultyMenu:Bool = false;

	var pauseMusic:FlxSound;

	var practiceText:FlxText;

	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	public static var songName:String = null;

	var pauseBG:FlxSprite;
	var selectedArrow:FlxSprite;
	var pauseBAR:FlxSprite;

	var letterScale:Float = 1.9;
	var letterPath:String = 'pauseMenuEXE/letters/';

	var digitScale:Float = 1.9;
	var digitSpacing:Float = 15.2;
	var numberPath:String = 'hud/numbers/';

	var optionX:Float = 510;

	var pauseBarFinalY:Float = 0;

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;

	var normalY:Array<Float> = [130, 230, 310, 390];
	var normalArrowY:Array<Float> = [137, 245, 320, 400, 480];

  var changeDifficultyArrowX:Float = 180;

	var chartY:Array<Float> = [70, 160, 250, 340, 430];
	var chartArrowY:Array<Float> = [77, 167, 257, 347, 437];

	var chartArrowX:Array<Float> = [250, 330, 290, 300, 360];

	var letterSprites:Array<FlxSprite> = [];
	var digitSprites:Array<FlxSprite> = [];

	var skipTimeLetters:Array<FlxSprite> = [];
	var skipTimeDigits:Array<FlxSprite> = [];

	override function create()
	{
		if(Difficulty.list.length < 2)
			menuItemsOG.remove('Change Difficulty');

		totalPages = PlayState.chartingMode ? 2 : 1;
		currentPage = 1;

		for(i in 0...Difficulty.list.length)
		{
			difficultyChoices.push(Difficulty.getString(i));
		}

		difficultyChoices.push('BACK');

		setupPage();

		pauseMusic = new FlxSound();

		try
		{
			var pauseSong:String = getPauseSong();

			if(pauseSong != null)
				pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		catch(e:Dynamic)
		{
		}

		pauseMusic.volume = 0;

		if(pauseMusic.length > 0)
			pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		else
			pauseMusic.play();

		FlxG.sound.list.add(pauseMusic);

		createPauseVisuals();
		createInformation();
		createErrorText();

		regenMenu();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		super.create();
	}

	function setupPage():Void
	{
		curSelected = 0;

		if(currentPage == 2 && PlayState.chartingMode)
		{
			menuItems = chartMenuItems.copy();

			if(!PlayState.instance.startingSong)
				menuItems.push('Skip Time');
		}
		else
		{
			menuItems = menuItemsOG.copy();
		}
	}

	function changePage(direction:Int):Void
	{
		if(!PlayState.chartingMode)
			return;

		if(inDifficultyMenu)
			return;

		var newPage:Int = currentPage + direction;

		if(newPage < 1)
			newPage = totalPages;

		if(newPage > totalPages)
			newPage = 1;

		if(newPage == currentPage)
			return;

		currentPage = newPage;

		setupPage();

		if(menuItems.length > 0 && menuItems[curSelected] == 'Skip Time')
			curTime = Math.max(0, Conductor.songPosition);

		regenMenu();

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function createPauseVisuals():Void
	{
		pauseBG = new FlxSprite(0, 0);

		pauseBG.frames = Paths.getSparrowAtlas('pauseMenuEXE/exepauseBG');
		pauseBG.animation.addByPrefix('idle', 'idle', 12, true);
		pauseBG.animation.play('idle');

		pauseBG.scale.set(3.8, 3.8);
		pauseBG.updateHitbox();
		pauseBG.antialiasing = false;
		pauseBG.scrollFactor.set();

		add(pauseBG);

		selectedArrow = new FlxSprite(0, 0);
		selectedArrow.loadGraphic(Paths.image('pauseMenuEXE/selectedArrow'));

		selectedArrow.scale.set(1.9, 1.8);
		selectedArrow.updateHitbox();
		selectedArrow.antialiasing = false;
		selectedArrow.scrollFactor.set();

		add(selectedArrow);

		pauseBAR = new FlxSprite(0, 0);
		pauseBAR.loadGraphic(Paths.image('pauseMenuEXE/pauseBAR'));

		pauseBAR.scale.set(3.3, 3.3);
		pauseBAR.updateHitbox();
		pauseBAR.antialiasing = false;
		pauseBAR.scrollFactor.set();

		add(pauseBAR);

		pauseBarFinalY = 0;

		pauseBAR.y = -pauseBAR.height - 10;

		FlxTween.tween(pauseBAR, {y: pauseBarFinalY}, 0.3, {ease: FlxEase.quadOut});
	}

	function createInformation():Void
	{
		practiceText = new FlxText(0, 0, 0, 'PRACTICE MODE', 32);
		practiceText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE);
		practiceText.scrollFactor.set();
		practiceText.visible = PlayState.instance.practiceMode;

		add(practiceText);
	}

	function createErrorText():Void
	{
		missingTextBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);

		missingTextBG.scale.set(FlxG.width, FlxG.height);
		missingTextBG.updateHitbox();
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		missingTextBG.scrollFactor.set();

		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;

		add(missingText);
	}

	function getPauseSong():String
	{
		var formattedSongName:String = 'TooSlowPause';

		if(songName != null)
			formattedSongName = Paths.formatToSongPath(songName);

		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);

		if(formattedSongName == 'none')
			return null;

		if(formattedSongName != 'none' && formattedPauseMusic == 'none')
			return null;

		if(formattedSongName != '')
			return formattedSongName;

		return formattedPauseMusic;
	}

	function clearLetterArray(array:Array<FlxSprite>):Void
	{
		while(array.length > 0)
		{
			var sprite:FlxSprite = array.pop();

			if(sprite != null)
			{
				remove(sprite, true);
				sprite.destroy();
			}
		}
	}

	function clearDigitArray(array:Array<FlxSprite>):Void
	{
		while(array.length > 0)
		{
			var sprite:FlxSprite = array.pop();

			if(sprite != null)
			{
				remove(sprite, true);
				sprite.destroy();
			}
		}
	}

	function getLetterWidth(character:String):Float
	{
		var temp:FlxSprite = new FlxSprite();

		temp.loadGraphic(Paths.image(letterPath + character));
		temp.scale.set(letterScale, letterScale);
		temp.updateHitbox();

		var width:Float = temp.width;

		temp.destroy();

		return width;
	}

	function getTextWidth(text:String):Float
	{
		var totalWidth:Float = 0;

		text = text.toUpperCase();

		for(i in 0...text.length)
		{
			var character:String = text.charAt(i);

			if(character == ' ')
				totalWidth += 16 * letterScale;
			else
				totalWidth += getLetterWidth(character);
		}

		return totalWidth;
	}

	function drawText(text:String, x:Float, y:Float, array:Array<FlxSprite>):Void
	{
		clearLetterArray(array);

		text = text.toUpperCase();

		var totalWidth:Float = getTextWidth(text);
		var offsetX:Float = 0;

		for(i in 0...text.length)
		{
			var character:String = text.charAt(i);

			if(character == ' ')
			{
				offsetX += 16 * letterScale;
			}
			else
			{
				var relativeOffset:Float = offsetX - totalWidth / 2;

				var letter:FlxSprite = new FlxSprite(x + relativeOffset, y);

				letter.loadGraphic(Paths.image(letterPath + character));
				letter.scale.set(letterScale, letterScale);
				letter.updateHitbox();

				letter.antialiasing = false;
				letter.scrollFactor.set();

				add(letter);

				array.push(letter);

				offsetX += letter.width;
			}
		}
	}

	function getNumberPath(character:String):String
	{
		if(character == ':')
			return numberPath + 'colon3';

		if(character == '/')
			return numberPath + 'slash';

		return numberPath + character;
	}

	function setNumber(value:String, x:Float, y:Float, align:String, array:Array<FlxSprite>):Void
	{
		clearDigitArray(array);

		var len:Int = value.length;
		var totalWidth:Float = len * digitSpacing;
		var startX:Float = x;

		if(align == 'center')
			startX = x - totalWidth / 2;
		else if(align == 'right')
			startX = x - totalWidth + 5;

		for(i in 0...len)
		{
			var character:String = value.charAt(i);

			var digit:FlxSprite = new FlxSprite(startX + i * digitSpacing, y);

			digit.loadGraphic(Paths.image(getNumberPath(character)));
			digit.scale.set(digitScale, digitScale);
			digit.updateHitbox();

			digit.antialiasing = false;
			digit.scrollFactor.set();

			add(digit);

			array.push(digit);
		}
	}

	function formatTime(time:Float):String
	{
		var totalSeconds:Int = Math.floor(time / 1000);
		var minutes:Int = Math.floor(totalSeconds / 60);
		var seconds:Int = totalSeconds % 60;

		var minuteText:String = Std.string(minutes);
		var secondText:String = Std.string(seconds);

		if(minutes < 10)
			minuteText = '0' + minuteText;

		if(seconds < 10)
			secondText = '0' + secondText;

		return minuteText + ':' + secondText;
	}

	function getNormalLabel(option:String):String
	{
		switch(option)
		{
			case 'Resume':
				return 'RESUME';

			case 'Restart Song':
				return 'RESTART';

			case 'Change Difficulty':
				return 'CHANGE DIFFICULTY';

			case 'Quit':
				return 'QUIT';
		}

		return option.toUpperCase();
	}

	function getChartLabel(option:String):String
	{
		switch(option)
		{
			case 'Leave Charting Mode':
				return 'LEAVING CHARTING MODE';

			case 'End Song':
				return 'END SONG';

			case 'Toggle Practice Mode':
				if(PlayState.instance.practiceMode)
					return 'PRACTICE MODE ON';

				return 'TOGGLE PRACTICE MODE';

			case 'Toggle Botplay':
				if(PlayState.instance.cpuControlled)
					return 'BOTPLAY ON';

				return 'TOGGLE BOTPLAY';

			case 'Skip Time':
				return 'SKIP TIME /';
		}

		return option.toUpperCase();
	}

	function getOptionY(index:Int):Float
	{
		if(currentPage == 2)
		{
			if(index >= 0 && index < chartY.length)
				return chartY[index];

			return chartY[chartY.length - 1];
		}

		if(index >= 0 && index < normalY.length)
			return normalY[index];

		return normalY[normalY.length - 1];
	}

	function getArrowY(index:Int):Float
	{
		if(currentPage == 2)
		{
			if(index >= 0 && index < chartArrowY.length)
				return chartArrowY[index];

			return chartArrowY[chartArrowY.length - 1];
		}

		if(index >= 0 && index < normalArrowY.length)
			return normalArrowY[index];

		return normalArrowY[normalArrowY.length - 1];
	}

  function getArrowX(index:Int):Float
  {
  	if(currentPage == 1)
  	{
  		if(index >= 0 && index < menuItems.length)
  		{
  			if(menuItems[index] == 'Change Difficulty')
  				return changeDifficultyArrowX;
  		}
  	}

  	if(currentPage == 2)
  	{
  		if(index >= 0 && index < chartArrowX.length)
  			return chartArrowX[index];
  	}

  	return optionX - selectedArrow.width - 122;
  }

	function drawSkipTime(index:Int):Void
	{
		var y:Float = getOptionY(index);

		drawText('SKIP TIME /', optionX - 100, y, skipTimeLetters);
		setNumber(formatTime(curTime), optionX + 170, y + 3, 'center', skipTimeDigits);
	}

	function regenMenu():Void
	{
		clearLetterArray(letterSprites);
		clearDigitArray(digitSprites);
		clearLetterArray(skipTimeLetters);
		clearDigitArray(skipTimeDigits);

		var index:Int = 0;

		for(option in menuItems)
		{
			if(option == 'Skip Time')
			{
				drawSkipTime(index);
			}
			else
			{
				var label:String;

				if(currentPage == 2)
					label = getChartLabel(option);
				else
					label = getNormalLabel(option);

				var currentLetters:Array<FlxSprite> = [];

				drawText(label, optionX, getOptionY(index), currentLetters);

				for(sprite in currentLetters)
					letterSprites.push(sprite);
			}

			index++;
		}

		updateArrow();
	}

	function updateArrow():Void
	{
		if(selectedArrow == null)
			return;

		if(menuItems.length == 0)
			return;

		var index:Int = curSelected;

		if(index < 0)
			index = 0;

		if(index >= menuItems.length)
			index = menuItems.length - 1;

		selectedArrow.x = getArrowX(index);
		selectedArrow.y = getArrowY(index);
	}

	function changeSelection(change:Int = 0):Void
	{
		if(menuItems.length == 0)
			return;

		curSelected += change;

		if(curSelected < 0)
			curSelected = menuItems.length - 1;

		if(curSelected >= menuItems.length)
			curSelected = 0;

		if(menuItems[curSelected] == 'Skip Time')
		{
			curTime = Math.max(0, Conductor.songPosition);
			updateSkipTimeText();
		}

		updateArrow();

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function updateSkipTimeText():Void
	{
		clearLetterArray(skipTimeLetters);
		clearDigitArray(skipTimeDigits);

		if(menuItems.length == 0)
			return;

		if(menuItems[curSelected] != 'Skip Time')
			return;

		var y:Float = getOptionY(curSelected);

		drawText('SKIP TIME /', optionX - 100, y, skipTimeLetters);
		setNumber(formatTime(curTime), optionX + 170, y + 3, 'center', skipTimeDigits);
	}

	function changeSkipTime(amount:Int):Void
	{
		curTime += amount;

		if(curTime < 0)
			curTime = 0;

		var songLength:Float = FlxG.sound.music.length;

		if(songLength > 0 && curTime > songLength)
			curTime = songLength;

		updateSkipTimeText();
	}

	function handleDifficulty():Void
	{
		if(!inDifficultyMenu)
			return;

		var songLowercase:String = Paths.formatToSongPath(PlayState.SONG.song);
		var poop:String = Highscore.formatSong(songLowercase, curSelected);

		try
		{
			if(curSelected < difficultyChoices.length - 1)
			{
				Song.loadFromJson(poop, songLowercase);

				PlayState.storyDifficulty = curSelected;

				MusicBeatState.resetState();

				FlxG.sound.music.volume = 0;

				PlayState.changedDifficulty = true;
				PlayState.chartingMode = false;

				return;
			}
		}
		catch(e:haxe.Exception)
		{
			trace('ERROR! ${e.message}');

			var errorStr:String = e.message;

			if(errorStr.startsWith('[lime.utils.Assets] ERROR:'))
				errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length - 1);
			else
				errorStr += '\n\n' + e.stack;

			missingText.text = 'ERROR WHILE LOADING CHART:\n' + errorStr;
			missingText.screenCenter(Y);
			missingText.visible = true;
			missingTextBG.visible = true;

			FlxG.sound.play(Paths.sound('cancelMenu'));

			return;
		}

		currentPage = 1;
		menuItems = menuItemsOG.copy();
		inDifficultyMenu = false;

		regenMenu();
	}

	function selectCurrentOption():Void
	{
		if(inDifficultyMenu)
		{
			if(curSelected >= difficultyChoices.length - 1)
			{
				menuItems = menuItemsOG.copy();
				inDifficultyMenu = false;
				curSelected = 0;
				currentPage = 1;

				regenMenu();

				FlxG.sound.play(Paths.sound('cancelMenu'));

				return;
			}

			handleDifficulty();

			return;
		}

		if(menuItems.length == 0)
			return;

		var selected:String = menuItems[curSelected];

		switch(selected)
		{
			case 'Resume':
				close();

			case 'Restart Song':
				restartSong(false);

			case 'Change Difficulty':
				menuItems = difficultyChoices;
				inDifficultyMenu = true;
				curSelected = 0;

				regenMenu();

			case 'Quit':
				exitToDataSelect();

			case 'Leave Charting Mode':
				PlayState.chartingMode = false;
				close();

			case 'End Song':
				close();

				PlayState.instance.notes.clear();
				PlayState.instance.unspawnNotes = [];

				PlayState.instance.finishSong(true);

			case 'Toggle Practice Mode':
				PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
				PlayState.changedDifficulty = true;

				regenMenu();

			case 'Toggle Botplay':
				PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
				PlayState.changedDifficulty = true;

				regenMenu();

			case 'Skip Time':
				if(curTime < Conductor.songPosition)
				{
					PlayState.startOnTime = curTime;

					restartSong(true);
				}
				else
				{
					if(curTime != Conductor.songPosition)
					{
						PlayState.instance.clearNotesBefore(curTime);
						PlayState.instance.setSongTime(curTime);
					}

					close();
				}
		}
	}

	function exitToDataSelect():Void
	{
		PlayState.deathCounter = 0;
		PlayState.seenCutscene = false;

		PlayState.instance.canResync = false;

		Mods.loadTopMod();

		PlayState.changedDifficulty = false;
		PlayState.chartingMode = false;

		MusicBeatState.switchState(new DataSelectState());

		FlxG.camera.followLerp = 0;
	}

	public static function restartSong(noTrans:Bool = false):Void
	{
		PlayState.instance.paused = true;

		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}

		MusicBeatState.resetState();
	}

	override function update(elapsed:Float):Void
	{
		cantUnpause -= elapsed;

		if(pauseMusic != null && pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		if(controls.BACK)
		{
			if(inDifficultyMenu)
			{
				menuItems = menuItemsOG.copy();
				inDifficultyMenu = false;
				curSelected = 0;
				currentPage = 1;

				regenMenu();

				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			else
			{
				close();
			}

			return;
		}

		if(FlxG.keys.justPressed.F5)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			PlayState.nextReloadAll = true;

			MusicBeatState.resetState();

			return;
		}

		if(!inDifficultyMenu && PlayState.chartingMode)
		{
			if(controls.UI_LEFT_P)
			{
				changePage(-1);
				return;
			}

			if(controls.UI_RIGHT_P)
			{
				changePage(1);
				return;
			}
		}

		if(controls.UI_UP_P)
			changeSelection(-1);

		if(controls.UI_DOWN_P)
			changeSelection(1);

		if(menuItems.length > 0 && menuItems[curSelected] == 'Skip Time')
		{
			if(controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

				changeSkipTime(-1000);

				holdTime = 0;
			}

			if(controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

				changeSkipTime(1000);

				holdTime = 0;
			}

			if(controls.UI_LEFT || controls.UI_RIGHT)
			{
				holdTime += elapsed;

				if(holdTime > 0.5)
					curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);

				var songLength:Float = FlxG.sound.music.length;

				if(songLength > 0 && curTime >= songLength)
					curTime -= songLength;
				else if(curTime < 0 && songLength > 0)
					curTime += songLength;

				updateSkipTimeText();
			}
		}

		if(controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode))
			selectCurrentOption();
	}

	override function destroy():Void
	{
		if(pauseMusic != null)
			pauseMusic.destroy();

		clearLetterArray(letterSprites);
		clearDigitArray(digitSprites);
		clearLetterArray(skipTimeLetters);
		clearDigitArray(skipTimeDigits);

		super.destroy();
	}
}
