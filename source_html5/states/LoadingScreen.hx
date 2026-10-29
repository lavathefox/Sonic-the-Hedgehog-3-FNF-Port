package states;

import flixel.FlxState;
import backend.StageData;

/**
 * HTML5 replacement for source/states/LoadingState.hx.
 *
 * Project.xml adds the source_html5 folder to the classpath only when building for html5, and Haxe
 * prefers the last classpath, so this file is used instead of the original one in that case.
 * The original relies on threads (sys.thread) which browsers don't have, and it waits for them in a
 * loop that would freeze the page. Here nothing is preloaded: lime already loads the bundled assets
 * when the page opens, so the next state is simply opened right away.
 *
 * The public functions below are the ones the rest of the code base calls.
 */
class LoadingState
{
	public static var loaded:Int = 0;
	public static var loadMax:Int = 0;

	public static function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true):Void
	{
		loadNextDirectory();

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxTransitionableState.skipNextTransIn = true;
		MusicBeatState.switchState(target);
	}

	public static function loadNextDirectory():Void
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0)
			directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
	}

	// Nothing to preload in the browser (see the comment at the top of the file).
	public static function prepareToSong():Void {}

	public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null):Void {}

	public static function checkLoaded():Bool
		return true;
}
