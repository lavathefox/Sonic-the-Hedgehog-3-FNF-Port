package backend;

class PlatformUtil
{
	public static inline var name:String =
		#if windows 'windows'
		#elseif mac 'macos'
		#elseif linux 'linux'
		#elseif android 'android'
		#elseif ios 'ios'
		#elseif html5 'html5'
		#elseif CONSOLE_BUILD 'console'
		#else 'unknown'
		#end;

	public static inline var isConsole:Bool = #if CONSOLE_BUILD true #else false #end;

	public static inline var gamepadOnly:Bool = #if CONSOLE_BUILD true #else false #end;

	public static inline var isDesktop:Bool = #if desktop true #else false #end;
	public static inline var isMobile:Bool = #if mobile true #else false #end;
	public static inline var isWeb:Bool = #if html5 true #else false #end;

	public static inline var usesTouchControls:Bool = #if mobile true #else false #end;

	public static inline var supportsMods:Bool = #if MODS_ALLOWED true #else false #end;
	public static inline var supportsLua:Bool = #if LUA_ALLOWED true #else false #end;
	public static inline var supportsHScript:Bool = #if HSCRIPT_ALLOWED true #else false #end;
	public static inline var supportsVideos:Bool = #if VIDEOS_ALLOWED true #else false #end;
	public static inline var supportsDiscord:Bool = #if DISCORD_ALLOWED true #else false #end;
	public static inline var supportsHaptics:Bool = #if (android || ios || html5) true #else false #end;

	public static inline var hasFileSystem:Bool = #if sys true #else false #end;

	public static inline var canQuit:Bool = #if (html5 || ios) false #else true #end;

	public static inline var hasKeyboard:Bool = #if (mobile || CONSOLE_BUILD) false #else true #end;

	public static inline var DATA_DIR:String = #if SWITCH_BUILD 'sdmc:/switch/Sonic3-FNF-Port' #else '.' #end;

	static inline function hasDevice(path:String):Bool
		return path.indexOf(':/') > 0;

	static function stripDotSlash(path:String):String
	{
		while (StringTools.startsWith(path, './'))
			path = path.substr(2);
		return path;
	}

	#if SWITCH_BUILD
	static final SD_FOLDERS:Array<String> = ['mods', 'saves', 'crash', 'shaderCrashes'];

	static final SD_FILES:Array<String> = ['modsList.txt', 'asset_problems.txt'];

	static function isSdPath(path:String):Bool
	{
		if (SD_FILES.indexOf(path) != -1)
			return true;
		for (folder in SD_FOLDERS)
		{
			if (path == folder || StringTools.startsWith(path, folder + '/'))
				return true;
		}
		return false;
	}
	#end

	public static function toFileSystemPath(path:String):String
	{
		#if SWITCH_BUILD
		if (path == null || path == '' || hasDevice(path))
			return path;
		path = stripDotSlash(path);
		if (isSdPath(path))
			return DATA_DIR + '/' + path;
		return 'romfs:/' + path;
		#else
		return path;
		#end
	}

	public static function toWritablePath(path:String):String
	{
		#if SWITCH_BUILD
		if (path == null || path == '' || hasDevice(path))
			return path;
		return DATA_DIR + '/' + stripDotSlash(path);
		#else
		return path;
		#end
	}

	public static function getWritableDir():String
	{
		#if sys
		try
		{
			#if android
			return lime.system.System.applicationStorageDirectory;
			#elseif ios
			return lime.system.System.documentsDirectory;
			#elseif SWITCH_BUILD
			return DATA_DIR + '/';
			#else
			return haxe.io.Path.addTrailingSlash(Sys.getCwd());
			#end
		}
		catch (e:Dynamic)
		{
			trace('PlatformUtil: could not resolve a writable dir -> ' + e);
		}
		#end
		return '';
	}

	public static function describe():String
	{
		var flags:Array<String> = [];
		if (supportsMods) flags.push('mods');
		if (supportsLua) flags.push('lua');
		if (supportsHScript) flags.push('hscript');
		if (supportsVideos) flags.push('videos');
		if (supportsDiscord) flags.push('discord');
		if (supportsHaptics) flags.push('haptics');

		return '$name [' + flags.join(', ') + ']';
	}
}
