package states;

import backend.Paths;
import backend.MusicBeatState;
import backend.StageData;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import openfl.utils.Assets;

class LoadingState
{
	public static var loaded:Int = 0;
	public static var loadMax:Int = 0;
	public static var currentTask:String = '';
	public static var initialThreadCompleted:Bool = true;

	public static var isLoading(default, null):Bool = false;
	public static var lastError(default, null):String = "";
	public static var currentDirectory(default, null):String = "shared";

	static var queuedImages:Array<String> = [];
	static var queuedSounds:Array<String> = [];
	static var queuedMusic:Array<String> = [];
	static var switching:Bool = false;

	public static function loadAndSwitchState(target:FlxState, stopMusic:Bool = false, intrusive:Bool = true):Void
	{
		if (target == null || switching)
			return;

		if (Std.isOfType(target, PlayState))
		{
			LoadingScreen.go(target, stopMusic);
			return;
		}

		switching = true;
		lastError = "";
		loadNextDirectory();
		prepareToSong();

		if (stopMusic && FlxG.sound != null && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxTransitionableState.skipNextTransIn = true;
		try
		{
			MusicBeatState.switchState(target);
		}
		catch (e:Dynamic)
		{
			lastError = Std.string(e);
			switching = false;
			throw e;
		}
		switching = false;
	}

	public static function loadNextDirectory():Void
	{
		var next:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;
		currentDirectory = next != null && StringTools.trim(next).length > 0
			? StringTools.trim(next)
			: "shared";
		Paths.setCurrentLevel(currentDirectory);
	}

	static function _startPool():Void
	{
		currentTask = '';
		initialThreadCompleted = true;
	}

	static function _loaded():Void
	{
		currentTask = '';
		loaded = 0;
		loadMax = 0;
		initialThreadCompleted = true;
		isLoading = false;
		FlxTransitionableState.skipNextTransIn = true;
	}

	public static function prepareToSong():Void
	{
		initialThreadCompleted = true;
		currentTask = '';
		loaded = loadMax;
		isLoading = false;
		clearQueue();
	}

	public static function prepare(?images:Array<String>, ?sounds:Array<String>, ?music:Array<String>):Void
	{
		clearQueue();
		appendUnique(queuedImages, images);
		appendUnique(queuedSounds, sounds);
		appendUnique(queuedMusic, music);
		loadMax = queuedImages.length + queuedSounds.length + queuedMusic.length;
		loaded = 0;
		isLoading = loadMax > 0;
		lastError = "";

		for (id in queuedImages) validateAsset(id);
		for (id in queuedSounds) validateAsset(id);
		for (id in queuedMusic) validateAsset(id);

		loaded = loadMax;
		isLoading = false;
	}

	public static function checkLoaded():Bool
	{
		return !isLoading && loaded >= loadMax && initialThreadCompleted;
	}

	public static function reset():Void
	{
		clearQueue();
		loaded = 0;
		loadMax = 0;
		currentTask = '';
		initialThreadCompleted = true;
		isLoading = false;
		lastError = "";
		switching = false;
	}

	static function validateAsset(id:String):Void
	{
		if (id == null || id.length == 0)
			return;
		try
		{
			if (!Assets.exists(id))
				lastError = "Asset not found in OpenFL manifest: " + id;
		}
		catch (e:Dynamic)
		{
			lastError = "Asset validation failed: " + id + " (" + Std.string(e) + ")";
		}
	}

	static function appendUnique(destination:Array<String>, source:Array<String>):Void
	{
		if (source == null)
			return;
		for (id in source)
			if (id != null && id.length > 0 && destination.indexOf(id) == -1)
				destination.push(id);
	}

	static function clearQueue():Void
	{
		queuedImages = [];
		queuedSounds = [];
		queuedMusic = [];
	}
}
