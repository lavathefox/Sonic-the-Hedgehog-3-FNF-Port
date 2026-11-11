package states;

import backend.Language;
import backend.MusicBeatState;
import backend.Paths;
import backend.Song;
import backend.StageData;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.URLRequest;
import openfl.utils.AssetType;
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
	static var prepareToken:Int = 0;

	static inline var SONG_TIMEOUT_MS:Int = 90000;

	public static function loadAndSwitchState(target:FlxState, stopMusic:Bool = false, intrusive:Bool = true):Void
	{
		if (target == null || switching)
			return;

		if (Std.isOfType(target, PlayState))
		{
			if (!isLoading && loadMax == 0 && !songIsReady())
				prepareToSong();
			LoadingScreen.go(target, stopMusic);
			return;
		}

		switching = true;
		lastError = "";
		loadNextDirectory();

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

	static function _startPool():Void {}

	static function _loaded():Void
	{
		currentTask = '';
		loaded = 0;
		loadMax = 0;
		initialThreadCompleted = true;
		isLoading = false;
		FlxTransitionableState.skipNextTransIn = true;
	}

	static function songFile(key:String):String
		return Paths.getPath(Language.getFileTranslation(key) + '.' + Paths.SOUND_EXT, AssetType.SOUND, 'songs');

	static function songFolder():String
	{
		var song = PlayState.SONG;
		if (song == null) return null;
		var name:String = (Song.loadedSongName != null && Song.loadedSongName.length > 0) ? Song.loadedSongName : song.song;
		return Paths.formatToSongPath(name);
	}

	static function songIsReady():Bool
	{
		var folder:String = songFolder();
		if (folder == null) return true;
		var file:String = songFile('$folder/Inst');
		return Paths.currentTrackedSounds.exists(file) || Assets.exists(file, AssetType.SOUND);
	}

	static function vocalsFileOf(char:String):String
	{
		if (char == null || char.length == 0) return null;
		try
		{
			var path:String = Paths.getPath('characters/$char.json', AssetType.TEXT);
			if (!Assets.exists(path)) return null;
			var json:Dynamic = haxe.Json.parse(Assets.getText(path));
			if (json != null && json.vocals_file != null && Std.string(json.vocals_file).length > 0)
				return Std.string(json.vocals_file);
		}
		catch (e:Dynamic) {}
		return null;
	}

	static function finishPrepare():Void
	{
		currentTask = '';
		isLoading = false;
		initialThreadCompleted = true;
	}

	public static function prepareToSong():Void
	{
		var token:Int = ++prepareToken;
		clearQueue();
		currentTask = '';
		loaded = 0;
		loadMax = 0;

		var folder:String = songFolder();
		if (folder == null)
		{
			finishPrepare();
			return;
		}

		var song = PlayState.SONG;
		var keys:Array<String> = ['$folder/Inst'];
		if (song.needsVoices)
		{
			keys.push('$folder/Voices');
			keys.push('$folder/Voices-Player');
			keys.push('$folder/Voices-Opponent');
			for (char in [song.player1, song.player2, song.gfVersion])
			{
				var vf:String = vocalsFileOf(char);
				if (vf != null && keys.indexOf('$folder/Voices-' + vf) == -1)
					keys.push('$folder/Voices-' + vf);
			}
		}

		var pending:Array<String> = [];
		for (key in keys)
		{
			var file:String = songFile(key);
			if (Paths.currentTrackedSounds.exists(file))
			{
				Paths.localTrackedAssets.push(file); // already downloaded, keep it
				continue;
			}
			if (Assets.exists(file, AssetType.SOUND)) continue; // still bundled by Lime
			if (pending.indexOf(file) == -1) pending.push(file);
		}

		if (pending.length == 0)
		{
			finishPrepare();
			return;
		}

		loadMax = pending.length;
		loaded = 0;
		isLoading = true;
		initialThreadCompleted = false;
		currentTask = 'song ' + folder;

		haxe.Timer.delay(function()
		{
			if (token == prepareToken && isLoading)
			{
				trace('[LoadingState] timeout while downloading the song, continuing anyway');
				loaded = loadMax;
				finishPrepare();
			}
		}, SONG_TIMEOUT_MS);

		for (file in pending) downloadSong(file, token);
	}

	static function downloadSong(file:String, token:Int):Void
	{
		var snd:Sound = new Sound();
		var done:Bool = false;

		function finish(ok:Bool):Void
		{
			if (done) return;
			done = true;

			if (ok)
			{
				Paths.currentTrackedSounds.set(file, snd);
				Paths.localTrackedAssets.push(file);
			}
			else trace('[LoadingState] song file not available (ok if optional): ' + file);

			if (token != prepareToken) return;
			loaded++;
			if (loaded >= loadMax) finishPrepare();
		}

		snd.addEventListener(Event.COMPLETE, function(_) finish(true));
		snd.addEventListener(IOErrorEvent.IO_ERROR, function(_) finish(false));

		try
		{
			snd.load(new URLRequest(js.Syntax.code('encodeURI({0})', file)));
		}
		catch (e:Dynamic)
		{
			finish(false);
		}
	}

	public static function prepare(?images:Array<String>, ?sounds:Array<String>, ?music:Array<String>):Void
	{
		clearQueue();
		appendUnique(queuedImages, images);
		appendUnique(queuedSounds, sounds);
		appendUnique(queuedMusic, music);

		for (id in queuedImages) validateAsset(id);
		for (id in queuedSounds) validateAsset(id);
		for (id in queuedMusic) validateAsset(id);
	}

	public static function checkLoaded():Bool
	{
		return !isLoading && loaded >= loadMax && initialThreadCompleted;
	}

	public static function reset():Void
	{
		prepareToken++;
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
