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

	public static function getWritableDir():String
	{
		#if sys
		try
		{
			#if android
			return lime.system.System.applicationStorageDirectory;
			#elseif ios
			return lime.system.System.documentsDirectory;
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
