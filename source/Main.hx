package;

import debug.FPSCounter;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import lime.app.Application;
import lime.system.System;
import states.Sonic3TitleStateV2;
import backend.Highscore;
import backend.Sonic3Storage;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end

#if (linux || mac)
import lime.graphics.Image;
#end

#if desktop
import backend.ALSoftConfig;
#end

#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import sys.FileSystem;
import sys.io.File;
#end

#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end
class Main extends Sprite
{
	public static final game = {
		width: 959,
		height: 670,
		initialState: Sonic3TitleStateV2,
		framerate: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static var fpsVar:FPSCounter;

	#if CRASH_HANDLER
	static inline var CRASH_LOG_NAME:String = 'CRASH_LOG.txt';
	static inline var CRASH_LOG_LIMIT:Int = 512 * 1024;
	#end

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if (cpp && windows)
		backend.Native.fixScaling();
		#end

		var needsPermission:Bool = setupStorage();

		#if (CRASH_HANDLER && android)
		writeLaunchLog();
		#end

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end);
		#end

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		Highscore.load();

		#if HSCRIPT_ALLOWED
		setupScriptLogging();
		#end

		#if LUA_ALLOWED
		Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call));
		#end

		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();
		#end

		var startState:Class<FlxState> = needsPermission ? states.PermissionState : game.initialState;
		addChild(new FlxGame(game.width, game.height, startState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		fpsVar.visible = ClientPrefs.data.showFPS;
		addChild(fpsVar);
		Lib.current.stage.align = 'tl';
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		#end

		#if (linux || mac)
		Lib.current.stage.window.setIcon(Image.fromFile('icon.png'));
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		FlxG.signals.gameResized.add(onGameResized);
	}

	static function setupStorage():Bool
	{
		#if android
		if (!Sonic3Storage.hasPermission())
		{
			useAppStorage();
			return true;
		}

		if (Sonic3Storage.ensureFolders(true))
			Sonic3Storage.syncBundledMods();
		else
		{
			Sys.println('Could not use ' + Sonic3Storage.getRoot() + ', falling back to the app storage directory.');
			useAppStorage();
		}
		#elseif ios
		useAppStorage();
		#end

		return false;
	}

	#if mobile
	static function useAppStorage():Void
	{
		Sys.setCwd(Path.addTrailingSlash(System.applicationStorageDirectory));
	}
	#end

	#if HSCRIPT_ALLOWED
	static function setupScriptLogging():Void
	{
		Iris.warn = function(x, ?pos:haxe.PosInfos)
		{
			Iris.logLevel(WARN, x, pos);
			showScriptMessage('WARNING', x, pos, FlxColor.YELLOW);
		}

		Iris.error = function(x, ?pos:haxe.PosInfos)
		{
			Iris.logLevel(ERROR, x, pos);
			showScriptMessage('ERROR', x, pos, FlxColor.RED);
		}

		Iris.fatal = function(x, ?pos:haxe.PosInfos)
		{
			Iris.logLevel(FATAL, x, pos);
			showScriptMessage('FATAL', x, pos, 0xFFBB0000);
		}
	}

	static function showScriptMessage(prefix:String, message:Dynamic, pos:haxe.PosInfos, color:FlxColor):Void
	{
		if (PlayState.instance == null || pos == null)
			return;

		var info:HScriptInfos = cast pos;
		var showLine:Bool = info.showLine != false;
		var location:String = (info.funcName != null ? '(${info.funcName}) - ' : '') + '${info.fileName}:';

		#if LUA_ALLOWED
		if (info.isLua == true)
		{
			location += 'HScript:';
			showLine = false;
		}
		#end

		if (showLine)
			location += '${info.lineNumber}:';

		PlayState.instance.addTextToDebug('$prefix: $location $message', color);
	}
	#end

	static function onGameResized(width:Int, height:Int):Void
	{
		if (FlxG.cameras != null)
		{
			for (cam in FlxG.cameras.list)
			{
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			}
		}

		if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	#if CRASH_HANDLER
	static function getCrashFolder():String
	{
		#if android
		if (FileSystem.exists(Sonic3Storage.getRoot()))
			return Sonic3Storage.getRoot() + 'Crashes/';

		return Path.addTrailingSlash(System.applicationStorageDirectory) + 'Sonic 3 FNF Port Crashes/';
		#else
		return './crash/';
		#end
	}

	static function appendToLog(path:String, text:String):Bool
	{
		try
		{
			var folder:String = Path.directory(path);
			if (folder.length > 0 && !FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			if (FileSystem.exists(path) && FileSystem.stat(path).size > CRASH_LOG_LIMIT)
			{
				var oldPath:String = path + '.old';
				if (FileSystem.exists(oldPath))
					FileSystem.deleteFile(oldPath);
				FileSystem.rename(path, oldPath);
			}

			var isNew:Bool = !FileSystem.exists(path);
			var output = File.append(path, false);
			if (isNew)
				output.writeString('Sonic 3 FNF Port diagnostic log.\nHaxe errors are recorded here; native crashes such as SIGSEGV may stop the process before the handler runs.\n');
			output.writeString(text);
			output.close();
			return true;
		}
		catch (error:Dynamic)
		{
			Sys.println('Could not write log ' + path + ': ' + error);
			return false;
		}
	}

	#if android
	static function writeLaunchLog():Void
	{
		var lines:Array<String> = [
			'',
			'=== APP STARTED: ' + Date.now().toString() + ' ===',
			'Package: ' + Application.current.meta.get('packageName'),
			'Version: ' + Application.current.meta.get('version'),
			'Storage directory: ' + System.applicationStorageDirectory,
			'Working directory: ' + Sys.getCwd(),
			''
		];

		appendToLog(getCrashFolder() + CRASH_LOG_NAME, lines.join('\n'));
	}
	#end

	static function buildCrashReport(error:Dynamic):String
	{
		var report:StringBuf = new StringBuf();

		for (item in CallStack.exceptionStack(true))
		{
			switch (item)
			{
				case FilePos(Method(className, method), file, line, _):
					report.add('$file (line $line) - $className.$method\n');
				case FilePos(_, file, line, _):
					report.add('$file (line $line)\n');
				default:
					Sys.println(item);
			}
		}

		report.add('\nUncaught Error: ' + Std.string(error));

		#if officialBuild
		report.add('\nPlease report this error to the GitHub page: https://github.com/lavathefox/Sonic-the-Hedgehog-3-FNF-Port');
		#end

		report.add('\n\n> Crash Handler written by: sqirra-rng');
		return report.toString();
	}

	function onCrash(e:UncaughtErrorEvent):Void
	{
		var message:String = buildCrashReport(e.error);

		#if android
		var path:String = getCrashFolder() + CRASH_LOG_NAME;
		#else
		var stamp:String = Date.now().toString().replace(' ', '_').replace(':', "'");
		var path:String = getCrashFolder() + 'Sonic3FNF_' + stamp + '.txt';
		#end

		var header:String = '\n=== HAXE CRASH: ' + Date.now().toString() + ' ===\n';
		if (appendToLog(path, header + message + '\n'))
			Sys.println('Crash dump saved in ' + Path.normalize(path));

		Sys.println(message);

		#if !android
		Application.current.window.alert(message, 'Error!');
		#end

		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end

		Sys.exit(1);
	}
	#end
}
